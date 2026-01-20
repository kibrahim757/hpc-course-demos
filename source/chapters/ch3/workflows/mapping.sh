#!/bin/bash
#
#SBATCH --job-name=mapping
#SBATCH --output=/shared/chapters/ch3/workflows/mapping.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal
#SBATCH --qpu=ibm_torino

# Your script goes here
source /shared/pyenv/bin/activate
srun python /shared/chapters/ch3/workflows/mapping.py
