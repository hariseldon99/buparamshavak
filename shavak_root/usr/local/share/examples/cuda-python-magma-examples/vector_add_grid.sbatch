BATCH --job-name=vecadd
#This sets the name of the job

#SBATCH --ntasks=1 
#This sets the number of processes to 1. Change if needed

#SBATCH --cpus-per-task=1
#This allocates the number of cpus per tasks. If the number of tasks is 1, and cpus per task is 1, then slurm will assign 1 X 1 = 1 cpus to the job

#SBATCH --time=00:05:00 
#This allocates the walltime to 5 minutes. The program will not run for longer.

#SBATCH --qos=normal 
#This sets the quality of service to 'normal'

#SBATCH --partition=GPU
#This now sets the partition to the GPU partition

#SBATCH --gres=mps:10
#This is a global resources (GRES) scheduler. It sets the resource for this program to 10% of the GPU

srun ./vector_add_grid
#The srun command is part of SLURM, and can run compatible programs in parallel with the allocated resources
