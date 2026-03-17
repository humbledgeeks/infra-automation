# VMware vSAN Automation

Automation scripts and playbooks for **VMware vSAN** hyper-converged storage using PowerShell (PowerCLI) and Ansible.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| VMware vSAN 7.x / 8.x | Hyper-converged storage — cluster health, disk groups, capacity, storage policies |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`PowerShell/`](./PowerShell/) | PowerShell | vSAN health, disk group reporting, and capacity analysis via VMware PowerCLI |
| [`Ansible/`](./Ansible/) | Ansible | vSAN cluster operations using the `community.vmware` Ansible collection |

## Prerequisites

| Requirement | PowerShell | Ansible |
|-------------|-----------|---------|
| Module / Collection | `VMware.PowerCLI` (includes vSAN cmdlets) | `community.vmware` collection |
| Install | `Install-Module VMware.PowerCLI -Scope CurrentUser` | `ansible-galaxy collection install community.vmware` |
| vCenter | 7.0+ (vSAN must be enabled on cluster) | 7.0+ |
| Access | vCenter Administrator or Read-Only | vCenter Administrator |

## Key vSAN Cmdlets

```powershell
Get-Cluster | Where-Object { $_.VsanEnabled }    # Find vSAN clusters
Get-VsanDiskGroup -VMHost $vmhost                 # Disk group inventory
Get-VsanSpaceUsage -Cluster $cluster              # Capacity reporting
Get-SpbmStoragePolicy | Where-Object { $_ -match "vSAN" }  # Storage policies
```

## Common Use Cases

- Health check across all vSAN clusters and disk groups
- Capacity and utilisation reporting per cluster
- Audit storage policy compliance for VMs
- Monitor vSAN resync and rebuild operations
- Report disk group composition (cache tier vs capacity tier)
- Validate vSAN witness appliance connectivity (stretched clusters)

## Related Agent

Use `/vmware-sme` in Claude Code for vSAN script generation, storage policy design, and cluster health diagnostics.
