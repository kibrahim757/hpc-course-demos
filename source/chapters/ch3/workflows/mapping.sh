#!/bin/bash
#
#SBATCH --job-name=mapping
#SBATCH --output=/shared/slurm-%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

# Your script goes here
source /shared/pyenv/bin/activate
srun python /shared/chapters/ch3/workflows/mapping.py
