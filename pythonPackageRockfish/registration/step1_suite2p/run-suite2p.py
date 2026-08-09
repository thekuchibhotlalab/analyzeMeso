import argparse
import os
from pathlib import Path


def make_ops():
    import suite2p

    ops = suite2p.default_ops()
    ops["batch_size"] = 200
    ops["threshold_scaling"] = 2.0
    ops["fs"] = 15
    ops["tau"] = 0.2
    ops["save_mat"] = True
    ops["do_bidiphase"] = True
    ops["input_format"] = "h5"
    ops["h5py_key"] = "data"
    ops["roidetect"] = False
    return ops


def find_session_folders(imaging_dir):
    session_folders = []
    for folder in sorted(p for p in imaging_dir.iterdir() if p.is_dir()):
        h5_files = sorted(folder.glob("*.h5"))
        if h5_files:
            session_folders.append(folder)
        else:
            print(f"Skipping {folder}: no .h5 files found.")
    return session_folders


def select_task_folders(session_folders, task_id=None, n_tasks=None):
    if task_id is None or n_tasks is None:
        return session_folders
    return [folder for idx, folder in enumerate(session_folders) if idx % n_tasks == task_id]


def get_slurm_array_args():
    task_id = os.environ.get("SLURM_ARRAY_TASK_ID")
    task_count = os.environ.get("SLURM_ARRAY_TASK_COUNT")
    if task_id is None or task_count is None:
        return None, None
    return int(task_id), int(task_count)


def run_suite2p_for_folder(folder, ops):
    import suite2p

    h5_files = sorted(folder.glob("*.h5"))
    print("=" * 80)
    print(f"Running suite2p: {folder}")
    print(f"H5 files ({len(h5_files)}):")
    for h5_file in h5_files:
        print(f"  {h5_file.name}")

    db = {"data_path": [str(folder)]}
    suite2p.run_s2p(ops=ops, db=db)


def main():
    parser = argparse.ArgumentParser(
        description="Run Suite2p on each subfolder under imagingSession that contains H5 files."
    )
    parser.add_argument(
        "--base-dir",
        default=".",
        help="Animal/base folder containing imagingSession. Default: current directory.",
    )
    parser.add_argument(
        "--task-id",
        type=int,
        default=None,
        help="Optional 0-based task index. Defaults to SLURM_ARRAY_TASK_ID when available.",
    )
    parser.add_argument(
        "--n-tasks",
        type=int,
        default=None,
        help="Optional number of task buckets. Defaults to SLURM_ARRAY_TASK_COUNT when available.",
    )
    args = parser.parse_args()

    base_dir = Path(args.base_dir).expanduser().resolve()
    imaging_dir = base_dir / "imagingSession"
    if not imaging_dir.is_dir():
        raise FileNotFoundError(f"Could not find imagingSession folder: {imaging_dir}")

    task_id, n_tasks = args.task_id, args.n_tasks
    slurm_task_id, slurm_n_tasks = get_slurm_array_args()
    if task_id is None:
        task_id = slurm_task_id
    if n_tasks is None:
        n_tasks = slurm_n_tasks

    if (task_id is None) != (n_tasks is None):
        raise ValueError("--task-id and --n-tasks must be provided together.")
    if task_id is not None and not (0 <= task_id < n_tasks):
        raise ValueError(f"task_id must satisfy 0 <= task_id < n_tasks, got {task_id}/{n_tasks}.")

    session_folders = find_session_folders(imaging_dir)
    selected_folders = select_task_folders(session_folders, task_id, n_tasks)

    print(f"Base folder: {base_dir}")
    print(f"Imaging folder: {imaging_dir}")
    print(f"Total H5 session folders: {len(session_folders)}")
    if task_id is not None:
        print(f"Task bucket: {task_id + 1}/{n_tasks}; selected {len(selected_folders)} folders.")
    else:
        print(f"No task bucket selected; processing all {len(selected_folders)} folders.")

    ops = make_ops()
    for folder in selected_folders:
        run_suite2p_for_folder(folder, ops.copy())


if __name__ == "__main__":
    main()
