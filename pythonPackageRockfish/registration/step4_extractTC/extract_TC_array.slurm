#!/bin/bash -l
#SBATCH --account=kkuchib1
#SBATCH --partition=shared
#SBATCH --job-name=extract_TC
#SBATCH --mem=15G
#SBATCH --output=extract_TC_%A_%a.out
#SBATCH --error=extract_TC_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --time=24:00:00
#SBATCH --array=0-9

# Submit from the animal/base folder with:
#   sbatch extract_TC_array.slurm
#
# This follows run-suite2p.slurm: fixed array tasks 0-9. Python divides the
# sorted imagingSession folders across these 10 task buckets.

module load anaconda
conda activate suite2p

export NUMBA_NUM_THREADS=${SLURM_CPUS_PER_TASK}
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

echo "SLURM_JOB_ID=${SLURM_JOB_ID}"
echo "SLURM_ARRAY_JOB_ID=${SLURM_ARRAY_JOB_ID}"
echo "SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
echo "SLURM_CPUS_PER_TASK=${SLURM_CPUS_PER_TASK}"
echo "NUMBA_NUM_THREADS=${NUMBA_NUM_THREADS}"
echo "Working directory: $(pwd)"

python extract_TC.py

conda deactivate
