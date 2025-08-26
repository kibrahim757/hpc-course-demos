#!/bin/bash
#
#SBATCH --job-name=hello-world
#SBATCH --output=hello-world.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=normal


srun python /data/ch2/hello_world/hello_world.py
