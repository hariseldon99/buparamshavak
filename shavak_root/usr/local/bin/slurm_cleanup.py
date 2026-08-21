#!/usr/bin/env python
import sys, os 
import traceback
import pyslurm


def get_alljobs():
    a = pyslurm.job()
    return a

def jobids_instate(jobs, state):
    j = jobs.get()
    if len(j) > 0:
       jobids = jobs.find('job_state', state)
    else:
       jobids = None
    return jobids

def jobids_inqos(jobs, qos):
    j = jobs.get()
    if len(j) > 0:
        jobids = jobs.find('qos', qos)
    else:
        jobids = None
    return jobids

def toggle_all_partitions(newstate="UP", reason="Uptime"):
    '''Down all SLURM partitions. All running and suspended jobs cancelled'''
    try:
        slurm_partitions = list(pyslurm.partition().get().keys())
        for p in slurm_partitions:
            part_dict = pyslurm.create_partition_dict()
            part_dict["Name"] = p
            part_dict["State"] = newstate
            part_dict["Reason"] = reason       
            a = pyslurm.slurm_update_partition(part_dict)    
    except Exception:
        traceback.print_exc()
        return False
    else:
        return True

def killall_extlogin():
    '''Kill all external logins'''
    try:
        os.system('/usr/bin/systemctl is-active dwagent && /usr/bin/systemctl stop dwagent')
    except Exception:
        traceback.print_exc()
        return False
    return True

def requeue_slurm_jobs(jobids):
    '''Requeue running or suspended jobs back to PENDING state non-destructively'''
    if not jobids:
        return True
    try:
        for jid in jobids:
            try:
                if hasattr(pyslurm, 'slurm_requeue'):
                    pyslurm.slurm_requeue(int(jid), 0)
                else:
                    os.system('/usr/bin/scontrol requeue {}'.format(jid))
            except Exception:
                os.system('/usr/bin/scontrol requeue {}'.format(jid))
        return True
    except Exception:
        traceback.print_exc()
        return False

def cancel_slurm_jobs(jobids):
    '''Cancel slurm jobs permanently (destructive)'''
    try:
        for id in jobids:
            rc = pyslurm.slurm_kill_job(id,9)
    except Exception:
        traceback.print_exc()
        return False
    else:
        return True

def suspend_slurm_jobs(jobids):
    try:
        for id in jobids:
            pyslurm.slurm_suspend(id)
        return True
    except Exception:
        traceback.print_exc()
        return False   

def resume_slurm_jobs(jobids):
    try:
        for id in jobids:
            pyslurm.slurm_resume(id)
        return True
    except Exception:
        traceback.print_exc()
        return False  

def shutdown_slurm():
    '''Clean Shutdown of all SLURM daemons. May interfere with systemd shutdown'''
    try:
        pyslurm.slurm_shutdown()
    except Exception:
        traceback.print_exc()
        return False
    else:
        return True

def shutdown():
    '''
    Non-destructive system shutdown routine:
    1. Sets all partitions DOWN to prevent new jobs from launching.
    2. Requeues all currently RUNNING and SUSPENDED jobs back to PENDING
       so they are preserved and automatically resumed on next bootup.
    '''
    result = toggle_all_partitions(newstate="DOWN", reason="Scheduled Shutdown / Downtime")
    
    jobs = get_alljobs()
    
    running_jobids = jobids_instate(jobs, "RUNNING")
    if running_jobids:
        requeue_slurm_jobs(running_jobids)
    
    suspended_jobids = jobids_instate(jobs, "SUSPENDED")
    if suspended_jobids:
        requeue_slurm_jobs(suspended_jobids)
        
    return result

def bootup():
    '''
    System bootup routine:
    Toggles all partitions back UP so scheduled and requeued jobs can execute.
    '''
    result = toggle_all_partitions(newstate="UP", reason="Uptime")
    return result

def pre_hibernate():
    '''
    DEPRECATED: Hibernation suspend handling has been superseded by the
    slurm-power-recovery framework. Jobs are now safely preserved across
    hibernation and cleanly requeued upon resume.
    '''
    result = toggle_all_partitions(newstate="DOWN", reason="Sched. Downtime")
    
    jobs = get_alljobs()
    running_jobids = jobids_instate(jobs, "RUNNING")
    normal_jobids = jobids_inqos(jobs, "normal")
    elevated_jobids = jobids_inqos(jobs, "elevated")

    running_normal = list(set(running_jobids).intersection(normal_jobids))
    #DISABLED: result = cancel_slurm_jobs(running_normal)
    result = suspend_slurm_jobs(running_normal)
    
    running_elevated = list(set(running_jobids).intersection(elevated_jobids))
    result = suspend_slurm_jobs(running_elevated)
    return result
    
def post_hibernate():
    '''
    DEPRECATED: Post-hibernation recovery has been superseded by
    slurm-power-recovery.service (slurm-recovery-hook.sh), which performs
    full hardware CPU frequency restoration, cgroup/orphan task purging,
    NVIDIA MPS stack reset, and automated job requeueing.
    '''
    result = toggle_all_partitions()
    
    jobs = get_alljobs()
    suspended_jobids = jobids_instate(jobs, "SUSPENDED")
    result = resume_slurm_jobs(suspended_jobids)
    
    return result
        
if __name__ == '__main__':
    try:
        action = globals()[sys.argv[1]]
        action()
    except Exception:
        traceback.print_exc()
