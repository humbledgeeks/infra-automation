# HPE Compute (ProLiant) — PowerShell Scripts

Automation scripts for **HPE ProLiant rack and tower servers** (DL380, DL360, DL560, ML350, etc.) using the **HPEiLOCmdlets** PowerShell module. These scripts connect directly to the **iLO (Integrated Lights-Out)** management interface to report server health, hardware inventory, and firmware versions.

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| PowerShell | 5.1 or 7.x | Windows, Linux, or macOS |
| HPEiLOCmdlets module | Latest | Supports iLO 4, iLO 5, and iLO 6 |
| iLO access | iLO 5 (Gen10) / iLO 6 (Gen11) | Must be reachable over HTTPS (port 443) |
| iLO account | Local or LDAP/AD account | `Administrator` role required for full inventory |

---

## Install HPEiLOCmdlets Module

```powershell
# Install from PowerShell Gallery
Install-Module HPEiLOCmdlets -Scope CurrentUser

# Verify install
Get-Module -ListAvailable -Name HPEiLOCmdlets

# Check available commands
Get-Command -Module HPEiLOCmdlets
```

> **Note:** HPEiLOCmdlets supports iLO 4 (Gen9), iLO 5 (Gen10/Gen10 Plus), and iLO 6 (Gen11). Some cmdlets are iLO 5/6 only — a warning will be shown if a command is unavailable on iLO 4.

---

## Credential Setup

### Interactive (Prompted at Run Time)
Omit the `-Credential` parameter — the script will call `Get-Credential` automatically.

### Pre-stored Credentials (Recommended for Scheduled Use)
```powershell
# Save iLO credentials to an encrypted file (per-user, per-machine)
$cred = Get-Credential
$cred | Export-Clixml -Path "$env:USERPROFILE\.ilo_cred.xml"

# Load at run time
$cred = Import-Clixml -Path "$env:USERPROFILE\.ilo_cred.xml"
.\get-ilo-server-health.ps1 -iLOAddress 10.10.1.20 -Credential $cred
```

> **Security:** `Export-Clixml` uses Windows DPAPI to encrypt the credential. The file is only decryptable by the same Windows user account on the same machine.

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `get-ilo-server-health.ps1` | Read-only health report: system overview, CPUs, memory, storage, fans, power supplies, and firmware inventory |

---

## How to Run

### `get-ilo-server-health.ps1`

**Parameters:**

| Parameter | Required | Description |
|---|---|---|
| `-iLOAddress` | Yes | IP address or FQDN of the iLO interface |
| `-Credential` | No | PSCredential — prompted if not supplied |
| `-SkipCertCheck` | No | Suppress TLS validation (lab environments only) |

**Examples:**

```powershell
# Basic — prompts for credentials
.\get-ilo-server-health.ps1 -iLOAddress 10.10.1.20

# With FQDN
.\get-ilo-server-health.ps1 -iLOAddress ilo-dl380-01.lab.local

# With pre-stored credentials
$cred = Import-Clixml "$env:USERPROFILE\.ilo_cred.xml"
.\get-ilo-server-health.ps1 -iLOAddress 10.10.1.20 -Credential $cred

# Lab environment — skip certificate validation
.\get-ilo-server-health.ps1 -iLOAddress 10.10.1.20 -SkipCertCheck

# Production — always use FQDN with valid iLO TLS cert
.\get-ilo-server-health.ps1 -iLOAddress ilo-dl380-01.corp.example.com -Credential $cred
```

**Sample Output:**
```
[OK]   HPEiLOCmdlets loaded

[INFO] Connecting to iLO: 10.10.1.20
[OK]   Connected to 10.10.1.20

========================================
 System Health Overview
========================================
  Model         : ProLiant DL380 Gen10
  Serial Number : MXQ12345AB
  System ROM    : U30 v2.72 (12/09/2022)
  Health Status : OK

[PROCESSORS]
  Processor 1          Cores: 20   Status: OK
  Processor 2          Cores: 20   Status: OK

[MEMORY]
  Total Memory  : 256 GB
  All DIMMs healthy

[STORAGE]
  Controller: HPE Smart Array P408i-a SR Gen10        Status: OK

[POWER SUPPLIES]
  PSU 1: Good, In Use
  PSU 2: Good, In Use

[FANS]
  All fans OK

[FIRMWARE]
  iLO 5                                    2.87 Feb 14 2024
  System ROM                               U30 v2.72 12/09/2022
  Smart Array P408i-a SR Gen10             7.00

[INFO] iLO health report complete for 10.10.1.20
[INFO] Disconnected from 10.10.1.20
```

---

## iLO Generation Reference

| Server Generation | iLO Version | Notes |
|---|---|---|
| Gen9 | iLO 4 | Legacy; some cmdlets not available |
| Gen10 / Gen10 Plus | iLO 5 | Full cmdlet support |
| Gen11 | iLO 6 | Full cmdlet support |

---

## PowerShell Help

All scripts include full comment-based help accessible via:

```powershell
Get-Help .\get-ilo-server-health.ps1
Get-Help .\get-ilo-server-health.ps1 -Full
Get-Help .\get-ilo-server-health.ps1 -Examples
```

---

## References

- [HPEiLOCmdlets on PowerShell Gallery](https://www.powershellgallery.com/packages/HPEiLOCmdlets)
- [HPE iLO Scripting and Command Line Guide](https://support.hpe.com/hpesc/public/docDisplay?docId=a00105132en_us)
- [HPE Redfish API Reference](https://developer.hpe.com/platform/ilo-restful-api/home/)
- [HPE ProLiant Gen10 iLO 5 User Guide](https://support.hpe.com/hpesc/public/docDisplay?docId=a00018324en_us)
