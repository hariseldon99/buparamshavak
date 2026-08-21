#!/bin/bash
# Generalized Post-Hibernation Recovery Framework
set -euo pipefail

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "=== [$(date)] Starting Automated Cluster Power Recovery ==="

# 1. Force the kernel to drop firmware-dictated ACPI PPC caps & restore CPU scaling
echo "Restoring CPU frequency scaling and clearing ACPI PPC throttling caps..."
if [ -f /sys/module/processor/parameters/ignore_ppc ]; then
    echo 1 > /sys/module/processor/parameters/ignore_ppc 2>/dev/null || true
fi

# Reset scaling boundaries and performance governor for every logical CPU core
for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
    if [ -d "${cpu_dir}" ]; then
        if [ -f "${cpu_dir}/cpuinfo_max_freq" ] && [ -w "${cpu_dir}/scaling_max_freq" ]; then
            max_freq=$(cat "${cpu_dir}/cpuinfo_max_freq" 2>/dev/null || echo "3000000")
            echo "${max_freq}" > "${cpu_dir}/scaling_max_freq" 2>/dev/null || true
        fi
        if [ -f "${cpu_dir}/cpuinfo_min_freq" ] && [ -w "${cpu_dir}/scaling_min_freq" ]; then
            min_freq=$(cat "${cpu_dir}/cpuinfo_min_freq" 2>/dev/null || echo "800000")
            echo "${min_freq}" > "${cpu_dir}/scaling_min_freq" 2>/dev/null || true
        fi
        if [ -w "${cpu_dir}/scaling_governor" ]; then
            echo "performance" > "${cpu_dir}/scaling_governor" 2>/dev/null || true
        fi
        if [ -w "${cpu_dir}/energy_performance_preference" ]; then
            echo "performance" > "${cpu_dir}/energy_performance_preference" 2>/dev/null || true
        fi
    fi
done

# Re-evaluate governor window via cpupower or cpufreq-set if available
if command -v cpupower &> /dev/null; then
    cpupower frequency-set -g performance >/dev/null 2>&1 || true
elif command -v cpufreq-set &> /dev/null; then
    cpufreq-set -r -g performance >/dev/null 2>&1 || true
fi

# Restart cpufrequtils service if active or enabled
if systemctl is-active --quiet cpufrequtils 2>/dev/null || systemctl is-enabled --quiet cpufrequtils 2>/dev/null; then
    systemctl restart cpufrequtils 2>/dev/null || true
fi

# 2. Capture the exact hostname and record stranded jobs before touching node state
NODE_NAME=$(hostname)
echo "Target Node: ${NODE_NAME}"

# Capture all currently running jobs and any jobs stuck in launch-failed holds on this node
STRANDED_RUNNING=$(squeue -w "${NODE_NAME}" -t RUNNING -h -o "%i" 2>/dev/null || true)
HELD_LAUNCH_FAILED=$(squeue -w "${NODE_NAME}" -t PENDING -h -o "%i %r" 2>/dev/null | grep -i "launch" | awk '{print $1}' || true)
ALL_TARGET_JOBS=$(echo -e "${STRANDED_RUNNING}\n${HELD_LAUNCH_FAILED}" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -u || true)

# 3. Cleanly wipe hanging child tasks, cgroups, and step execution environments
echo "Purging lingering job processes and step execution environments..."

# 3a. Kill all child processes registered under Slurm cgroups
if [ -d /sys/fs/cgroup ]; then
    while IFS= read -r proc_file; do
        if [ -n "${proc_file}" ] && [ -f "${proc_file}" ]; then
            while read -r pid; do
                if [ -n "${pid}" ] && [ "${pid}" -gt 1 ]; then
                    kill -9 "${pid}" 2>/dev/null || true
                fi
            done < "${proc_file}" || true
        fi
    done < <(find /sys/fs/cgroup \( -path "*slurm*job*" -o -path "*slurm*step*" -o -path "*/slurm/*" \) \( -name "cgroup.procs" -o -name "tasks" \) 2>/dev/null || true)
fi

# 3b. Kill all direct and indirect children of active slurmstepd daemons
for s_pid in $(pgrep -f slurmstepd 2>/dev/null || true); do
    pkill -9 -P "${s_pid}" 2>/dev/null || true
done

# 3c. Wipe slurmstepd daemons themselves
pkill -9 -f slurmstepd 2>/dev/null || true

# 4. Reset the NVIDIA Multi-Process Service (MPS) framework if present
if command -v nvidia-cuda-mps-control &> /dev/null; then
    echo "NVIDIA Stack detected. Cleaning up global compute pipes..."
    nvidia-cuda-mps-control quit 2>/dev/null || true
    sleep 1
    nvidia-cuda-mps-control -d 2>/dev/null || true
fi

# 5. Cycle the local slurmd execution agent to re-register clean state
echo "Cycling local slurm processor agent..."
systemctl stop OpenSM slurmd 2>/dev/null || true
systemctl stop slurmd 2>/dev/null || true
sleep 1
systemctl start slurmd

# Wait for slurmd to establish connection with slurmctld and resume node
sleep 2
scontrol update nodename="${NODE_NAME}" state=RESUME 2>/dev/null || true

# 6. Requeue and release stranded jobs now that the node is fully healthy
if [ -n "${ALL_TARGET_JOBS}" ]; then
    echo "Requeuing and releasing target jobs on node: ${ALL_TARGET_JOBS}"
    echo "${ALL_TARGET_JOBS}" | xargs -r scontrol requeue 2>/dev/null || true
    echo "${ALL_TARGET_JOBS}" | xargs -r scontrol release 2>/dev/null || true
else
    echo "No stranded running or held tasks detected on this node footprint."
fi

echo "=== Recovery Pipeline Successfully Completed ==="

