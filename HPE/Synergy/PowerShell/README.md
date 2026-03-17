# HPE Synergy — PowerShell Scripts

Automation scripts for **HPE Synergy composable infrastructure** using the **HPEOneView** PowerShell module. These scripts connect to HPE OneView (or Synergy Composer) to report enclosure health, compute module status, server profile compliance, and active alerts.

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| PowerShell | 5.1 or 7.x | Windows recommended; PS 7 works on Linux/macOS |
| HPEOneView module | Match your appliance | `HPEOneView.800`, `HPEOneView.900`, etc. |
| HPE OneView / Synergy Composer | 8.x or 9.x | Must be reachable over HTTPS |
| Network access | HTTPS (443) | From workstation to OneView appliance |

---

## Install HPEOneView Module

HPE releases a separate module version for each OneView appliance major release. Install the version that matches your appliance.

```powershell
# Find available versions on the PowerShell Gallery
Find-Module -Name 'HPEOneView.*'

# Install for OneView 8.x
Install-Module HPEOneView.800 -Scope CurrentUser

# Install for OneView 9.x
Install-Module HPEOneView.900 -Scope CurrentUser

# Verify install
Get-Module -ListAvailable -Name 'HPEOneView.*'
```

> **Tip:** If you have multiple versions installed, the scripts auto-detect and load the newest available version.

---

## Credential Setup

### Interactive (Prompted at Run Time)
Omit the `-Credential` parameter — the script will call `Get-Credential` automatically.

### Pre-stored Credentials (Recommended for Scheduled Use)
```powershell
# Save credentials to an encrypted file (per-user, per-machine)
$cred = Get-Credential
$cred | Export-Clixml -Path "$env:USERPROFILE\.oneview_cred.xml"

# Load at run time
$cred = Import-Clixml -Path "$env:USERPROFILE\.oneview_cred.xml"
.\get-synergy-enclosure-health.ps1 -OneViewFQDN oneview.lab.local -Credential $cred
```

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `get-synergy-enclosure-health.ps1` | Read-only health report: enclosure status, compute module inventory, profile compliance, and active alerts |

---

## How to Run

### `get-synergy-enclosure-health.ps1`

**Parameters:**

| Parameter | Required | Description |
|---|---|---|
| `-OneViewFQDN` | Yes | FQDN or IP of the HPE OneView / Synergy Composer appliance |
| `-Credential` | No | PSCredential — prompted if not supplied |
| `-SkipCertCheck` | No | Suppress TLS validation (lab environments only) |

**Examples:**

```powershell
# Basic — prompts for credentials
.\get-synergy-enclosure-health.ps1 -OneViewFQDN oneview.lab.local

# With pre-stored credentials
$cred = Import-Clixml "$env:USERPROFILE\.oneview_cred.xml"
.\get-synergy-enclosure-health.ps1 -OneViewFQDN oneview.lab.local -Credential $cred

# Lab environment — skip certificate validation
.\get-synergy-enclosure-health.ps1 -OneViewFQDN 10.10.1.50 -SkipCertCheck

# Production — use FQDN with valid cert
.\get-synergy-enclosure-health.ps1 -OneViewFQDN oneview.corp.example.com -Credential $cred
```

**Sample Output:**
```
[OK]   Loaded module: HPEOneView.800 v8.9.0.0

[INFO] Connecting to HPE OneView: oneview.lab.local
[OK]   Connected to oneview.lab.local

========================================
 Enclosure Health
========================================
  Synergy-Frame-1                          Status: OK         State: Monitored

========================================
 Server Hardware (Compute Modules)
========================================

  Total: 12  |  Powered On: 10  |  Off/Standby: 2

  Frame1, Bay1                              Power: On       Health: OK         Profile: Assigned
  Frame1, Bay2                              Power: On       Health: OK         Profile: Assigned

========================================
 Server Profile Compliance
========================================

  Total Profiles: 12  |  Compliant: 12  |  Non-Compliant / No Template: 0

========================================
 Active Alerts
========================================
  No active Warning or Critical alerts

[INFO] Synergy health report complete
[INFO] Disconnected from oneview.lab.local
```

---

## PowerShell Help

All scripts include full comment-based help accessible via:

```powershell
Get-Help .\get-synergy-enclosure-health.ps1
Get-Help .\get-synergy-enclosure-health.ps1 -Full
Get-Help .\get-synergy-enclosure-health.ps1 -Examples
```

---

## References

- [HPEOneView PowerShell Library on GitHub](https://github.com/HewlettPackard/POSH-HPEOneView)
- [HPEOneView on PowerShell Gallery](https://www.powershellgallery.com/packages?q=HPEOneView)
- [HPE OneView REST API Reference](https://techlibrary.hpe.com/docs/enterprise/servers/oneview6.0/cicf-api/en/index.html)
- [HPE Synergy Product Page](https://www.hpe.com/us/en/integrated-systems/synergy.html)
