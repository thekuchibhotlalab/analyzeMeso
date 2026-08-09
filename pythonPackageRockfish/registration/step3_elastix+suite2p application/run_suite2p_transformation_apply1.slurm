#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=suite2p_apply
#SBATCH --mem=64G  
#SBATCH --output=suite2p_apply_movie1.out
#SBATCH --error=suite2p_apply_movie1.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00


# Load any necessary modules or dependencies
module load anaconda

# Activate the virtual environment
conda activate suite2p 

# Run your Python script
python run_suite2p_transformation_apply1.py

# Deactivate the virtual environment
conda deactivate