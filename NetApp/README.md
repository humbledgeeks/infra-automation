# NetApp

Automation scripts and playbooks for NetApp storage infrastructure.

## Structure

| Folder | Description |
|--------|-------------|
| [ONTAP/](./ONTAP) | ONTAP cluster management — setup scripts, NFS plugin, Ansible learning series (00–08) |
| [ONTAP/PowerShell](./ONTAP/PowerShell) | ONTAP setup scripts, NFS plugin install, disk serial reference |
| [ONTAP/Ansible](./ONTAP/Ansible) | Ansible for NetApp ONTAP — step-by-step learning series (00–08) |
| [StorageGRID/](./StorageGRID) | StorageGRID grid and tenant automation via REST API — PowerShell and Ansible |

Each subfolder contains `PowerShell/` and/or `Ansible/` directories grouping scripts by tool.

## Related Agent

Use `/netapp-sme` in Claude Code for NetApp ONTAP and StorageGRID script generation, storage architecture, and troubleshooting.
