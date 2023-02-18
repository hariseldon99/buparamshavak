#!/usr/bin/env python
import sys, os, subprocess
import traceback

slurm_partitions = ["CPU", "GPU"]
slurm_qos = ["normal", "elevated"]

def killall_extlogin():
    '''Kill all external logins'''
    os.system('/usr/bin/systemctl is-active dwagent && /usr/bin/systemctl stop dwagent')
    return True

def toggle_slurm_state(partition, state):
    cmd = f'scontrol update PartitionName={partition} State={state}'
    os.system(cmd)
    return True

def cancel_slurm_jobs(state="R", qos="normal"):
    subprocess.call(f'squeue -q {qos} -ho %A -t {state}| xargs -n 1 scancel', shell=True)
    return True

def toggle_suspend_slurm_jobs(state="R", qos="elevated", action="suspend"):
    subprocess.call('squeue -q {qos} -ho %A -t {state} | xargs -n 1 scontrol {action}', shell=True)

def shutdown_slurm():
    '''Clean Shutdown of all SLURM daemons'''
    subprocess.call('scontrol shutdown')
    return True


def shutdown():
    killall_extlogin()
    #Drain all SLURM partitions
    for p in slurm_partitions:
        toggle_slurm_state(p,"DRAIN")
    #Cancel all running jobs   
    for q in slurm_qos:
        cancel_slurm_jobs(qos=q)
    shutdown_slurm()
    return True

def bootup():
    #UnDrain all SLURM partitions
    for p in slurm_partitions:
        toggle_slurm_state(p,"UP")
    return True

def pre_hibernate():
    #Drain all SLURM partitions
    for p in slurm_partitions:
        toggle_slurm_state(p,"DRAIN")
    #Cancel all jobs running in normal SLURM QoS
    cancel_slurm_jobs()
    #Suspend all jobs running in elevated SLURM Qos 
    toggle_suspend_slurm_jobs()
    
def post_hibernate():
    #Resume all suspended jobs
    for q in slurm_qos:
        toggle_suspend_slurm_jobs(state="S", qos=q, action="resume")
    #UnDrain all SLURM partitions
    for p in slurm_partitions:
        toggle_slurm_state(p,"UP")
        
if __name__ == '__main__':
    try:
        action = globals()[sys.argv[1]]
        action()
    except Exception:
        traceback.print_exc()