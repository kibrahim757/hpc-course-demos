#!/bin/bash
#
#SBATCH --job-name=mpi-hello-world
#SBATCH --output=mpi-hello-world.out
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal

source /shared/pyenv/bin/activate
srun python mpi-hello-world.py