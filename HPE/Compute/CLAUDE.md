# HPE Compute (ProLiant) — SME Context

Automation for **HPE ProLiant rack and tower servers** (DL380, DL360, DL560, ML350, etc.) via **HPE iLO (Integrated Lights-Out)**. These are standalone servers managed via iLO — not Synergy composable. Use this folder for iLO-based health checks, firmware queries, BIOS configuration, and hardware inventory.

---

## Management Stack

| Layer | Tool |
|---|---|
| Out-of-band management | HPE iLO 5 (Gen10) / iLO 6 (Gen11) |
| PowerShell | `HPEiLOCmdlets` module |
| Ansible | `uri` module against iLO Redfish REST API |
| REST API standard | Redfish v1 (`/redfish/v1/`) |
| Direct iLO UI | `https://<ilo-ip>` |

---

## iLO Generation Reference

| Server Generation | iLO Version | Redfish | Notes |
|---|---|---|---|
| Gen9 | iLO 4 | Partial (v4.3+) | Legacy; prefer iLO 5+ |
| Gen10 / Gen10 Plus | iLO 5 | Full | DL380 Gen10, DL360 Gen10 |
| Gen11 | iLO 6 | Full | DL380 Gen11, DL360 Gen11 |

---

## Key Redfish Endpoints

| Endpoint | Returns |
|---|---|
| `/redfish/v1/Systems/1/` | Server model, serial, health, power state |
| `/redfish/v1/Systems/1/Processors/` | CPU count, model, cores |
| `/redfish/v1/Systems/1/Memory/` | DIMM inventory, total RAM |
| `/redfish/v1/Systems/1/Storage/` | RAID controllers, drives |
| `/redfish/v1/Chassis/1/Thermal/` | Fan speeds, temperatures |
| `/redfish/v1/Chassis/1/Power/` | PSU status, wattage |
| `/redfish/v1/Managers/1/` | iLO firmware version, NIC info |
| `/redfish/v1/UpdateService/FirmwareInventory/` | All component firmware versions |
| `/redfish/v1/Systems/1/Bios/` | Current BIOS settings |

---

## HPEiLOCmdlets Key Commands

```powershell
# Connect
$conn = Connect-HPEiLO -IP $iloIP -Credential $cred -DisableCertificateAuthentication

# Health
Get-HPEiLOHealthSummary -Connection $conn
Get-HPEiLOServerInfo -Connection $conn

# Hardware inventory
Get-HPEiLOProcessor -Connection $conn
Get-HPEiLOMemoryInfo -Connection $conn
Get-HPEiLOStorageController -Connection $conn

# Power and thermal
Get-HPEiLOPowerSupply -Connection $conn
Get-HPEiLOFan -Connection $conn
Get-HPEiLOTemperature -Connection $conn

# Firmware
Get-HPEiLOFirmwareInventory -Connection $conn

# iLO settings
Get-HPEiLONTPSetting -Connection $conn
Get-HPEiLOSNMPAlertDestination -Connection $conn

# Disconnect
Disconnect-HPEiLO -Connection $conn
```

---

## Ansible Redfish Pattern

```yaml
# Authentication — Basic auth or session token
- name: Get iLO system info
  uri:
    url: "https://{{ ilo_ip }}/redfish/v1/Systems/1/"
    method: GET
    user: "{{ vault_ilo_username }}"
    password: "{{ vault_ilo_password }}"
    force_basic_auth: true
    validate_certs: false
    return_content: true
  register: system_info
  no_log: true
```

---

## Folder Contents
- `PowerShell/` — iLO scripts using `HPEiLOCmdlets` module
- `Ansible/` — Redfish REST API playbooks using `uri` module
