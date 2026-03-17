# VMware NSX Automation

Automation scripts and playbooks for **VMware NSX-T** (NSX Data Center) software-defined networking using PowerShell and Ansible.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| VMware NSX-T 3.x / 4.x | Software-defined networking — segments, gateways, distributed firewall, load balancing |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`PowerShell/`](./PowerShell/) | PowerShell | NSX-T automation via the NSX Policy REST API using built-in `Invoke-RestMethod` — no module required |
| [`Ansible/`](./Ansible/) | Ansible | NSX-T automation using the `vmware.ansible_for_nsxt` collection |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module / Collection | None — uses `Invoke-RestMethod` against NSX Policy API | `vmware.ansible_for_nsxt` collection |
| Install | — | `ansible-galaxy collection install vmware.ansible_for_nsxt` |
| NSX-T Version | 3.x+ | 3.x+ |
| Access | NSX Admin or Auditor account | NSX Admin account |
| Network | HTTPS to NSX Manager port 443 | HTTPS to NSX Manager port 443 |

## Key API Base Paths

| API | Base URL | Use |
|-----|----------|-----|
| NSX Policy API | `/policy/api/v1/` | **Recommended** — all new scripts |
| NSX Management API | `/api/v1/` | Legacy — avoid for new work |

## Common Use Cases

- Query and report network segment configurations
- List Tier-0 and Tier-1 gateway topology
- Audit distributed firewall policies and rules
- Monitor cluster and transport node health
- Export NSX topology for documentation
- Validate segment connectivity and routing

## Related Agent

Use `/vmware-sme` in Claude Code for NSX-T script generation, network design patterns, and NSX Policy API queries.
