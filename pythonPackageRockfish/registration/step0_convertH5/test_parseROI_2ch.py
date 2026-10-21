"""Synthetic TIFF tests; no animal data is needed."""
import tempfile
import unittest
from pathlib import Path

import h5py
import numpy as np
import tifffile
from scipy.io import loadmat

from fn_parseROI_2ch import fn_parseROI_2ch, fn_saveh5_2ch


class TestTwoChannels(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.session = self.root / "20240605_session1"
        self.session.mkdir()
        self.green = np.arange(3 * 5 * 4, dtype=np.uint16).reshape(3, 5, 4) + 40000
        self.red = np.arange(3 * 5 * 4, dtype=np.uint16).reshape(3, 5, 4)

    def check_outputs(self, outputs):
        self.assertEqual(len(outputs), 4)
        for path in outputs:
            channel, roi = path.parent.name.split("_")
            movie = self.green if channel == "green" else self.red
            expected = movie[:, :2] if roi == "PPC" else movie[:, 3:]
            with h5py.File(path) as h5:
                np.testing.assert_array_equal(h5["data"][:], expected.transpose(0, 2, 1))
                self.assertEqual(h5["data"].dtype, np.dtype("uint16"))
                self.assertEqual(h5["data"].attrs["channel"], channel)
            mean_path = path.with_name(path.name.replace("_parsed.h5", "_meanImg.mat"))
            np.testing.assert_allclose(loadmat(mean_path)["meanImg"], expected.mean(axis=0))

    def test_alternating_pages_compressed_and_uint16(self):
        movie = np.stack([self.green, self.red], axis=1).reshape(6, 5, 4)
        tifffile.imwrite(self.session / "movie.tif", movie, photometric="minisblack",
                         compression="deflate", metadata={"axes": "TYX"})
        outputs = fn_parseROI_2ch(self.root, ["PPC", "AC"], [2, 2], chunk_frames=2)
        self.check_outputs(outputs)
        with self.assertRaises(FileExistsError):
            fn_saveh5_2ch(self.session / "movie.tif", self.root, ["PPC", "AC"], [2, 2])

    def test_named_channel_axis_before_time(self):
        file = self.session / "channel_first.tiff"
        movie = np.stack([self.green, self.red], axis=0)
        tifffile.imwrite(file, movie, photometric="minisblack", metadata={"axes": "CTYX"})
        self.check_outputs(fn_saveh5_2ch(file, self.root, ["PPC", "AC"], [2, 2]))

    def test_named_channel_axis_after_time(self):
        file = self.session / "time_first.tif"
        tifffile.imwrite(file, np.stack([self.green, self.red], axis=1),
                         photometric="minisblack", metadata={"axes": "TCYX"})
        self.check_outputs(fn_saveh5_2ch(file, self.root, ["PPC", "AC"], [2, 2]))

    def test_two_samples_in_each_page(self):
        file = self.session / "samples.tif"
        tifffile.imwrite(file, np.stack([self.green, self.red], axis=-1),
                         photometric="minisblack", planarconfig="contig",
                         extrasamples=["unspecified"], metadata={"axes": "TYXS"})
        self.check_outputs(fn_saveh5_2ch(file, self.root, ["PPC", "AC"], [2, 2]))

    def test_red_first_green_only_and_stack_folder(self):
        folder = self.root / "reference_stack"
        folder.mkdir()
        file = folder / "stack.tif"
        movie = np.stack([self.red, self.green], axis=1).reshape(6, 5, 4)
        tifffile.imwrite(file, movie, photometric="minisblack")
        previous_stack = self.root / "green_PPC" / "old_stack"
        previous_stack.mkdir(parents=True)
        (previous_stack / "note.txt").write_text("keep me")
        outputs = fn_parseROI_2ch(self.root, ["PPC", "AC"], [2, 2],
                                 channel_order=("red", "green"), save_channels=("green",))
        self.assertEqual(len(outputs), 2)
        self.assertFalse((self.root / "red_PPC").exists())
        self.assertEqual(outputs[0].parent, self.root / "green_PPC")
        self.assertEqual((self.root / "green_PPC" / "stack" / "old_stack" / "note.txt").read_text(), "keep me")
        with h5py.File(outputs[0]) as h5:
            np.testing.assert_array_equal(h5["data"][:], self.green[:, :2].transpose(0, 2, 1))
            np.testing.assert_array_equal(h5["source_page_indices_0based"][:], [1, 3, 5])

    def test_filename_and_layout_match_original_converter(self):
        from fn_saveh5 import fn_saveh5

        file = self.session / "zz180_20260302_2AFC_00001.tif"
        movie = np.stack([self.green, self.red], axis=1).reshape(6, 5, 4)
        tifffile.imwrite(file, movie, photometric="minisblack")
        outputs = fn_parseROI_2ch(self.root, ["PPC", "AC"], [2, 2], layout="interleaved")
        self.check_outputs(outputs)
        original_root = self.root / "original"
        fn_saveh5(str(original_root), str(self.session), file.name, ["PPC", "AC"], [2, 2])
        for roi in ("PPC", "AC"):
            original_names = {p.name for p in (original_root / f"green_{roi}").iterdir()}
            for channel in ("green", "red"):
                new_folder = self.root / f"{channel}_{roi}"
                self.assertEqual({p.name for p in new_folder.iterdir() if p.is_file()}, original_names)
                self.assertTrue((new_folder / "zz180_20260302_2AFC1_parsed.h5").is_file())
                self.assertFalse((new_folder / self.session.name).exists())

    def test_batch_continues_after_bad_file(self):
        tifffile.imwrite(self.session / "a_bad.tif", self.green, photometric="minisblack")
        movie = np.stack([self.green, self.red], axis=1).reshape(6, 5, 4)
        tifffile.imwrite(self.session / "zz180_20260302_2AFC_00012.tif", movie,
                         photometric="minisblack")
        outputs = fn_parseROI_2ch(self.root, ["PPC", "AC"], [2, 2])
        self.check_outputs(outputs)
        self.assertTrue(all(p.name == "zz180_20260302_2AFC12_parsed.h5" for p in outputs))

    def test_reject_incomplete_pair_and_bad_roi_height(self):
        file = self.session / "odd.tif"
        tifffile.imwrite(file, self.green, photometric="minisblack")
        with self.assertRaisesRegex(ValueError, "odd page count"):
            fn_saveh5_2ch(file, self.root, ["PPC", "AC"], [2, 2])
        file = self.session / "even.tif"
        tifffile.imwrite(file, np.stack([self.green, self.red], axis=1).reshape(6, 5, 4),
                         photometric="minisblack")
        with self.assertRaisesRegex(ValueError, "ROI heights must fit"):
            fn_saveh5_2ch(file, self.root, ["PPC", "AC"], [3, 3])


if __name__ == "__main__":
    unittest.main()
