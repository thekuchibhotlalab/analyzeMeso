"""Session deconvolution with a shrinking 2000-frame 25th-percentile baseline.

Dependencies: numpy, scipy, pandas, h5py, oasis-deconv. Keep the companion
collect_session_deconv_stats.py alongside this script for MAT-file loading.
Use --session-folder imagingSessionDeconv to process the copied trace tree.
F0 is still the session-level 25th percentile: dff = (F - movingP25(F))/F0.
Do not use --skip-existing when migrating outputs from an older baseline.
"""
import argparse
import os
import time
from pathlib import Path

import numpy as np
import scipy.io as sio
import pandas as pd
from collect_session_deconv_stats import load_numeric_variable


def get_session_dirs(parent_directory, session_folder='imagingSession'):
    if session_folder not in ('imagingSession', 'imagingSessionDeconv'):
        raise ValueError('Unsupported session folder')
    parent_path = Path(parent_directory) / session_folder
    if not parent_path.exists():
        raise FileNotFoundError(f"Could not find imagingSession folder: {parent_path}")
    return sorted([folder for folder in parent_path.iterdir() if folder.is_dir()], key=lambda p: p.name)


def process_session_folder(folder, session_num=None, total_sessions=None, overwrite=True,
                           fixed_decay=None):
    from oasis.functions import deconvolve
    tic = time.time()
    mat_file_path = folder / 'suite2p' / 'plane0' / 'data_F.mat'
    save_path = folder / 'suite2p' / 'plane0'
    session_label = f"{session_num:03d}" if session_num is not None else "unknown"

    print("=" * 80)
    if total_sessions is not None and session_num is not None:
        print(f"Processing sorted session {session_num}/{total_sessions}: {folder.name}")
    else:
        print(f"Processing session folder: {folder.name}")
    print(f"Session folder: {folder}")
    print(f"Input trace file: {mat_file_path}")
    print(f"Output folder: {save_path}")

    if not mat_file_path.exists():
        print(f"Session {session_label}: data_F.mat not found; skipping.")
        return None

    suffix = '_fixed' if fixed_decay is not None else ''
    output_files = [save_path / f'data_{name}{suffix}.mat' for name in ('C', 'S', 'spkOps')]
    if fixed_decay is None:
        output_files.append(save_path / 'data_dff.mat')
    if not overwrite and all(path.exists() for path in output_files):
        print(f"Session {session_label}: deconvolution outputs already exist; skipping.")
        return save_path / f'data_S{suffix}.mat'

    if fixed_decay is None:
        _, allTraces = load_numeric_variable(mat_file_path, ('allTraces',))
        dff, spike_scale_factor = compute_dff(allTraces, return_scale_factor=True)
        del allTraces
        sio.savemat(save_path / 'data_dff.mat', {'dff': dff})
        provenance = {
            'baselineMethod': 'moving_percentile', 'baselinePercentile': 25,
            'baselineCorrectionWindow': 2000, 'baselineEndpoints': 'shrink',
            'percentileInterpolation': 'linear', 'normalizationPercentile': 25,
            'spikeScaleFactor': spike_scale_factor[np.newaxis, :],
            'F0': spike_scale_factor[np.newaxis, :],
        }
    else:
        _, dff = load_numeric_variable(save_path / 'data_dff.mat', ('dff', 'F'))
        provenance = {k: v for k, v in sio.loadmat(save_path / 'data_spkOps.mat').items()
                      if not k.startswith('__') and k not in ('b', 'g', 'lam')}
        if dff.shape[1] != fixed_decay['gFixed'].size:
            raise ValueError(f'{folder.name}: neuron count does not match statistics')
        provenance.update(fixed_decay)

    T, N = dff.shape
    C = np.zeros((T, N))
    S = np.zeros((T, N))
    Bs = []
    Gs = []
    Lams = []

    print(f"Session {session_label}: deconvolving {N} neurons")
    for i in range(N):
        trace = dff[:, i]
        try:
            if not np.isfinite(trace).all():
                raise ValueError('Nonfinite dff trace')
            options = {}
            if fixed_decay is not None:
                gi = fixed_decay['gFixed'][i]
                if not np.isfinite(gi):
                    raise ValueError('No valid decay estimates for this neuron')
                options = {'g': (float(gi),), 'optimize_g': 0}
            c, s, b, g, lam = deconvolve(trace, penalty=1, b_nonneg=False, **options)
            g = float(np.asarray(g).reshape(-1)[0])
        except Exception as e:
            print(f"Session {session_label}: deconvolution failed for neuron {i}: {e}")
            c = s = np.full(trace.shape, np.nan)
            b = g = lam = np.nan

        C[:, i] = c
        S[:, i] = s
        Bs.append(b)
        Gs.append(g)
        Lams.append(lam)

    sio.savemat(save_path / f'data_C{suffix}.mat', {'C': C})
    sio.savemat(save_path / f'data_S{suffix}.mat', {'S': S})
    sio.savemat(save_path / f'data_spkOps{suffix}.mat', {
        **provenance,
        'b': np.array(Bs),
        'g': np.array(Gs),
        'lam': np.array(Lams),
        'deconvolutionSuccess': np.isfinite(Gs), 'penalty': 1, 'b_nonneg': False,
    })
    print(f"Session {session_label}: saved C, S, spkOps (suffix='{suffix}')")
    print(f"Session {session_label}: finished in {time.time() - tic:.1f} sec")
    return save_path / f'data_S{suffix}.mat'


