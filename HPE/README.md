# HPE Automation

Automation scripts and playbooks for **HPE infrastructure** — both Synergy composable infrastructure (OneView) and ProLiant rack/tower servers (iLO) — using PowerShell and Ansible.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| HPE Synergy | Composable infrastructure — frames, compute modules, Virtual Connect, Image Streamer — managed via OneView |
| HPE ProLiant (Gen9/10/11) | Rack and tower servers — health monitoring and management via iLO 4/5/6 |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`Synergy/PowerShell/`](./Synergy/PowerShell/) | PowerShell | Synergy enclosure health, compute modules, and profile compliance via `HPEOneView.800+` |
| [`Synergy/Ansible/`](./Synergy/Ansible/) | Ansible | Synergy automation using the `hpe.oneview` collection |
| [`Compute/PowerShell/`](./Compute/PowerShell/) | PowerShell | ProLiant iLO health — CPU, memory, storage, fans, PSUs, firmware via `HPEiLOCmdlets` |
| [`Compute/Ansible/`](./Compute/Ansible/) | Ansible | ProLiant iLO health via Redfish REST API (`uri` module — no collection required) |

## Prerequisites by Platform

| Platform | PowerShell Module | Ansible Collection | Notes |
|----------|------------------|-------------------|-------|
| HPE Synergy / OneView | `HPEOneView.800+` | `hpe.oneview` | Module version must match OV firmware |
| HPE ProLiant / iLO | `HPEiLOCmdlets` | None — Redfish REST | Supports iLO 4 (Gen9), iLO 5 (Gen10), iLO 6 (Gen11) |

## Authentication

Both platforms use encrypted credential storage — credentials are never hardcoded:

```powershell
# Synergy / OneView
$cred = Import-Clixml "$env:USERPROFILE\.creds\oneview-creds.xml"
Connect-OVMgmt -Hostname "oneview.lab.local" -Credential $cred

# ProLiant / iLO
$cred = Import-Clixml "$env:USERPROFILE\.creds\ilo-creds.xml"
Connect-HPEiLO -IP "192.168.1.10" -Credential $cred -DisableCertificateAuthentication
```

## Common Use Cases

- Retrieve Synergy enclosure and compute module health status
- Audit Server Profile compliance against Server Profile Templates
- Report iLO hardware health across ProLiant fleet (fans, PSUs, temperatures, drives)
- Inventory firmware versions across all HPE servers
- Monitor OneView and iLO alerts

## Related Agent

Use `/hpe-sme` in Claude Code for HPE Synergy/OneView and ProLiant/iLO script generation, composable infrastructure design, and hardware troubleshooting.
