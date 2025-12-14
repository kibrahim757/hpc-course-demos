#!/bin/bash

#SBATCH --job-name=hello-qiskit
#SBATCH --output=slurm-%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --qpu=ibm_torino

# Your script goes here
source /shared/pyenv/bin/activate
srun python /shared/chapters/ch2/hello_qiskit/hello_qiskit.py
