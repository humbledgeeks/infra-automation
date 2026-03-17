# NetApp Domain — Context

This folder contains Ansible playbooks and PowerShell scripts for managing NetApp storage infrastructure.

Refer to the top-level `CLAUDE.md` for full role definition, coding standards, and core philosophy. This file provides NetApp-specific context.

---

## Folder Structure

```
NetApp/
├── ONTAP/
│   ├── Ansible/
│   │   └── ONTAP-Learning/   - Structured Ansible learning path (00–08)
│   └── PowerShell/           - ONTAP management scripts
│       ├── Install_NetAPP_NFS_Plugin.ps1
│       └── ONTAP-Initial-Cluster-Setup.txt
└── StorageGRID/              - StorageGRID object storage automation
```

---

## Technology Context

### Platform Stack

- **ONTAP**: Primary storage OS for AFF/FAS/ASA platforms (unified NAS + SAN)
- **E-Series (SANtricity)**: Block-only storage platform for high-throughput SAN workloads
- **Ansible**: Uses `netapp.ontap` collection (maintained by NetApp); `netapp_eseries.santricity` for E-Series
- **PowerShell**: Uses `DataONTAP` module for ONTAP management
- **StorageGRID**: S3-compatible object storage platform
- **BlueXP**: Hybrid cloud data management (cloud-connected environments)

### Ansible Collection

```yaml
# Always specify the netapp.ontap collection
collections:
  - netapp.ontap

# Connection vars (use Ansible Vault for credentials — see 07-Ansible Vault)
vars:
  hostname: "{{ ontap_cluster_mgmt_ip }}"
  username: "{{ vault_ontap_username }}"
  password: "{{ vault_ontap_password }}"
  https: true
  validate_certs: false   # Set true in production with valid certs
```

Common modules used in this repo:

```yaml
- na_ontap_volume           # Volume create/modify/delete
- na_ontap_svm              # SVM management
- na_ontap_interface        # LIF management
- na_ontap_nfs              # NFS configuration
- na_ontap_iscsi            # iSCSI configuration
- na_ontap_lun              # LUN provisioning
- na_ontap_snapshot         # Snapshot management
- na_ontap_snapmirror       # SnapMirror relationships
- na_ontap_snapmirror_policy # SnapMirror policy management
- na_ontap_info             # Gather ONTAP facts
- na_ontap_aggregate        # Aggregate management
- na_ontap_qos_policy_group # QoS policy management
- na_ontap_rest_info        # REST-based fact gathering (ONTAP 9.6+)
```

**E-Series (SANtricity) Ansible collection:**

```yaml
collections:
  - netapp_eseries.santricity

# Common E-Series modules
- netapp_eseries.santricity.na_santricity_volume          # Volume management
- netapp_eseries.santricity.na_santricity_host            # Host and host group mapping
- netapp_eseries.santricity.na_santricity_storage_pool    # Pool/disk group management
- netapp_eseries.santricity.na_santricity_facts           # Gather E-Series facts
```

### PowerShell / DataONTAP Module

```powershell
# Connect to cluster
Import-Module DataONTAP
Connect-NcController -Name $clusterMgmtIP -Credential $creds

# Useful starting commands
Get-NcNode
Get-NcVol | Select Name, State, Used, Available
Get-NcSvm
Get-NcNetInterface
```

---

## ONTAP Learning Path

The `ONTAP/Ansible/ONTAP-Learning/` directory is a structured, numbered learning series:

| Folder | Topic |
|--------|-------|
| 00 | Lab Setup |
| 01 | Install Ansible |
| 02 | Update NetApp Modules |
| 03 | Understanding Playbooks |
| 04 | First Playbook Example |
| 05 | Complete Workflow |
| 06 | Just the Facts (na_ontap_info) |
| 07 | Ansible Vault (credential management) |
| 08 | Ansible Roles for ONTAP |

When adding new content to this learning series, maintain the numbered naming convention and include a `README.md` per section.

---

## NetApp Best Practices (This Repo)

### SVM Design
- One SVM per protocol type or per tenant/workload where separation is required
- Never mix NFS and iSCSI on the same SVM in production (protocol isolation)
- Use dedicated data LIFs per protocol; keep cluster management LIF separate

### Data Protection

- Implement SnapMirror for DR replication to secondary cluster or cloud (BlueXP)
- Configure SnapVault for compliance-grade long-term retention
- Define snapshot schedules at the volume level — hourly, daily, weekly minimum

#### SnapMirror Relationship Types

Always select the correct relationship type for the use case:

