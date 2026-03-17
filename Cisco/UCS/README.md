# Cisco UCS Automation

Automation scripts and playbooks for **Cisco UCS (Unified Computing System)** using PowerShell and Ansible.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| UCS Manager (UCSM) | Blade server chassis management — Service Profiles, vNICs, vHBAs, pools, policies |
| UCS Central | Multi-domain management across multiple UCS domains |
| Cisco Intersight | Cloud-based management and monitoring for UCS and HyperFlex |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`PowerShell/`](./PowerShell/) | PowerShell | UCS automation using Cisco's `Cisco.UCSManager` PowerTool module |
| [`Ansible/`](./Ansible/) | Ansible | UCS automation using the `cisco.ucs` Ansible collection |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module / Collection | `Cisco.UCSManager` PowerTool | `cisco.ucs` collection |
| Install | `Install-Module Cisco.UCSManager -Scope CurrentUser` | `ansible-galaxy collection install cisco.ucs` |
| Python Library | — | `ucsmsdk` (`pip install ucsmsdk`) |
| UCS Version | UCSM 3.2+ | UCSM 3.2+ |
| Access | UCS admin or read-only account | UCS admin or read-only account |

## Authentication

```powershell
# PowerShell — connect to UCS Manager (never hardcode credentials)
$credential = Import-Clixml "$env:USERPROFILE\.creds\ucs-creds.xml"
Connect-Ucs -Name ucsm.lab.local -Credential $credential

# Disconnect when done
Disconnect-Ucs
```

## Common Use Cases

- Report all Service Profile associations and server assignments
- Audit vNIC and vHBA templates and pool utilisation
- Monitor server health, faults, and firmware versions
- Automate Service Profile creation from templates
- Export UCS configuration for backup and documentation
- Check UCSM cluster high-availability status

## Related Agent

Use `/cisco-sme` in Claude Code for Cisco UCS script generation, Service Profile design, and troubleshooting.
