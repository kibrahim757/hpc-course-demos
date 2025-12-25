#!/bin/bash
#
#SBATCH --job-name=sqd-mapping
#SBATCH --output=/shared/chapters/ch4/sqd/sqd-mapping.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal

source /shared/pyenv/bin/activate
srun python /shared/chapters/ch4/sqd/mapping.py