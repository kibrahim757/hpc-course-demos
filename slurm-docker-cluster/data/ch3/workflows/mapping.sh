#!/bin/bash
#
#SBATCH --job-name=mapping
#SBATCH --output=mapping.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal


srun python /data/ch3/workflows/mapping.py
