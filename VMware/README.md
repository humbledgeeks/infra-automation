# VMware

Automation scripts and playbooks for the VMware stack — ESXi, vCenter, NSX, and vSAN.

## Structure

| Folder | Description |
|--------|-------------|
| [ESXi/](./ESXi) | ESXi host hardening, configuration, and NFS — PowerShell and Ansible |
| [vCenter/](./vCenter) | vCenter VM deployment and vLab management — PowerShell |
| [NSX/](./NSX) | NSX-T segment inventory, gateway topology, and distributed firewall — PowerShell and Ansible |
| [vSAN/](./vSAN) | vSAN cluster health, disk group reporting, and capacity analysis — PowerShell and Ansible |

Each subfolder contains `PowerShell/` and/or `Ansible/` directories grouping scripts by tool.

## Related Agent

Use `/vmware-sme` in Claude Code for VMware script generation, architecture guidance, and troubleshooting across vSphere, vSAN, NSX, and vCenter.
