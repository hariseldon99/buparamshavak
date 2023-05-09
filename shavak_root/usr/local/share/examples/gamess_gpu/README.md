# Using the singularity image of GAMESS

## Introduction
The General Atomic and Molecular Electronic Structure Systems (GAMESS) program simulates molecular quantum chemistry, allowing users to calculate various molecular properties and dynamics.

This directory contains the gamess input files for formaldehyde. The file is named 'cc-h2co.inp' and its contents are:

```json
!   CC-SD(T) computation on H2CO...formaldehyde
!   there are 4 atoms and 8 occupied MOs (4 are core)
!   the cc-pVTZ basis has 208 AOs and 196 MOs.
!
!   GAMESS' FORTRAN: FINAL= -113.9108006987, 12 iters, CCSD(T)= -114.3336903108
!   GAMESS+LIBCCHEM: FINAL= -113.9108006987, 12 iters, CCSD(T)= -114.3336903151
!
!   this run took 51 wall seconds on one node w/6 cores and w/1 GPU
!
!   GAMESS' FORTRAN full results
!     REFERENCE ENERGY:     -113.9108006987, 12 iters
!       MBPT(2) ENERGY:     -114.3069217412
!      CC-SD    ENERGY:     -114.3169914353, 17 iters
!      CC-SD[T] ENERGY:     -114.3347603627
!      CC-SD(T) ENERGY:     -114.3336903108
!   GAMESS+LIBCCHEM full results
!          E(RHF)     =     -113.9108006987, 12 iters
!          E(MP2)     =     -114.3069217412
!         E(CC-SD)    =     -114.3169914376, 13 iters
!         E(CC-SD[T]) =     -114.3347603681
!         E(CC-SD(T)) =     -114.3336903151
!
 $contrl scftyp=rhf cctyp=ccsd(t) runtyp=energy ispher=1 $end
 $system mwords=8 memddi=8 $end
 $basis  gbasis=cct $end
 $scf    dirscf=.true. $end
 $data
COH2 cc-pVTZ, R(CO) = equilibrium value
Cnv  2

Oxygen         8.       0.00000000    0.00000000     0.0000000
Carbon         6.       0.00000000    0.00000000    -1.208
Hydrogen       1.       0.00000000    0.94848024537 -1.79608266777
 $end

```

You can view the structure by loading this file in software like [wxMacMolPlt](https://brettbode.github.io/wxmacmolplt/).


The sample SLURM batch submission script for GAMESS is named 'gamess_gpu.sbatch', and its contents are

```bash
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

```

As always, the lines beginning with '#SBATCH' are special commands for the SLURM job scheduler. You may adjust the '--ntasks' to the number of cpus that ypou want to use, as well as any job-name/qos/wall-time settings. It is advisable to leave the '--partition' and '--gres' settings intact, as these settings pertain to the use of the GPU.

Finally, the command 

```bash
readonly infile="cc-h2co.inp"
```

feeds your input file to singularity/GAMESS. You must change the supplied name to your needs.

The BUParamShavak cluster has a singularity image with GAMESS installed inside it. This installation is professionally prepared and compiled, taken from the [nvidia NGC catalog](https://catalog.ngc.nvidia.com/orgs/hpc/containers/gamess), and can use both the CPU and GPU to do computations. Therefore, it should run more smoothly than the version of GAMESS installed in the host itself.

When run properly, Any simulation will have the following standard output:

```json
$ [Running input $JOB on $NCPUS node(s) with $NGPUS gpu(s)]
$ [Run completed]

```

The bulk of the output will be directed to the log file, not the standard output.

# Steps

The run-script assumes the file structure below for your own jobs:

```bash
/path/to/your_workspace
    scratch/
    restart/
    results/
    your_input.inp
```

** Notabene: It is very important that you keep separate directories for separate runs. DO NOT MIX DIFFERENT INPUT/OUTPUT IN THE SAME DIRECTORY TREE**

1. Place your input file in an empty directory. For the sake of concreteness, let us choose a name like 'gamess_run'
2. Copy the SLURM submit script named 'gamess_gpu.sbatch' to that directory. You may rename it, if you wish.
3. Put your input file in the same directory.
4. Open the sbatch file in any text editor, then

   a) Change the name of the input file from the default
   
   b) Adjust the job-name, ntasks and wall-time settings as needed
   
   c) If you need to add additional '#SBATCH' instructions, you may do so.
   

5. **Optional**: You may create the three directories, 'scratch', 'restart', and 'results'. if you do not do so, then the script will do it for you.
   
6.  Submit the job to SLURM with the command 

    ```bash
    $sbatch gamess_gpu.sbatch
    ```

## Output

When the job is running, GAMESS will direct the output to a file named 'cc-h2co.log', where 'cc-h2co.inp' is your input file. As long as the job is running, it will be in the 'gamess_run' directory. Once the job is finished, it will be moved to 'gamess_run/results/'. In addition, the 'gamess_run/restart' and 'gamess_run/scratch' directories will contain checkpointing data and temporary data, respectively, from the job run. 