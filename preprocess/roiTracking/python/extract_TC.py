import argparse
import os
import numpy as np
import mmap
import scipy.io
from typing import Tuple, List
from numba import jit, prange
from matplotlib.path import Path  # For converting ROI coordinates to mask using meshgrid

class MovieTransformationProcessor:
    def __init__(self, base_directory: str, animal_name: str, chunk_size: int = 1000):
        """
        Initialize the movie transformation processor.
        
        Args:
            base_directory: Base path containing all session directories.
            animal_name: Name of the animal.
            chunk_size: Number of frames to process at once.
        """
        self.base_directory = base_directory
        self.chunk_size = chunk_size
        self.animal_name = animal_name

    def _get_movie_dimensions(self, bin_file_path: str) -> Tuple[int, int, int]:
        """
        Get the dimensions of the movie from the 'ops.npy' file and binary file size.
        
        Args:
            bin_file_path: Path to the binary movie file.

        Returns:
            A tuple of (x_pixels, y_pixels, n_frames).
        """
        ops_path = os.path.join(os.path.dirname(bin_file_path), 'ops.npy')
        ops = np.load(ops_path, allow_pickle=True).item()
        self.ops = ops
        file_size = os.path.getsize(bin_file_path)
        x_pixels = ops['Lx']
        y_pixels = ops['Ly']
        n_frames = file_size // (x_pixels * y_pixels * np.dtype('int16').itemsize)
        return x_pixels, y_pixels, n_frames

    def _get_ops(self, bin_file_path: str):
        """
        Get the operations dictionary from the 'ops.npy' file.
        
        Args:
            bin_file_path: Path to the binary movie file.

        Returns:
            The operations dictionary.
        """
        ops_path = os.path.join(os.path.dirname(bin_file_path), 'ops.npy')
        ops = np.load(ops_path, allow_pickle=True).item()
        return ops

    def _read_chunk(self, mm: mmap.mmap, start_frame: int, dimensions: Tuple[int, int, int]) -> np.ndarray:
        """
        Read a chunk (one frame) of data from the memory-mapped file.
        
        Args:
            mm: Memory-mapped file of the binary movie.
            start_frame: Starting frame index.
            dimensions: Tuple containing (x_pixels, y_pixels, n_frames).
        
        Returns:
            A numpy array representing one frame, reshaped as (y_pixels, x_pixels).
        """
        x_pixels, y_pixels, _ = dimensions
        bytes_per_frame = x_pixels * y_pixels * np.dtype('int16').itemsize
        offset = start_frame * bytes_per_frame

        mm.seek(offset)
        chunk_data = mm.read(bytes_per_frame)
        chunk_array = np.frombuffer(chunk_data, dtype='int16')
        return chunk_array.reshape((y_pixels, x_pixels))
    
    def _roi_to_mask(self, roi_coords: np.ndarray, x_pixels: int, y_pixels: int) -> np.ndarray:
        """
        Convert ROI coordinates (n x 2 array) into a binary mask using a meshgrid approach.
        
        If roi_coords is empty (shape (0,)), returns a mask of zeros.
        
        Args:
            roi_coords: Array of ROI coordinates with shape (n, 2), where the first column
                        corresponds to x coordinates and the second to y coordinates.
            x_pixels: Number of pixels in the x-dimension.
            y_pixels: Number of pixels in the y-dimension.
        
        Returns:
            A binary mask of shape (y_pixels, x_pixels) where pixels inside the ROI are True.
            
        Raises:
            ValueError: If roi_coords is non-empty and does not have the shape (N, 2).
        """
        # If empty, return an all-zero mask.
        if roi_coords.size == 0:
            return np.zeros((y_pixels, x_pixels), dtype=bool)
        
        if roi_coords.ndim != 2 or roi_coords.shape[1] != 2:
            raise ValueError("ROI coordinates must have shape (N, 2).")
        
        # Create a grid of pixel coordinates.
        # xx: x-coordinates (columns), yy: y-coordinates (rows)
        xx, yy = np.meshgrid(np.arange(x_pixels), np.arange(y_pixels))
        # Combine the coordinate grids into a list of (x, y) positions.
        points = np.vstack((xx.ravel(), yy.ravel())).T
        
        # Create a Path object from the ROI coordinates.
        # Note: ROI coordinates are assumed to be in (x, y) order.
        roi_path = Path(roi_coords)
        mask_flat = roi_path.contains_points(points)
        mask = mask_flat.reshape((y_pixels, x_pixels))
        return mask

    @staticmethod
    def _rois_to_object_cell(roi_coords_list: List[np.ndarray]) -> np.ndarray:
        roi_cell = np.empty((1, len(roi_coords_list)), dtype=object)
        for idx, coords in enumerate(roi_coords_list):
            roi_cell[0, idx] = np.asarray(coords)
        return roi_cell

    def _save_first_session_debug_mat(self, output_dir: str, session_num: int,
                                      session_dir: str, bin_file_path: str,
                                      roi_coords_list: List[np.ndarray],
                                      roi_masks: np.ndarray, first_frame: np.ndarray,
                                      mean_img_sum: np.ndarray, mean_img: np.ndarray,
                                      x_pixels: int, y_pixels: int, n_frames: int) -> None:
        """
        Save first-session ROI mask and movie-axis diagnostics next to extraction outputs.
        """
        os.makedirs(output_dir, exist_ok=True)
        roi_masks_for_extraction = roi_masks.astype(np.uint8)
        output_path = os.path.join(output_dir, f'debug_session_{session_num:03d}_roi_masks.mat')
        scipy.io.savemat(
            output_path,
            {
                'roi_coords_read': self._rois_to_object_cell(roi_coords_list),
                'roi_masks_for_extraction': roi_masks_for_extraction,
                'roi_mask_sum_for_extraction': np.sum(roi_masks_for_extraction, axis=0),
                'first_frame_python': first_frame,
                'mean_img_sum_python': mean_img_sum,
                'mean_img_python': mean_img,
                'x_pixels': x_pixels,
                'y_pixels': y_pixels,
                'n_frames': n_frames,
                'mean_frames_used': n_frames,
                'session_dir': session_dir,
                'bin_file_path': bin_file_path,
                'coordinate_note': (
                    'TC extraction uses the extract_TC_old.py convention: ROI coordinates are passed '
                    'directly to matplotlib.path.Path as [x, y]. Movie and mask arrays are [y, x].'
                ),
            },
            do_compression=True,
        )
        print(f'Saved first-session ROI mask debug file: {output_path}')

    def transform_movie(self, session_dir: str, animal_name: str, session_num: int,
                        roi_coords_list: List[np.ndarray], overwrite: bool = False) -> str:
        """
        Transform a movie file using pre-computed transformation parameters and ROIs.
        
        Args:
            session_dir: Path to the session directory containing suite2p/plane0/data.bin.
            animal_name: Name of the animal.
            session_num: Session number (1-indexed) for the transformation file.
            roi_coords_list: List of ROI coordinate arrays for the session.
                             Each element is an array of shape (n_points, 2).
                             
        Returns:
            Path to the output transformed movie file.
        """
        bin_file_path = os.path.join(session_dir, 'suite2p', 'plane0', 'data_suite2p.bin')
        mat_save_path = os.path.join(session_dir, 'suite2p', 'plane0', 'data_F.mat')

        print(f"Session {session_num:03d}: input session folder: {session_dir}")
        print(f"Session {session_num:03d}: reading movie: {bin_file_path}")
        print(f"Session {session_num:03d}: saving traces: {mat_save_path}")
        if os.path.exists(mat_save_path) and not overwrite:
            print(f"Session {session_num:03d}: data_F.mat already exists; skipping. Use --overwrite to rerun.")
            return mat_save_path
        
        if not os.path.exists(bin_file_path):
            raise FileNotFoundError(f"Input file not found: {bin_file_path}")
        
        dimensions = self._get_movie_dimensions(bin_file_path)
        x_pixels, y_pixels, n_frames = dimensions
        ops = self._get_ops(bin_file_path)
        print(f"Block size: {ops.get('block_size', 'N/A')}")
        print(f"y_pixels: {y_pixels}")
        print(f"x_pixels: {x_pixels}")
        
        # Convert each ROI coordinate set into a binary mask.
        roi_masks = []
        count = 0
        for roi_coords in roi_coords_list:
            count += 1
            mask = self._roi_to_mask(roi_coords, x_pixels, y_pixels)
            roi_masks.append(mask)
            if count == 10:
                scipy.io.savemat(os.path.join(session_dir, 'suite2p', 'plane0', 'mask.mat'), {'mask': mask})
        
        roi_masks = np.array(roi_masks)  # Shape: (nROI, y_pixels, x_pixels)
        allTraces = np.zeros((n_frames, len(roi_masks)))

        debug_output_dir = os.path.join(self.base_directory, 'roiTracking', 'extractTC')
        save_debug_mat = session_num == 1
        mean_img_sum = np.zeros((y_pixels, x_pixels), dtype=np.float64) if save_debug_mat else None
        first_frame = None
        with open(bin_file_path, 'rb') as f:
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)

            for start_frame in range(0, n_frames):
                chunk = self._read_chunk(mm, start_frame, dimensions)
                chunk32 = chunk.astype('float32')
                if save_debug_mat:
                    if start_frame == 0:
                        first_frame = chunk32.copy()
                    mean_img_sum += chunk32
                traces = self._extract_traces(chunk32, roi_masks)
                allTraces[start_frame] = traces
                if start_frame == 10:
                    scipy.io.savemat(os.path.join(session_dir, 'suite2p', 'plane0', 'img.mat'), {'chunk32': chunk32})
            mm.close()

        if save_debug_mat:
            mean_img = mean_img_sum / n_frames
            self._save_first_session_debug_mat(
                debug_output_dir,
                session_num,
                session_dir,
                bin_file_path,
                roi_coords_list,
                roi_masks,
                first_frame,
                mean_img_sum,
                mean_img,
                x_pixels,
                y_pixels,
                n_frames
            )
        
        # Save the traces to a MATLAB file.
        scipy.io.savemat(mat_save_path, {'allTraces': allTraces})
        print(f'Session {session_num:03d}: transformed movie saved to {mat_save_path}')
        return mat_save_path

    @staticmethod
    @jit(nopython=True, parallel=True)
    def _extract_traces(data, roi_masks):
        """
        Extract traces by averaging the pixel values inside each ROI mask.
        
        If no pixel is present (count==0), returns NaN for that ROI.
        
        Args:
            data: A numpy array of shape (y_pixels, x_pixels) representing a single frame.
            roi_masks: A numpy array of ROI masks (nROI, y_pixels, x_pixels).
            
        Returns:
            A 1D numpy array containing the averaged trace for each ROI.
        """
        num_rois = roi_masks.shape[0]
        traces = np.empty(num_rois, dtype=np.float32)
        for i in prange(num_rois):
            count = 0
            sum_val = 0.0
            for y in range(roi_masks.shape[1]):
                for x in range(roi_masks.shape[2]):
                    if roi_masks[i, y, x]:
                        sum_val += data[y, x]
                        count += 1
            if count > 0:
                traces[i] = sum_val / count
            else:
                traces[i] = np.nan  # output NaN when mask has no pixels
        return traces

    def _get_session_dirs(self):
        imaging_session_dir = os.path.join(self.base_directory, 'imagingSession')
        print(f"Imaging session directory: {imaging_session_dir}")
        if not os.path.exists(imaging_session_dir):
            raise FileNotFoundError(f"Imaging session directory not found: {imaging_session_dir}")

        session_dirs = [d for d in os.listdir(imaging_session_dir)
                        if os.path.isdir(os.path.join(imaging_session_dir, d))]
        session_dirs.sort()
        print(f"Found {len(session_dirs)} session folder(s).")
        return imaging_session_dir, session_dirs

    def _load_roi_cell(self):
        roi_mat_path = os.path.join(self.base_directory, 'stackROI_final_tracked.mat')
        if not os.path.exists(roi_mat_path):
            raise FileNotFoundError(f"ROI file not found: {roi_mat_path}")
        print(f"Loading ROI file: {roi_mat_path}")
        roi_mat = scipy.io.loadmat(roi_mat_path, squeeze_me=True, struct_as_record=False)
        roi_cell = roi_mat['roiFinal']  # Expected shape: (nSession, nROI)
        print(f"ROI cell shape: {roi_cell.shape}")
        return roi_cell

    @staticmethod
    def _roi_row_to_list(roi_row):
        if isinstance(roi_row, np.ndarray) and roi_row.ndim == 2:
            return [roi_row]
        return list(roi_row) if hasattr(roi_row, '__iter__') else [roi_row]

    def process_one_session(self, session_num: int, overwrite: bool = False) -> str:
        """
        Process one session by 1-indexed session number.

        This is the safe mode for Slurm arrays: each array task processes exactly
        one sorted imagingSession subfolder and writes only inside that folder.
        """
        imaging_session_dir, session_dirs = self._get_session_dirs()
        if session_num < 1 or session_num > len(session_dirs):
            print(
                f"Requested session {session_num}, but only found {len(session_dirs)} "
                "session folder(s). Nothing to do."
            )
            return ''

        roi_cell = self._load_roi_cell()
        idx = session_num - 1
        if idx >= roi_cell.shape[0]:
            print(
                f"Requested session {session_num}, but roiFinal only has "
                f"{roi_cell.shape[0]} session row(s). Nothing to do."
            )
            return ''
        session_dir = session_dirs[idx]
        full_session_dir = os.path.join(imaging_session_dir, session_dir)
        roi_row = roi_cell[idx]
        roi_coords_list = self._roi_row_to_list(roi_row)

        print("=" * 80)
        print(f"Parallel-safe single-session mode")
        print(f"SLURM_JOB_ID: {os.environ.get('SLURM_JOB_ID', 'not_slurm')}")
        print(f"SLURM_ARRAY_JOB_ID: {os.environ.get('SLURM_ARRAY_JOB_ID', 'not_array')}")
        print(f"SLURM_ARRAY_TASK_ID: {os.environ.get('SLURM_ARRAY_TASK_ID', 'not_array')}")
        print(f"Sorted session index: {session_num}/{len(session_dirs)}")
        print(f"Session folder name: {session_dir}")
        print(f"Full session folder: {full_session_dir}")
        print(f"Number of ROIs in session: {len(roi_coords_list)}")
        print(f"Output folder: {os.path.join(full_session_dir, 'suite2p', 'plane0')}")

        scipy.io.savemat(os.path.join(full_session_dir, 'suite2p', 'plane0', 'roi_cell.mat'), {'shape': roi_cell.shape})
        output_path = self.transform_movie(full_session_dir, self.animal_name, session_num, roi_coords_list, overwrite=overwrite)
        print(f"Successfully processed {session_dir}")
        return output_path

    def process_session_bucket(self, task_id: int, n_tasks: int, overwrite: bool = False) -> None:
        """
        Process a bucket of sessions for a fixed-size Slurm array.

        This matches the run-suite2p.py pattern: with --array=0-9, task 0
        processes sorted session indices 0,10,20..., task 1 processes
        1,11,21..., etc. Outputs are still saved inside each session folder.
        """
        if not (0 <= task_id < n_tasks):
            raise ValueError(f"task_id must satisfy 0 <= task_id < n_tasks, got {task_id}/{n_tasks}.")

        imaging_session_dir, session_dirs = self._get_session_dirs()
        roi_cell = self._load_roi_cell()
        selected = [(idx, session_dir) for idx, session_dir in enumerate(session_dirs) if idx % n_tasks == task_id]

        print("=" * 80)
        print("Parallel-safe bucket mode")
        print(f"SLURM_JOB_ID: {os.environ.get('SLURM_JOB_ID', 'not_slurm')}")
        print(f"SLURM_ARRAY_JOB_ID: {os.environ.get('SLURM_ARRAY_JOB_ID', 'not_array')}")
        print(f"SLURM_ARRAY_TASK_ID: {os.environ.get('SLURM_ARRAY_TASK_ID', 'not_array')}")
        print(f"SLURM_ARRAY_TASK_COUNT: {os.environ.get('SLURM_ARRAY_TASK_COUNT', 'not_array')}")
        print(f"Task bucket: {task_id + 1}/{n_tasks}")
        print(f"Total sorted session folders: {len(session_dirs)}")
        print(f"Selected {len(selected)} session(s):")
        for idx, session_dir in selected:
            print(f"  sorted_session_index={idx + 1:03d}, folder={session_dir}")

        for idx, session_dir in selected:
            session_num = idx + 1
            if idx >= roi_cell.shape[0]:
                print(
                    f"Skipping session {session_num}: roiFinal only has "
                    f"{roi_cell.shape[0]} session row(s)."
                )
                continue

            full_session_dir = os.path.join(imaging_session_dir, session_dir)
            roi_row = roi_cell[idx]
            roi_coords_list = self._roi_row_to_list(roi_row)

            print("=" * 80)
            print(f"Bucket {task_id + 1}/{n_tasks} processing sorted session {session_num}/{len(session_dirs)}")
            print(f"Session folder name: {session_dir}")
            print(f"Full session folder: {full_session_dir}")
            print(f"Number of ROIs in session: {len(roi_coords_list)}")
            print(f"Output folder: {os.path.join(full_session_dir, 'suite2p', 'plane0')}")

            scipy.io.savemat(os.path.join(full_session_dir, 'suite2p', 'plane0', 'roi_cell.mat'), {'shape': roi_cell.shape})
            self.transform_movie(full_session_dir, self.animal_name, session_num, roi_coords_list, overwrite=overwrite)
            print(f"Successfully processed {session_dir}")

    def process_all_sessions(self, overwrite: bool = False):
        """
        Process all sessions found in the imaging session directory.
        Loads the cell array of ROI coordinates from the MATLAB file (stackROI_final_tracked.mat)
        at the base directory. This is a cell array of size (nSession x nROI). For each session,
        the corresponding row (1st dimension) is used for processing.
        Each ROI coordinate array (n * 2) is converted into a binary mask where the first column
        corresponds to x_pixels and the second to y_pixels.
        """
        imaging_session_dir, session_dirs = self._get_session_dirs()
        roi_cell = self._load_roi_cell()

        # Process each session directory.
        for idx, session_dir in enumerate(session_dirs):
            full_session_dir = os.path.join(imaging_session_dir, session_dir)
            session_num = idx + 1  # 1-indexed session number
            print("=" * 80)
            print(f"Sequential mode processing session {session_num}/{len(session_dirs)}")
            print(f"Session folder name: {session_dir}")
            print(f"Full session folder: {full_session_dir}")

            roi_row = roi_cell[idx]
            roi_coords_list = self._roi_row_to_list(roi_row)
            print("Number of ROIs in session:", len(roi_coords_list))
            if hasattr(roi_row, 'shape'):
                print("ROI row shape:", roi_row.shape)
            print(f"Output folder: {os.path.join(full_session_dir, 'suite2p', 'plane0')}")
            scipy.io.savemat(os.path.join(full_session_dir, 'suite2p', 'plane0', 'roi_cell.mat'), {'shape': roi_cell.shape})
                
            self.transform_movie(full_session_dir, self.animal_name, session_num, roi_coords_list, overwrite=overwrite)
            print(f"Successfully processed {session_dir}")

