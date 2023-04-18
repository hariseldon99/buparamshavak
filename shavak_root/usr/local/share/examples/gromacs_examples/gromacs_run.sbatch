#!/bin/bash

#SBATCH --job-name=gromacstest
#This sets the name of the job

#SBATCH --partition=CPU

#SBATCH --ntasks=10
#This sets the number of processes to 10.

#SBATCH --cpus-per-task=1
#This allocates the number of cpus per tasks. 

#SBATCH --time=01:00:00 
#This allocates the walltime to 60 minutes. The program will not run for longer.

#SBATCH --qos=normal 
#This sets the quality of service to 'normal'

export TOPOL_FILE=topol.tpr

gmx mdrun -ntmpi 1 -nb gpu -pin on -v -noconfout -nsteps 5000 -ntomp ${SLURM_NTASKS} -s $TOPOL_FILE
#DO NOT USE 'srun' as it launches multiple independent jobs
