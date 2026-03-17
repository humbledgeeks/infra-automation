# NUCLab — PowerShell

PowerShell scripts for managing the Intel NUC home lab environment using **VMware PowerCLI**. Scripts here handle day-2 operations, health reporting, and lab lifecycle management against the NUCLab vCenter instance.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ (cross-platform) |
| VMware PowerCLI | 12.x | 13.x (latest) |
| OS | Windows 10 | Windows Server 2022 / Ubuntu 22.04 |
| vCenter | 7.0 | 8.0+ |

---

## Installation

### Step 1 — Install PowerShell 7 (if not already installed)

```powershell
# Windows — via winget
winget install Microsoft.PowerShell

# Ubuntu / Debian
sudo apt update && sudo apt install -y wget
wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.6/powershell_7.4.6-1.deb_amd64.deb
sudo dpkg -i powershell_7.4.6-1.deb_amd64.deb

# Verify
pwsh --version
```

### Step 2 — Install VMware PowerCLI

```powershell
# Install from PowerShell Gallery (run from pwsh)
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force

# Verify installation
Get-Module -ListAvailable VMware.PowerCLI
(Get-Module VMware.PowerCLI -ListAvailable).Version
```

### Step 3 — Configure PowerCLI for Lab Use

```powershell
# Disable certificate warnings (lab only — do NOT use in production)
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Opt out of CEIP telemetry (optional)
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false

# Confirm settings
Get-PowerCLIConfiguration
```

---

## Credential Setup

**Never hardcode credentials in scripts.** Use one of these patterns:

```powershell
# Option 1 — Prompt at runtime (recommended for interactive use)
$credential = Get-Credential -Message "Enter NUCLab vCenter credentials"

# Option 2 — Encrypted credential file (per-user, per-machine)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.nuclab-creds.xml"

# Load saved credential
$credential = Import-Clixml -Path "$env:USERPROFILE\.nuclab-creds.xml"
```

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `get-nuclab-status.ps1` | Reports ESXi host CPU/memory utilization, VM power states, and datastore capacity across the NUCLab cluster |

---

## How to Run

### get-nuclab-status.ps1

Connects to NUCLab vCenter and produces a quick health summary of all hosts, VMs, and datastores.

```powershell
# Basic run — uses default vCenter (vcenter.lab.local), prompts for credentials
.\get-nuclab-status.ps1

# Specify a different vCenter
.\get-nuclab-status.ps1 -vCenterServer vcenter-nuclab.home.local

# With pre-loaded credential
$cred = Import-Clixml "$env:USERPROFILE\.nuclab-creds.xml"
.\get-nuclab-status.ps1 -vCenterServer vcenter.lab.local -Credential $cred

# Skip TLS certificate check (lab environment)
.\get-nuclab-status.ps1 -vCenterServer vcenter.lab.local -SkipCertCheck
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-vCenterServer` | No | `vcenter.lab.local` | FQDN or IP of the vCenter Server |
| `-Credential` | No | Prompted | PSCredential for vCenter login |
| `-SkipCertCheck` | No | `$false` | Suppress TLS cert validation (lab only) |

---

## Execution Policy

```powershell
# Allow locally written scripts
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Bypass for a single run
powershell -ExecutionPolicy Bypass -File .\get-nuclab-status.ps1
```

---

## Useful PowerCLI Commands for NUCLab

```powershell
# Connect to vCenter
Connect-VIServer -Server vcenter.lab.local -Credential $cred

# List all VMs and their power states
Get-VM | Select-Object Name, PowerState, NumCpu, MemoryGB | Sort-Object Name

# List all ESXi hosts with resource usage
Get-VMHost | Select-Object Name, ConnectionState, CpuUsageMhz, MemoryUsageGB

# List datastores with capacity
Get-Datastore | Select-Object Name, FreeSpaceGB, CapacityGB | Sort-Object Name

# Disconnect cleanly
Disconnect-VIServer -Confirm:$false
```

---

## Lab Notes

- This is a **lab environment** — nested virtualization is acceptable
- PowerShell scripts complement the Ansible playbooks in `../Ansible/`
- Default vCenter hostname is `vcenter.lab.local` — adjust per your lab DNS
- Certificate warnings are expected in lab; `-SkipCertCheck` is provided for convenience

---

## References

- [VMware PowerCLI on PowerShell Gallery](https://www.powershellgallery.com/packages/VMware.PowerCLI)
- [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)
- [PowerCLI Code Capture](https://developer.vmware.com/docs/powercli/latest/)
