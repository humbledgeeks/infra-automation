# Cisco UCS — PowerShell

PowerShell automation scripts for Cisco UCS using the **Cisco UCS PowerTool** (`Cisco.UCSManager`) for Classic UCS/UCSM environments and the **Intersight PowerShell** module for UCS X-Series / IMM environments.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ (cross-platform) |
| OS | Windows 10/Server 2016 | Windows Server 2022 / Linux |
| .NET | 4.7.2 | .NET 8 |

---

## Installation

### Step 1 — Install PowerShell 7 (if not already installed)

```powershell
# Windows — via winget
winget install Microsoft.PowerShell

# Or via MSI download
# https://github.com/PowerShell/PowerShell/releases
```

### Step 2 — Install Cisco UCS PowerTool (Classic UCSM)

```powershell
# Install from PowerShell Gallery
Install-Module -Name Cisco.UCSManager -Scope CurrentUser -Force

# Verify installation
Get-Module -ListAvailable Cisco.UCSManager
```

### Step 3 — Install Intersight PowerShell Module (X-Series / IMM)

```powershell
# Install from PowerShell Gallery
Install-Module -Name Intersight.PowerShell -Scope CurrentUser -Force

# Verify installation
Get-Module -ListAvailable Intersight.PowerShell
```

### Step 4 — (Optional) Install Cisco UCS Central PowerTool

```powershell
Install-Module -Name Cisco.UCSCentral -Scope CurrentUser -Force
```

---

## Credential Setup

**Never hardcode credentials.** Use PowerShell secure credential prompts or store in a vault.

```powershell
# Prompt for credentials at runtime (recommended for interactive use)
$credential = Get-Credential -Message "Enter UCS Manager credentials"

# Or store encrypted credential to disk (per-user, per-machine)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.ucs-creds.xml"

# Load saved credential
$credential = Import-Clixml -Path "$env:USERPROFILE\.ucs-creds.xml"
```

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `get-ucs-inventory.ps1` | Lists all blade servers with service profile associations and active faults |

---

## How to Run

### get-ucs-inventory.ps1

Gathers a full blade inventory from a UCSM domain including service profile associations and any active faults.

```powershell
# Interactive — prompts for credentials
.\get-ucs-inventory.ps1 -UCSManager ucs-fi-a.lab.local

# With saved credential object
$cred = Import-Clixml "$env:USERPROFILE\.ucs-creds.xml"
.\get-ucs-inventory.ps1 -UCSManager ucs-fi-a.lab.local -Credential $cred

# Pipe output to a CSV report
.\get-ucs-inventory.ps1 -UCSManager ucs-fi-a.lab.local | Export-Csv -Path ucs-inventory.csv -NoTypeInformation
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-UCSManager` | Yes | — | FQDN or IP of the Fabric Interconnect |
| `-Credential` | No | Prompted | PSCredential for UCSM login |

---

## Execution Policy

If you receive an execution policy error, run the following once per machine:

```powershell
# Allow locally written scripts (recommended)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Alternatively, bypass for a single run
powershell -ExecutionPolicy Bypass -File .\get-ucs-inventory.ps1 -UCSManager <host>
```

---

## Useful Module Commands

```powershell
# Connect to UCSM
Connect-Ucs -Name ucs-fi-a.lab.local -Credential $cred

# List all blades
Get-UcsBlade

# List service profiles
Get-UcsServiceProfile

# List active faults
Get-UcsFault | Where-Object { $_.Severity -ne 'cleared' }

# Disconnect
Disconnect-Ucs
```

---

## References

- [Cisco UCS PowerTool on PowerShell Gallery](https://www.powershellgallery.com/packages/Cisco.UCSManager)
- [Intersight PowerShell on PowerShell Gallery](https://www.powershellgallery.com/packages/Intersight.PowerShell)
- [Cisco UCS PowerTool User Guide](https://developer.cisco.com/docs/ucs-dev-center/)
