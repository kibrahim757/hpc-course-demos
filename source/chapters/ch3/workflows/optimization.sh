#!/bin/bash
#
#SBATCH --job-name=optimization
#SBATCH --output=/shared/chapters/ch3/workflows/optimization.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

# Your script goes here
source /shared/pyenv/bin/activate
srun python /shared/chapters/ch3/workflows/optimization.py
