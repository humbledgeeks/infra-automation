# VMware Domain — Context

This folder contains automation scripts, Ansible playbooks, and PowerShell tooling for managing VMware / Broadcom infrastructure.

Refer to the top-level `CLAUDE.md` for full role definition, coding standards, and core philosophy. This file provides VMware-specific context.

---

## Folder Structure

```
VMware/
├── ESXi/
│   ├── Ansible/        - ESXi host configuration playbooks (HDC, Humbled)
│   └── PowerShell/
│       ├── Hardening/  - ESXi security hardening scripts
│       ├── Host-Config/ - Host configuration automation
│       └── NFS/        - NFS datastore management
├── NSX/                - NSX-T network virtualization
├── vCenter/
│   └── PowerShell/
│       └── vLab/       - Virtual lab management platform (PowerShell + Node.js)
└── vSAN/               - vSAN cluster management
```

---

## Technology Context

### Platform Stack

- **vSphere**: ESXi 7.x / 8.x hosts managed via vCenter
- **PowerCLI**: Primary automation tool for VMware PowerShell work
- **Ansible**: Uses `community.vmware` collection for ESXi/vCenter tasks
- **NSX-T**: Software-defined networking and microsegmentation
- **vSAN**: Hyperconverged storage (policy-based via SPBM)
- **vLab**: Custom PowerShell + Node.js lab management platform in `vCenter/PowerShell/vLab`

### Key Modules and Tools

```powershell
# PowerCLI — always connect before operations
Connect-VIServer -Server $vCenterFQDN -Credential $creds

# Useful starting commands
Get-VMHost | Select Name, ConnectionState, PowerState
Get-Cluster | Get-VMHost
Get-Datastore | Select Name, FreeSpaceGB, CapacityGB
```

```yaml
# Ansible — VMware collection
collections:
  - community.vmware

# Common modules
- vmware_host_config_manager   # ESXi host settings
- vmware_vswitch               # Standard vSwitch management
- vmware_dvswitch              # Distributed vSwitch
- vmware_cluster_ha            # HA configuration
- vmware_cluster_drs           # DRS configuration
- vmware_datastore_info        # Datastore facts
- vmware_migrate_vmk           # VMkernel migration
- vmware_host_ntp              # NTP configuration
- vmware_host_service          # Service state management (SSH, Shell)
- vmware_host_lockdown         # Lockdown mode management
```

### REST API (vCenter)

vCenter Server exposes a modern REST API for automation workflows. Prefer REST for new automation over the older SOAP-based SDKs where possible.

```powershell
# Authenticate to vCenter REST API
$baseUrl = "https://$vCenterFQDN/api"
$headers = @{ "vmware-api-session-id" = $sessionId }

# Get all hosts via REST
Invoke-RestMethod -Uri "$baseUrl/vcenter/host" -Headers $headers -Method GET

# Get all VMs
Invoke-RestMethod -Uri "$baseUrl/vcenter/vm" -Headers $headers -Method GET
```

```python
# Python / vSphere Automation SDK
from com.vmware.vcenter_client import VM, Host, Cluster
# Use pyVmomi for legacy SOAP operations
# Use vsphere-automation-sdk-python for REST-based workflows
```

---

## VMware Best Practices (This Repo)

### Networking
- Always use **VDS (vSphere Distributed Switches)** — never standard vSwitches in production
- Separate traffic types: Management, vMotion, vSAN, VM Network, Storage (NFS/iSCSI)
- Use dedicated VMkernel ports per traffic type with correct TCP/IP stack

### Storage
- Apply **Storage Policy Based Management (SPBM)** for all vSAN and datastore assignments
- Use **Storage vMotion** for non-disruptive workload migrations
- NFS datastores: use dedicated VMkernel NFS port group, enable Jumbo Frames (MTU 9000) on storage network

### Compute
- Enable **HA** on all production clusters (Admission Control enforced)
- Enable **DRS** (Fully Automated) on production clusters
- Use **vSphere Lifecycle Manager (vLCM)** for host firmware and patch management
- Enforce consistent hardware configurations within a cluster

### vMotion

- Ensure a **dedicated VMkernel port group** for vMotion traffic on all hosts in the cluster
- Validate CPU compatibility before live migration (EVC mode recommended for cluster consistency)
- Check storage accessibility — source and destination hosts must both have access to the VM's datastores
- Use Enhanced vMotion Compatibility (EVC) to maximize live migration flexibility across CPU generations
- Monitor vMotion network bandwidth — 10GbE minimum recommended for production workloads

