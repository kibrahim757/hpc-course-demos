#!/bin/bash
#
#SBATCH --job-name=hello-world
#SBATCH --output=hello-world.out
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=quantum
#SBATCH --gres=qpu:1


export OPENBLAS_L2_SIZE=256

srun python /data/ch2/hello_qiskit/hello_qiskit.py
