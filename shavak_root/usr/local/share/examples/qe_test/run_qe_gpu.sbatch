#!/bin/bash
#SBATCH --reservation=daily_run

#SBATCH --job-name=qetestGPU
#This sets the name of the job

#SBATCH --time=00:05:00 
#This allocates the walltime to 5 minutes. The program will not run for longer.

#SBATCH --ntasks=1
#This sets the number of processes to 4. Change if needed

#SBATCH --cpus-per-task=1
#This allocates the number of cpus per tasks. If the number of tasks is 4, and cpus per task is 1, then slurm will assign 4 X 1 = 4 cpus to the job

#SBATCH --partition=GPU
#This now sets the partition to the GPU partition

#SBATCH --gres=gpu:1
#This is a global resources (GRES) scheduler. It sets the resource for this program to 1 GPU

set -e; set -o pipefail



# Set cluster/experiment specific variables
readonly gpus_per_node=1

readonly infile_scf="pw.graphene.scf.in"
readonly outfile_scf="pw.graphene.scf.out"

readonly infile_nscf="pw.graphene.nscf.in"
readonly outfile_nscf="pw.graphene.nscf.out"

readonly qe_sif="${SIFDIR}/qe/qe-7.1_20230206.sif"

# The GPU image does not have dos.x or bands.x

# Attempt to start MPS server within container if needed
#if (( procs_per_gpu > 1 )); then
#    srun --ntasks-per-node=1 /bin/bash -c "nvidia-cuda-mps-control -d; sleep infinity" &
#fi

# Launch parallel QE experiment
srun --mpi=pmi2 --output=$outfile_scf\
     singularity run --nv "-B${PWD}:/host_pwd" --pwd /host_pwd \
     ${qe_sif} \
     pw.x \
     -input $infile_scf \

srun --mpi=pmi2 --output=$outfile_nscf\
     singularity run --nv "-B${PWD}:/host_pwd" --pwd /host_pwd \
     ${qe_sif} \
     pw.x \
     -input $infile_nscf \

# Attempt to exit MPS server
#srun --ntasks-per-node=1 /bin/bash -c "echo quit | nvidia-cuda-mps-control || true"
