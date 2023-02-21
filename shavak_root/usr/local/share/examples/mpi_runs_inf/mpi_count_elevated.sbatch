#!/bin/bash
# Put your SLURM options here
#SBATCH --qos=elevated
#SBATCH -J elevated       # Job Name
#SBATCH --partition=GPU
#SBATCH -o MPI_count.o%j      # Name of the output file (myMPI.oJobID)
#SBATCH -n 1                  # Number of tasks
#SBATCH --time=10:15:00           # put proper time of reservation here
#SBATCH -e MPI_count.err%j    # Direct error to the error file

readonly RUNEXEC="./mpi_count"
mpirun -np ${SLURM_NTASKS} $RUNEXEC
