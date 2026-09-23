import argparse
import os
import time
from pathlib import Path

import numpy as np
import scipy.io as sio
from oasis.functions import deconvolve
from scipy.ndimage import uniform_filter1d


def get_session_dirs(parent_directory):
    parent_path = Path(parent_directory) / 'imagingSession'
    if not parent_path.exists():
        raise FileNotFoundError(f"Could not find imagingSession folder: {parent_path}")
    return sorted([folder for folder in parent_path.iterdir() if folder.is_dir()], key=lambda p: p.name)


def process_session_folder(folder, session_num=None, total_sessions=None, overwrite=True):
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

    output_files = [
        save_path / 'data_dff.mat',
        save_path / 'data_C.mat',
        save_path / 'data_S.mat',
        save_path / 'data_spkOps.mat',
    ]
    if not overwrite and all(path.exists() for path in output_files):
        print(f"Session {session_label}: deconvolution outputs already exist; skipping.")
        return save_path / 'data_S.mat'

    mat_contents = sio.loadmat(mat_file_path)
    if 'allTraces' not in mat_contents:
        print(f"Session {session_label}: 'allTraces' not found in {mat_file_path}; skipping.")
        return None

    allTraces = mat_contents['allTraces']  # shape: (T, N)
    print(f"Session {session_label}: allTraces shape = {allTraces.shape}")

    dff = compute_dff(allTraces, baseline_correction_window=1000)
    sio.savemat(save_path / 'data_dff.mat', {'dff': dff})

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
            c, s, b, g, lam = deconvolve(trace, penalty=1, b_nonneg=False)
        except Exception as e:
            print(f"Session {session_label}: deconvolution failed for neuron {i}: {e}")
            c = s = np.full(trace.shape, np.nan)
            b = g = lam = np.nan

        C[:, i] = c
        S[:, i] = s
        Bs.append(b)
        Gs.append(g)
        Lams.append(lam)

    sio.savemat(save_path / 'data_C.mat', {'C': C})
    sio.savemat(save_path / 'data_S.mat', {'S': S})
    sio.savemat(save_path / 'data_spkOps.mat', {
        'b': np.array(Bs),
        'g': np.array(Gs),
        'lam': np.array(Lams)
    })
    print(f"Session {session_label}: saved data_dff.mat, data_C.mat, data_S.mat, data_spkOps.mat")
    print(f"Session {session_label}: finished in {time.time() - tic:.1f} sec")
    return save_path / 'data_S.mat'


def process_all_sessions(parent_directory, overwrite=True):
    session_dirs = get_session_dirs(parent_directory)
    print(f"Sequential mode: found {len(session_dirs)} session folder(s).")
    for idx, folder in enumerate(session_dirs):
        process_session_folder(folder, idx + 1, len(session_dirs), overwrite=overwrite)


def process_one_session(parent_directory, session_num, overwrite=True):
    session_dirs = get_session_dirs(parent_directory)
    if session_num < 1 or session_num > len(session_dirs):
        print(
            f"Requested session {session_num}, but only found {len(session_dirs)} "
            "session folder(s). Nothing to do."
        )
        return None
    return process_session_folder(session_dirs[session_num - 1], session_num, len(session_dirs), overwrite=overwrite)


def process_session_bucket(parent_directory, task_id, n_tasks, overwrite=True):
    if not (0 <= task_id < n_tasks):
        raise ValueError(f"task_id must satisfy 0 <= task_id < n_tasks, got {task_id}/{n_tasks}.")

    session_dirs = get_session_dirs(parent_directory)
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
        process_session_folder(folder, idx + 1, len(session_dirs), overwrite=overwrite)

def compute_dff(rawTC, baseline_correction_window=1000):
    """
    Compute ΔF/F from raw fluorescence traces with baseline correction.

    Parameters:
    - rawTC: 2D numpy array of shape (n_frames, n_neurons)
    - baseline_correction_window: int, window size (in frames) for moving average baseline correction

    Returns:
    - dff: ΔF/F matrix, same shape as rawTC
    """
    # Step 1: Calculate 25th percentile baseline for each neuron
    baseline = np.percentile(rawTC, 25, axis=0)  # shape: (n_neurons,)

    # Step 2: Compute dF/F = (F - F0) / F0 = F / F0 - 1
    dff = rawTC / baseline[np.newaxis, :] - 1  # shape: (n_frames, n_neurons)

    # Step 3: Smooth dF/F to get a slow fluctuating baseline (moving average)
    baseline_smooth = uniform_filter1d(dff, size=baseline_correction_window, axis=0, mode='nearest')

    baseline = uniform_filter1d(dff, size=baseline_correction_window, axis=0, mode='nearest')

    # Step 2: Subtract the mean across time (for each neuron), keeping the shape
    baseline = baseline - np.nanmean(baseline, axis=0, keepdims=True)
    
    # Step 5: Subtract smooth baseline from original dF/F
    dff_corrected = dff - baseline_smooth

    return dff_corrected

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Compute dff and Oasis deconvolution for extracted ROI traces.")
    parser.add_argument("--base-dir", default=os.getcwd(), help="Animal/base directory. Defaults to current directory.")
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
    args = parser.parse_args()

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
        process_one_session(base_dir, args.session, overwrite=not args.skip_existing)
    elif task_id is not None or n_tasks is not None:
        if task_id is None or n_tasks is None:
            raise ValueError("--task-id and --n-tasks must be provided together.")
        process_session_bucket(base_dir, task_id, n_tasks, overwrite=not args.skip_existing)
    else:
        print("No session argument or SLURM_ARRAY_TASK_ID detected; processing all sessions sequentially.")
        process_all_sessions(base_dir, overwrite=not args.skip_existing)
