#!/bin/bash

#SBATCH --job-name=hello_mpi
#This sets the name of the job

#SBATCH --ntasks=4 
#This sets the number of processes to 4. Change if needed

#SBATCH --cpus-per-task=1
#This allocates the number of cpus per tasks. If the number of tasks is 4, and cpus per task is 1, then slurm will assign 4 X 1 = 4 cpus to the job

#SBATCH --time=00:05:00 
#This allocates the walltime to 5 minutes. The program will not run for longer.

#SBATCH --qos=normal 
#This sets the quality of service to 'normal'

srun ./hello_mpi
#The srun command is part of SLURM, and can run compatible programs in parallel with the allocated resources
