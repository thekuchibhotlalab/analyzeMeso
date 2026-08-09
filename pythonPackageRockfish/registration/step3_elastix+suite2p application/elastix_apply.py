import SimpleITK as sitk
import numpy as np
import os
from typing import Tuple
import mmap
import scipy.io

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
        
    def _get_movie_dimensions(self, bin_file_path: str) -> Tuple[int, int, int]:
        """
        Get the dimensions of the movie from ops.npy file and binary file size.
        """
        ops_path = os.path.join(os.path.dirname(bin_file_path), 'ops.npy')
        ops = np.load(ops_path, allow_pickle=True).item()
        
        file_size = os.path.getsize(bin_file_path)
        x_pixels = ops['Lx']
        y_pixels = ops['Ly']
        n_frames = file_size // (x_pixels * y_pixels * np.dtype('int16').itemsize)
        return x_pixels, y_pixels, n_frames
    
    def _read_chunk(self, mm: mmap, start_frame: int, 
                    dimensions: Tuple[int, int, int]) -> np.ndarray:
        """Read a chunk of frames from the memory-mapped file."""
        x_pixels, y_pixels, _ = dimensions
        bytes_per_frame = x_pixels * y_pixels * np.dtype('int16').itemsize
        offset = start_frame * bytes_per_frame
        
        mm.seek(offset)
        chunk_data = mm.read(bytes_per_frame)
        
        chunk_array = np.frombuffer(chunk_data, dtype='int16')
        return chunk_array.reshape((y_pixels, x_pixels))
    
    def transform_movie(self, session_dir: str, animal_name: str, session_num: int, xyshift) -> str:
        """
        Transform a movie file using pre-computed transformation parameters.
        
        Args:
            session_dir: Path to the session directory containing suite2p/plane0/data.bin
            animal_name: Name of the animal (for finding transformation file)
            session_num: Session number for the transformation file
            
        Returns:
            Path to the output transformed movie file
        """
        bin_file_path = os.path.join(session_dir, 'suite2p', 'plane0', 'data.bin')
        output_path = os.path.join(session_dir, 'suite2p', 'plane0', 'data_elastix.bin')
        mean_image_path = os.path.join(session_dir, 'suite2p', 'plane0', 'exampleImg.mat')

        
        if not os.path.exists(bin_file_path):
            raise FileNotFoundError(f"Input file not found: {bin_file_path}")
        
        dimensions = self._get_movie_dimensions(bin_file_path)
        x_pixels, y_pixels, n_frames = dimensions
        
        print(f'elastix/alignedElastix_param/{animal_name}_session{session_num:02d}_transform.txt')
        transform_param_file = os.path.join(
            self.base_directory, 
            f'elastix/alignedElastix_param/{animal_name}_session{session_num:02d}_transform.txt'
        )
        transform_parameter_map = sitk.ReadParameterFile(transform_param_file)
        transform = sitk.TransformixImageFilter()
        transform.SetTransformParameterMap(transform_parameter_map)
        
        with open(bin_file_path, 'rb') as f, \
             open(output_path, 'wb') as out_f:
            
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            print(xyshift[session_num-1,:])
            
            for start_frame in range(0, n_frames):
                
                chunk = self._read_chunk(mm, start_frame, dimensions)
                print(chunk.shape)
                chunk = np.roll(chunk, shift=(xyshift[session_num-1,1], xyshift[session_num-1,0]), axis=(0, 1))

                frame = sitk.GetImageFromArray(np.transpose(chunk))
                
                transform.SetMovingImage(frame)
                transform.Execute()
                transformed_frame = transform.GetResultImage()
                #transformed_frame = sitk.Resample(frame, transform_parameter_map) 
                transformed_chunk = sitk.GetArrayFromImage(transformed_frame)
                
                # Scale back to original range and convert to int16
                # transformed_chunk = np.clip(transformed_chunk, data_min, data_max)
                transformed_chunk = transformed_chunk.astype('int16')
                
                transformed_chunk.tofile(out_f)
                if start_frame == 10:
                    scipy.io.savemat(mean_image_path, {'img1': transformed_chunk,'img0':np.transpose(chunk)})
                
            mm.close()
        
        print(f'Transformed movie saved to {output_path}')
        return output_path

    def process_all_sessions(self,opsPath: str):
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

        xyshift = scipy.io.loadmat(opsPath)
        xyshift = xyshift['initial_transform_coord']
        print(xyshift)
        # Process each session directory
        for idx, session_dir in enumerate(session_dirs):
            full_session_dir = os.path.join(imaging_session_dir, session_dir)
            print(f"Processing session directory: {session_dir}")

            try:
                # Assuming directory format is "animalname_sessioninfo"
                #animal_name = session_dir.split('_')[0] + '_' + session_dir.split('_')[1]
                #print(animal_name)
                animal_name = self.animal_name
                session_num = idx + 1  # Use 1-based indexing for session numbers
                
                self.transform_movie(full_session_dir, animal_name, session_num, xyshift)
                print(f"Successfully processed {session_dir}")
            except Exception as e:
                print(f"Error processing {session_dir}: {str(e)}")

if __name__ == "__main__":
    base_dir = os.getcwd()
    animal_name = 'zz172_PPC1'
    processor = MovieTransformationProcessor(base_dir,animal_name)
    opsPath = os.path.join(base_dir, 'ops.mat')
    print('ops Path is: ' + opsPath)
    processor.process_all_sessions(opsPath)