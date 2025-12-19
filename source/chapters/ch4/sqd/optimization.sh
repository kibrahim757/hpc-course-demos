#!/bin/bash
#
#SBATCH --job-name=sqd-optimization
#SBATCH --output=/shared/chapters/ch4/sqd/sqd-optimization.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --qpu=ibm_torino

source /shared/pyenv/bin/activate
srun python /shared/chapters/ch4/sqd/optimization.py
