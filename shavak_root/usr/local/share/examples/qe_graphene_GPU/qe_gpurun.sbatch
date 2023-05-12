#!/bin/bash

#SBATCH --job-name=qetest-gr
# This sets the name of the job

#SBATCH --partition=GPU
#This sets the partition to the GPU partition. Important for GPU jobs

# <---DISABLED SBATCH --gres=mps:100
#SBATCH --gres=gpu:1
# This allocates 100% of 1 GPU as MPS. Important for GPU jobs
# Choose either GRES or MPS for GPU Allocation

#SBATCH --ntasks=16
# This sets the number of processes to 16.

#SBATCH --cpus-per-task=1
# This allocates the number of cpus per tasks. 

#SBATCH --time=12:00:00 
# This allocates the walltime to 12 hours. The program will not run for longer.

# Avoid editing below this line unless absolutely necessary
########################################################################################
export QE_IMGDIR=$SIFDIR/qe
export QE_IMG=qe-7.1-thermopw-20230501.sif

export OMPI_MCA_btl="self,vader,tcp"
export SINGULARITYENV_PMIX_MCA_gds=hash
# Do not change these. These variables forcibly turn off infiniband use, 
# and ib is not supported properly in the singularity image

export OPENMPI_HOME=/opt/nvidia/hpc_sdk/Linux_x86_64/23.3/comm_libs/openmpi/openmpi-3.1.5
export OPAL_PREFIX=${OPENMPI_HOME}
export OPAL_EXEC_PREFIX=${OPENMPI_HOME}
export OPAL_BINDIR=${OPENMPI_HOME}/bin
export OPAL_SBINDIR=${OPENMPI_HOME}/sbin
export OPAL_LIBEXECDIR=${OPENMPI_HOME}/libexec
export OPAL_DATAROOTDIR=${OPENMPI_HOME}/share
export OPAL_DATADIR=${OPENMPI_HOME}/share
export OPAL_SYSCONFDIR=${OPENMPI_HOME}/etc
export OPAL_LOCALSTATEDIR=${OPENMPI_HOME}/etc
export OPAL_LIBDIR=${OPENMPI_HOME}/lib
export OPAL_INCLUDEDIR=${OPENMPI_HOME}/include
export OPAL_INFODIR=${OPENMPI_HOME}/share/info
export OPAL_MANDIR=${OPENMPI_HOME}/share/man
export OPAL_PKGDATADIR=${OPENMPI_HOME}/share/openmpi
export OPAL_PKGLIBDIR=${OPENMPI_HOME}/lib/openmpi
export OPAL_PKGINCLUDEDIR=${OPENMPI_HOME}/include/openmpi
# Do not change these. This variables allow openmpi running in the 
# singularity image to find the MPI installation
# Necessary due to a bug in nvidia hpc sdk

export SINGULARITY="singularity run --nv -B ${PWD}:/host_pwd --pwd /host_pwd ${QE_IMGDIR}/${QE_IMG}"

echo "###########################################"
echo "SCF Calculation:"
srun $SINGULARITY pw.x < scf.in > scf.out
echo "###########################################"
echo "NSCF Calculation:"
srun $SINGULARITY pw.x < nscf.in > nscf.out
echo "###########################################"
echo "BAND Calculation:"
srun $SINGULARITY bands.x < bands.in > bands.out
echo "###########################################"
echo "DOS Calculation:"
srun $SINGULARITY dos.x < dos.in > dos.out
