# NetApp ONTAP — Ansible

Ansible playbooks for automating NetApp ONTAP (AFF / FAS / ASA) using the **`netapp.ontap`** collection. This collection provides modules for SVM management, volume provisioning, SnapMirror configuration, network setup, and more.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Python | 3.9 | 3.11+ |
| Ansible | 2.14 | 2.17+ |
| netapp.ontap collection | 21.x | 22.x (latest) |
| ONTAP | 9.8 | 9.13+ |
| OS | Linux / macOS / WSL2 | Ubuntu 22.04 LTS |

---

## Installation

### Step 1 — Install Python 3 and pip

```bash
# Ubuntu / Debian
sudo apt update && sudo apt install -y python3 python3-pip python3-venv

# macOS
brew install python@3.11
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

### Step 4 — Install the netapp.ontap collection

```bash
ansible-galaxy collection install netapp.ontap

# Verify
ansible-galaxy collection list | grep netapp.ontap
```

### Step 5 — Install required Python dependencies

```bash
pip install netapp-lib requests

# Verify
python3 -c "import netapp_lib; print('netapp-lib OK')"
```

---

## Credential Setup — Ansible Vault

**Never store credentials in plain text.** Use Ansible Vault.

```bash
# Create vault file
ansible-vault create group_vars/all/vault.yml
```

Inside `vault.yml`:

```yaml
vault_ontap_hostname: cluster01.lab.local
vault_ontap_username: admin
vault_ontap_password: YourClusterPassword
vault_ontap_https:    true
vault_ontap_validate_certs: false   # true in production
```

Reference in playbooks:

```yaml
vars:
  hostname:       "{{ vault_ontap_hostname }}"
  username:       "{{ vault_ontap_username }}"
  password:       "{{ vault_ontap_password }}"
  https:          "{{ vault_ontap_https }}"
  validate_certs: "{{ vault_ontap_validate_certs }}"
```

---

## Inventory Setup

ONTAP playbooks run from **localhost** using `connection: local` — the collection communicates with ONTAP directly via HTTPS/REST.

```ini
# inventory/hosts.ini
[localhost]
localhost ansible_connection=local
```

---

## Playbooks in This Folder

| Location | Description |
|---|---|
| `ONTAP-Learning/` | Step-by-step learning lab playbooks (modules 03–08) |
| `ONTAP-Learning/03-understanding playbooks/` | Sample playbook structure walkthrough |
| `ONTAP-Learning/04-First Playbook Example/` | First volume provisioning playbook |
| `ONTAP-Learning/05-Complete Workflow/` | End-to-end SVM + volume workflow |
| `ONTAP-Learning/06-Just the Facts/` | Fact gathering and reporting playbooks |
| `ONTAP-Learning/07-Ansible Vault/` | Vault encryption patterns for ONTAP |
| `ONTAP-Learning/08-Ansible Roles for ONTAP/` | Role-based cluster setup |

---

## How to Run

### Learning Lab Playbooks

```bash
# Navigate to a specific learning module
cd ONTAP-Learning/04-First\ Playbook\ Example/

# Syntax check
ansible-playbook volume.yml --syntax-check

# Run with vault prompt
ansible-playbook volume.yml --ask-vault-pass

# Run with vault password file
ansible-playbook volume.yml --vault-password-file ~/.vault_pass

# Check mode (dry run — no changes)
ansible-playbook volume.yml --check --ask-vault-pass
```

### Example — Create a 20GB Volume

```bash
cd ONTAP-Learning/04-First\ Playbook\ Example/
ansible-playbook volume-20gb.yml --ask-vault-pass
```

### Full Cluster Setup (Role-Based)

```bash
cd ONTAP-Learning/08-Ansible\ Roles\ for\ ONTAP/
ansible-playbook cluster-setup.yml --ask-vault-pass
```

---

## Common netapp.ontap Module Reference

```yaml
# Create an SVM
- name: Create SVM
  netapp.ontap.na_ontap_svm:
    state: present
    name: svm01
    root_volume: svm01_root
    hostname: "{{ hostname }}"
    username: "{{ username }}"
    password: "{{ password }}"

# Create a volume
- name: Create volume
  netapp.ontap.na_ontap_volume:
    state: present
    name: vol01
    vserver: svm01
    size: 100
    size_unit: gb
    hostname: "{{ hostname }}"
    username: "{{ username }}"
    password: "{{ password }}"
```

---

## Lint and Validation

```bash
pip install ansible-lint

ansible-lint ONTAP-Learning/04-First\ Playbook\ Example/volume.yml
```

---

## References

- [netapp.ontap on Ansible Galaxy](https://galaxy.ansible.com/netapp/ontap)
- [netapp.ontap GitHub](https://github.com/ansible-collections/netapp.ontap)
- [netapp-lib on PyPI](https://pypi.org/project/netapp-lib/)
- [ONTAP Ansible Collection Documentation](https://docs.netapp.com/us-en/ansible-ontap/)
