#!/bin/bash
#
#SBATCH --job-name=mpi-hello-world
#SBATCH --output=mpi-hello-world.out
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal


/usr/lib64/openmpi/bin/mpirun python /data/ch3/parallel/mpi-hello-world.py
