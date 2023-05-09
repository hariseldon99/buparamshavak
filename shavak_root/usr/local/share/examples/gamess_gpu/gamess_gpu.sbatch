#!/bin/bash

#---------------------------------------------------
#SBATCH --job-name=form
# This sets the job name. Change if needed

#SBATCH --partition=GPU
#SBATCH --gres=gpu:1

#SBATCH --ntasks=8
# This sets the number of tasks

#SBATCH --cpus-per-task=1
# This sets the number of processes. Change if needed

#SBATCH --qos=normal
# This sets the quality of service to 'normal'

#SBATCH --time=12:00:00
# This allocates the walltime to 12 hrs
# The program will not run for longer.

readonly infile="cc-h2co.inp"
# This sets the name of the input file

# There should be no need to edit below this line
#---------------------------------------------------
readonly nprocs=`expr ${SLURM_NTASKS} \* ${SLURM_CPUS_PER_TASK}`
export SIMG=${SIFDIR}/gamess/gamess_17.09-r2-libcchem.simg
mkdir -p scratch restart results

echo '---------------------------------------------------'
echo "Beginning GAMESS RUN WITH:"
echo "NPROCS = " ${nprocs}
echo '---------------------------------------------------'

#Start time
start=`date +%s.%N`

singularity run --cleanenv --nv -B ${PWD}:/workspace -B ${PWD}/results:/results ${SIMG} -c "cd /workspace && rungms ${infile} -p ${nprocs}"

#End time
end=`date +%s.%N`

runtime=$( echo "$end - $start" | bc -l )
echo '---------------------------------------------------'
echo "Runtime: ${runtime} sec"
echo '---------------------------------------------------'
