import argparse
import mmap
import os
from pathlib import Path
from typing import Optional, Tuple

import numpy as np
import scipy.io
import SimpleITK as sitk


class MovieTransformationProcessor:
    def __init__(self, base_directory: str, animal_name: str):
        self.base_directory = Path(base_directory).resolve()
        self.animal_name = animal_name
        self.transform_dir = self.base_directory / "elastix" / "alignedElastix_param"

    def _get_movie_dimensions(self, bin_file_path: Path) -> Tuple[int, int, int]:
        ops_path = bin_file_path.parent / "ops.npy"
        ops = np.load(ops_path, allow_pickle=True).item()

        x_pixels = int(ops["Lx"])
        y_pixels = int(ops["Ly"])
        file_size = bin_file_path.stat().st_size
        n_frames = file_size // (x_pixels * y_pixels * np.dtype("int16").itemsize)
        return x_pixels, y_pixels, n_frames

    def _read_frame(self, mm: mmap.mmap, start_frame: int, dimensions: Tuple[int, int, int]) -> np.ndarray:
        x_pixels, y_pixels, _ = dimensions
        bytes_per_frame = x_pixels * y_pixels * np.dtype("int16").itemsize
        offset = start_frame * bytes_per_frame

        mm.seek(offset)
        frame_data = mm.read(bytes_per_frame)
        frame = np.frombuffer(frame_data, dtype="int16")
        return frame.reshape((y_pixels, x_pixels))

    def _find_transform_file(self, session_num: int) -> Path:
        transform_file = self.transform_dir / f"{self.animal_name}_session{session_num:02d}_transform.txt"
        if transform_file.is_file():
            return transform_file
        raise FileNotFoundError(f"Could not find transform file: {transform_file}")

    def transform_movie(self, session_dir: Path, session_order: int, session_num: int, xyshift: np.ndarray) -> Path:
        bin_file_path = session_dir / "suite2p" / "plane0" / "data.bin"
        output_path = session_dir / "suite2p" / "plane0" / "data_elastix.bin"
        mean_image_path = session_dir / "suite2p" / "plane0" / "exampleImg.mat"

        if not bin_file_path.is_file():
            raise FileNotFoundError(f"Input file not found: {bin_file_path}")
        if session_num > xyshift.shape[0]:
            raise IndexError(
                f"session_num={session_num} needs row {session_num} in initial_transform_coord, "
                f"but xyshift only has {xyshift.shape[0]} rows."
            )

        dimensions = self._get_movie_dimensions(bin_file_path)
        x_pixels, y_pixels, n_frames = dimensions
        transform_param_file = self._find_transform_file(session_num)
        initial_shift = xyshift[session_num - 1, :]

        print("-" * 80)
        print(f"Folder order: {session_order}")
        print(f"Session folder: {session_dir.name}")
        print(f"Session number: {session_num}")
        print(f"Using transform txt: {transform_param_file.name}")
        print(f"Movie dimensions: Ly={y_pixels}, Lx={x_pixels}, frames={n_frames}")
        print(f"Transform file: {transform_param_file.name}")
        print(f"initial_transform_coord row {session_num}: {initial_shift}")

        transform_parameter_map = sitk.ReadParameterFile(str(transform_param_file))
        transform = sitk.TransformixImageFilter()
        transform.SetTransformParameterMap(transform_parameter_map)

        with open(bin_file_path, "rb") as f, open(output_path, "wb") as out_f:
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            try:
                for frame_idx in range(n_frames):
                    frame = self._read_frame(mm, frame_idx, dimensions)
                    frame = np.roll(frame, shift=(initial_shift[1], initial_shift[0]), axis=(0, 1))

                    sitk_frame = sitk.GetImageFromArray(np.transpose(frame))
                    transform.SetMovingImage(sitk_frame)
                    transform.Execute()
                    transformed_frame = sitk.GetArrayFromImage(transform.GetResultImage()).astype("int16")
                    transformed_frame.tofile(out_f)

                    if frame_idx == 10:
                        scipy.io.savemat(
                            mean_image_path,
                            {"img1": transformed_frame, "img0": np.transpose(frame)},
                        )
            finally:
                mm.close()

        print(f"Transformed movie saved to {output_path}")
        return output_path

    def collect_sessions(self) -> list[Path]:
        imaging_session_dir = self.base_directory / "imagingSession"
        if not imaging_session_dir.is_dir():
            raise FileNotFoundError(f"Imaging session directory not found: {imaging_session_dir}")

        session_dirs = sorted(p for p in imaging_session_dir.iterdir() if p.is_dir())
        return session_dirs

    def print_mapping(self, session_dirs: list[Path], xyshift: np.ndarray) -> None:
        print("Session-to-transform mapping:")
        for idx, session_dir in enumerate(session_dirs):
            session_num = idx + 1
            transform_file = self._find_transform_file(session_num)
            shift_text = xyshift[session_num - 1, :] if session_num <= xyshift.shape[0] else "MISSING"
            print(
                f"  folder_order={idx + 1:03d}: session_num={session_num:02d}, "
                f"folder={session_dir.name}, transform={transform_file.name}, xyshift={shift_text}"
            )

    def process_sessions(self, ops_path: Path, task_id: Optional[int], n_tasks: Optional[int]) -> None:
        xyshift = scipy.io.loadmat(ops_path)["initial_transform_coord"]
        session_dirs = self.collect_sessions()
        self.print_mapping(session_dirs, xyshift)

        if (task_id is None) != (n_tasks is None):
            raise ValueError("task_id and n_tasks must be provided together.")
        if task_id is not None and not (0 <= task_id < n_tasks):
            raise ValueError(f"task_id must satisfy 0 <= task_id < n_tasks, got {task_id}/{n_tasks}")

        if task_id is None:
            selected = list(enumerate(session_dirs))
            print(f"Processing all {len(selected)} sessions in one job.")
        else:
            selected = [(idx, session_dir) for idx, session_dir in enumerate(session_dirs) if idx % n_tasks == task_id]
            print(f"Task bucket {task_id + 1}/{n_tasks}: processing {len(selected)} session(s).")

        for idx, session_dir in selected:
            session_num = idx + 1
            try:
                self.transform_movie(session_dir, idx + 1, session_num, xyshift)
                print(f"Successfully processed {session_dir.name}")
            except Exception as exc:
                print(f"Error processing {session_dir.name}: {exc}")


