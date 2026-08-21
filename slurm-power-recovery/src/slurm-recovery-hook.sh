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

# 2. Capture the exact hostname as recognized by your Slurm Controller
NODE_NAME=$(hostname)
echo "Target Node: ${NODE_NAME}"

# 3. Extract and requeue ALL jobs running on this physical node
# This is generalized: it affects all frameworks (GROMACS, Amber, PyTorch, etc.)
ACTIVE_JOBS=$(squeue -w "${NODE_NAME}" -t RUNNING -h -o "%i" || true)

if [ -n "${ACTIVE_JOBS}" ]; then
    echo "Found active running jobs stranded on node. Forcing requeue..."
    echo "${ACTIVE_JOBS}" | xargs -r scontrol requeue
else
    echo "No running tasks detected on this node cluster footprint."
fi

# 4. Cleanly wipe hanging step daemons from the local Linux process tree
echo "Purging lingering step execution environments..."
pkill -9 slurmstepd || true

# 5. Cycle the local execution agent to drop corrupted state tracking maps
echo "Cycling local slurm processor agent..."
systemctl stop OpenSM slurmd 2>/dev/null || true
systemctl stop slurmd || true
sleep 1
systemctl start slurmd

# 6. Reset the NVIDIA Multi-Process Service (MPS) framework if it is active
if command -v nvidia-cuda-mps-control &> /dev/null; then
    echo "NVIDIA Stack detected. Cleaning up global compute pipes..."
    nvidia-cuda-mps-control quit || true
    sleep 2
    nvidia-cuda-mps-control -d
fi

echo "=== Recovery Pipeline Successfully Completed ==="
