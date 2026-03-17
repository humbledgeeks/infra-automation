# HPE Synergy Automation

Automation scripts and playbooks for **HPE Synergy composable infrastructure** managed via HPE OneView using PowerShell and Ansible.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| HPE Synergy | Composable infrastructure — frames, compute modules, Image Streamer, Virtual Connect |
| HPE OneView | Unified management plane for Synergy — profiles, templates, firmware, alerts |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`PowerShell/`](./PowerShell/) | PowerShell | Synergy and OneView management using the `HPEOneView.800+` module |
| [`Ansible/`](./Ansible/) | Ansible | Synergy automation using the `hpe.oneview` Ansible collection |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module / Collection | `HPEOneView.800` (or matching your OV version) | `hpe.oneview` collection |
| Install | `Install-Module HPEOneView.800 -Scope CurrentUser` | `ansible-galaxy collection install hpe.oneview` |
| Python Library | — | `hpeOneView` (`pip install hpeOneView`) |
| OneView Version | 8.x (module version tracks OV firmware) | 8.x |
| Access | OneView Administrator or Infrastructure Viewer | OneView Administrator |

## Module Version Note

The HPEOneView PowerShell module version must match your OneView appliance firmware version:

| OneView Version | PowerShell Module |
|----------------|-------------------|
| 8.x | `HPEOneView.800` |
| 7.x | `HPEOneView.700` |
| 6.x | `HPEOneView.660` |

## Authentication

```powershell
# PowerShell — store OneView credentials securely
$credential = Get-Credential -Message "Enter OneView credentials"
$credential | Export-Clixml -Path "$env:USERPROFILE\.creds\oneview-creds.xml"

# Connect to OneView
$cred = Import-Clixml "$env:USERPROFILE\.creds\oneview-creds.xml"
Connect-OVMgmt -Hostname "oneview.lab.local" -Credential $cred
```

## Common Use Cases

- Retrieve enclosure and compute module health status
- Audit Server Profile compliance against Server Profile Templates
- Report firmware versions across all Synergy compute modules
- Monitor OneView alerts and critical events
- Export Server Profile configurations for documentation
- Validate composable fabric connectivity

## Related Agent

Use `/hpe-sme` in Claude Code for HPE Synergy/OneView script generation, composable infrastructure design, and OneView API patterns.
