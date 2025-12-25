#!/bin/bash
#
#SBATCH --job-name=optimization
#SBATCH --output=/shared/chapters/ch3/workflows/optimization.out
#SBATCH --ntasks=4
#SBATCH --partition=normal
#SBATCH --qpu=ibm_torino

# Your script goes here
source /shared/pyenv/bin/activate
srun python /shared/chapters/ch3/workflows/optimization.py
