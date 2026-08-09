#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=fn_step0_organizeData
#SBATCH --mem=15G  
#SBATCH --output=fn_step0_organizeData.out
#SBATCH --error=fn_step0_organizeData.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00

# Load any necessary modules or dependencies
module load anaconda

# Activate the virtual environment
conda activate suite2p 

# Run your Python script
python fn_step0_organizeData.py

# Deactivate the virtual environment
conda deactivate