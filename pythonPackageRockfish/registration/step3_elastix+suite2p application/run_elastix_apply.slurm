#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=suite2p
#SBATCH --mem=64G  
#SBATCH --output=elastix_apply_movie.out
#SBATCH --error=elastix_apply_movie.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

# Load any necessary modules or dependencies
module load anaconda

# Activate the virtual environment
conda activate suite2p 

# Run your Python script
python elastix_apply.py

# Deactivate the virtual environment
conda deactivate