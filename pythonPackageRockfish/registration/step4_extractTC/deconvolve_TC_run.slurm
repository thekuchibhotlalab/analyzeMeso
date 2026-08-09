#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=deconvolveTC
#SBATCH --mem=15G  
#SBATCH --output=deconvolveTC.out
#SBATCH --error=deconvolveTC.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

# Load any necessary modules or dependencies
module load anaconda

# Activate the virtual environment
conda activate oasis 

# Run your Python script
python deconvolve_TC.py

# Deactivate the virtual environment
conda deactivate