| Type | Policy | Use Case |
|------|--------|----------|
| **XDP** | MirrorAllSnapshots | DR with full snapshot preservation |
| **XDP** | MirrorAndVault | Combined DR + long-term retention (preferred) |
| **XDP** | Unified7year | Compliance retention (SnapVault replacement) |
| **Async** | DPDefault | Legacy DR replication (ONTAP 8.x style) |
| **Sync** | Sync / StrictSync | Zero-RPO synchronous replication |

```bash
# Create XDP MirrorAndVault relationship (preferred for new deployments)
snapmirror create -source-path SVM1:SourceVol -destination-path SVM2:DestVol \
  -policy MirrorAndVault -type XDP -schedule hourly
snapmirror initialize -destination-path SVM2:DestVol

# Validate replication health
snapmirror show -fields state,lag-time,healthy
```

#### Veeam Integration

When integrating NetApp with Veeam Backup & Replication:
- Use **Veeam's NetApp Storage Integration** (add storage system in Veeam console)
- Leverage **NetApp storage snapshots** for application-consistent backups without VSS overhead
- Veeam creates, mounts, and manages ONTAP snapshots directly via ONTAP REST/ZAPI
- Ensure the Veeam backup server or proxy has iSCSI or NFS access to the NetApp SVM
- Use **SnapMirror-to-backup** workflows for offloading backup I/O from production SVMs

### Performance
- Place volumes on appropriate aggregates based on workload type (latency-sensitive vs. throughput)
- Use QoS policies to protect critical workloads from noisy neighbors
- Monitor with ONTAP System Manager or ActiveIQ for performance anomalies

### E-Series (SANtricity)
- E-Series is block-only — no NAS protocols; SAN (FC/iSCSI/SRP/NVMe-oF) only
- Use **Dynamic Disk Pools (DDP)** for simplified management and fast rebuild times
- Configure **multipathing (ALUA)** on all hosts — use native OS MPIO or third-party (PowerPath)
- Host mappings define which hosts can see which volumes — always use host groups for shared access
- Ideal for high-throughput workloads: backup repositories, analytics, media storage

### Security
- Do **not** commit ONTAP credentials — always use Ansible Vault (see `07-Ansible Vault`)
- Use HTTPS for all API and management connections
- Enable AutoSupport for proactive support and telemetry

### NFS Plugin (VMware)
- `Install_NetAPP_NFS_Plugin.ps1` installs the NFS Plug-in for VMware VAAI
- Must be run per ESXi host; requires DataONTAP module and PowerCLI
- Validate VAAI offload is active post-install: `esxcli storage core device vaai status get`

---

## ONTAP REST API

ONTAP 9.6+ exposes a fully documented REST API. Prefer REST over ZAPI for all new automation development.

```powershell
# PowerShell — ONTAP REST API example
$baseUrl  = "https://$clusterMgmt/api"
$headers  = @{ "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$user:$pass")) }

# Get all SVMs
Invoke-RestMethod -Uri "$baseUrl/svm/svms" -Headers $headers -Method GET

# Get all volumes
Invoke-RestMethod -Uri "$baseUrl/storage/volumes" -Headers $headers -Method GET

# Get SnapMirror relationships
Invoke-RestMethod -Uri "$baseUrl/snapmirror/relationships" -Headers $headers -Method GET
```

```python
# Python — ONTAP REST API via netapp-ontap library
from netapp_ontap import config, HostConnection, utils
from netapp_ontap.resources import Volume, Svm, SnapmirrorRelationship

config.CONNECTION = HostConnection("cluster-mgmt", username="admin", password="pass", verify=False)

for vol in Volume.get_collection():
    vol.get()
    print(vol.name, vol.state)
```

The ONTAP REST API documentation is available at: `https://<cluster-mgmt>/docs/api`

---

## StorageGRID Context

StorageGRID is NetApp's S3-compatible object storage platform. Key concepts:

- **Grid**: Full StorageGRID deployment (admin, gateway, storage nodes)
- **Tenant accounts**: Multi-tenancy via S3 bucket policies
- **ILM (Information Lifecycle Management)**: Policy-driven data placement and replication
- **Traffic classification**: QoS for tenant workloads

Automation for StorageGRID should use the StorageGRID REST API or `netapp.storagegrid` Ansible collection where available.

---

## Validation Commands

```bash
# ONTAP CLI — cluster health
cluster show
system node show
storage aggregate show
volume show -state online
network interface show
snapmirror show
```

```powershell
# PowerShell / DataONTAP validation
Get-NcNode | Select Name, NodeUptime, IsNodeHealthy
Get-NcAggregate | Select Name, State, SizeAvailable
Get-NcVol | Where-Object {$_.State -eq "online"} | Select Name, SizeUsed
Get-NcSnapmirror | Select SourceLocation, DestinationLocation, MirrorState
```
