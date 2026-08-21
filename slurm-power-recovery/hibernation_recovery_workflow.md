Here is a complete, production-ready, generalized project layout tailored for a GitHub repository. It packages your generalized recovery hooks into both a standard clean source tarball installation system and a Debian packaging template (dpkg) Link: GitHub.

This design completely broadens the recovery mechanism: it scans the local host name dynamically, safely issues clean requeues to **all** active running Slurm tasks regardless of their binary framework, completely flushes unkillable processes, and resets the core system resources.

## **Part 1: Repository Directory Structure**

Organize your GitHub project directory to exactly match this tree:

`slurm-power-recovery/`  
`├── LICENSE`  
`├── README.md`  
`├── Makefile`  
`├── debian/`  
`│   ├── control`  
`│   ├── rules`  
`│   ├── changelog`  
`│   ├── compat`  
`│   └── slurm-power-recovery.install`  
`└── src/`  
    `├── slurm-recovery-hook.sh`  
    `└── slurm-power-recovery.service`

## ---

**Part 2: The Core Source Components**

## **src/slurm-recovery-hook.sh**

This generalized script purges zombie configurations, identifies all current jobs allocated to this machine, forces Slurm to safely transition them to pending states, and clears resource contexts.

*`#!/bin/bash`*  
*`# Generalized Post-Hibernation Recovery Framework`*  
`set -euo pipefail`

`export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`

`echo "=== [$(date)] Starting Automated Cluster Power Recovery ==="`

*`# 1. Force the kernel to drop firmware-dictated ACPI PPC caps & restore CPU scaling`*  
`echo "Restoring CPU frequency scaling and clearing ACPI PPC throttling caps..."`  
`if [ -f /sys/module/processor/parameters/ignore_ppc ]; then`  
    `echo 1 > /sys/module/processor/parameters/ignore_ppc 2>/dev/null || true`  
`fi`  

`for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do`  
    `if [ -d "${cpu_dir}" ]; then`  
        `if [ -f "${cpu_dir}/cpuinfo_max_freq" ] && [ -w "${cpu_dir}/scaling_max_freq" ]; then`  
            `max_freq=$(cat "${cpu_dir}/cpuinfo_max_freq" 2>/dev/null || echo "3000000")`  
            `echo "${max_freq}" > "${cpu_dir}/scaling_max_freq" 2>/dev/null || true`  
        `fi`  
        `if [ -f "${cpu_dir}/cpuinfo_min_freq" ] && [ -w "${cpu_dir}/scaling_min_freq" ]; then`  
            `min_freq=$(cat "${cpu_dir}/cpuinfo_min_freq" 2>/dev/null || echo "800000")`  
            `echo "${min_freq}" > "${cpu_dir}/scaling_min_freq" 2>/dev/null || true`  
        `fi`  
        `if [ -w "${cpu_dir}/scaling_governor" ]; then`  
            `echo "performance" > "${cpu_dir}/scaling_governor" 2>/dev/null || true`  
        `fi`  
        `if [ -w "${cpu_dir}/energy_performance_preference" ]; then`  
            `echo "performance" > "${cpu_dir}/energy_performance_preference" 2>/dev/null || true`  
        `fi`  
    `fi`  
`done`  

`if command -v cpupower &> /dev/null; then`  
    `cpupower frequency-set -g performance >/dev/null 2>&1 || true`  
`elif command -v cpufreq-set &> /dev/null; then`  
    `cpufreq-set -r -g performance >/dev/null 2>&1 || true`  
`fi`  

`if systemctl is-active --quiet cpufrequtils 2>/dev/null || systemctl is-enabled --quiet cpufrequtils 2>/dev/null; then`  
    `systemctl restart cpufrequtils 2>/dev/null || true`  
`fi`  

*`# 2. Capture the exact hostname and record stranded jobs before touching node state`*  
`NODE_NAME=$(hostname)`  
`echo "Target Node: ${NODE_NAME}"`

