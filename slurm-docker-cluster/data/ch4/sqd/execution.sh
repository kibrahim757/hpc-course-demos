#!/bin/bash
#
#SBATCH --job-name=sqd-execution
#SBATCH --output=sqd-execution.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=quantum
#SBATCH --gres=qpu:1


srun python /data/ch4/sqd/execution.py
