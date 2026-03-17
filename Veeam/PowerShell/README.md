# Veeam — PowerShell

PowerShell automation scripts for Veeam Backup & Replication using the **Veeam PowerShell Toolkit**. The toolkit ships as a PSSnapin (`VeeamPSSnapin`) and is installed automatically with Veeam B&R v12+. No separate download is required if you have the VBR console installed.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ |
| Veeam B&R | 11 | 12 (latest) |
| OS | Windows Server 2019 | Windows Server 2022 |
| .NET | 4.7.2 | .NET 8 |

> **Important:** The Veeam PowerShell Toolkit requires Windows — it is **not** cross-platform. Scripts must run on a Windows machine with the Veeam B&R console or server installed.

---

## Installation

### Step 1 — Install Veeam Backup & Replication (or console only)

The PowerShell Toolkit is bundled with the Veeam B&R installation. Install either:
- Full VBR server (provides all toolkit cmdlets), or
- Veeam B&R Console (remote management, lighter install)

Download from: https://www.veeam.com/downloads.html

### Step 2 — Verify the PSSnapin is available

```powershell
# Check if the snapin is available
Get-PSSnapin -Registered | Where-Object { $_.Name -like "*Veeam*" }

# Load the snapin manually (VBR 11 and earlier)
Add-PSSnapin VeeamPSSnapin

# VBR 12+ — snapin loads automatically when you use Veeam cmdlets
# Or load explicitly
Add-PSSnapin VeeamPSSnapin -ErrorAction SilentlyContinue

# Verify cmdlets are available
Get-Command -Module VeeamPSSnapin | Select-Object -First 20
```

### Step 3 — Install PowerShell 7 (recommended)

```powershell
# Via winget
winget install Microsoft.PowerShell

# Verify
pwsh --version
```

---

## Credential Setup

**Never hardcode credentials.** Use one of these patterns:

```powershell
# Option 1 — Prompt at runtime (recommended for interactive use)
$credential = Get-Credential -Message "Enter VBR server credentials"

# Option 2 — Encrypted credential file (per-user, per-machine)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.vbr-creds.xml"

# Load saved credential
$credential = Import-Clixml -Path "$env:USERPROFILE\.vbr-creds.xml"
```

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `get-vbr-job-status.ps1` | Connects to VBR server; reports last 24h job results (success/warning/failed counts) and repository capacity with color-coded utilization |

---

## How to Run

### get-vbr-job-status.ps1

Connects to a Veeam B&R server and produces a job status and repository capacity report.

```powershell
# Run on the local VBR server (no credentials needed)
.\get-vbr-job-status.ps1

# Connect to a remote VBR server
.\get-vbr-job-status.ps1 -VBRServer vbr01.lab.local

# Extend history window to 48 hours
.\get-vbr-job-status.ps1 -VBRServer vbr01.lab.local -HoursBack 48

# With pre-loaded credential (remote only)
$cred = Import-Clixml "$env:USERPROFILE\.vbr-creds.xml"
.\get-vbr-job-status.ps1 -VBRServer vbr01.lab.local -Credential $cred
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-VBRServer` | No | `localhost` | FQDN or IP of the VBR server |
| `-HoursBack` | No | `24` | Hours of job history to report |
| `-Credential` | No | Current user | PSCredential for remote VBR connection |

---

## Key Veeam PowerShell Cmdlets

```powershell
# Connect / Disconnect
Connect-VBRServer -Server vbr01.lab.local -Credential $cred
Disconnect-VBRServer

# Jobs
Get-VBRJob
Get-VBRJob -Name "Backup-Prod-VMs"
Start-VBRJob -Job (Get-VBRJob -Name "Backup-Prod-VMs")
Stop-VBRJob  -Job (Get-VBRJob -Name "Backup-Prod-VMs")

# Sessions and results
Get-VBRBackupSession | Sort-Object CreationTime -Descending | Select-Object -First 20
Get-VBRBackupSession | Where-Object { $_.Result -in "Failed","Warning" }

# Repositories
Get-VBRBackupRepository
Get-VBRScaleOutBackupRepository   # SOBR (Scale-Out Backup Repository)

# Restore points
Get-VBRRestorePoint -Name "VMName" | Sort-Object CreationTime -Descending | Select-Object -First 5

# Tape
Get-VBRTapeJob
Get-VBRTapeLibrary

# SureBackup verification
Get-VBRSureBackupJob
Start-VBRSureBackupJob -Job (Get-VBRSureBackupJob -Name "SureBackup-Weekly")
```

---

## Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## References

- [Veeam PowerShell Reference Guide](https://helpcenter.veeam.com/docs/backup/powershell/overview.html)
- [Veeam B&R Downloads](https://www.veeam.com/downloads.html)
- [Veeam Community Forum — PowerShell](https://forums.veeam.com/powershell-f26/)
