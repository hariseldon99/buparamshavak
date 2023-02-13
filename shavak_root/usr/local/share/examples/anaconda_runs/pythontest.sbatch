#!/bin/bash

#SBATCH --job-name=pythontest
#This sets the name of the job

#SBATCH --ntasks=10
#This sets the number of processes to 10. Change if needed

#SBATCH --cpus-per-task=1
#This allocates the number of cpus per tasks. If the number of tasks is 4, and cpus per task is 1, then slurm will assign 4 X 1 = 4 cpus to the job

#SBATCH --time=00:05:00 
#This allocates the walltime to 5 minutes. The program will not run for longer.

#SBATCH --qos=normal 
#This sets the quality of service to 'normal'


source /usr/local/condaenv/bin/activate
conda activate ~/.testenv
srun python ./square.py 10
conda deactivate
