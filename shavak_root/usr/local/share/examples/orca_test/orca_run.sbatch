#!/bin/bash

#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --time=8760:00:00
#SBATCH --qos=elevated
#SBATCH --error="%x.e%j"
#SBATCH --output="%x.o%j"

# Usage of this script:

#sbatch -J jobname orca_run.sbatch , where jobname is the name of your ORCA inputfile (jobname.inp).

# Jobname below is set automatically when submitting like this: sbatch -J jobname orca_run.sbatch

#Can alternatively be set manually below. job variable should be the name of the inputfile without extension (.inp)

job=${SLURM_JOB_NAME}

job=$(echo ${job%%.*})


export orcadir=/opt/orca

export RSH_COMMAND="/usr/bin/ssh -x"

export PATH=$orcadir:$PATH

export LD_LIBRARY_PATH=$orcadir:$LD_LIBRARY_PATH

# Creating local scratch folder for the user on the computing node. 

#Set the scratchlocation variable to the location of the local scratch, e.g. /scratch or /localscratch 

export scratchlocation=$SLURM_SUBMIT_DIR/scratch

if [ ! -d $scratchlocation/$USER ]

then

  mkdir -p $scratchlocation/$USER

fi

tdir=$(mktemp -d $scratchlocation/$USER/orcajob__$SLURM_JOB_ID-XXXX)

# Copy only the necessary stuff in submit directory to scratch directory. Add more here if needed.

cp  $SLURM_SUBMIT_DIR/*.inp $tdir/

cp  $SLURM_SUBMIT_DIR/*.gbw $tdir/

cp  $SLURM_SUBMIT_DIR/*.xyz $tdir/

# Creating nodefile in scratch

echo $SLURM_NODELIST > $tdir/$job.nodes

# cd to scratch

cd $tdir

# Copy job and node info to beginning of outputfile

echo "Job execution start: $(date)" >>  $SLURM_SUBMIT_DIR/$job.out

echo "Shared library path: $LD_LIBRARY_PATH" >>  $SLURM_SUBMIT_DIR/$job.out

echo "Slurm Job ID is: ${SLURM_JOB_ID}" >>  $SLURM_SUBMIT_DIR/$job.out

echo "Slurm Job name is: ${SLURM_JOB_NAME}" >>  $SLURM_SUBMIT_DIR/$job.out

echo $SLURM_NODELIST >> $SLURM_SUBMIT_DIR/$job.out

#Start ORCA job. ORCA is started using full pathname (necessary for parallel execution). Output file is written directly to submit directory on frontnode.

$orcadir/orca $job.inp --oversubscribe >> $SLURM_SUBMIT_DIR/$job.out

# ORCA has finished here. Now copy important stuff back (xyz files, GBW files etc.). Add more here if needed.

cp $tdir/*.gbw $SLURM_SUBMIT_DIR

cp $tdir/*.engrad $SLURM_SUBMIT_DIR

cp $tdir/*.xyz $SLURM_SUBMIT_DIR

cp $tdir/*.loc $SLURM_SUBMIT_DIR

cp $tdir/*.qro $SLURM_SUBMIT_DIR

cp $tdir/*.uno $SLURM_SUBMIT_DIR

cp $tdir/*.unso $SLURM_SUBMIT_DIR

cp $tdir/*.uco $SLURM_SUBMIT_DIR

cp $tdir/*.hess $SLURM_SUBMIT_DIR

cp $tdir/*.cis $SLURM_SUBMIT_DIR

cp $tdir/*.dat $SLURM_SUBMIT_DIR

cp $tdir/*.mp2nat $SLURM_SUBMIT_DIR

cp $tdir/*.nat $SLURM_SUBMIT_DIR

cp $tdir/*.scfp_fod $SLURM_SUBMIT_DIR

cp $tdir/*.scfp $SLURM_SUBMIT_DIR

cp $tdir/*.scfr $SLURM_SUBMIT_DIR

cp $tdir/*.nbo $SLURM_SUBMIT_DIR

cp $tdir/FILE.47 $SLURM_SUBMIT_DIR

cp $tdir/*_property.txt $SLURM_SUBMIT_DIR

cp $tdir/*spin* $SLURM_SUBMIT_DIR
