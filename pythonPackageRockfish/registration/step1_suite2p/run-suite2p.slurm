#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=suite2p
#SBATCH --mem=64G  
#SBATCH --output=suite2p_%A_%a.out
#SBATCH --error=suite2p_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=24:00:00
#SBATCH --array=0-9

# Load any necessary modules or dependencies
module load anaconda

# Activate the virtual environment
conda activate suite2p 

# Run your Python script
python run-suite2p.py

# Deactivate the virtual environment
conda deactivate
