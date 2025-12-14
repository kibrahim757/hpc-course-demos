#!/bin/bash

#SBATCH --job-name=hello-world
#SBATCH --output=/shared/slurm-%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1

# Your script goes here
source /shared/pyenv/bin/activate
srun python /shared/chapters/ch2/hello_world/hello_world.py