def process_all_sessions(parent_directory, overwrite=True, session_folder='imagingSession', **kwargs):
    session_dirs = get_session_dirs(parent_directory, session_folder)
    print(f"Sequential mode: found {len(session_dirs)} session folder(s).")
    for idx, folder in enumerate(session_dirs):
        process_session_folder(folder, idx + 1, len(session_dirs), overwrite=overwrite, **kwargs)


def process_one_session(parent_directory, session_num, overwrite=True, session_folder='imagingSession', **kwargs):
    session_dirs = get_session_dirs(parent_directory, session_folder)
    if session_num < 1 or session_num > len(session_dirs):
        print(
            f"Requested session {session_num}, but only found {len(session_dirs)} "
            "session folder(s). Nothing to do."
        )
        return None
    return process_session_folder(session_dirs[session_num - 1], session_num, len(session_dirs), overwrite=overwrite, **kwargs)


def process_session_bucket(parent_directory, task_id, n_tasks, overwrite=True, session_folder='imagingSession', **kwargs):
    if not (0 <= task_id < n_tasks):
        raise ValueError(f"task_id must satisfy 0 <= task_id < n_tasks, got {task_id}/{n_tasks}.")

    session_dirs = get_session_dirs(parent_directory, session_folder)
    selected = [(idx, folder) for idx, folder in enumerate(session_dirs) if idx % n_tasks == task_id]

    print("=" * 80)
    print("Parallel-safe bucket mode")
    print(f"SLURM_JOB_ID: {os.environ.get('SLURM_JOB_ID', 'not_slurm')}")
    print(f"SLURM_ARRAY_JOB_ID: {os.environ.get('SLURM_ARRAY_JOB_ID', 'not_array')}")
    print(f"SLURM_ARRAY_TASK_ID: {os.environ.get('SLURM_ARRAY_TASK_ID', 'not_array')}")
    print(f"SLURM_ARRAY_TASK_COUNT: {os.environ.get('SLURM_ARRAY_TASK_COUNT', 'not_array')}")
    print(f"Task bucket: {task_id + 1}/{n_tasks}")
    print(f"Total sorted session folders: {len(session_dirs)}")
    print(f"Selected {len(selected)} session(s):")
    for idx, folder in selected:
        print(f"  sorted_session_index={idx + 1:03d}, folder={folder.name}")

    for idx, folder in selected:
        process_session_folder(folder, idx + 1, len(session_dirs), overwrite=overwrite, **kwargs)

