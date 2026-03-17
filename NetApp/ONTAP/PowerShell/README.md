# NetApp ONTAP — PowerShell

PowerShell scripts for managing NetApp ONTAP (AFF / FAS / ASA) using the **NetApp ONTAP PowerShell Toolkit** (`NetApp.ONTAP` module) and the ONTAP REST API via `Invoke-RestMethod`.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ (cross-platform) |
| NetApp PowerShell Toolkit | 9.10 | 9.13+ (latest) |
| ONTAP | 9.8 | 9.13+ |
| OS | Windows 10 | Windows Server 2022 / Ubuntu 22.04 |

---

## Installation

### Step 1 — Install PowerShell 7 (if not already installed)

```powershell
# Windows
winget install Microsoft.PowerShell

# Ubuntu
sudo apt update && sudo apt install -y powershell

# Verify
pwsh --version
```

### Step 2 — Install the NetApp ONTAP PowerShell Toolkit

```powershell
# Install from PowerShell Gallery
Install-Module -Name NetApp.ONTAP -Scope CurrentUser -Force

# Verify installation
Get-Module -ListAvailable NetApp.ONTAP
(Get-Module NetApp.ONTAP -ListAvailable).Version
```

### Step 3 — (Optional) Install the DataONTAP module (legacy environments)

For ONTAP 9.7 and earlier, the legacy toolkit may be needed:

```powershell
# Download from NetApp Support
# https://mysupport.netapp.com/site/tools/tool-eula/ontap-powershell-toolkit
Import-Module DataONTAP
```

---

## Credential Setup

**Never hardcode credentials.** Use one of these patterns:

```powershell
# Option 1 — Prompt at runtime
$credential = Get-Credential -Message "Enter ONTAP cluster credentials"

# Option 2 — Encrypted credential file (per-user, per-machine)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.ontap-creds.xml"

# Load saved credential
$credential = Import-Clixml -Path "$env:USERPROFILE\.ontap-creds.xml"

# Option 3 — REST API token (ONTAP 9.6+)
# Use Connect-NcController or Invoke-RestMethod with basic auth headers
```

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `Install_NetAPP_NFS_Plugin.ps1` | Installs the NetApp NFS Plugin for VMware vSphere on ESXi hosts |

---

## How to Run

### Install_NetAPP_NFS_Plugin.ps1

Installs the NetApp NFS VAAI plugin on VMware ESXi hosts managed by vCenter.

```powershell
# Run and follow prompts
.\Install_NetAPP_NFS_Plugin.ps1

# Review with execution policy bypass if needed
powershell -ExecutionPolicy Bypass -File .\Install_NetAPP_NFS_Plugin.ps1
```

> **Note:** This script may contain hardcoded credentials — run `/script-polish` in Claude Code to standardize before use in production.

---

## Common NetApp ONTAP PowerShell Toolkit Commands

```powershell
# Connect to an ONTAP cluster
Connect-NcController -Name cluster01.lab.local -Credential $credential

# List SVMs
Get-NcVserver

# List volumes
Get-NcVol | Select-Object Name, State, TotalSize, Used

# List aggregates
Get-NcAggr | Select-Object Name, State, SizeAvailable, SizeTotal

# List SnapMirror relationships
Get-NcSnapmirror | Select-Object SourceLocation, DestinationLocation, Status, MirrorState

# Disconnect
Disconnect-NcController
```

## ONTAP REST API (PowerShell)

For ONTAP 9.6+ you can use the REST API directly:

```powershell
# Authenticate and query cluster info
$headers = @{}
$cred64  = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("admin:password"))
$headers["Authorization"] = "Basic $cred64"

$cluster = Invoke-RestMethod -Uri "https://cluster01/api/cluster" -Headers $headers -SkipCertificateCheck
$cluster.name
```

---

## Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## References

- [NetApp ONTAP PowerShell Toolkit on PowerShell Gallery](https://www.powershellgallery.com/packages/NetApp.ONTAP)
- [NetApp ONTAP REST API Documentation](https://docs.netapp.com/us-en/ontap-automation/)
- [NetApp PowerShell Toolkit User Guide](https://library.netapp.com/ecmdocs/ECMP1148981/html/index.html)
