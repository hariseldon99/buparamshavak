# Instructions

Please read the GROMACS webpage @ the [BUParamShavak website](https://sites.google.com/phys.buruniv.ac.in/buparamshavakcluster/using-singularity-containers/using-gromacs) first

* Download the water benchmark dataset grom the GROMACS website and unpack it

`DATA_SET=water_GMX50_bare
 wget -c https://ftp.gromacs.org/pub/benchmarks/${DATA_SET}.tar.gz
 tar xf ${DATA_SET}.tar.gz
 cd ./water-cut1.0_GMX50_bare/1536`

* Then, run a shell inside the GROMACS singularity container and setup the input

`singularity shell --nv -B ${PWD}:/host_pwd --pwd /host_pwd $SIFDIR/gromacs/gromacs-2022.3_20230205.sif
source /usr/local/gromacs/avx_512/bin/GMXRC activate
gmx grompp -f pme.mdp
exit`

* Copy the sbatch file over to the running directory and submit the job

`cp ../../gromacs_run.sbatch ./
sbatch gromacs_run.sbatch`

# References:
1. GROMACS NGC container: https://catalog.ngc.nvidia.com/orgs/hpc/containers/gromacs
2. GROMACS webpage @ BUParamShavak: https://sites.google.com/phys.buruniv.ac.in/buparamshavakcluster/using-singularity-containers/using-gromacs
