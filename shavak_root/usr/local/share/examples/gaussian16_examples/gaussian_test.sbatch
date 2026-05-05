#!/bin/bash
#SBATCH --job-name=gaussian-test
#This sets the name of the job

#SBATCH --ntasks=16
#This sets the number of processes to 1. Change if needed

#SBATCH --cpus-per-task=1
#This allocates the number of cpus per tasks. If the number of tasks is 4, and cpus per task is 1, then slurm will assign 4 X 1 = 4 cpus to the job

#SBATCH --time=01:00:00 
#This allocates the walltime to 1 hour. The program will not run for longer.

#SBATCH --qos=normal 
#This sets the quality of service to 'normal'

export INPUT_FILE=8HQSCAN.gjf
export OUTPUT_FILE=output.log

source /etc/g16setup

# update inputfile for CPUs
CPUS=$(taskset -cp $$ | awk -F':' '{print $2}')
sed -i -e "/^.*%cpu/I s/=.*$/=$CPUS/" ${INPUT_FILE}

g16 < ${INPUT_FILE} > ${OUTPUT_FILE}
