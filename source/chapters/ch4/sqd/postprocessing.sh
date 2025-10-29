#!/bin/bash
#
#SBATCH --job-name=sqd-postprocessing
#SBATCH --output=/shared/chapters/ch4/sqd/sqd-postprocessing.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

source /shared/pyenv/bin/activate
srun python /shared/chapters/ch4/sqd/postprocessing.py
