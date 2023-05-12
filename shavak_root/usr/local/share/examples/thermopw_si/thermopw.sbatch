#!/bin/bash

#SBATCH --job-name=thermopw-si
# This sets the name of the job

#SBATCH --partition=GPU
#This sets the partition to the GPU partition. Important for GPU jobs

#SBATCH --gres=gpu:1
# This allocates 100% of 1 GPU as MPS. Important for GPU jobs
# Choose either GRES or MPS for GPU Allocation

#SBATCH --ntasks=16
# This sets the number of processes to 16.

#SBATCH --cpus-per-task=1
# This allocates the number of cpus per tasks. 

#SBATCH --time=12:00:00 
# This allocates the walltime to 12 hours. The program will not run for longer.

#SBATCH --output=R-%x.%j.out
#SBATCH --error=R-%x.%j.err

export PSEUDO_DIR_HOST=/usr/share/espresso/pseudo/
export PSEUDO_DIR_IMG=/pseudo 
export PSEUDO_LIST="Si.pz-vbc.UPF"
export TMP_DIR=./tmp
# This sets pseudopotential and temporary files directories in the host


export NIMG="1"
# Below are the input cards
cat > thermo_control << EOF
 &INPUT_THERMO
  what='scf',
 /
EOF

cat > scf.in << EOF
 &control
    calculation = 'scf'
    restart_mode='from_scratch',
    prefix='silicon',
    tstress = .true.
    tprnfor = .true.
    pseudo_dir = '${PSEUDO_DIR_IMG}/',
    outdir='${TMP_DIR}/'
 /
 &system
    ibrav=  2, celldm(1) =10.20, nat=  2, ntyp= 1,
    ecutwfc =24.0,
 /
 &electrons
    mixing_mode = 'plain'
    mixing_beta = 0.7
    conv_thr =  1.0d-8
 /
ATOMIC_SPECIES
 Si  28.086  ${PSEUDO_LIST}
ATOMIC_POSITIONS (alat)
 Si 0.00 0.00 0.00
 Si 0.25 0.25 0.25
K_POINTS AUTOMATIC
4 4 4 1 1 1 
EOF


# Avoid editing below this line unless absolutely necessary
########################################################################################
export ECHO="echo -e"
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

export SINGULARITY="singularity run --nv -B ${PWD}:/host_pwd -B ${PSEUDO_DIR_HOST}:${PSEUDO_DIR_IMG} --pwd /host_pwd ${QE_IMGDIR}/${QE_IMG}"

echo "###########################################"
export PARA_IMAGE_PREFIX="srun ${SINGULARITY}"
export PARA_IMAGE_POSTFIX="-ni ${NIMG}"

# required executables and pseudopotentials
BIN_LIST="thermo_pw.x"



# how to run executables
THERMO_PW_COMMAND="$PARA_IMAGE_PREFIX thermo_pw.x $PARA_IMAGE_POSTFIX"
$ECHO 
$ECHO "  running thermo_pw.x as: $THERMO_PW_COMMAND"
$ECHO

cd $SLURM_SUBMIT_DIR


$ECHO "  cleaning $TMP_DIR..."
rm -rf $TMP_DIR/*
$ECHO " done"

$ECHO "  running the thermo_pw calculation..."
$THERMO_PW_COMMAND < scf.in > scf.out
$ECHO " done"

