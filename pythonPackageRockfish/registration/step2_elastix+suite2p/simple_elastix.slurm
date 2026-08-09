#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=simple_elastix
#SBATCH --mem=64G  
#SBATCH --output=simple_elastix.out
#SBATCH --error=simple_elastix.err
#SBATCH --ntasks=2
#SBATCH --cpus-per-task=2
#SBATCH --time=24:00:00

# Load any necessary modules or dependencies
module load anaconda

# Activate the virtual environment
conda activate suite2p 

# Run your Python script
python simple_elastix.py

# Deactivate the virtual environment
conda deactivate