# For running the module independently.
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Extract ROI fluorescence traces from Suite2p binary movies."
    )
    parser.add_argument("--base-dir", default=os.getcwd(), help="Animal/base directory. Defaults to current directory.")
    parser.add_argument("--animal", default=None, help="Animal name. Defaults to the base directory name.")
    parser.add_argument(
        "--session",
        type=int,
        default=None,
        help="1-indexed sorted session number to process. If omitted, Slurm array bucket mode is used when available.",
    )
    parser.add_argument("--task-id", type=int, default=None, help="0-based task bucket. Defaults to SLURM_ARRAY_TASK_ID.")
    parser.add_argument("--n-tasks", type=int, default=None, help="Number of task buckets. Defaults to SLURM_ARRAY_TASK_COUNT.")
    parser.add_argument("--overwrite", action="store_true", help="Recompute even when data_F.mat already exists.")
    args = parser.parse_args()

    base_dir = os.path.abspath(args.base_dir)
    animal = args.animal or os.path.basename(base_dir)
    processor = MovieTransformationProcessor(base_dir, animal)

    env_task_id = os.environ.get("SLURM_ARRAY_TASK_ID")
    env_n_tasks = os.environ.get("SLURM_ARRAY_TASK_COUNT")
    session_num = args.session
    task_id = args.task_id
    n_tasks = args.n_tasks
    if task_id is None and env_task_id is not None:
        task_id = int(env_task_id)
    if n_tasks is None and env_n_tasks is not None:
        n_tasks = int(env_n_tasks)

    print(f"Base directory: {base_dir}")
    print(f"Animal name: {animal}")
    if session_num is not None:
        processor.process_one_session(session_num, overwrite=args.overwrite)
    elif task_id is not None or n_tasks is not None:
        if task_id is None or n_tasks is None:
            raise ValueError("--task-id and --n-tasks must be provided together.")
        processor.process_session_bucket(task_id, n_tasks, overwrite=args.overwrite)
    else:
        print("No session argument or SLURM_ARRAY_TASK_ID detected; processing all sessions sequentially.")
        processor.process_all_sessions(overwrite=args.overwrite)
