# VMware ESXi — PowerShell

PowerShell and PowerCLI automation scripts for ESXi host configuration, security hardening, NFS best practices, and storage setup. All scripts use **VMware PowerCLI** to connect through vCenter or directly to ESXi hosts.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ (cross-platform) |
| VMware PowerCLI | 12.x | 13.x (latest) |
| vCenter / ESXi | 7.0 | 8.0+ |
| OS | Windows 10 | Windows Server 2022 / Ubuntu 22.04 |

---

## Installation

### Step 1 — Install PowerShell 7

```powershell
# Windows
winget install Microsoft.PowerShell

# Ubuntu
sudo apt update && sudo apt install -y powershell

# Verify
pwsh --version
```

### Step 2 — Install VMware PowerCLI

```powershell
# Install from PowerShell Gallery
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force

# Verify installation
Get-Module -ListAvailable VMware.PowerCLI
(Get-Module VMware.PowerCLI -ListAvailable).Version
```

### Step 3 — Configure PowerCLI for Lab Use

```powershell
# Disable certificate warnings (lab only)
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Opt out of CEIP telemetry (optional)
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false

# Confirm settings
Get-PowerCLIConfiguration
```

---

## Credential Setup

**Never hardcode credentials in scripts.**

```powershell
# Option 1 — Prompt at runtime
$credential = Get-Credential -Message "Enter vCenter / ESXi credentials"

# Option 2 — Encrypted credential file (per-user, per-machine)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.esxi-creds.xml"

# Load saved credential
$credential = Import-Clixml -Path "$env:USERPROFILE\.esxi-creds.xml"
```

---

## Scripts in This Folder

### Hardening/

| Script | Description |
|---|---|
| `ESXi_Hardening_V4.ps1` | Menu-driven hardening with dry-run mode, CSV/vCenter/standalone input, HTML report output |
| `ESXi_Hardening_V6h.ps1` | **Recommended** — Improved UI, KPI dashboard, per-setting overrides, set+verify+fallback reliability |
| `ESXi_Hardening_Verbose.ps1` | Verbose version with detailed output per setting applied |

### Host-Config/

| Script | Description |
|---|---|
| `Configure_ESX_Hosts.ps1` | Single-host: NTP, DNS, hardening, NFS best practices, vSwitch/port group, NFS datastore attach |
| `Configure_ESX_Hosts_v2.ps1` | Updated version of the above |
| `configure_hosts.ps1` | CSV-driven multi-host configuration (NFS datastore commented out) |
| `configure_hosts_addon.ps1` | CSV-driven multi-host with NFS datastore attachment and scratch location active |
| `ESXConfiguration.ps1` | HPE cluster configuration with vDS migration (legacy) |
| `EnableSSH.ps1` | Enable SSH service on ESXi hosts |
| `backup_esxihost_config_v2.ps1` | Backup ESXi host configuration to file |

### NFS/

| Script | Description |
|---|---|
| `ESXI_NFS_BestPractices.ps1` | Apply NetApp NFS best practice advanced settings |
| `ESXI_NFS_BestPracticesV4.ps1` | Updated version with heap, queue depth, heartbeat settings |
| `NetAppVIB_Installation.ps1` | Install the NetApp NAS VAAI plugin VIB on ESXi hosts |

---

## How to Run

### ESXi_Hardening_V6h.ps1 (recommended hardening script)

```powershell
# Connect to vCenter first
$cred = Get-Credential
Connect-VIServer -Server vcenter.lab.local -Credential $cred

# Run against all hosts in vCenter
.\Hardening\ESXi_Hardening_V6h.ps1

# Run against a single host
.\Hardening\ESXi_Hardening_V6h.ps1 -TargetHost esxi01.lab.local
```

### configure_hosts.ps1 (multi-host CSV-driven)

```powershell
# Prepare your CSV input file (see data/ folder for examples)
# Then run:
.\Host-Config\configure_hosts.ps1 -CsvPath .\Host-Config\data\configure_hosts.csv

# Dry run first to review planned changes
.\Host-Config\configure_hosts.ps1 -CsvPath .\Host-Config\data\configure_hosts.csv -WhatIf
```

### ESXI_NFS_BestPracticesV4.ps1

```powershell
# Apply NFS best practices to all hosts under a vCenter cluster
.\NFS\ESXI_NFS_BestPracticesV4.ps1 -vCenterServer vcenter.lab.local -ClusterName "Lab-Cluster"
```

### NetAppVIB_Installation.ps1

```powershell
# Install VAAI plugin — place the .vib file on an NFS datastore first
.\NFS\NetAppVIB_Installation.ps1 -vCenterServer vcenter.lab.local -VibPath "[datastore] NetAppNasPlugin.vib"
```

> **Note:** `Configure_ESX_Hosts.ps1` may contain hardcoded credentials — run `/script-polish` in Claude Code to standardize before production use.

---

## Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## References

- [VMware PowerCLI on PowerShell Gallery](https://www.powershellgallery.com/packages/VMware.PowerCLI)
- [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)
- [VMware Security Configuration Guide (ESXi)](https://core.vmware.com/security-configuration-guide)
