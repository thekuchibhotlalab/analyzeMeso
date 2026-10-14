"""Second pass: average AR(1) decay times per tracked neuron, then fix g.

Run after ALL first-pass sessions finish and collect_session_deconv_stats.py
has saved their summary. All sessions must have the same frame interval and
the same neuron column identities. Inputs are read-only; only data_C_fixed.mat,
data_S_fixed.mat and data_spkOps_fixed.mat are written, per session.
Invalid fits (nonfinite g or g outside (0,1)) are omitted from the average.
Neurons without any valid fits remain NaN in the fixed-pass outputs.
"""
from pathlib import Path
import warnings

import numpy as np
from scipy.io import loadmat

from deconvolve_TC import build_parser, get_session_dirs, run_from_args


def average_decay(g, frame_rate=None):
    """Equal session weighting in decay-time space, never in g space.

    tauFrames = -1/log(g). For common fps, averaging tauFrames is exactly
    equivalent to averaging tauSeconds and converting back at that fps.
    """
    g = np.asarray(g, dtype=float)
    if g.ndim != 2 or 0 in g.shape:
        raise ValueError('Statistics g must be nSession x nNeuron (AR1)')
    if frame_rate is not None and (not np.isfinite(frame_rate) or frame_rate <= 0):
        raise ValueError('frame_rate must be positive and finite')
    valid = np.isfinite(g) & (g > 0) & (g < 1)
    tau = np.zeros(g.shape)
    tau[valid] = -1.0 / np.log(g[valid])
    counts = valid.sum(axis=0)
    mean_tau = np.full(g.shape[1], np.nan)
    np.divide(tau.sum(axis=0), counts, out=mean_tau, where=counts > 0)
    fixed_g = np.exp(-1.0 / mean_tau)
    if np.any(counts == 0):
        warnings.warn(f'{np.sum(counts == 0)} neuron(s) have no valid decay fits; fixed outputs will be NaN')
    result = {'gFixed': fixed_g, 'tauFrames': mean_tau, 'nDecaySessions': counts}
    if frame_rate is not None:
        result.update(frameRate=frame_rate, tauSeconds=mean_tau / frame_rate)
    return result


def matlab_text(value):
    while isinstance(value, np.ndarray) and value.dtype == object:
        value = value.item()
    return ''.join(np.asarray(value).astype(str).reshape(-1))


def load_fixed_decay(stats_path, session_dirs, session_folder, frame_rate=None):
    # The supplied collector produces compact v5 files, preserving both axes.
    stats = loadmat(stats_path)
    if 'g' not in stats or 'sessionNames' not in stats:
        raise ValueError('Statistics must contain g and sessionNames; regenerate with the collector')
    names = [matlab_text(v) for v in stats['sessionNames'].reshape(-1)]
    if len(names) != len(set(names)) or set(names) != {p.name for p in session_dirs}:
        raise ValueError('Statistics sessionNames do not match selected folder; regenerate statistics')
    if 'sessionFolder' in stats and matlab_text(stats['sessionFolder']) != session_folder:
        raise ValueError('Statistics belong to a different session folder')
    g = np.asarray(stats['g'], dtype=float)
    if g.ndim != 2 or g.shape[0] != len(names):
        raise ValueError('Statistics g must have one row per session')
    # Prevent a partial or stale first pass from silently mixing decay estimates.
    rows = {name: i for i, name in enumerate(names)}
    for folder in session_dirs:
        plane = folder / 'suite2p' / 'plane0'
        if not (plane / 'data_dff.mat').is_file():
            raise FileNotFoundError(f'Missing first-pass dff: {plane}')
        ops = loadmat(plane / 'data_spkOps.mat')
        actual = np.asarray(ops['g']).reshape(-1)
        if actual.shape != g.shape[1:] or not np.allclose(actual, g[rows[folder.name]], equal_nan=True):
            raise ValueError(f'Stale statistics for {folder.name}; regenerate statistics')
        if (matlab_text(ops.get('baselineMethod', '')) != 'moving_percentile'
                or np.asarray(ops.get('baselineCorrectionWindow', 0)).item() != 2000):
            raise ValueError(f'{folder.name}: rerun first pass with the new 2000-frame percentile baseline')
    result = average_decay(g, frame_rate)
    result['decayStatsFile'] = str(Path(stats_path).resolve())
    result['decaySessionNames'] = np.array(names, dtype=object).reshape(-1, 1)
    return result


def main():
    parser = build_parser()
    parser.description = __doc__
    parser.add_argument('--stats-file', help='Override the folder-specific session_deconv_stats MAT file')
    parser.add_argument('--frame-rate', type=float,
                        help='Common frame rate of ALL sessions; saves tauSeconds as well as tauFrames')
    args = parser.parse_args()
    name = ('session_deconv_stats.mat' if args.session_folder == 'imagingSession'
            else 'session_deconv_stats_imagingSessionDeconv.mat')
    stats_path = Path(args.stats_file) if args.stats_file else Path(args.base_dir) / name
    sessions = get_session_dirs(args.base_dir, args.session_folder)
    fixed = load_fixed_decay(stats_path, sessions, args.session_folder, args.frame_rate)
    run_from_args(args, fixed_decay=fixed)


if __name__ == '__main__':
    main()
