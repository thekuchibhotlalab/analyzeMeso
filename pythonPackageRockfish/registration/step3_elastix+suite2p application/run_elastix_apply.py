# run_processor.py
import os
from elastix_apply import MovieTransformationProcessor

# Create and run processor
base_dir = os.getcwd()
animal_name = 'zz172_PPC1'
processor = MovieTransformationProcessor(base_dir,animal_name)
opsPath = os.path.join(base_dir, 'ops.mat')
print('ops Path is: ' + opsPath)
processor.process_all_sessions(opsPath)