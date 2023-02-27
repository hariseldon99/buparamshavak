#!/bin/bash
#
# Epilog modded from Sample Prolog to quit the MPS server
# NOTE: This is only a sample and may need modification for your environment
#

# Specify directory where MPS and Slurm commands are located (if not in search path)
#MPS_CMD_DIR="/usr/bin/"
#SLURM_CMD_DIR="/usr/bin/"

# Determine which GPU the MPS server is running on
KILL_MPS_SERVER=1

if [ -n "${KILL_MPS_SERVER}" ]; then
	# Determine if MPS server is running
	ps aux | grep nvidia-cuda-mps-control | grep -v grep > /dev/null
	if [ $? -eq 0 ]; then
		echo "Stopping MPS control daemon"
		# Reset GPU mode to default
		${MPS_CMD_DIR}nvidia-smi -c ${CUDA_VISIBLE_DEVICES}
		# Quit MPS server daemon
		killall nvidia-cuda-mps-control
		# Test for presence of MPS zombie process
		ps aux | grep nvidia-cuda-mps | grep -v grep > /dev/null
		if [ $? -eq 0 ]; then
			killall nvidia-cuda-mps-control
		fi
	fi
fi
exit 0