```powershell
# Verify EVC mode on cluster
Get-Cluster | Select Name, EVCMode

# Check VMkernel vMotion configuration
Get-VMHost | Get-VMHostNetworkAdapter | Where-Object {$_.VMotionEnabled} | Select VMHost, Name, IP
```

### Storage vMotion

- Use Storage vMotion to migrate VMs between datastores without downtime
- Validate SPBM policy compliance on destination datastore before migrating
- Avoid initiating Storage vMotion during peak hours — it generates significant I/O on both source and destination
- Track Storage vMotion tasks in vCenter to avoid concurrent migrations overwhelming storage

```powershell
# Migrate VM to a different datastore
Move-VM -VM "VMName" -Datastore "DestinationDatastore"

# Migrate with specific disk format
Move-VM -VM "VMName" -Datastore "DestinationDatastore" -DiskStorageFormat Thin
```

### vCenter RBAC and Identity Management

- Always use **role-based access control (RBAC)** — never assign broad permissions to individuals
- Integrate vCenter with Active Directory / LDAP for centralized identity management
- Use the **principle of least privilege**: assign only the permissions required per role
- Audit vCenter permissions regularly; remove stale accounts
- Use named service accounts for automation — never use admin credentials in scripts

```powershell
# List all vCenter permissions
Get-VIPermission | Select Principal, Role, Entity, Propagate

# Add a role assignment
New-VIPermission -Entity (Get-Datacenter "DC-Name") -Principal "DOMAIN\GroupName" -Role "ReadOnly" -Propagate $true
```

### Security (ESXi Hardening)
- Scripts in `ESXi/PowerShell/Hardening/` should follow the **VMware Security Configuration Guide** (current version)
- Disable unnecessary services: SSH, ESXi Shell — enable only for break-glass maintenance, then disable
- Enforce NTP synchronization on all hosts (required for certificate validity and log correlation)
- Enable **lockdown mode** (Normal) on production hosts; use Exception Users list for break-glass access
- Ensure all hosts run supported, patched firmware per VMware HCL
- Audit and restrict DCUI access
- Configure syslog forwarding to centralized logging platform

```powershell
# Check SSH and Shell status across all hosts
Get-VMHost | Get-VMHostService | Where-Object {$_.Key -in "TSM","TSM-SSH"} | Select VMHost, Key, Running, Policy

# Disable SSH on all hosts
Get-VMHost | Get-VMHostService | Where-Object {$_.Key -eq "TSM-SSH"} | Set-VMHostService -Policy Off | Stop-VMHostService -Confirm:$false

# Check NTP configuration
Get-VMHost | Get-VMHostNtpServer
```

---

## vLab Platform Notes

The `vCenter/PowerShell/vLab/` directory contains a custom virtual lab management platform.

Key scripts:
- `install.ps1` — platform bootstrap
- `new-vlabclone.ps1` — clone a lab environment from template
- `start-vlab.ps1` / `stop-vlab.ps1` — lab lifecycle management
- `show-dashboard-html.ps1` — HTML dashboard rendering
- `get-vlabstats.ps1` — lab utilization reporting
- `settings.cfg.sample` — template for environment config (copy to `settings.cfg`, do not commit credentials)

When working on vLab scripts, maintain the existing verb-noun PowerShell naming convention.

---

## Validation Commands

```powershell
# Verify cluster health
Get-Cluster | Get-VMHost | Select Name, ConnectionState, PowerState

# Check HA / DRS status
Get-Cluster | Select Name, HAEnabled, DrsEnabled, DrsAutomationLevel

# Verify VDS configuration
Get-VDSwitch | Select Name, NumUplinkPorts, Version

# Check datastore utilization
Get-Datastore | Select Name, @{N="FreeGB";E={[math]::Round($_.FreeSpaceGB,1)}}, @{N="TotalGB";E={[math]::Round($_.CapacityGB,1)}}

# NFS datastore connectivity
Get-VMHost | Get-VMHostStorage
```

```bash
# ESXi CLI validation
esxcli network nic list
esxcli storage nfs list
esxcli system version get
vim-cmd hostsvc/hostsummary
```
