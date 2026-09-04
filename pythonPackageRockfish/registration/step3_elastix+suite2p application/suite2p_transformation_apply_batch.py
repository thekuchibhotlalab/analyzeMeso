import argparse
import mmap
import os
from pathlib import Path
from typing import Optional, Tuple

import numpy as np
import scipy.io
from suite2p.registration import nonrigid
from suite2p.registration import rigid


class Suite2pTransformationBatchProcessor:
    def __init__(self, base_dir: Path, imaging_dir: Path, ops_path: Path, strict_nr_limit: bool = False):
        self.base_dir = base_dir.resolve()
        self.imaging_dir = imaging_dir.resolve()
        self.ops_path = ops_path.resolve()
        self.strict_nr_limit = strict_nr_limit
        self.ops = self._load_ops(self.ops_path)

    @staticmethod
    def _load_ops(ops_path: Path) -> dict:
        ops_file = ops_path / "ops.npy"
        if not ops_file.is_file():
            raise FileNotFoundError(f"Could not find ops.npy: {ops_file}")
        ops = np.load(ops_file, allow_pickle=True).item()
        print(f"Loaded Suite2p ops from: {ops_file}")
        print(f"  Lx={ops['Lx']}, Ly={ops['Ly']}, block_size={ops['block_size']}")
        return ops

    def collect_sessions(self) -> list[Path]:
        if not self.imaging_dir.is_dir():
            raise FileNotFoundError(f"Imaging directory not found: {self.imaging_dir}")
        session_dirs = sorted(p for p in self.imaging_dir.iterdir() if p.is_dir())
        return session_dirs

    def _get_movie_dimensions(self, bin_file_path: Path) -> Tuple[int, int, int]:
        file_size = bin_file_path.stat().st_size
        x_pixels = int(self.ops["Lx"])
        y_pixels = int(self.ops["Ly"])
        n_frames = file_size // (x_pixels * y_pixels * np.dtype("int16").itemsize)
        return x_pixels, y_pixels, n_frames

    @staticmethod
    def _read_frame(mm: mmap.mmap, start_frame: int, dimensions: Tuple[int, int, int]) -> np.ndarray:
        x_pixels, y_pixels, _ = dimensions
        bytes_per_frame = x_pixels * y_pixels * np.dtype("int16").itemsize
        offset = start_frame * bytes_per_frame

        mm.seek(offset)
        frame_data = mm.read(bytes_per_frame)
        frame = np.frombuffer(frame_data, dtype="int16")
        return frame.reshape((y_pixels, x_pixels))

    def _check_nonrigid_offsets(self, cross_session_align: dict, session_dir: Path) -> None:
        if "yoff1" not in cross_session_align or "xoff1" not in cross_session_align:
            print("No xoff1/yoff1 fields found; nonrigid transform cannot be checked.")
            return

        yoff1 = np.asarray(cross_session_align["yoff1"], dtype=float)
        xoff1 = np.asarray(cross_session_align["xoff1"], dtype=float)
        max_y = float(np.nanmax(np.abs(yoff1))) if yoff1.size else np.nan
        max_x = float(np.nanmax(np.abs(xoff1))) if xoff1.size else np.nan
        limit = float(self.ops.get("maxregshiftNR", np.nan))

        print(f"Nonrigid max abs shift: yoff1={max_y:.3f}, xoff1={max_x:.3f}, ops maxregshiftNR={limit}")
        hard_limit = limit + 0.5
        if np.isfinite(limit) and (max_y > hard_limit or max_x > hard_limit):
            msg = (
                f"WARNING: {session_dir.name} has nonrigid offsets larger than "
                f"ops['maxregshiftNR']={limit} plus the expected subpixel margin. This usually means "
                "crossSessionSuite2p.mat was generated from an older Suite2p run, "
                "or Suite2p did not use the expected registration settings."
            )
            if self.strict_nr_limit:
                raise ValueError(msg)
            print(msg)

    @staticmethod
    def session_ops_index(folder_order_zero_based: int, total_sessions: int, use_legacy_copy_rule: bool) -> int:
        if use_legacy_copy_rule and total_sessions < 120:
            return folder_order_zero_based * 2
        return folder_order_zero_based

    def print_mapping(self, session_dirs: list[Path], use_legacy_copy_rule: bool) -> None:
        print("Session mapping for Suite2p transformation apply:")
        for idx, session_dir in enumerate(session_dirs):
            ops_index = self.session_ops_index(idx, len(session_dirs), use_legacy_copy_rule)
            coord_path = session_dir / "crossSessionSuite2p.mat"
            print(
                f"  folder_order={idx + 1:03d}, ops_session_index={ops_index}, "
                f"folder={session_dir.name}, coords={coord_path}"
            )

    def transform_session(
        self,
        session_dir: Path,
        folder_order: int,
        ops_session_index: int,
    ) -> Path:
        bin_file_path = session_dir / "suite2p" / "plane0" / "data_elastix.bin"
        output_path = session_dir / "suite2p" / "plane0" / "data_suite2p.bin"
        mean_image_path = session_dir / "suite2p" / "plane0" / "exampleImg_suite2p.mat"
        coord_path = session_dir / "crossSessionSuite2p.mat"

        print("-" * 80)
        print(f"Folder order: {folder_order}")
        print(f"Session folder: {session_dir.name}")
        print(f"Ops session index: {ops_session_index}")
        print(f"Coordinates loaded from: {coord_path}")
        print(f"Input bin: {bin_file_path}")
        print(f"Output bin: {output_path}")

        if not bin_file_path.is_file():
            raise FileNotFoundError(f"Input file not found: {bin_file_path}")
        if not coord_path.is_file():
            raise FileNotFoundError(f"Coordinate file not found: {coord_path}")

        cross_session_align = scipy.io.loadmat(coord_path)
        dimensions = self._get_movie_dimensions(bin_file_path)
        x_pixels, y_pixels, n_frames = dimensions
        print(f"Movie dimensions: Ly={y_pixels}, Lx={x_pixels}, frames={n_frames}")
        print(f"Rigid shift: yoff={cross_session_align['yoff'][0][0]}, xoff={cross_session_align['xoff'][0][0]}")
        print(
            f"Nonrigid coords: yoff1 shape={cross_session_align['yoff1'].shape}, "
            f"xoff1 shape={cross_session_align['xoff1'].shape}"
        )
        self._check_nonrigid_offsets(cross_session_align, session_dir)

        blocks = nonrigid.make_blocks(Ly=y_pixels, Lx=x_pixels, block_size=self.ops["block_size"])

        with open(bin_file_path, "rb") as f, open(output_path, "wb") as out_f:
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            try:
                for frame_idx in range(n_frames):
                    frame = self._read_frame(mm, frame_idx, dimensions)
                    frame32 = frame.astype("float32").reshape((1, y_pixels, x_pixels))

                    transformed = rigid.shift_frame(
                        frame=frame32,
                        dy=cross_session_align["yoff"][0][0],
                        dx=cross_session_align["xoff"][0][0],
                    )
                    transformed = nonrigid.transform_data(
                        data=transformed,
                        nblocks=blocks[2],
                        xblock=blocks[1],
                        yblock=blocks[0],
                        ymax1=cross_session_align["yoff1"].reshape(1, -1),
                        xmax1=cross_session_align["xoff1"].reshape(1, -1),
                    )
                    transformed = transformed.astype("int16")
                    transformed = transformed.transpose((0, 2, 1))
                    transformed.tofile(out_f)

                    if frame_idx == 1:
                        scipy.io.savemat(
                            mean_image_path,
                            {
                                "img1": np.squeeze(np.mean(transformed, axis=0)),
                                "img0": np.squeeze(np.mean(frame, axis=0)),
                            },
                        )
            finally:
                mm.close()

        print(f"Transformed movie saved to {output_path}")
        return output_path

    def process_sessions(
        self,
        task_id: Optional[int],
        n_tasks: Optional[int],
        use_legacy_copy_rule: bool,
    ) -> None:
        session_dirs = self.collect_sessions()
        self.print_mapping(session_dirs, use_legacy_copy_rule)

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
            ops_session_index = self.session_ops_index(idx, len(session_dirs), use_legacy_copy_rule)
            try:
                self.transform_session(session_dir, idx + 1, ops_session_index)
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
        description="Apply Suite2p rigid/nonrigid transformations to data_elastix.bin files."
    )
    parser.add_argument("--base-dir", default=".", help="Animal/base directory. Default: current directory.")
    parser.add_argument(
        "--imaging-dir",
        default=None,
        help="Folder containing session subfolders. Default: <base-dir>/imagingSession.",
    )
    parser.add_argument(
        "--ops-path",
        default=None,
        help="Folder containing Suite2p ops.npy. Default: <base-dir>/elastix/alignedElastix/suite2p/plane0.",
    )
    parser.add_argument("--task-id", type=int, default=None, help="0-based task id. Defaults to SLURM_ARRAY_TASK_ID.")
    parser.add_argument("--n-tasks", type=int, default=None, help="Number of task buckets. Defaults to SLURM_ARRAY_TASK_COUNT.")
    parser.add_argument(
        "--no-legacy-copy-rule",
        action="store_true",
        help="Disable old idx*2 session-index print rule for <120 sessions.",
    )
    parser.add_argument(
        "--strict-nr-limit",
        action="store_true",
        help="Stop if crossSessionSuite2p.mat xoff1/yoff1 exceed ops['maxregshiftNR'].",
    )
    args = parser.parse_args()

    base_dir = Path(args.base_dir).resolve()
    imaging_dir = Path(args.imaging_dir).resolve() if args.imaging_dir else base_dir / "imagingSession"
    ops_path = Path(args.ops_path).resolve() if args.ops_path else base_dir / "elastix" / "alignedElastix" / "suite2p" / "plane0"

    task_id = args.task_id
    n_tasks = args.n_tasks
    slurm_task_id, slurm_n_tasks = slurm_array_args()
    if task_id is None:
        task_id = slurm_task_id
    if n_tasks is None:
        n_tasks = slurm_n_tasks

    print(f"Base directory: {base_dir}")
    print(f"Imaging directory: {imaging_dir}")
    print(f"Ops path: {ops_path}")
    print(f"Task id: {task_id}")
    print(f"N tasks: {n_tasks}")
    print(f"Strict nonrigid limit check: {args.strict_nr_limit}")

    processor = Suite2pTransformationBatchProcessor(base_dir, imaging_dir, ops_path, strict_nr_limit=args.strict_nr_limit)
    processor.process_sessions(
        task_id=task_id,
        n_tasks=n_tasks,
        use_legacy_copy_rule=not args.no_legacy_copy_rule,
    )


if __name__ == "__main__":
    main()
