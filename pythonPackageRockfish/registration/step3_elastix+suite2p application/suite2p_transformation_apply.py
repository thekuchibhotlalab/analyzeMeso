import SimpleITK as sitk
import numpy as np
import os
from typing import Tuple
import mmap
import scipy.io
from suite2p.registration import nonrigid
from suite2p.registration import rigid

class MovieTransformationProcessor:
    def __init__(self, base_directory: str,animal_name: str, chunk_size: int = 1000):
        """
        Initialize the movie transformation processor.
        
        Args:
            base_directory: Base path containing all session directories
            chunk_size: Number of frames to process at once
        """
        self.base_directory = base_directory
        self.chunk_size = chunk_size
        self.animal_name = animal_name

    @staticmethod
    def _check_nonrigid_offsets(cross_session_align: dict, ops: dict, session_dir: str) -> None:
        if "yoff1" not in cross_session_align or "xoff1" not in cross_session_align:
            print("No xoff1/yoff1 fields found; nonrigid transform cannot be checked.")
            return

        yoff1 = np.asarray(cross_session_align["yoff1"], dtype=float)
        xoff1 = np.asarray(cross_session_align["xoff1"], dtype=float)
        max_y = float(np.nanmax(np.abs(yoff1))) if yoff1.size else np.nan
        max_x = float(np.nanmax(np.abs(xoff1))) if xoff1.size else np.nan
        limit = float(ops.get("maxregshiftNR", np.nan))

        print(f"Nonrigid max abs shift: yoff1={max_y:.3f}, xoff1={max_x:.3f}, ops maxregshiftNR={limit}")
        hard_limit = limit + 0.5
        if np.isfinite(limit) and (max_y > hard_limit or max_x > hard_limit):
            print(
                f"WARNING: {os.path.basename(session_dir)} has nonrigid offsets larger than "
                f"ops['maxregshiftNR']={limit} plus the expected subpixel margin. Regenerate crossSessionSuite2p.mat "
                "from the new Suite2p run before applying these shifts."
            )
        
    def _get_movie_dimensions(self, bin_file_path: str,ops:dict) -> Tuple[int, int, int]:
        """
        Get the dimensions of the movie from ops.npy file and binary file size.
        """
        #ops_path = os.path.join(os.path.dirname(bin_file_path), 'ops.npy')
        #ops = np.load(ops_path, allow_pickle=True).item()
        self.ops = ops
        file_size = os.path.getsize(bin_file_path)
        x_pixels = ops['Lx']
        y_pixels = ops['Ly']
        n_frames = file_size // (x_pixels * y_pixels * np.dtype('int16').itemsize)
        return x_pixels, y_pixels, n_frames
    def _get_ops(self, ops_path: str):
        """
        Get the dimensions of the movie from ops.npy file and binary file size.
        """
        ops = np.load ( os.path.join(ops_path,'ops.npy'), allow_pickle=True).item()
        
        return ops
    
    def _read_chunk(self, mm: mmap, start_frame: int, 
                    dimensions: Tuple[int, int, int]) -> np.ndarray:
        """Read a chunk of frames from the memory-mapped file."""
        x_pixels, y_pixels, _ = dimensions
        bytes_per_frame = x_pixels * y_pixels * np.dtype('int16').itemsize
        offset = start_frame * bytes_per_frame
        
        mm.seek(offset)
        chunk_data = mm.read( bytes_per_frame)
        
        chunk_array = np.frombuffer(chunk_data, dtype='int16')
        #return chunk_array.reshape((1,y_pixels, x_pixels))
        return chunk_array.reshape((y_pixels, x_pixels))
    
    def transform_movie(self, session_dir: str, ops: dict, session_num: int) -> str:
        """
        Transform a movie file using pre-computed transformation parameters.
        
        Args:
            session_dir: Path to the session directory containing suite2p/plane0/data.bin
            ops: ops containing the alignment infomation of each session 
            session_num: Session number for the transformation file
            
        Returns:
            Path to the output transformed movie file
        """
        bin_file_path = os.path.join(session_dir, 'suite2p', 'plane0', 'data_elastix.bin')
        output_path = os.path.join(session_dir, 'suite2p', 'plane0', 'data_suite2p.bin')
        mean_image_path = os.path.join(session_dir, 'suite2p', 'plane0', 'exampleImg_suite2p.mat')
        crossSessionAlignPath = os.path.join(session_dir, 'crossSessionSuite2p.mat')
        crossSessionAlign = scipy.io.loadmat(crossSessionAlignPath)

        #print(crossSessionAlign["xoff"].shape)
        #print(crossSessionAlign["xoff"][0].shape)
        #print(crossSessionAlign["xoff1"].shape)
        #print(crossSessionAlign["xoff1"][0].shape)
        print("session num: " + str(session_num))
        
        if not os.path.exists(bin_file_path):
            raise FileNotFoundError(f"Input file not found: {bin_file_path}")
        
        dimensions = self._get_movie_dimensions(bin_file_path,ops)
        x_pixels, y_pixels, n_frames = dimensions
        #ops = self._get_ops(bin_file_path)
        #print(ops["block_size"])
        print("x: " + str(x_pixels) + "y: " + str(y_pixels) + "frames: " + str(n_frames))
        self._check_nonrigid_offsets(crossSessionAlign, ops, session_dir)
        blocks = nonrigid.make_blocks(Ly=y_pixels, Lx=x_pixels,block_size=ops["block_size"])

        with open(bin_file_path, 'rb') as f, \
             open(output_path, 'wb') as out_f:
            
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            
            for start_frame in range(0, n_frames):
                chunk = self._read_chunk(mm, start_frame, dimensions)   
                chunk32 = chunk.astype('float32')
                chunk32 = chunk32.reshape((1,y_pixels, x_pixels))
  
                # Convert to float32 for SimpleITK processing
                print(str(crossSessionAlign["yoff"][0][0]) + " " + str(crossSessionAlign["xoff"][0][0]))
                transformed_chunk = rigid.shift_frame(frame=chunk32, dy=crossSessionAlign["yoff"][0][0], dx= crossSessionAlign["xoff"][0][0])


                transformed_chunk = nonrigid.transform_data(data=transformed_chunk, nblocks=blocks[2], xblock=blocks[1], yblock=blocks[0], 
                                                            ymax1 = crossSessionAlign["yoff1"].reshape(1, -1), xmax1 = crossSessionAlign["xoff1"].reshape(1, -1))
                # Scale back to original range and convert to int16
                transformed_chunk = transformed_chunk.astype('int16')
                transformed_chunk = transformed_chunk.transpose((0, 2, 1))
                transformed_chunk.tofile(out_f)
                if start_frame == 1:
                    scipy.io.savemat(mean_image_path, {'img1': np.squeeze(np.mean(transformed_chunk,axis=0)),'img0':np.squeeze(np.mean(chunk,axis=0))})
               
            mm.close()
        print(f'Transformed movie saved to {output_path}')
        return output_path

    def process_all_sessions(self, opsPath: str):
        """
        Process all sessions found in the imaging session directory.
        """
        imaging_session_dir = os.path.join(self.base_directory, 'imagingSession')
        print(imaging_session_dir)
        if not os.path.exists(imaging_session_dir):
            raise FileNotFoundError(f"Imaging session directory not found: {imaging_session_dir}")

        # Get the list of session directories and sort them
        session_dirs = [d for d in os.listdir(imaging_session_dir) 
                       if os.path.isdir(os.path.join(imaging_session_dir, d))]
        session_dirs.sort()

        # Process each session directory
        for idx, session_dir in enumerate(session_dirs):
            full_session_dir = os.path.join(imaging_session_dir, session_dir)
            print(f"Processing session directory: {session_dir}")
            
  
            # Assuming directory format is "animalname_sessioninfo"
            #animal_name = session_dir.split('_')[0] + '_' + session_dir.split('_')[1]
            #print(animal_name)
            ops = self._get_ops(opsPath)
            if len(session_dirs) < 120:
                session_num = idx * 2
                print ('Copy of tiff detected! Loading ops file session: ' + str(idx) + ' as ' + str(session_num) )
            else: 
                session_num = idx # Use 1-based indexing for session numbers
            self.transform_movie(full_session_dir, ops, session_num)
            print(f"Successfully processed {session_dir}")
                


if __name__ == "__main__":
    base_dir = os.getcwd()
    animal_name = 'zz172_PPC1'
    processor = MovieTransformationProcessor(base_dir,animal_name)
    opsPath = os.path.join(base_dir, 'elastix','alignedElastix','suite2p','plane0')
    print('ops Path is: ' + opsPath)
    processor.process_all_sessions(opsPath)











