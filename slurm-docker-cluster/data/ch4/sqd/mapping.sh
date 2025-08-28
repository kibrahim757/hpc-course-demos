#!/bin/bash
#
#SBATCH --job-name=sqd-mapping
#SBATCH --output=sqd-mapping.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal


srun python /data/ch4/sqd/mapping.py
