# NetApp StorageGRID — PowerShell

PowerShell scripts for managing and reporting on NetApp StorageGRID using the **StorageGRID REST API v3** via `Invoke-RestMethod`. StorageGRID does not have a dedicated PowerShell module — all automation uses the REST API directly.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ (cross-platform) |
| StorageGRID | 11.5 | 11.8+ |
| OS | Windows 10 | Windows Server 2022 / Ubuntu 22.04 |
| Network | HTTPS to Admin Node port 443 | — |

> No external PowerShell modules are required. All scripts use the built-in `Invoke-RestMethod` cmdlet.

---

## Installation

### Step 1 — Install PowerShell 7 (recommended for cross-platform use)

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

---

## Credential Setup

**Never hardcode credentials.** Use one of these patterns:

```powershell
# Option 1 — Prompt at runtime (recommended for interactive use)
$credential = Get-Credential -Message "Enter StorageGRID credentials"
$sgUser = $credential.UserName
$sgPass = $credential.GetNetworkCredential().Password

# Option 2 — Encrypted credential file (per-user, per-machine)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.sg-creds.xml"

# Load saved credential later
$credential = Import-Clixml -Path "$env:USERPROFILE\.sg-creds.xml"
$sgPass = $credential.GetNetworkCredential().Password
```

---

## StorageGRID API Authentication Pattern

All scripts in this folder use Bearer token authentication:

```powershell
# Obtain a Bearer token
$body = @{
    username  = $sgUser
    password  = $sgPass
    cookie    = $false
    csrfToken = $false
} | ConvertTo-Json

$authUri = "https://$sgAdminNode/api/v3/authorize"
$token   = (Invoke-RestMethod -Uri $authUri -Method POST -Body $body `
             -ContentType "application/json" -SkipCertificateCheck).data

$headers = @{ "Authorization" = "Bearer $token" }
```

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `get-sg-grid-health.ps1` | Authenticates to StorageGRID REST API; reports node health, active alerts, and tenant count |

---

## How to Run

### get-sg-grid-health.ps1

Queries the StorageGRID REST API to display grid node health, active alert summary, and tenant count.

```powershell
# Basic run — prompts for credentials
.\get-sg-grid-health.ps1 -SGAdminNode storagegrid-admin.lab.local

# Skip TLS certificate validation (lab environments only)
.\get-sg-grid-health.ps1 -SGAdminNode storagegrid-admin.lab.local -SkipCertCheck

# With pre-loaded encrypted credential
$cred = Import-Clixml "$env:USERPROFILE\.sg-creds.xml"
.\get-sg-grid-health.ps1 -SGAdminNode storagegrid-admin.lab.local -Credential $cred -SkipCertCheck
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-SGAdminNode` | Yes | — | FQDN or IP of the StorageGRID Admin Node |
| `-Credential` | No | Prompted | PSCredential for StorageGRID login |
| `-SkipCertCheck` | No | `$false` | Suppress TLS cert validation (lab only) |

---

## Useful StorageGRID REST API Endpoints

```powershell
# After obtaining $headers (as shown in the auth pattern above):

# Grid node health
Invoke-RestMethod "https://$sg/api/v3/grid/node-health" -Headers $headers -SkipCertificateCheck

# Active alerts
Invoke-RestMethod "https://$sg/api/v3/grid/alarms" -Headers $headers -SkipCertificateCheck

# Tenant accounts
Invoke-RestMethod "https://$sg/api/v3/grid/accounts" -Headers $headers -SkipCertificateCheck

# Grid health topology
Invoke-RestMethod "https://$sg/api/v3/grid/health/topology" -Headers $headers -SkipCertificateCheck
```

---

## Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## References

- [StorageGRID REST API Documentation](https://docs.netapp.com/us-en/storagegrid-118/s3/index.html)
- [StorageGRID API Browser](https://your-admin-node/api) — live Swagger UI on your grid
- [StorageGRID Administration Guide](https://docs.netapp.com/us-en/storagegrid-118/admin/index.html)
