#!/usr/bin/env python
import traceback
import os, subprocess

cmd_slurm_resume="squeue -ho %A -t S | xargs -n 1 scontrol resume"
slurm_partitions = ["CPU", "GPU"]

if __name__ == '__main__':
    try:
        time.sleep(10.0)
        subprocess.call(cmd_slurm_resume, shell=True)
        #Bring up all SLURM partitions
        for partition in slurm_partitions:
            undraincmd = f'scontrol update PartitionName={partition} State=UP'
            os.system(undraincmd)
    except Exception:
        traceback.print_exc()
