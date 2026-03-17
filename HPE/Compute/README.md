# HPE Compute Automation

Automation scripts and playbooks for **HPE ProLiant rack and tower servers** using iLO (Integrated Lights-Out) via PowerShell and Ansible.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| HPE ProLiant Gen9 | iLO 4 — HPEiLOCmdlets PowerShell module |
| HPE ProLiant Gen10 | iLO 5 — HPEiLOCmdlets PowerShell module |
| HPE ProLiant Gen11 | iLO 6 — HPEiLOCmdlets PowerShell module + Redfish REST API |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`PowerShell/`](./PowerShell/) | PowerShell | iLO health checks, firmware inventory, hardware status via `HPEiLOCmdlets` module |
| [`Ansible/`](./Ansible/) | Ansible | iLO automation via Redfish REST API — no Ansible collection required |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module / Collection | `HPEiLOCmdlets` | None — uses Redfish REST API via `uri` module |
| Install | `Install-Module HPEiLOCmdlets -Scope CurrentUser` | — |
| iLO Network Access | HTTPS to iLO port 443 | HTTPS to iLO port 443 |
| iLO Account | iLO Administrator or Read-Only | iLO Administrator or Read-Only |

## iLO Generation Reference

| Server Gen | iLO Version | Module Support | Redfish Support |
|------------|------------|----------------|-----------------|
| Gen9       | iLO 4      | HPEiLOCmdlets  | Limited         |
| Gen10      | iLO 5      | HPEiLOCmdlets  | Full            |
| Gen11      | iLO 6      | HPEiLOCmdlets  | Full            |

## Authentication

```powershell
# PowerShell — store iLO credentials securely
$credential = Get-Credential -Message "Enter iLO credentials"
$credential | Export-Clixml -Path "$env:USERPROFILE\.creds\ilo-creds.xml"

# Connect to iLO
$connection = Connect-HPEiLO -IP "192.168.1.10" -Credential (Import-Clixml "$env:USERPROFILE\.creds\ilo-creds.xml") -DisableCertificateAuthentication
```

## Common Use Cases

- Retrieve server hardware health summary (fans, PSUs, temperatures, drives)
- Inventory firmware versions across a fleet of servers
- Monitor active iLO alerts and IML (Integrated Management Log)
- Bulk iLO health check across multiple servers
- Collect server serial numbers and model information for CMDB

## Related Agent

Use `/hpe-sme` in Claude Code for HPE ProLiant/iLO script generation, hardware troubleshooting, and Redfish API patterns.