def compute_dff(rawTC, baseline_correction_window=2000, return_scale_factor=False):
    """
    Compute ΔF/F from raw fluorescence traces with baseline correction.

    Parameters:
    - rawTC: 2D numpy array of shape (n_frames, n_neurons)
    - baseline_correction_window: int, moving 25th-percentile window in frames.
      Centered (even windows include one extra preceding frame), shrinking
      at endpoints. Uses NumPy/pandas linear percentile interpolation.
    - return_scale_factor: if True, also return the per-neuron 25th percentile F0

    Returns:
    - dff: ΔF/F matrix, same shape as rawTC
    - If return_scale_factor is True, returns (dff, F0), with F0 shape (n_neurons,).
    """
    rawTC = np.asarray(rawTC, dtype=float)
    if rawTC.ndim != 2 or 0 in rawTC.shape:
        raise ValueError('allTraces must be a nonempty (nFrame, nNeuron) matrix')
    # Session-level F0 remains the amplitude denominator.
    spike_scale_factor = np.percentile(rawTC, 25, axis=0)  # shape: (n_neurons,)

    # Step 2: Compute dF/F = (F - F0) / F0 = F / F0 - 1
    valid = np.isfinite(rawTC).all(axis=0) & np.isfinite(spike_scale_factor) & (spike_scale_factor > 0)
    dff = np.full(rawTC.shape, np.nan)
    dff[:, valid] = rawTC[:, valid] / spike_scale_factor[None, valid] - 1

    # No padding or duplicated endpoint samples. Rolling quantile avoids
    # materializing a huge nFrame x window x nNeuron array.
    baseline_smooth = pd.DataFrame(dff).rolling(
        window=baseline_correction_window, center=True, min_periods=1
    ).quantile(0.25, interpolation='linear').to_numpy()
    
    # Step 5: Subtract smooth baseline from original dF/F
    dff_corrected = dff - baseline_smooth

    if return_scale_factor:
        return dff_corrected, spike_scale_factor
    return dff_corrected

def build_parser():
    parser = argparse.ArgumentParser(description="Compute dff and Oasis deconvolution for extracted ROI traces.")
    parser.add_argument("--base-dir", default=os.getcwd(), help="Animal/base directory. Defaults to current directory.")
    parser.add_argument('--session-folder', choices=['imagingSession', 'imagingSessionDeconv'], default='imagingSession')
    parser.add_argument(
        "--session",
        type=int,
        default=None,
        help="1-indexed sorted session number to process. If omitted, Slurm array bucket mode is used when available.",
    )
    parser.add_argument("--task-id", type=int, default=None, help="0-based task bucket. Defaults to SLURM_ARRAY_TASK_ID.")
    parser.add_argument("--n-tasks", type=int, default=None, help="Number of task buckets. Defaults to SLURM_ARRAY_TASK_COUNT.")
    parser.add_argument(
        "--skip-existing",
        action="store_true",
        help="Skip sessions where all deconvolution outputs already exist.",
    )
    return parser


def run_from_args(args, **kwargs):

    base_dir = os.path.abspath(args.base_dir)
    env_task_id = os.environ.get("SLURM_ARRAY_TASK_ID")
    env_n_tasks = os.environ.get("SLURM_ARRAY_TASK_COUNT")
    task_id = args.task_id
    n_tasks = args.n_tasks
    if task_id is None and env_task_id is not None:
        task_id = int(env_task_id)
    if n_tasks is None and env_n_tasks is not None:
        n_tasks = int(env_n_tasks)

    print(f"Base directory: {base_dir}")
    print(f"Overwrite existing outputs: {not args.skip_existing}")
    if args.session is not None:
        process_one_session(base_dir, args.session, overwrite=not args.skip_existing, session_folder=args.session_folder, **kwargs)
    elif task_id is not None or n_tasks is not None:
        if task_id is None or n_tasks is None:
            raise ValueError("--task-id and --n-tasks must be provided together.")
        process_session_bucket(base_dir, task_id, n_tasks, overwrite=not args.skip_existing, session_folder=args.session_folder, **kwargs)
    else:
        print("No session argument or SLURM_ARRAY_TASK_ID detected; processing all sessions sequentially.")
        process_all_sessions(base_dir, overwrite=not args.skip_existing, session_folder=args.session_folder, **kwargs)


def main():
    run_from_args(build_parser().parse_args())


if __name__ == '__main__':
    main()
