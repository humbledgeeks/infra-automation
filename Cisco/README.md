# Cisco Automation

Automation scripts and playbooks for **Cisco infrastructure** using PowerShell and Ansible.

## Platforms Covered

| Platform | Tool | Description |
|----------|------|-------------|
| Cisco UCS (UCSM) | PowerShell + Ansible | Blade servers, Service Profiles, vNIC/vHBA templates, pools |
| Cisco UCS Central | PowerShell | Multi-domain UCS management |
| Cisco Intersight | REST API / Ansible | Cloud-based UCS and HyperFlex management |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`UCS/PowerShell/`](./UCS/PowerShell/) | PowerShell | UCS Manager automation using `Cisco.UCSManager` PowerTool |
| [`UCS/Ansible/`](./UCS/Ansible/) | Ansible | UCS automation using the `cisco.ucs` collection |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module / Collection | `Cisco.UCSManager` PowerTool | `cisco.ucs` collection |
| Install | `Install-Module Cisco.UCSManager -Scope CurrentUser` | `ansible-galaxy collection install cisco.ucs` |
| Python Library | — | `ucsmsdk` (`pip install ucsmsdk`) |
| UCSM Version | 3.2+ | 3.2+ |
| Access | UCS admin or read-only | UCS admin |

## Authentication

```powershell
# Connect to UCS Manager — never hardcode credentials
$credential = Import-Clixml "$env:USERPROFILE\.creds\ucs-creds.xml"
Connect-Ucs -Name ucsm.lab.local -Credential $credential

# Always disconnect when done
Disconnect-Ucs
```

## Common Use Cases

- Report all Service Profile associations and server slot assignments
- Audit vNIC and vHBA templates, uplink configuration, and SAN connectivity
- Monitor server faults, firmware versions, and hardware health
- Export UCS domain configuration for documentation and DR planning
- Automate Service Profile creation from templates
- Check UCSM high-availability (primary/subordinate FI status)

## Related Agent

Use `/cisco-sme` in Claude Code for Cisco UCS script generation, Service Profile design, fabric topology, and troubleshooting.
