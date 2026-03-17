# Cisco Domain — Context

This folder contains automation scripts and configuration references for managing Cisco compute infrastructure.

Refer to the top-level `CLAUDE.md` for full role definition, coding standards, and core philosophy. This file provides Cisco UCS-specific context.

---

## Folder Structure

```
Cisco/
└── UCS/    - Cisco UCS automation scripts and configuration references
```

---

## Technology Context

### Platform Stack

- **Cisco UCS Manager (UCSM)**: Primary management plane for UCS Classic (Fabric Interconnects + blade/rack chassis)
- **Cisco Intersight**: Cloud-based management for UCS X-Series and managed UCS Classic
- **PowerShell / Cisco UCS PowerTool**: Primary automation module (`Cisco.UCSManager`)
- **Ansible**: Uses `cisco.ucs` collection for UCS automation
- **Python / UCSMSDK**: Alternative SDK for complex UCS automation

### PowerShell / UCS PowerTool

```powershell
# Import and connect to UCSM
Import-Module Cisco.UCSManager
$handle = Connect-Ucs -Name $ucsManagerIP -Credential $creds

# Useful starting commands
Get-UcsFabricInterconnect
Get-UcsBlade
Get-UcsServiceProfile
Get-UcsVnicTemplate
Get-UcsVhbaTemplate
Get-UcsFirmwareRunning
```

### Ansible Collection

```yaml
collections:
  - cisco.ucs

# Connection vars
vars:
  ip: "{{ ucs_mgmt_ip }}"
  username: "{{ vault_ucs_username }}"
  password: "{{ vault_ucs_password }}"

# Common modules
- cisco.ucs.ucs_service_profile_template   # Service Profile Templates
- cisco.ucs.ucs_vnic_template              # vNIC Templates
- cisco.ucs.ucs_vhba_template             # vHBA Templates
- cisco.ucs.ucs_mac_pool                  # MAC address pools
- cisco.ucs.ucs_wwn_pool                  # WWPN/WWNN pools
- cisco.ucs.ucs_lan_connectivity          # LAN connectivity policies
- cisco.ucs.ucs_san_connectivity          # SAN connectivity policies
```

### Cisco Intersight

Intersight is Cisco's SaaS-based management platform for UCS X-Series and cloud-managed UCS Classic environments.

Key concepts:
- **Organization**: Logical container for all policies and profiles in Intersight
- **Server Profile**: Intersight equivalent of UCS Service Profile
- **Server Profile Template**: Defines a reusable baseline; profiles derived from templates inherit updates
- **Policy Buckets**: Modular policies (BIOS, Boot Order, iSCSI, vNIC, vHBA) assembled into profiles

```powershell
# Intersight REST API via PowerShell (using Intersight.PowerShell module)
Import-Module Intersight.PowerShell

$Configuration = Initialize-IntersightConfiguration
$Configuration.BaseUrl    = "https://intersight.com"
$Configuration.ApiKeyId   = $env:INTERSIGHT_API_KEY_ID
$Configuration.ApiKeyFile = $env:INTERSIGHT_API_KEY_FILE

# Get all server profiles
Get-IntersightServerProfile | Select-Object Name, AssignedServer, ConfigState

# Get all policies
Get-IntersightBiosPolicy
Get-IntersightBootPrecisionPolicy
```

```python
# Python — Intersight REST API
import intersight
from intersight.api import server_api

configuration = intersight.Configuration(
    host="https://intersight.com",
    signing_info=intersight.signing.HttpSigningConfiguration(
        key_id=api_key_id,
        private_key_path=api_key_file,
    )
)

with intersight.ApiClient(configuration) as api_client:
    api = server_api.ServerApi(api_client)
    profiles = api.get_server_profile_list()
```

**Intersight REST API docs**: `https://intersight.com/apidocs/introduction/overview/`

---

## UCS Architecture Context

### Platform Selection

| Platform | Management | Use Case |
|----------|-----------|---------|
| UCS Classic (B/C-Series) | UCS Manager (UCSM) | Existing datacenter deployments |
| UCS X-Series | Cisco Intersight | New deployments, cloud-managed |
| UCS IMM (Intersight Managed Mode) | Intersight | Migrating Classic to cloud-managed |

### Core Design Principles

- **Stateless compute**: Server identity is abstracted through Service Profiles
- **Service Profile Templates**: All physical blades should be associated to templates (not standalone profiles) for consistent management
- **A/B Fabric separation**: All vNICs and vHBAs must have one leg on Fabric A and one on Fabric B — no single-fabric adapters in production
- **Pool-based identity**: MAC addresses, WWPNs, WWNNs, UUIDs, and server IDs should all be drawn from defined pools

### Identity Pools

| Pool Type | Purpose |
|-----------|---------|
| MAC Pool | vNIC MAC address assignment |
| WWPN Pool | vHBA World Wide Port Name |
| WWNN Pool | World Wide Node Name |
| UUID Pool | Server UUID assignment |
| IP Pool (KVM) | Out-of-band KVM management IPs |

### SAN Boot Architecture

- Production workloads should use **SAN boot** (FC or iSCSI) via vHBA boot policies
- Boot targets defined in boot policies — primary and secondary paths across A/B fabrics
- Validate boot policy targets match zoned storage ports

### Firmware Management

- Maintain consistent firmware versions within a chassis / domain
- Use **Host Firmware Packages** to define target firmware baseline
- Validate against Cisco UCS Hardware Compatibility List (HCL) before upgrading
- Stage firmware before activating to minimize maintenance windows

---

## Cisco UCS Best Practices (This Repo)

- Always use **Service Profile Templates** — never manually configure individual server profiles
- Use **Named vNIC/vHBA Templates** to ensure consistent adapter configuration
- Separate management, storage, and VM traffic across dedicated vNICs
- Apply **QoS policies** for storage traffic (FCoE / iSCSI) prioritization
- Do not commit UCS credentials — use Ansible Vault or PowerShell SecretManagement
- Document pool ranges and VLAN/VSAN assignments in script headers

---

## Validation Commands

```powershell
# Health and inventory
Get-UcsFabricInterconnect | Select Dn, Model, Serial, OperState
Get-UcsBlade | Select Dn, Model, Serial, AssignedToDn, OperState
Get-UcsServiceProfile | Select Name, AssocState, PnDn

# Networking
Get-UcsVnicTemplate | Select Name, Fabric, MacAddressType, Mtu
Get-UcsFabricVlan | Select Id, Name

# Storage
Get-UcsVhbaTemplate | Select Name, Fabric, Type
Get-UcsFabricVsan | Select Id, Name, FcoeVlan

# Firmware
Get-UcsFirmwareRunning | Where-Object {$_.Type -eq "blade-controller"} | Select Dn, PackageVersion
```

```bash
# UCSM CLI (SSH to Fabric Interconnect)
show server status
show service-profile status
show fabric-interconnect
show version
```
