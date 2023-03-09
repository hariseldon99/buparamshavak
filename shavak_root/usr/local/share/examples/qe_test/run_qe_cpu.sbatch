#!/bin/bash

#SBATCH --job-name=qetest_graphene
#This sets the name of the job

#SBATCH --time=00:05:00 
#This allocates the walltime to 5 minutes. The program will not run for longer.

#SBATCH --ntasks=1
#This sets the number of processes to 4. Adjust as necessary

#Quantum Espresso seems to ignore this setting,effectively setting this to one always
#<-DISABLED--->SBATCH --cpus-per-task=1

#SBATCH --partition=CPU
#This now sets the partition to the CPU partition

set -e; set -o pipefail
readonly INDIR=${PWD}
readonly OUTDIR=${PWD}/outdir


# Launch parallel QE experiment: See README for details
srun pw.x -input $INDIR/pw.graphene.scf.in > $OUTDIR/pw.graphene.scf.out
srun pw.x -input $INDIR/pw.graphene.nscf.in > $OUTDIR/pw.graphene.nscf.out
srun dos.x -input $INDIR/dos.graphene.in > $OUTDIR/dos.graphene.out
srun pw.x -input $INDIR/pw.graphene.bands.in > $OUTDIR/pw.graphene.bands.out
srun bands.x -input $INDIR/bands.graphene.in > $OUTDIR/bands.graphene.out 
