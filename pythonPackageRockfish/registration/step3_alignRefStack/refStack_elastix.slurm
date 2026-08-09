#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=refStack_elastix
#SBATCH --mem=8G  
#SBATCH --output=refStack_elastix.out
#SBATCH --error=refStack_elastix.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00


# Load any necessary modules or dependencies
module load anaconda

# Activate the virtual environment
conda activate suite2p 

# Run your Python script
python refStack_elastix.py

# Deactivate the virtual environment
conda deactivate