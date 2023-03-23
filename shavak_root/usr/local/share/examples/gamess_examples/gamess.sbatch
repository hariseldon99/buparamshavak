#!/bin/bash

#---------------------------------------------------
#SBATCH --job-name=retinal-gamess
# This sets the job name. Change if needed

#SBATCH --ntasks=16
# This sets the number of processes. Change if needed

#SBATCH --qos=normal 
# This sets the quality of service to 'normal'

#SBATCH --time=00:05:00 
# This allocates the walltime to 5 minutes. 
# The program will not run for longer.

export infile="retinal.inp"
export outfile="retinal.log"

# There should be no need to edit below this line
#---------------------------------------------------


export ver=00
export nprocs=${SLURM_NTASKS}
export nslots=$((nprocs / 2))
export CMD="rungms-dev ${infile} ${ver} ${nslots} ${nslots} ${nslots} >& ${outfile}"

echo '---------------------------------------------------'
echo "Beginning GAMESS RUN WITH:"
echo "NPROCS = "$nprocs
echo "NSLOTS = "$nslots
echo "SHELL CMD : "$CMD
echo '---------------------------------------------------'

#Start time
start=`date +%s.%N`

eval $CMD

#End time
end=`date +%s.%N`

RUNTIME=$( echo "$end - $start" | bc -l )
echo '---------------------------------------------------'
echo "Runtime: "$RUNTIME" sec"
echo '---------------------------------------------------'