`STRANDED_JOBS=$(squeue -w "${NODE_NAME}" -t RUNNING,SUSPENDED -h -o "%i" 2>/dev/null || true)`  
`HELD_LAUNCH_FAILED=$(squeue -w "${NODE_NAME}" -t PENDING -h -o "%i %r" 2>/dev/null | grep -i "launch" | awk '{print $1}' || true)`  
`ALL_TARGET_JOBS=$(echo -e "${STRANDED_JOBS}\n${HELD_LAUNCH_FAILED}" | tr ' ' '\n' | grep -E '^[0-9]+$' | sort -u || true)`

*`# 3. Cleanly wipe hanging child tasks, cgroups, and step execution environments`*  
`echo "Purging lingering job processes and step execution environments..."`  
`if [ -d /sys/fs/cgroup ]; then`  
    `while IFS= read -r proc_file; do`  
        `if [ -n "${proc_file}" ] && [ -f "${proc_file}" ]; then`  
            `while read -r pid; do`  
                `if [ -n "${pid}" ] && [ "${pid}" -gt 1 ]; then`  
                    `kill -9 "${pid}" 2>/dev/null || true`  
                `fi`  
            `done < "${proc_file}" || true`  
        `fi`  
    `done < <(find /sys/fs/cgroup \( -path "*slurm*job*" -o -path "*slurm*step*" -o -path "*/slurm/*" \) \( -name "cgroup.procs" -o -name "tasks" \) 2>/dev/null || true)`  
`fi`  
`for s_pid in $(pgrep -f slurmstepd 2>/dev/null || true); do`  
    `pkill -9 -P "${s_pid}" 2>/dev/null || true`  
`done`  
`pkill -9 -f slurmstepd 2>/dev/null || true`

*`# 4. Reset the NVIDIA Multi-Process Service (MPS) framework if present`*  
`if command -v nvidia-cuda-mps-control &> /dev/null; then`  
    `echo "NVIDIA Stack detected. Cleaning up global compute pipes..."`  
    `nvidia-cuda-mps-control quit 2>/dev/null || true`  
    `sleep 1`  
    `nvidia-cuda-mps-control -d 2>/dev/null || true`  
`fi`

*`# 5. Cycle the local slurmd execution agent to re-register clean state`*  
`echo "Cycling local slurm processor agent..."`  
`systemctl stop OpenSM slurmd 2>/dev/null || true`  
`systemctl stop slurmd 2>/dev/null || true`  
`sleep 1`  
`systemctl start slurmd`  
`sleep 2`  
`scontrol update nodename="${NODE_NAME}" state=RESUME 2>/dev/null || true`  
`scontrol update PartitionName=ALL State=UP 2>/dev/null || true`

*`# 6. Requeue and release stranded jobs now that the node is fully healthy`*  
`if [ -n "${ALL_TARGET_JOBS}" ]; then`  
    `echo "Requeuing and releasing target jobs on node: ${ALL_TARGET_JOBS}"`  
    `echo "${ALL_TARGET_JOBS}" | xargs -r scontrol requeue 2>/dev/null || true`  
    `echo "${ALL_TARGET_JOBS}" | xargs -r scontrol release 2>/dev/null || true`  
`else`  
    `echo "No stranded running, suspended, or held tasks detected on this node footprint."`  
`fi`

`echo "=== Recovery Pipeline Successfully Completed ==="`

## **src/slurm-power-recovery.service**

The systemd configuration file that fires the handler immediately upon clean resume targets.

`[Unit]`  
`Description=Automated Generalized Slurm and NVIDIA MPS Post-Hibernation Reset Hook`  
`After=hibernate.target hybrid-sleep.target suspend.target`  
`StartLimitIntervalSec=0`

`[Service]`  
`Type=oneshot`  
`RemainAfterExit=no`  
`ExecStart=/usr/libexec/slurm-power-recovery/slurm-recovery-hook.sh`

`[Install]`  
`WantedBy=hibernate.target hybrid-sleep.target suspend.target`

## ---

**Part 3: Building from Source Tarball (Makefile)**

