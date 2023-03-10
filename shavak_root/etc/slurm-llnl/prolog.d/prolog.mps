#!/bin/bash
#
# Sample Prolog to start and quit the MPS server as needed
# NOTE: This is only a sample and may need modification for your environment
#

# Specify default locations of file where script tracks the MPS device ID
MPS_DEV_ID_FILE="/var/run/mps_dev_id"

# Specify directory where MPS and Slurm commands are located (if not in search path)
#MPS_CMD_DIR="/usr/bin/"
#SLURM_CMD_DIR="/usr/bin/"

# Determine which GPU the MPS server is running on
if [ -f ${MPS_DEV_ID_FILE} ]; then
	MPS_DEV_ID=$(cat ${MPS_DEV_ID_FILE})
else
	MPS_DEV_ID=""
fi

# If job requires MPS, determine if it is running now on wrong (old) GPU assignment
unset KILL_MPS_SERVER
if [ -n "${CUDA_VISIBLE_DEVICES}" ] &&
   [ -n "${CUDA_MPS_ACTIVE_THREAD_PERCENTAGE}" ] &&
   [[ ${CUDA_VISIBLE_DEVICES} != ${MPS_DEV_ID} ]]; then
	KILL_MPS_SERVER=1
# If job requires full GPU(s) then kill the MPS server if it is still running
# on any of the GPUs allocated to this job.
# This string compare assumes there are not more than 10 GPUs per node.
elif [ -n "${CUDA_VISIBLE_DEVICES}" ] &&
     [ -z "${CUDA_MPS_ACTIVE_THREAD_PERCENTAGE}" ] &&
     [[ ${CUDA_VISIBLE_DEVICES} == *${MPS_DEV_ID}* ]]; then
	KILL_MPS_SERVER=1
fi

if [ -n "${KILL_MPS_SERVER}" ]; then
	echo -1 >${MPS_DEV_ID_FILE}
	# Determine if MPS server is running
	ps aux | grep nvidia-cuda-mps-control | grep -v grep > /dev/null
	if [ $? -eq 0 ]; then
		echo "Stopping MPS control daemon"
		# Reset GPU mode to default
		${MPS_CMD_DIR}nvidia-smi -c ${CUDA_VISIBLE_DEVICES}
		# Quit MPS server daemon
		echo quit | ${MPS_CMD_DIR}nvidia-cuda-mps-control
		# Check GPU sanity, simple check
		${MPS_CMD_DIR}nvidia-smi > /dev/null
		if [ $? -ne 0 ]; then
			logger "`hostname` Slurm Prolog: GPU not operational! Downing node"
			${SLURM_CMD_DIR}scontrol update nodename=${SLURMD_NODENAME} State=DOWN Reason="GPU not operational"
		fi
	fi
fi

# If job requires MPS then write device ID to file and start server as needed
# If server is already running the start requests just return with an error
if [ -n "${CUDA_VISIBLE_DEVICES}" ] &&
   [ -n "${CUDA_MPS_ACTIVE_THREAD_PERCENTAGE}" ]; then
	echo ${CUDA_VISIBLE_DEVICES} >${MPS_DEV_ID_FILE}
	unset CUDA_MPS_ACTIVE_THREAD_PERCENTAGE
	export CUDA_MPS_PIPE_DIRECTORY=/tmp/nvidia-mps_${CUDA_VISIBLE_DEVICES}
	export CUDA_MPS_LOG_DIRECTORY=/tmp/nvidia-log_${CUDA_VISIBLE_DEVICES}
	${MPS_CMD_DIR}nvidia-cuda-mps-control -d && echo "MPS control daemon started"
	sleep 1
	${MPS_CMD_DIR}nvidia-cuda-mps-control start_server -uid $SLURM_JOB_UID && echo "MPS server started for $SLURM_JOB_UID"
fi

exit 0
