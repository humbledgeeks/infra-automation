# NUCLab

End-to-end lab automation suite for NUC-based homelab environments. Deploys a complete stack: ESXi → Active Directory → vCenter → ONTAP Select → Integration.

## Structure

| Folder | Tool | Description |
|--------|------|-------------|
| [Ansible/](./Ansible) | Ansible | Full lab build playbooks (00–06), vars, and unattend |

## Ansible

Sequential playbooks that build a full lab from scratch:

| Playbook | Stage |
|----------|-------|
| `00_MainInstaller.yml` | Master — runs all stages in sequence |
| `01_ESXi_Config.yml` | ESXi host configuration |
| `02_DC_Deploy.yml` / `02_DC_Config.yml` | Active Directory Domain Controller |
| `03_VC_Deploy.yml` / `03_VC_Config.yml` | vCenter Server |
| `04_OTS_Deploy.yml` / `04_OTS_Configure.yml` | ONTAP Select |
| `05_Integration.yml` | Integrate all components |
| `06_Portal.yml` | Portal/dashboard setup |

See [Ansible/README.md](./Ansible/README.md) for full details, vault setup, and run commands.

## Related Agent

Use `/infra-orchestrate` in Claude Code for multi-vendor lab build workflows spanning VMware, NetApp, and Active Directory. Use `/vmware-sme` or `/netapp-sme` for vendor-specific tasks within the lab.