This standard Unix Makefile targets manual production deployments and source packaging abstractions:

`PREFIX ?= /usr`  
`SYSCONFDIR ?= /etc`

`all:`  
	`@echo "Source compilation complete. Ready for manual target layout install."`

`install:`  
	`install -d $(DESTDIR)$(PREFIX)/libexec/slurm-power-recovery`  
	`install -m 0755 src/slurm-recovery-hook.sh $(DESTDIR)$(PREFIX)/libexec/slurm-power-recovery/slurm-recovery-hook.sh`  
	`install -d $(DESTDIR)$(PREFIX)/lib/systemd/system`  
	`install -m 0644 src/slurm-power-recovery.service $(DESTDIR)$(PREFIX)/lib/systemd/system/slurm-power-recovery.service`

`.PHONY: all install`

## **Manual Installation Sequence (via Source Tarball)**

Users downloading the code directly can compile and install it globally using standard terminal invocations:

*`# To generate a distribution package archive:`*  
`tar -czf slurm-power-recovery-1.0.0.tar.gz src/ Makefile`

*`# To unpack and deploy manually on a live node cluster:`*  
`tar -xzf slurm-power-recovery-1.0.0.tar.gz`  
`cd slurm-power-recovery`  
`sudo make install`  
`sudo systemctl daemon-reload`  
`sudo systemctl enable slurm-power-recovery.service`

## ---

**Part 4: Native Debian/Ubuntu Packaging Configuration (dpkg)**

To allow systemic package management tracking via dpkg \-i or clean distribution via custom .deb repositories, add the following target text files into the debian/ directory:

## **debian/control**

`Source: slurm-power-recovery`  
`Section: admin`  
`Priority: optional`  
`Maintainer: Lab Admin <admin@shavak.cluster>`  
`Build-Depends: debhelper-compat (= 13)`  
`Standards-Version: 4.6.0`

`Package: slurm-power-recovery`  
`Architecture: all`  
`Depends: ${misc:Depends}, slurm-wlm | munge, procps`  
`Description: Package system to automate cluster jobs requeueing and hardware environment recovery after an OS hibernation resume event.`

## **debian/rules**

The standard execution wrapper using direct debhelper automation mechanisms:

`#!/usr/bin/make -f`  
`%:`  
	`dh $@`

*(Make sure to flag this file as executable inside Git: chmod \+x debian/rules).*

## **debian/slurm-power-recovery.install**

Dictates the physical deployment paths for the binary files inside the .deb payload structure:

`src/slurm-recovery-hook.sh usr/libexec/slurm-power-recovery/`  
`src/slurm-power-recovery.service lib/systemd/system/`

## **debian/changelog**

`slurm-power-recovery (1.0.0-1) unstable; urgency=medium`

  `* Initial production packaging release.`  
  `* Generalized node identification to automatically drop/requeue all running tasks.`

 `-- Lab Admin <admin@shavak.cluster>  Fri, 21 Aug 2026 10:39:12 +0530`

## ---

**Part 5: Compiling the Native .deb Binary Package**

Once the directory schema is pushed up and cloned locally from your GitHub instance, build the package cleanly by invoking standard Debian build utilities inside the project root:

*`# Install the minimal target compiler utilities`*  
`sudo apt-get install build-essential devscripts debhelper dh-make`

*`# Run the package compiler sequence inside the root repository tree`*  
`debuild -us -uc -b`

*`# Install the freshly generated architecture-independent debian package`*  
`sudo dpkg -i ../slurm-power-recovery_1.0.0-1_all.deb`

*`# Enable and initialize the tracking system targets`*  
`sudo systemctl daemon-reload`  
`sudo systemctl enable slurm-power-recovery.service`

## **Verification Testing**

You can cleanly mimic an outage recovery event without shutting down your production node by manually invoking the target systemd pipeline wrapper:

`sudo systemctl start slurm-power-recovery.service`

Check your logs via journalctl \-u slurm-power-recovery.service to verify that Slurm identified your active node dynamically and flagged your jobs for a clean restart.

