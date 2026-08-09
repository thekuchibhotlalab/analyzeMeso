# run_processor.py
import os
from suite2p_transformation_apply import MovieTransformationProcessor

# Create and run processor
base_dir = os.getcwd()
animal_name = 'zz172_PPC1'

suite2pPath = os.path.join(base_dir, 'imagingSession','batch1')
processor = MovieTransformationProcessor(suite2pPath,animal_name)

opsPath = os.path.join(base_dir, 'elastix','alignedElastix','suite2p','plane0')

processor.process_all_sessions(opsPath)