def slurm_array_args() -> Tuple[Optional[int], Optional[int]]:
    task_id = os.environ.get("SLURM_ARRAY_TASK_ID")
    task_count = os.environ.get("SLURM_ARRAY_TASK_COUNT")
    if task_id is None or task_count is None:
        return None, None
    return int(task_id), int(task_count)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Apply Elastix transforms to Suite2p data.bin files, optionally as a Slurm array."
    )
    parser.add_argument("--base-dir", default=".", help="Animal/base directory. Default: current directory.")
    parser.add_argument("--animal-name", default=None, help="Animal name used in transform filenames.")
    parser.add_argument("--ops-path", default=None, help="Path to ops.mat. Default: <base-dir>/ops.mat.")
    parser.add_argument("--task-id", type=int, default=None, help="0-based task id. Defaults to SLURM_ARRAY_TASK_ID.")
    parser.add_argument("--n-tasks", type=int, default=None, help="Number of task buckets. Defaults to SLURM_ARRAY_TASK_COUNT.")
    args = parser.parse_args()

    base_dir = Path(args.base_dir).resolve()
    animal_name = args.animal_name or base_dir.name
    ops_path = Path(args.ops_path).resolve() if args.ops_path else base_dir / "ops.mat"

    task_id = args.task_id
    n_tasks = args.n_tasks
    slurm_task_id, slurm_n_tasks = slurm_array_args()
    if task_id is None:
        task_id = slurm_task_id
    if n_tasks is None:
        n_tasks = slurm_n_tasks

    print(f"Base directory: {base_dir}")
    print(f"Animal name: {animal_name}")
    print(f"Ops path: {ops_path}")
    print(f"Task id: {task_id}")
    print(f"N tasks: {n_tasks}")

    processor = MovieTransformationProcessor(str(base_dir), animal_name)
    processor.process_sessions(ops_path, task_id, n_tasks)


if __name__ == "__main__":
    main()
