# NetApp ONTAP Automation

Automation scripts and playbooks for **NetApp ONTAP** storage platform using PowerShell and Ansible.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| ONTAP 9.x / 10.x | Clustered Data ONTAP — NAS (NFS/CIFS), SAN (iSCSI/FC), SnapMirror, SVM management |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`PowerShell/`](./PowerShell/) | PowerShell | ONTAP cluster management using the NetApp PowerShell Toolkit and REST API |
| [`Ansible/`](./Ansible/) | Ansible | ONTAP automation using the `netapp.ontap` collection — volumes, SVMs, policies, SnapMirror |
| [`Ansible/ONTAP-Learning/`](./Ansible/ONTAP-Learning/) | Ansible | Step-by-step learning series — from Ansible basics to full ONTAP workflow automation |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module / Collection | `NetApp.ONTAP` PS Toolkit or REST API | `netapp.ontap` collection |
| Install | `Install-Module NetApp.ONTAP -Scope CurrentUser` | `ansible-galaxy collection install netapp.ontap` |
| Python Library | — | `pip install netapp-lib --break-system-packages` |
| ONTAP Version | 9.6+ | 9.6+ |
| Access | Cluster admin or SVM admin | Cluster admin or SVM admin |

## Authentication

All scripts and playbooks use secure credential handling:
- **PowerShell** — `Get-Credential` + `Export-Clixml` (no hardcoded passwords)
- **Ansible** — `ansible-vault` with `vault_ontap_*` variable convention

## Common Use Cases

- Create and configure NFS/CIFS volumes and qtrees
- Manage Storage Virtual Machines (SVMs) and LIFs
- Configure and monitor SnapMirror replication relationships
- Automate aggregate and capacity reporting
- Apply and audit export policies and access controls
- Cluster health monitoring and alert triage

## Related Agent

Use `/netapp-sme` in Claude Code for NetApp-specific script generation, troubleshooting, and best practices.
