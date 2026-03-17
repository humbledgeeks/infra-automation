# Cisco UCS — Ansible

Ansible playbooks for Cisco UCS using the **`cisco.ucs`** collection for Classic UCS Manager (UCSM) environments.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Python | 3.9 | 3.11+ |
| Ansible | 2.14 | 2.17+ |
| OS | Linux / macOS / WSL2 | Ubuntu 22.04 LTS |

---

## Installation

### Step 1 — Install Python 3 and pip

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y python3 python3-pip python3-venv

# macOS (via Homebrew)
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

### Step 4 — Install the cisco.ucs collection

```bash
ansible-galaxy collection install cisco.ucs

# Verify
ansible-galaxy collection list | grep cisco.ucs
```

### Step 5 — Install the UCS Python SDK (required dependency)

```bash
pip install ucsmsdk

# Verify
python3 -c "from ucsmsdk.ucshandle import UcsHandle; print('ucsmsdk OK')"
```

---

## Credential Setup — Ansible Vault

**Never store credentials in plain text.** Use Ansible Vault for all sensitive variables.

```bash
# Create an encrypted vault file
ansible-vault create group_vars/all/vault.yml
```

Inside `vault.yml`, add:

```yaml
vault_ucs_hostname: ucs-fi-a.lab.local
vault_ucs_username: admin
vault_ucs_password: YourPasswordHere
```

```bash
# Encrypt an existing file
ansible-vault encrypt group_vars/all/vault.yml

# Edit an encrypted vault file later
ansible-vault edit group_vars/all/vault.yml

# View without editing
ansible-vault view group_vars/all/vault.yml
```

Reference vault variables in playbooks using the `vault_` prefix convention:

```yaml
vars:
  ucs_hostname: "{{ vault_ucs_hostname }}"
  ucs_username: "{{ vault_ucs_username }}"
  ucs_password: "{{ vault_ucs_password }}"
```

---

## Inventory Setup

UCS playbooks run from **localhost** using `connection: local` — no UCS hosts need to be in your inventory.

```ini
# inventory/hosts.ini
[localhost]
localhost ansible_connection=local
```

---

## Playbooks in This Folder

| Playbook | Description |
|---|---|
| `ucs-gather-inventory.yml` | Gathers blade inventory and service profile facts; ends with assertion validation |

---

## How to Run

### ucs-gather-inventory.yml

Connects to UCS Manager and returns blade hardware inventory with service profile associations.

```bash
# Syntax check first (no execution)
ansible-playbook ucs-gather-inventory.yml --syntax-check

# Run with vault password prompt
ansible-playbook ucs-gather-inventory.yml --ask-vault-pass

# Run with vault password file (CI/CD or scheduled)
echo "YourVaultPassword" > ~/.vault_pass && chmod 600 ~/.vault_pass
ansible-playbook ucs-gather-inventory.yml --vault-password-file ~/.vault_pass

# Dry run — check mode, no changes
ansible-playbook ucs-gather-inventory.yml --check --ask-vault-pass

# Verbose output for troubleshooting
ansible-playbook ucs-gather-inventory.yml -vvv --ask-vault-pass
```

---

## Lint and Validation

```bash
# Install ansible-lint
pip install ansible-lint

# Lint a playbook
ansible-lint ucs-gather-inventory.yml

# Syntax check all playbooks in the folder
for f in *.yml; do ansible-playbook "$f" --syntax-check; done
```

---

## References

- [cisco.ucs on Ansible Galaxy](https://galaxy.ansible.com/cisco/ucs)
- [Cisco UCS Ansible Collection GitHub](https://github.com/CiscoDevNet/ansible-ucs)
- [ucsmsdk Python Library](https://pypi.org/project/ucsmsdk/)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
