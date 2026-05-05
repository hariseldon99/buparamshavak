#!/bin/bash
# Put your SLURM options here
#SBATCH --qos=elevated
#SBATCH -J win2k19       # Job Name
#SBATCH -n 8             # Number of cpus. Don't change this without changing num of cpus in the vm itself
#SBATCH --time=12:00:00  # Put proper time of reservation here


readonly VM_NAME="win2k19" #Change this to your vm name
#Notabene: If your job crashes prematurely, then kindly shutdown the vm manually with the command: virsh shutdown win2k19 afterwards



virsh start $VM_NAME

get_time_remaining(){

	REMAINING=`squeue -h -j ${SLURM_JOBID} -o "%L"`
	days=$(echo $REMAINING | awk -F- '{print $1}')
	hms=$(echo $REMAINING | awk -F- '{print $2}')

	if [[ -n "$hms" ]] 
	then
		declare -i days_int=$days
	else
		hms=$days
		declare -i days_int=0
	fi

	days_in_secs=86400*days_int

	declare -i seconds=$(echo $hms | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
	declare -i time_remaining=seconds+days_in_secs
	export TR=$time_remaining
}

get_time_remaining
declare -i time_remaining=$TR
echo $time_remaining

while [[ "$time_remaining" -gt 0 ]]
do
	sleep 1
	get_time_remaining
	declare -i time_remaining=$TR
done

virsh shutdown $VM_NAME
echo "Shutdown command sent to ${VM_NAME}, exiting now."
