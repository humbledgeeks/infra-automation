# Veeam Automation

Automation scripts and playbooks for **Veeam Backup & Replication (VBR)** using PowerShell and the Veeam REST API.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| Veeam B&R 12.x | Backup jobs, SOBR, repository management, session history, recovery |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`PowerShell/`](./PowerShell/) | PowerShell | VBR job status, session history, and repository capacity via VeeamPSSnapin |
| [`Ansible/`](./Ansible/) | Ansible | VBR job status and session reporting via Veeam REST API (OAuth2 / uri module) |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module | `VeeamPSSnapin` (Windows only — installed with VBR) | None — uses REST API via `uri` module |
| VBR Version | 12.x | 12.x |
| OS | Windows Server (VBR server or remote management) | Any (targets VBR REST API) |
| Access | VBR Administrator or Restore Operator | VBR REST API credentials |

## Authentication

```powershell
# PowerShell — VeeamPSSnapin is installed with VBR
# Run on the VBR server or a machine with the remote console installed
Add-PSSnapin VeeamPSSnapin
Connect-VBRServer -Server vbr.lab.local -Credential (Import-Clixml "$env:USERPROFILE\.creds\vbr-creds.xml")

# Disconnect when done
Disconnect-VBRServer
```

```yaml
# Ansible — OAuth2 token via Veeam REST API
# Vault variables: vault_vbr_host, vault_vbr_username, vault_vbr_password
- name: Get VBR API token
  uri:
    url: "https://{{ vault_vbr_host }}:9419/api/oauth2/token"
    method: POST
    body_format: form-urlencoded
    body:
      grant_type: password
      username: "{{ vault_vbr_username }}"
      password: "{{ vault_vbr_password }}"
    validate_certs: false
    no_log: true
```

## Common Use Cases

- Report all backup job status and last session results
- Identify failed or warning-state jobs for immediate attention
- Monitor repository capacity and scale-out backup repository (SOBR) tiers
- Generate weekly/monthly backup success rate reports
- Audit backup job schedules and retention policies
- Check restore point counts and last successful backup per VM

## 3-2-1-1-0 Rule

All Veeam configurations in this repo follow the **3-2-1-1-0 backup strategy**:
- **3** copies of data
- **2** different media types
- **1** copy offsite
- **1** copy air-gapped or immutable
- **0** errors on recovery verification (SureBackup / SureReplica)

## Related Agent

Use `/veeam-sme` in Claude Code for Veeam script generation, backup job design, SOBR architecture, and recovery workflow automation.
