# VMware vSAN — PowerShell

PowerShell scripts for vSAN cluster health monitoring, disk group reporting, and capacity analysis using **VMware PowerCLI**. The vSAN cmdlets are bundled with PowerCLI — no separate module is required.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ (cross-platform) |
| VMware PowerCLI | 12.x | 13.x (latest) |
| vCenter / ESXi | 7.0 | 8.0+ (vSAN required on cluster) |
| OS | Windows 10 | Windows Server 2022 / Ubuntu 22.04 |

---

## Installation

### Step 1 — Install PowerShell 7

```powershell
# Windows
winget install Microsoft.PowerShell

# Ubuntu
sudo apt update && sudo apt install -y powershell

# macOS
brew install --cask powershell

# Verify
pwsh --version
```

### Step 2 — Install VMware PowerCLI

```powershell
# Install from PowerShell Gallery
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force

# Verify installation and version
Get-Module -ListAvailable VMware.PowerCLI
(Get-Module VMware.PowerCLI -ListAvailable).Version
```

### Step 3 — Configure PowerCLI for Lab Use

```powershell
# Disable certificate warnings (lab only — do NOT use in production)
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Opt out of CEIP telemetry
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false
```

---

## Credential Setup

**Never hardcode credentials.**

```powershell
# Option 1 — Prompt at runtime
$credential = Get-Credential -Message "Enter vCenter credentials"

# Option 2 — Encrypted credential file (per-user, per-machine)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.vcenter-creds.xml"

# Load saved credential
$credential = Import-Clixml -Path "$env:USERPROFILE\.vcenter-creds.xml"
```

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `get-vsan-health.ps1` | Enumerates vSAN-enabled clusters; reports disk groups, health test results, and datastore capacity with color-coded utilization |

---

## How to Run

### get-vsan-health.ps1

Connects to vCenter and produces a vSAN health summary for all vSAN-enabled clusters.

```powershell
# Basic run — prompts for credentials
.\get-vsan-health.ps1 -vCenterServer vcenter.lab.local

# Skip TLS certificate validation (lab only)
.\get-vsan-health.ps1 -vCenterServer vcenter.lab.local -SkipCertCheck

# With pre-loaded encrypted credential
$cred = Import-Clixml "$env:USERPROFILE\.vcenter-creds.xml"
.\get-vsan-health.ps1 -vCenterServer vcenter.lab.local -Credential $cred -SkipCertCheck
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-vCenterServer` | Yes | — | FQDN or IP of the vCenter Server |
| `-Credential` | No | Prompted | PSCredential for vCenter login |
| `-SkipCertCheck` | No | `$false` | Suppress TLS cert validation (lab only) |

---

## Key PowerCLI vSAN Cmdlets

```powershell
# Connect first
Connect-VIServer -Server vcenter.lab.local -Credential $credential

# List vSAN-enabled clusters
Get-Cluster | Where-Object { $_.VsanEnabled }

# Get disk groups per host
Get-VsanDiskGroup -VMHost (Get-VMHost "esxi01.lab.local")

# Get vSAN health (requires vSAN view API)
$vsanView = Get-VsanView -Id "VsanVcClusterHealthSystem-vsan-cluster-health-system"
$vsanView.VsanQueryVcClusterHealthSummary($cluster.ExtensionData.MoRef, $null, $null, $true, $null, $null, 'defaultView')

# Get vSAN space usage
Get-VsanSpaceUsage -Cluster (Get-Cluster "vSAN-Cluster")

# Get storage policies
Get-SpbmStoragePolicy | Where-Object { $_.AnyOfRuleSets -match "vSAN" }

# Disconnect
Disconnect-VIServer -Confirm:$false
```

---

## Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## References

- [VMware PowerCLI on PowerShell Gallery](https://www.powershellgallery.com/packages/VMware.PowerCLI)
- [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)
- [vSAN PowerCLI Cmdlet Reference](https://developer.vmware.com/docs/powercli/latest/)
- [VMware vSAN Documentation](https://docs.vmware.com/en/VMware-vSAN/index.html)
