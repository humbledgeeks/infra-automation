# NetApp StorageGRID Automation

Automation scripts and playbooks for **NetApp StorageGRID** object storage platform using PowerShell and Ansible.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| StorageGRID 11.x+ | S3-compatible object storage — grid management, tenant management, ILM policies, S3 buckets |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`PowerShell/`](./PowerShell/) | PowerShell | StorageGRID management via the Grid Management REST API using `Invoke-RestMethod` |
| [`Ansible/`](./Ansible/) | Ansible | StorageGRID automation via REST API — grid health, tenant operations, S3 bucket management |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module | None — uses built-in `Invoke-RestMethod` | None — uses `uri` module with REST API |
| PowerShell | 5.1+ / 7+ recommended | — |
| Ansible | — | 2.12+ |
| Access | Grid Admin or Tenant Admin account | Grid Admin or Tenant Admin account |
| Network | HTTPS to Grid Manager (port 443) | HTTPS to Grid Manager (port 443) |

## Authentication

StorageGRID uses token-based authentication:

```powershell
# PowerShell — obtain and store a Grid Management API token
$body = @{ username = "admin"; password = "YourPassword"; cookie = $false; csrfToken = $false } | ConvertTo-Json
$response = Invoke-RestMethod -Uri "https://$gridManager/api/v3/authorize" -Method POST -Body $body -ContentType "application/json" -SkipCertificateCheck
$token = $response.data
$headers = @{ "Authorization" = "Bearer $token" }
```

## Common Use Cases

- Monitor grid node health and alert status
- Manage tenant accounts and S3 buckets
- Review and audit ILM (Information Lifecycle Management) policies
- Report on object storage capacity and utilisation
- Automate S3 bucket creation and policy assignment
- Collect grid topology and site information

## Related Agent

Use `/netapp-sme` in Claude Code for NetApp StorageGRID script generation, troubleshooting, and REST API patterns.
