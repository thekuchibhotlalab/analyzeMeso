#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=suite2p_elastix
#SBATCH --mem=64G  
#SBATCH --output=suite2p_elastix.out
#SBATCH --error=suite2p_elastix.err
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=2
#SBATCH --time=24:00:00

# Load any necessary modules or dependencies
module load anaconda

# Activate the virtual environment
conda activate suite2p 

# Run your Python script
python suite2p_elastix.py

# Deactivate the virtual environment
conda deactivate