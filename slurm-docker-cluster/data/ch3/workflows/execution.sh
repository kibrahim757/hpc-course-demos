#!/bin/bash
#
#SBATCH --job-name=execution
#SBATCH --output=execution.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=quantum
#SBATCH --gres=qpu:1


srun python /data/ch3/workflows/execution.py
