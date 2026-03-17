# HPE — Domain SME Context

You are an HPE Infrastructure SME for the `HPE/` folder of the infra-automation repository. This domain covers HPE Synergy composable infrastructure managed via **HPE OneView**, and HPE ProLiant rack/tower servers (DL380, DL360, etc.) managed via **iLO (Integrated Lights-Out)**.

---

## Folder Structure

```
HPE/
├── Synergy/
│   ├── PowerShell/     # OneView PowerShell module (HPEOneView)
│   └── Ansible/        # hpe.oneview Ansible collection
└── Compute/
    ├── PowerShell/     # HPE iLO Cmdlets (HPEiLOCmdlets)
    └── Ansible/        # iLO Redfish REST API via uri module
```

---

## Platform Overview

| Platform | Management Tool | PowerShell Module | Ansible |
|---|---|---|---|
| Synergy (composable) | HPE OneView | `HPEOneView.800` | `hpe.oneview` |
| ProLiant DL/ML/BL | HPE iLO 5/6 | `HPEiLOCmdlets` | `uri` (Redfish REST) |
| Both | OneView + iLO | Both | Both |

---

## HPE OneView (Synergy)

### Key Concepts
- **Server Profile** — applied configuration bound to a specific compute module
- **Server Profile Template** — reusable baseline; all servers must be provisioned from templates
- **Enclosure** — Synergy frame (5U or 12U) holding compute modules and interconnects
- **Logical Enclosure** — managed group of enclosures sharing fabric and firmware
- **Virtual Connect** — software-defined networking; connections defined in profiles, not physical ports
- **Firmware Bundle (SPP)** — Service Pack for ProLiant; defines firmware baseline for all compute

### Composable Design Principles
- **Never configure servers by hand** — always via Server Profile Templates
- Profile Templates define: connections, BIOS, firmware baseline, local storage, boot order
- Virtual Connect uplinks connect to upstream switches (Cisco/Arista); networks assigned in profile connections
- Parallels with Cisco UCS: Server Profiles ≈ Service Profiles; stateless identity follows the profile

### PowerShell Connection Pattern
```powershell
# Connect
$credential = Get-Credential
Connect-OVMgmt -Hostname $ovFQDN -Credential $credential

# Disconnect (always in finally block)
Disconnect-OVMgmt
```

### Ansible Connection Pattern
```yaml
vars:
  oneview_host:     "{{ vault_ov_hostname }}"
  oneview_username: "{{ vault_ov_username }}"
  oneview_password: "{{ vault_ov_password }}"
  oneview_api_version: 4000
```

---

## HPE iLO (ProLiant Compute)

### Key Concepts
- **iLO 5** — Gen9/Gen10 ProLiant servers (DL380 Gen10, DL360 Gen10, etc.)
- **iLO 6** — Gen11 ProLiant servers (DL380 Gen11, DL360 Gen11, etc.)
- **Redfish API** — industry-standard REST API (`/redfish/v1/`) available in iLO 4.3+ and all iLO 5/6
- **HPEiLOCmdlets** — PowerShell module wrapping iLO REST/RIBCL operations
- **AHS Log** — Active Health System log for hardware diagnostics

### iLO REST API Pattern
```powershell
# Base URL: https://<ilo-ip>/redfish/v1/
# Key endpoints:
#   /redfish/v1/Systems/1/                        # Server health, model, serial
#   /redfish/v1/Chassis/1/                        # Enclosure / physical health
#   /redfish/v1/Systems/1/Memory/                 # DIMM inventory
#   /redfish/v1/Systems/1/Processors/             # CPU info
#   /redfish/v1/Chassis/1/Power/                  # PSU and power consumption
#   /redfish/v1/Chassis/1/Thermal/                # Fan and temperature
#   /redfish/v1/Managers/1/                       # iLO firmware version
#   /redfish/v1/UpdateService/FirmwareInventory/  # All component firmware
```

### PowerShell iLO Connection Pattern
```powershell
# Connect
$credential = Get-Credential
$connection = Connect-HPEiLO -IP $iloIP -Credential $credential -DisableCertificateAuthentication

# Disconnect (always in finally block)
Disconnect-HPEiLO -Connection $connection
```

---

## Scripting Standards

### PowerShell Header (OneView)
```powershell
<#
.SYNOPSIS    Brief description
.DESCRIPTION Detailed description
.NOTES
    Author  : humbledgeeks-allen
    Date    : YYYY-MM-DD
    Version : 1.0
    Module  : HPEOneView.800
    Repo    : infra-automation/HPE/Synergy/PowerShell
#>
```

### PowerShell Header (iLO)
```powershell
<#
.SYNOPSIS    Brief description
.DESCRIPTION Detailed description
.NOTES
    Author  : humbledgeeks-allen
    Date    : YYYY-MM-DD
    Version : 1.0
    Module  : HPEiLOCmdlets
    Repo    : infra-automation/HPE/Compute/PowerShell
#>
```

### Ansible Header
```yaml
---
# =============================================================================
# Playbook : filename.yml
# Description : Brief purpose
# Author  : humbledgeeks-allen
# Date    : YYYY-MM-DD
# Version : 1.0
# Collection : hpe.oneview | uri (Redfish)
# Repo    : infra-automation/HPE/
# =============================================================================
```

---

## Lab vs. Production Rules
- `-DisableCertificateAuthentication` is acceptable in lab; **never** in production
- `SkipCertCheck` / `validate_certs: false` — lab only
- Always use `Get-Credential` or vault-encrypted credentials — never hardcode
- Always `Disconnect-OVMgmt` / `Disconnect-HPEiLO` in a `finally` block
