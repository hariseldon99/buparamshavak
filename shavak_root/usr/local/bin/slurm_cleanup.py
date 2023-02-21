#!/usr/bin/env python
import sys, os 
import traceback
import pyslurm

slurm_partitions = ["CPU", "GPU"]

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
        for p in slurm_partitions:
            part_dict = pyslurm.create_partition_dict()
            part_dict["Name"] = p
            part_dict["State"] = newstate
            part_dict["Reason"] = reason       
            a = pyslurm.slurm_update_partition(part_dict)    
    except Exception as e:
        return False
    else:
        return True

def killall_extlogin():
    '''Kill all external logins'''
    os.system('/usr/bin/systemctl is-active dwagent && /usr/bin/systemctl stop dwagent')
    return True

def cancel_slurm_jobs(jobids):
    try:
        for id in jobids:
            rc = pyslurm.slurm_kill_job(id,9)
    except Exception:
        return False
    else:
        return True

def suspend_slurm_jobs(jobids):
    try:
        for id in jobids:
            pyslurm.slurm_suspend(id)
        return True
    except Exception:
        return False   

def resume_slurm_jobs(jobids):
    try:
        for id in jobids:
            pyslurm.slurm_resume(id)
        return True
    except Exception:
        return False  

def shutdown_slurm():
    '''Clean Shutdown of all SLURM daemons. May interfere with systemd shutdown'''
    try:
        pyslurm.slurm_shutdown()
    except Exception:
        return False
    else:
        return True

def shutdown():
    #DISABLED: killall_extlogin()
    result = toggle_all_partitions(newstate="DOWN", reason="Unsched. Downtime")
    
    jobs = get_alljobs()
    
    running_jobids = jobids_instate(jobs,"RUNNING")
    result = cancel_slurm_jobs(running_jobids)
    
    suspended_jobids  = jobids_instate(jobs, "SUSPENDED")
    result = cancel_slurm_jobs(suspended_jobids)
    #DISABLED: result = shutdown_slurm()
    return result

def bootup():
    result = toggle_all_partitions()
    return result

def pre_hibernate():
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
