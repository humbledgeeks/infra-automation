# NetApp StorageGRID — Ansible

Ansible playbooks for automating NetApp StorageGRID using the **`uri` module** to call the StorageGRID REST API v3. All playbooks are agentless — no special Ansible collection is required.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Python | 3.9 | 3.11+ |
| Ansible | 2.14 | 2.17+ |
| StorageGRID | 11.5 | 11.8+ |
| OS | Linux / macOS / WSL2 | Ubuntu 22.04 LTS |
| Network | HTTPS to Admin Node port 443 | — |

> **No additional Ansible collections are required.** The `uri` module is bundled with core Ansible (`ansible.builtin.uri`).

---

## Installation

### Step 1 — Install Python and pip

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y python3 python3-pip python3-venv

# macOS
brew install python@3.11

# Verify
python3 --version && pip3 --version
```

### Step 2 — Create a virtual environment (recommended)

```bash
python3 -m venv ~/ansible-venv
source ~/ansible-venv/bin/activate
```

### Step 3 — Install Ansible

```bash
pip install ansible
ansible --version
```

### Step 4 — (Optional) Install the netapp.storagegrid collection

If you prefer module-based playbooks over raw REST calls:

```bash
ansible-galaxy collection install netapp.storagegrid

# Verify
ansible-galaxy collection list | grep netapp.storagegrid
```

---

## Credential Setup — Ansible Vault

**Never store credentials in plain text.** Use Ansible Vault.

```bash
# Create encrypted vault file
ansible-vault create group_vars/all/vault.yml
```

Inside `vault.yml`:

```yaml
vault_sg_admin_node: storagegrid-admin.lab.local
vault_sg_username:   root
vault_sg_password:   YourGridPassword
```

```bash
# Edit vault later
ansible-vault edit group_vars/all/vault.yml

# View without editing
ansible-vault view group_vars/all/vault.yml
```

Reference in playbooks:

```yaml
vars:
  sg_admin_node: "{{ vault_sg_admin_node }}"
  sg_username:   "{{ vault_sg_username }}"
  sg_password:   "{{ vault_sg_password }}"
  sg_api_base:   "https://{{ vault_sg_admin_node }}/api/v3"
```

---

## Inventory Setup

StorageGRID playbooks run from **localhost** using `connection: local` — all API calls go to the Admin Node via HTTPS.

```ini
# inventory/hosts.ini
[localhost]
localhost ansible_connection=local
```

---

## Playbooks in This Folder

| Playbook | Description |
|---|---|
| `sg-gather-grid-info.yml` | Authenticates via REST API; gathers node health and tenant info; ends with assertion validation |

---

## How to Run

### sg-gather-grid-info.yml

Authenticates to StorageGRID REST API and reports grid node health and tenant accounts.

```bash
# Syntax check first (no execution)
ansible-playbook sg-gather-grid-info.yml --syntax-check

# Run with vault password prompt
ansible-playbook sg-gather-grid-info.yml --ask-vault-pass

# Run with vault password file (CI/CD or automation)
echo "YourVaultPassword" > ~/.vault_pass && chmod 600 ~/.vault_pass
ansible-playbook sg-gather-grid-info.yml --vault-password-file ~/.vault_pass

# Verbose output for troubleshooting
ansible-playbook sg-gather-grid-info.yml -vvv --ask-vault-pass
```

---

## StorageGRID Authentication Pattern (Ansible)

All playbooks use this token auth pattern with `no_log: true` to protect credentials:

```yaml
- name: Authenticate to StorageGRID
  uri:
    url: "https://{{ sg_admin_node }}/api/v3/authorize"
    method: POST
    body_format: json
    body:
      username: "{{ sg_username }}"
      password: "{{ sg_password }}"
      cookie: false
      csrfToken: false
    validate_certs: false   # Set true in production
    status_code: 200
  register: sg_auth
  no_log: true   # Prevent credentials appearing in logs

- name: Set auth token
  set_fact:
    sg_token: "{{ sg_auth.json.data }}"
    sg_headers:
      Authorization: "Bearer {{ sg_auth.json.data }}"
```

---

## Lint and Validation

```bash
pip install ansible-lint

# Lint playbook
ansible-lint sg-gather-grid-info.yml

# Syntax check
ansible-playbook sg-gather-grid-info.yml --syntax-check
```

---

## References

- [StorageGRID REST API Documentation](https://docs.netapp.com/us-en/storagegrid-118/s3/index.html)
- [Ansible uri module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)
- [netapp.storagegrid on Ansible Galaxy](https://galaxy.ansible.com/netapp/storagegrid)
- [Ansible Vault Guide](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
