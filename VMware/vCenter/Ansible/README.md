# VMware vCenter — Ansible

Ansible playbooks for vCenter Server automation using the **`community.vmware`** collection. Playbooks cover cluster management, ESXi host facts, VM inventory, networking, RBAC, and lifecycle operations.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Python | 3.9 | 3.11+ |
| Ansible | 2.14 | 2.17+ |
| community.vmware | 3.x | 4.x (latest) |
| vCenter / ESXi | 7.0 | 8.0+ |
| OS | Linux / macOS / WSL2 | Ubuntu 22.04 LTS |

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

### Step 4 — Install the community.vmware collection

```bash
ansible-galaxy collection install community.vmware

# Verify
ansible-galaxy collection list | grep community.vmware
```

### Step 5 — Install Python dependencies

```bash
pip install PyVmomi requests

# For vSphere Automation SDK features (optional, needed for REST-based modules)
pip install vsphere-automation-sdk-python

# Verify PyVmomi
python3 -c "import pyVmomi; print('PyVmomi OK')"
```

---

## Credential Setup — Ansible Vault

**Never store credentials in plain text.**

```bash
# Create encrypted vault file
ansible-vault create group_vars/all/vault.yml
```

Inside `vault.yml`:

```yaml
vault_vcenter_hostname: vcenter.lab.local
vault_vcenter_username: administrator@vsphere.local
vault_vcenter_password: YourVCenterPassword
```

```bash
# Edit vault later
ansible-vault edit group_vars/all/vault.yml
```

Reference in playbooks:

```yaml
vars:
  vcenter_hostname:       "{{ vault_vcenter_hostname }}"
  vcenter_username:       "{{ vault_vcenter_username }}"
  vcenter_password:       "{{ vault_vcenter_password }}"
  vcenter_validate_certs: false   # Set true in production
```

---

## Inventory Setup

vCenter playbooks run from **localhost** using `connection: local` — the `community.vmware` collection communicates with vCenter via the vSphere API.

```ini
# inventory/hosts.ini
[localhost]
localhost ansible_connection=local
```

---

## Playbooks in This Folder

| Playbook | Description |
|---|---|
| `vcenter-gather-inventory.yml` | Gathers cluster facts, ESXi host details, and VM power-state summary; ends with assertion validation |

---

## How to Run

### vcenter-gather-inventory.yml

Connects to vCenter and returns a full inventory of clusters, ESXi hosts, and VMs.

```bash
# Syntax check first
ansible-playbook vcenter-gather-inventory.yml --syntax-check

# Run with vault password prompt
ansible-playbook vcenter-gather-inventory.yml --ask-vault-pass

# Run with vault password file (CI/CD or automation)
ansible-playbook vcenter-gather-inventory.yml --vault-password-file ~/.vault_pass

# Check mode (dry run)
ansible-playbook vcenter-gather-inventory.yml --check --ask-vault-pass

# Verbose output
ansible-playbook vcenter-gather-inventory.yml -vvv --ask-vault-pass
```

---

## Useful community.vmware Module Reference

```yaml
# Cluster inventory
- community.vmware.vmware_cluster_info       # Cluster configuration and host list
- community.vmware.vmware_host_facts         # ESXi host hardware and software facts
- community.vmware.vmware_vm_facts           # VM inventory with config details

# VM lifecycle
- community.vmware.vmware_guest              # Create, clone, modify, delete VMs
- community.vmware.vmware_guest_snapshot     # Snapshot management

# Networking
- community.vmware.vmware_dvswitch           # Distributed vSwitch management
- community.vmware.vmware_dvs_portgroup      # Port group management

# RBAC
- community.vmware.vmware_role               # Custom role creation
- community.vmware.vmware_object_role_permission  # Assign roles to objects

# Tags
- community.vmware.vmware_tag               # Tag management
- community.vmware.vmware_tag_manager       # Apply/remove tags
```

---

## Lint and Validation

```bash
pip install ansible-lint

ansible-lint vcenter-gather-inventory.yml
ansible-playbook vcenter-gather-inventory.yml --syntax-check
```

---

## References

- [community.vmware on Ansible Galaxy](https://galaxy.ansible.com/community/vmware)
- [community.vmware GitHub](https://github.com/ansible-collections/community.vmware)
- [community.vmware Module Index](https://docs.ansible.com/ansible/latest/collections/community/vmware/index.html)
- [PyVmomi on PyPI](https://pypi.org/project/PyVmomi/)
