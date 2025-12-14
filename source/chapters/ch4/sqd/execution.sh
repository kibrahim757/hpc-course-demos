#!/bin/bash
#
#SBATCH --job-name=sqd-execution
#SBATCH --output=slurm-%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --qpu=ibm_torino

source /shared/pyenv/bin/activate
srun python /shared/chapters/ch4/sqd/execution.py
