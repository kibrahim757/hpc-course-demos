#!/bin/bash
#
#SBATCH --job-name=sqd-optimization
#SBATCH --output=sqd-optimization.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal


srun python /data/ch4/sqd/optimization.py
