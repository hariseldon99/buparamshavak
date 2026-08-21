# Slurm Power Recovery

Automated Generalized Slurm, CPU Frequency Scaling, and NVIDIA MPS Post-Hibernation Recovery Framework.

## Overview

This project provides a robust, generalized recovery mechanism for Linux-based Slurm compute nodes following an OS suspend, hibernate, or hybrid-sleep resume event.

Key features:
- **CPU Scaling & ACPI PPC Override**: Overrides firmware-dictated ACPI PPC throttling caps (`ignore_ppc=1`), resets scaling frequency ceilings (`scaling_max_freq`) across all logical cores to hardware limits, and enforces the `performance` scaling governor.
- **Dynamic Node Resolution**: Scans the local host name dynamically (`hostname`).
- **Framework-Agnostic Requeuing**: Safely issues clean requeues (`scontrol requeue`) to **all** active running Slurm tasks on the node, regardless of their binary framework (e.g., GROMACS, Amber, PyTorch, Quantum ESPRESSO).
- **Process Cleanup**: Completely flushes unkillable or hanging `slurmstepd` daemons from the local Linux process tree.
- **Daemon State Cycle**: Cycles `slurmd` (and `OpenSM` if present) to drop corrupted state tracking maps.
- **NVIDIA MPS Reset**: Automatically detects and resets the NVIDIA Multi-Process Service (MPS) control daemon if present.

---

## Directory Structure

```text
slurm-power-recovery/
├── LICENSE
├── README.md
├── Makefile
├── debian/
│   ├── control
│   ├── rules
│   ├── changelog
│   ├── compat
│   └── slurm-power-recovery.install
└── src/
    ├── slurm-recovery-hook.sh
    ├── slurm-power-recovery.service.in
    └── slurm-power-recovery.service
```

---

## Installation Methods

### Method 1: Manual Installation from Source (`PREFIX=/usr/local` by default)

By default, the `Makefile` installs to `/usr/local` (with systemd unit configured in `/etc/systemd/system`):

```bash
# Default installation to /usr/local/libexec and /etc/systemd/system
sudo make install

# Or explicitly customize the target prefix (e.g., /usr):
# sudo make install PREFIX=/usr

# Reload systemd and enable the recovery service hook
sudo systemctl daemon-reload
sudo systemctl enable slurm-power-recovery.service
```

#### Uninstalling

```bash
sudo make uninstall
# or: sudo make uninstall PREFIX=/usr
```

#### Generating a Source Tarball

To package a standalone source distribution tarball:

```bash
tar -czf slurm-power-recovery-1.0.0.tar.gz src/ Makefile
```

To unpack and deploy from tarball on a node:

```bash
tar -xzf slurm-power-recovery-1.0.0.tar.gz
cd slurm-power-recovery
sudo make install
sudo systemctl daemon-reload
sudo systemctl enable slurm-power-recovery.service
```

---

### Method 2: Native Debian/Ubuntu Package (`PREFIX=/usr` standard root)

Debian packaging builds with `PREFIX=/usr` per Debian policy and installs binaries to `/usr/libexec` and systemd units to `/lib/systemd/system`:

```bash
# Install required build tools (if not already installed)
sudo apt-get install build-essential devscripts debhelper dh-make

# Build binary package without signing
debuild -us -uc -b

# Install the generated .deb package
sudo dpkg -i ../slurm-power-recovery_1.0.0-1_all.deb

# Reload systemd and enable the service
sudo systemctl daemon-reload
sudo systemctl enable slurm-power-recovery.service
```

---

## Verification Testing

You can test the recovery pipeline without performing a physical system reboot or suspend/hibernate cycle by manually triggering the systemd unit:

```bash
sudo systemctl start slurm-power-recovery.service
```

Check the unit execution logs to verify that CPU scaling was restored and Slurm identified your active node dynamically:

```bash
journalctl -u slurm-power-recovery.service -e
```
