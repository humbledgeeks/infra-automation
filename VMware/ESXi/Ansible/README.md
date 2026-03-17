# VMware ESXi — Ansible

Ansible playbooks for ESXi host configuration, vCenter deployment, and lab infrastructure setup using the **`community.vmware`** collection.

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
vault_esxi_root_password: ESXiRootPass
```

```bash
# Edit vault
ansible-vault edit group_vars/all/vault.yml
```

---

## Inventory Setup

Most ESXi playbooks run from **localhost** using `connection: local`. For direct ESXi host tasks (pre-vCenter bootstrapping), add hosts to inventory:

```ini
# inventory/hosts.ini

[localhost]
localhost ansible_connection=local

[esxi_hosts]
esxi01.lab.local ansible_user=root ansible_password={{ vault_esxi_root_password }} ansible_connection=ssh
esxi02.lab.local ansible_user=root ansible_password={{ vault_esxi_root_password }} ansible_connection=ssh
```

---

## Playbooks in This Folder

### HDC/ (Home Data Center)

| Playbook | Description |
|---|---|
| `HDC/01_ESXi_Config.yml` | Configures ESXi hosts for the HDC environment |
| `HDC/vars.yml` | HDC-specific variable definitions |

### Humbled/ (Lab Environment)

| Playbook | Description |
|---|---|
| `Humbled/01_ESXi_Config.yml` | Full ESXi host configuration (NTP, DNS, SSH, VDS, storage) |
| `Humbled/01_ESXi_Config_Inventory.yml` | Inventory-only version for multiple hosts |
| `Humbled/01_ESXi_Config_Single.yml` | Targeted single-host configuration |
| `Humbled/02_DC_Deploy.yml` | Deploys domain controller VM |
| `Humbled/03_VC_Config.yml` | Configures vCenter post-deployment |
| `Humbled/vars.yml` | Lab variable definitions |
| `Humbled/vcenter-properties.yml` | vCenter property settings |

---

## How to Run

### Full ESXi Host Configuration

```bash
# Syntax check first
ansible-playbook Humbled/01_ESXi_Config.yml --syntax-check

# Run with vault password prompt
ansible-playbook Humbled/01_ESXi_Config.yml --ask-vault-pass

# Run with vault password file
ansible-playbook Humbled/01_ESXi_Config.yml --vault-password-file ~/.vault_pass

# Target a specific host
ansible-playbook Humbled/01_ESXi_Config.yml --limit esxi01.lab.local --ask-vault-pass

# Dry run — check mode
ansible-playbook Humbled/01_ESXi_Config.yml --check --ask-vault-pass

# Verbose output
ansible-playbook Humbled/01_ESXi_Config.yml -vvv --ask-vault-pass
```

### HDC Environment

```bash
ansible-playbook HDC/01_ESXi_Config.yml --ask-vault-pass
```

---

## Key community.vmware ESXi Module Reference

```yaml
# ESXi host configuration
- community.vmware.vmware_host_config_manager    # Advanced settings
- community.vmware.vmware_host_ntp               # NTP server configuration
- community.vmware.vmware_host_dns               # DNS configuration
- community.vmware.vmware_host_service           # Service management (SSH, etc.)
- community.vmware.vmware_host_vmhba_info        # HBA/storage adapter info
- community.vmware.vmware_host_iscsi             # iSCSI adapter configuration

# Networking
- community.vmware.vmware_vswitch                # Standard vSwitch
- community.vmware.vmware_portgroup              # Standard switch port groups
- community.vmware.vmware_dvswitch               # Distributed vSwitch
- community.vmware.vmware_dvs_portgroup          # Distributed port groups

# Datastores
- community.vmware.vmware_host_datastore         # NFS/VMFS datastore management
```

---

## Lint and Validation

```bash
pip install ansible-lint

ansible-lint Humbled/01_ESXi_Config.yml
ansible-playbook Humbled/01_ESXi_Config.yml --syntax-check
```

---

## References

- [community.vmware on Ansible Galaxy](https://galaxy.ansible.com/community/vmware)
- [community.vmware GitHub](https://github.com/ansible-collections/community.vmware)
- [community.vmware Module Index](https://docs.ansible.com/ansible/latest/collections/community/vmware/index.html)
- [PyVmomi on PyPI](https://pypi.org/project/PyVmomi/)
