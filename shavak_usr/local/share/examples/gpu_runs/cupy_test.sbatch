#!/bin/bash

#SBATCH --job-name=cupy-test
#This sets the name of the job

#SBATCH --partition=GPU
#This sets the partition to the GPU partition. Important for GPU jobs

#SBATCH --gres=gpu:1
#This allocates 1 GPU as a Global Resource (gres). Important for GPU jobs

#SBATCH --ntasks=1 
#This sets the number of processes to 1.

#SBATCH --cpus-per-task=1
#This allocates the number of cpus per tasks. 

#SBATCH --time=00:01:00 
#This allocates the walltime to 5 minutes. The program will not run for longer.

#SBATCH --qos=normal 
#This sets the quality of service to 'normal'

source /usr/local/condaenv/bin/activate
srun python3 ./cupy_test.py
