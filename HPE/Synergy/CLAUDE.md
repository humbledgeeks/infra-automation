# HPE Synergy — SME Context

Automation for **HPE Synergy composable infrastructure** using HPE OneView as the management plane. All compute provisioning goes through Server Profile Templates — never direct bare-metal configuration.

---

## Management Stack

| Layer | Tool |
|---|---|
| Management Appliance | HPE OneView (Virtual Appliance or Synergy Composer) |
| PowerShell | `HPEOneView.800` (or version-matched to your appliance) |
| Ansible | `hpe.oneview` collection + `hpeOneView` Python SDK |
| REST API | `https://<oneview-fqdn>/rest/` (X-API-Version header required) |

---

## Core OneView Resources

| Resource | PowerShell Cmdlet | Description |
|---|---|---|
| Server Hardware | `Get-OVServer` | Physical compute modules |
| Server Profile | `Get-OVServerProfile` | Applied config on a server |
| Server Profile Template | `Get-OVServerProfileTemplate` | Reusable baseline |
| Enclosure | `Get-OVEnclosure` | Synergy frame |
| Logical Enclosure | `Get-OVLogicalEnclosure` | Managed enclosure group |
| Interconnect | `Get-OVInterconnect` | Virtual Connect modules |
| Network | `Get-OVNetwork` | Ethernet/FC networks in OneView |
| Firmware Bundle | `Get-OVBaseline` | SPP firmware baselines |
| Alerts | `Get-OVAlert` | Active OneView alerts |

---

## Key Compliance Checks

```powershell
# Server profile compliance vs template
Get-OVServerProfile | Select-Object Name, TemplateCompliance, Status

# Firmware compliance
Get-OVServer | Select-Object Name, Status, FirmwareVersion

# Enclosure health
Get-OVEnclosure | Select-Object Name, Status, State

# Active alerts
Get-OVAlert -State Active | Select-Object Description, Severity, Created
```

---

## Ansible Collection Pattern

```yaml
collections:
  - hpe.oneview

vars:
  config: "{{ playbook_dir }}/oneview_config.json"
  # oneview_config.json contains ip, credentials, api_version
  # Encrypt with ansible-vault
```

---

## Folder Contents
- `PowerShell/` — OneView PowerShell scripts using `HPEOneView` module
- `Ansible/` — OneView playbooks using `hpe.oneview` collection
