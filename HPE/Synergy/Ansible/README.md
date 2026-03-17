# HPE Synergy — Ansible Playbooks

Ansible playbooks for **HPE Synergy composable infrastructure** using the **hpe.oneview** Ansible collection. These playbooks connect to HPE OneView (or Synergy Composer) to gather enclosure inventory, server hardware status, and server profile compliance data.

---

## Prerequisites

| Requirement | Version | Notes |
|---|---|---|
| Python | 3.9+ | Required for `hpe.oneview` collection |
| Ansible | 2.14+ | Core automation engine |
| hpe.oneview collection | Latest | From Ansible Galaxy |
| hpeOneView Python library | Latest | Backend SDK used by the collection |
| requests | Latest | HTTP client library |
| HPE OneView / Synergy Composer | 8.x or 9.x | Must be reachable over HTTPS |

---

## Install Dependencies

### 1 — Install the hpe.oneview Ansible Collection

```bash
ansible-galaxy collection install hpe.oneview
```

Verify the install:
```bash
ansible-galaxy collection list | grep hpe
```

### 2 — Install the Python SDK and Dependencies

```bash
pip install hpeOneView requests --break-system-packages
```

Or use a virtual environment (recommended):
```bash
python3 -m venv ~/.venv/hpe-ansible
source ~/.venv/hpe-ansible/bin/activate
pip install hpeOneView requests ansible
```

---

## Credential Setup (Ansible Vault)

All playbooks use Ansible Vault for credential storage. Never store plaintext credentials in your inventory or vars files.

### Create a Vault File

```bash
ansible-vault create group_vars/all/vault.yml
```

Add the following variables:
```yaml
vault_ov_hostname: "oneview.lab.local"
vault_ov_username: "administrator"
vault_ov_password: "YourSecurePassword"
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
| `synergy-gather-enclosure-info.yml` | Read-only inventory: enclosure health, compute module status, and server profile compliance from HPE OneView |

---

## How to Run

### `synergy-gather-enclosure-info.yml`

**Variables (set via Vault):**

| Variable | Description |
|---|---|
| `vault_ov_hostname` | FQDN or IP of the HPE OneView appliance |
| `vault_ov_username` | OneView service account username |
| `vault_ov_password` | OneView service account password |

**Run Commands:**

```bash
# Prompt for vault password at run time
ansible-playbook synergy-gather-enclosure-info.yml --ask-vault-pass

# Use a saved vault password file
ansible-playbook synergy-gather-enclosure-info.yml --vault-password-file ~/.vault_pass

# Check mode (dry run — validates playbook syntax without connecting)
ansible-playbook synergy-gather-enclosure-info.yml --ask-vault-pass --check

# Verbose output (useful for debugging API responses)
ansible-playbook synergy-gather-enclosure-info.yml --ask-vault-pass -v
```

**Sample Output:**
```
TASK [Display enclosure health summary]
ok: [localhost] => (item=Synergy-Frame-1) => {
    "msg": "Enclosure: Synergy-Frame-1 | Status: OK | State: Monitored"
}

TASK [Display server hardware summary]
ok: [localhost] => (item=Frame1, Bay1) => {
    "msg": "Server: Frame1, Bay1 | Model: Synergy 480 Gen10 | Power: On | Status: OK"
}

TASK [Display server profile compliance]
ok: [localhost] => (item=Web-Server-Profile-01) => {
    "msg": "Profile: Web-Server-Profile-01 | Status: OK | Compliance: Compliant"
}

TASK [Validate - confirm inventory was returned]
ok: [localhost] => {
    "changed": false,
    "msg": "OneView inventory gathered from oneview.lab.local — 1 enclosures, 12 compute modules, all profiles compliant"
}
```

---

## OneView API Version

The playbooks default to `api_version: 4000` (OneView 8.x). Adjust if your appliance version requires a different API level:

```yaml
vars:
  oneview_api_version: 4400   # OneView 9.x
```

To check your appliance's supported API versions:
```bash
curl -sk https://<oneview-ip>/rest/version | python3 -m json.tool
```

---

## References

- [hpe.oneview on Ansible Galaxy](https://galaxy.ansible.com/hpe/oneview)
- [hpe.oneview GitHub Repository](https://github.com/HewlettPackard/oneview-ansible-collection)
- [hpeOneView Python SDK](https://github.com/HewlettPackard/python-hpOneView)
- [HPE OneView REST API Reference](https://techlibrary.hpe.com/docs/enterprise/servers/oneview6.0/cicf-api/en/index.html)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
