"""Small synthetic checks; run with python -m unittest test_deconvolution_pipeline."""
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import numpy as np
from scipy.io import loadmat, savemat

import deconvolve_TC as first
from collect_session_deconv_stats import collect_session_deconv_stats
from deconvolve_TC_fixDecay import average_decay, load_fixed_decay


class PipelineTests(unittest.TestCase):
    def test_percentile_edges_and_even_windows(self):
        rng = np.random.default_rng(7)
        x = rng.uniform(700, 850, (31, 3))
        x[0, 0] = 5000
        x[-1, 1] = 9000
        for w in (1, 3, 4, 2000):
            actual, f0 = first.compute_dff(x, w, True)
            baseline = np.array([
                np.percentile(x[max(0, i-w//2):min(len(x), i+(w-1)//2+1)], 25, axis=0)
                for i in range(len(x))
            ])
            np.testing.assert_allclose(actual, (x-baseline)/f0, atol=1e-12)
            np.testing.assert_array_equal(f0, np.percentile(x, 25, axis=0))

    def test_decay_average_and_invalid_values(self):
        g = np.exp(-1 / np.array([[5., 10.], [15., 30.]]))
        result = average_decay(g, 15)
        np.testing.assert_allclose(result['tauFrames'], [10, 20])
        np.testing.assert_allclose(result['tauSeconds'], np.array([10, 20])/15)
        np.testing.assert_allclose(result['gFixed'], np.exp(-1/np.array([10., 20.])))
        self.assertFalse(np.allclose(result['gFixed'], g.mean(axis=0)))
        with self.assertWarns(UserWarning):
            result = average_decay([[.9, 1], [np.nan, 0], [-.1, np.inf]])
        np.testing.assert_array_equal(result['nDecaySessions'], [1, 0])
        self.assertTrue(np.isnan(result['gFixed'][1]))

    def test_bucket_partition(self):
        with tempfile.TemporaryDirectory() as root:
            for i in range(13):
                (Path(root)/'imagingSessionDeconv'/f's{i:02d}').mkdir(parents=True)
            seen = []
            with patch.object(first, 'process_session_folder', side_effect=lambda p, *a, **k: seen.append(p.name)):
                for task in range(10):
                    first.process_session_bucket(root, task, 10, session_folder='imagingSessionDeconv')
            self.assertEqual(len(seen), 13)
            self.assertEqual(len(set(seen)), 13)

    def test_real_oasis_two_passes(self):
        # Require a real OASIS installation: this also checks that optimize_g=0
        # keeps the supplied g while baseline/noise/lambda remain free.
        import oasis.functions  # noqa: F401
        rng = np.random.default_rng(42)
        with tempfile.TemporaryDirectory() as root:
            sessions = []
            for j in range(2):
                folder = Path(root)/'imagingSessionDeconv'/f'session{j}'
                plane = folder/'suite2p'/'plane0'
                plane.mkdir(parents=True)
                c = np.zeros((1200, 2))
                for t in range(1, len(c)):
                    c[t] = .94*c[t-1] + (rng.random(2)<.04)*.15
                raw = 800*(1+c+rng.normal(0, .003, c.shape))
                savemat(plane/'data_F.mat', {'allTraces': raw})
                sessions.append(folder)
                first.process_session_folder(folder)
            summary = collect_session_deconv_stats(root, 'imagingSessionDeconv')
            self.assertEqual(summary.name, 'session_deconv_stats_imagingSessionDeconv.mat')
            fixed = load_fixed_decay(summary, sessions, 'imagingSessionDeconv', 15)
            self.assertTrue(np.isfinite(fixed['gFixed']).all())
            for folder in sessions:
                plane = folder/'suite2p'/'plane0'
                original = {p.name: p.read_bytes() for p in plane.glob('*.mat')}
                first.process_session_folder(folder, fixed_decay=fixed)
                ops = loadmat(plane/'data_spkOps_fixed.mat')
                np.testing.assert_allclose(ops['g'].ravel(), fixed['gFixed'], atol=1e-12)
                self.assertTrue(np.isfinite(ops['b']).all())
                self.assertTrue(np.isfinite(ops['lam']).all())
                for name in ('S', 'C'):
                    values = loadmat(plane/f'data_{name}_fixed.mat')[name]
                    self.assertEqual(values.shape, (1200, 2))
                    self.assertTrue(np.isfinite(values).all())
                for name, content in original.items():
                    self.assertEqual((plane/name).read_bytes(), content)
                fixed_bytes = (plane/'data_S_fixed.mat').read_bytes()
                first.process_session_folder(folder, overwrite=False, fixed_decay=fixed)
                self.assertEqual((plane/'data_S_fixed.mat').read_bytes(), fixed_bytes)
            stale = loadmat(summary)
            stale['g'][0, 0] = .5
            savemat(summary, {k:v for k,v in stale.items() if not k.startswith('__')})
            with self.assertRaisesRegex(ValueError, 'Stale statistics'):
                load_fixed_decay(summary, sessions, 'imagingSessionDeconv')


if __name__ == '__main__':
    unittest.main()
