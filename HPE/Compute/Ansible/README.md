# HPE Compute (ProLiant) — Ansible Playbooks

Ansible playbooks for **HPE ProLiant rack and tower servers** (DL380, DL360, DL560, ML350, etc.) using the **iLO Redfish REST API**. These playbooks connect directly to iLO via the standard `uri` module — no extra Ansible collection required.

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Python | 3.9+ | Required for Ansible |
| Ansible | 2.14+ | Core automation engine |
| iLO access | iLO 5 (Gen10) / iLO 6 (Gen11) | Must be reachable over HTTPS (port 443) |
| iLO account | Local or LDAP/AD account | Read-Only role is sufficient for health checks |

> **No extra collection required.** These playbooks use Ansible's built-in `uri` module against the standard Redfish REST API. iLO 5 and iLO 6 both support Redfish v1 natively.

---

## Install Ansible

```bash
# Install Ansible (if not already installed)
pip install ansible --break-system-packages

# Or via package manager
sudo apt install ansible        # Debian/Ubuntu
brew install ansible            # macOS

# Verify
ansible --version
```

---

## Credential Setup (Ansible Vault)

All playbooks use Ansible Vault for iLO credential storage. Never store credentials in plaintext YAML files.

### Create a Vault File

```bash
ansible-vault create group_vars/all/vault.yml
```

Add the following variables:
```yaml
vault_ilo_ip:       "10.10.1.20"          # iLO IP or FQDN
vault_ilo_username: "administrator"
vault_ilo_password: "YourSecurePassword"
```

### Edit an Existing Vault File

```bash
ansible-vault edit group_vars/all/vault.yml
```

### Store the Vault Password (Optional, for CI/CD)

```bash
echo "your-vault-password" > ~/.vault_pass
chmod 600 ~/.vault_pass
```

---

## Scripts in This Folder

| Playbook | Description |
|---|---|
| `ilo-gather-server-health.yml` | Read-only health report via Redfish: system overview, processors, memory, thermal, power supplies, and iLO firmware version |

---

## How to Run

### `ilo-gather-server-health.yml`

**Variables (set via Vault):**

| Variable | Description |
|---|---|
| `vault_ilo_ip` | iLO IP address or FQDN |
| `vault_ilo_username` | iLO account username |
| `vault_ilo_password` | iLO account password |

**Run Commands:**

```bash
# Prompt for vault password at run time
ansible-playbook ilo-gather-server-health.yml --ask-vault-pass

# Use a saved vault password file
ansible-playbook ilo-gather-server-health.yml --vault-password-file ~/.vault_pass

# Check mode (dry run — validates structure without connecting to iLO)
ansible-playbook ilo-gather-server-health.yml --ask-vault-pass --check

# Verbose output (shows full Redfish JSON responses)
ansible-playbook ilo-gather-server-health.yml --ask-vault-pass -v
```

**Sample Output:**
```
TASK [Display system overview]
ok: [localhost] => {
    "msg": "Model: ProLiant DL380 Gen10 | Serial: MXQ12345AB | Health: OK | Power: On"
}

TASK [Display processor count]
ok: [localhost] => {
    "msg": "Processors found: 2"
}

TASK [Display memory info]
ok: [localhost] => {
    "msg": "Total Memory DIMMs: 16"
}

TASK [Display fan status]
ok: [localhost] => (item=Fan 1) => {
    "msg": "Fan: Fan 1 | Status: OK | Speed: 18%"
}

TASK [Display power supply status]
ok: [localhost] => (item=HpeServerPowerSupply 1) => {
    "msg": "PSU: HpeServerPowerSupply 1 | Status: OK | State: Enabled"
}

TASK [Display iLO firmware version]
ok: [localhost] => {
    "msg": "iLO Version: iLO 5 v2.87 | Model: iLO 5"
}

TASK [Validate - confirm system health data was returned]
ok: [localhost] => {
    "changed": false,
    "msg": "iLO health data gathered from 10.10.1.20 — ProLiant DL380 Gen10 Health: OK"
}
```

---

## Redfish Endpoint Reference

| Endpoint | Data Returned |
|---|---|
| `/redfish/v1/Systems/1/` | Model, serial number, health, power state |
| `/redfish/v1/Systems/1/Processors/` | CPU count and member list |
| `/redfish/v1/Systems/1/Memory/` | DIMM count and member list |
| `/redfish/v1/Chassis/1/Thermal/` | Fan speeds, temperatures |
| `/redfish/v1/Chassis/1/Power/` | PSU status and wattage |
| `/redfish/v1/Managers/1/` | iLO firmware version, model |

---

## iLO Generation Reference

| Server Generation | iLO Version | Redfish Support |
|---|---|---|
| Gen9 | iLO 4 | Partial (v4.3+) — some endpoints may differ |
| Gen10 / Gen10 Plus | iLO 5 | Full Redfish v1 |
| Gen11 | iLO 6 | Full Redfish v1 |

---

## TLS Certificate Note

By default these playbooks set `validate_certs: false` for lab compatibility. In production environments, set the iLO cert to a trusted CA-signed certificate and change to:

```yaml
validate_certs: true
```

---

## References

- [HPE iLO Redfish API Reference](https://developer.hpe.com/platform/ilo-restful-api/home/)
- [DMTF Redfish Standard](https://www.dmtf.org/standards/redfish)
- [Ansible uri Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
- [HPE ProLiant iLO 5 User Guide](https://support.hpe.com/hpesc/public/docDisplay?docId=a00018324en_us)
