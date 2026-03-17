# VMware vSAN — Ansible

Ansible playbooks for vSAN cluster configuration and reporting using the **`community.vmware`** collection. This collection includes modules for enabling vSAN, managing storage policies, and gathering datastore facts.

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
```

### Step 2 — Create a virtual environment

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

# Verify
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

vSAN playbooks run from **localhost** using `connection: local`.

```ini
# inventory/hosts.ini
[localhost]
localhost ansible_connection=local
```

---

## Playbooks in This Folder

| Playbook | Description |
|---|---|
| `vsan-cluster-info.yml` | Gathers vSAN cluster configuration, datastore capacity in GB; ends with assertion validation |

---

## How to Run

### vsan-cluster-info.yml

Connects to vCenter and returns vSAN cluster status and datastore capacity.

```bash
# Syntax check first
ansible-playbook vsan-cluster-info.yml --syntax-check

# Run with vault password prompt
ansible-playbook vsan-cluster-info.yml --ask-vault-pass

# Run with vault password file
ansible-playbook vsan-cluster-info.yml --vault-password-file ~/.vault_pass

# Check mode (dry run)
ansible-playbook vsan-cluster-info.yml --check --ask-vault-pass

# Verbose output
ansible-playbook vsan-cluster-info.yml -vvv --ask-vault-pass
```

---

## Key community.vmware vSAN Module Reference

```yaml
# Enable vSAN on a cluster
- community.vmware.vmware_cluster_vsan:
    hostname:         "{{ vcenter_hostname }}"
    username:         "{{ vcenter_username }}"
    password:         "{{ vcenter_password }}"
    datacenter_name:  "DC-Primary"
    cluster_name:     "Cluster-01"
    enable:           true
    validate_certs:   false

# Get vSAN cluster info
- community.vmware.vmware_vsan_cluster

# Get datastore info (filter by type: vsan)
- community.vmware.vmware_datastore_info

# Manage storage policies
- community.vmware.vmware_vm_storage_policy
- community.vmware.vmware_spbm_tag_policy
```

---

## Lint and Validation

```bash
pip install ansible-lint

ansible-lint vsan-cluster-info.yml
ansible-playbook vsan-cluster-info.yml --syntax-check
```

---

## References

- [community.vmware on Ansible Galaxy](https://galaxy.ansible.com/community/vmware)
- [community.vmware GitHub](https://github.com/ansible-collections/community.vmware)
- [vmware_cluster_vsan module docs](https://docs.ansible.com/ansible/latest/collections/community/vmware/vmware_cluster_vsan_module.html)
- [VMware vSAN Documentation](https://docs.vmware.com/en/VMware-vSAN/index.html)
