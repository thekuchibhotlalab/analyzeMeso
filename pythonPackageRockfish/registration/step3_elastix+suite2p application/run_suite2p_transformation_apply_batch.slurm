#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=suite2p_apply
#SBATCH --mem=64G
#SBATCH --output=suite2p_apply_%A_%a.out
#SBATCH --error=suite2p_apply_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=24:00:00
#SBATCH --array=0-9

module load anaconda
conda activate suite2p

python suite2p_transformation_apply_batch.py

conda deactivate
