# VMware NSX — PowerShell

PowerShell scripts for VMware NSX-T automation via the **NSX-T Policy REST API** using `Invoke-RestMethod`. NSX-T does not have a dedicated PowerShell module — all automation uses the NSX Manager REST API directly.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ (cross-platform) |
| NSX-T | 3.x | 4.x (latest) |
| OS | Windows 10 | Windows Server 2022 / Ubuntu 22.04 |
| Network | HTTPS to NSX Manager port 443 | — |

> No external PowerShell modules are required. All scripts use the built-in `Invoke-RestMethod` cmdlet.

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

---

## Credential Setup

**Never hardcode credentials.** Use one of these patterns:

```powershell
# Option 1 — Prompt at runtime
$credential = Get-Credential -Message "Enter NSX Manager credentials"
$nsxUser = $credential.UserName
$nsxPass = $credential.GetNetworkCredential().Password

# Option 2 — Encrypted credential file
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.nsx-creds.xml"

# Load saved credential
$credential = Import-Clixml -Path "$env:USERPROFILE\.nsx-creds.xml"
$nsxPass = $credential.GetNetworkCredential().Password
```

---

## NSX-T API Authentication Pattern

All scripts use Basic auth with the NSX Policy API:

```powershell
# Build Basic auth header
$base64Auth = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes("$nsxUser`:$nsxPass"))

$headers = @{
    "Authorization" = "Basic $base64Auth"
    "Content-Type"  = "application/json"
    "Accept"        = "application/json"
}

# Test connection
Invoke-RestMethod -Uri "https://$nsxManager/api/v1/cluster/status" `
    -Headers $headers -SkipCertificateCheck
```

---

## API Reference

| API | Base Path | Use |
|---|---|---|
| NSX-T Policy API | `/policy/api/v1/` | **Recommended** for new work |
| NSX-T Management API | `/api/v1/` | Legacy — use Policy API instead |
| Swagger UI | `/policy/api/v1/spec/openapi/json` | Live API docs on your NSX Manager |

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `get-nsx-segments.ps1` | Queries NSX-T Policy API for network segments and Tier-1 gateways; `-SkipCertCheck` for lab |

---

## How to Run

### get-nsx-segments.ps1

Retrieves all NSX-T segments and Tier-1 gateway configurations from the Policy API.

```powershell
# Basic run — prompts for credentials
.\get-nsx-segments.ps1 -NSXManager nsx-manager.lab.local

# Skip TLS certificate validation (lab environments only)
.\get-nsx-segments.ps1 -NSXManager nsx-manager.lab.local -SkipCertCheck

# With pre-loaded encrypted credential
$cred = Import-Clixml "$env:USERPROFILE\.nsx-creds.xml"
.\get-nsx-segments.ps1 -NSXManager nsx-manager.lab.local -Credential $cred -SkipCertCheck
```

**Parameters:**

| Parameter | Required | Default | Description |
|---|---|---|---|
| `-NSXManager` | Yes | — | FQDN or IP of the NSX Manager |
| `-Credential` | No | Prompted | PSCredential for NSX Manager login |
| `-SkipCertCheck` | No | `$false` | Suppress TLS cert validation (lab only) |

---

## Useful NSX Policy API Endpoints

```powershell
# After building $headers (as shown above):

# List all segments
Invoke-RestMethod "https://$nsx/policy/api/v1/infra/segments" -Headers $headers -SkipCertificateCheck

# List Tier-1 gateways
Invoke-RestMethod "https://$nsx/policy/api/v1/infra/tier-1s" -Headers $headers -SkipCertificateCheck

# List Tier-0 gateways
Invoke-RestMethod "https://$nsx/policy/api/v1/infra/tier-0s" -Headers $headers -SkipCertificateCheck

# List distributed firewall policies
Invoke-RestMethod "https://$nsx/policy/api/v1/infra/domains/default/security-policies" -Headers $headers -SkipCertificateCheck

# Cluster status
Invoke-RestMethod "https://$nsx/api/v1/cluster/status" -Headers $headers -SkipCertificateCheck
```

---

## Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## References

- [NSX-T Policy API Documentation](https://developer.vmware.com/apis/nsx-t)
- [NSX-T REST API Guide](https://docs.vmware.com/en/VMware-NSX-T-Data-Center/index.html)
- [NSX-T Swagger UI](https://your-nsx-manager/policy/api/v1/spec/openapi/json)
