# NUCLab — Ansible

Ansible playbooks for building and configuring the Intel NUC home lab environment. These playbooks automate ESXi configuration, vCenter deployment, domain controller setup, OTS deployment, and lab integration using the **`community.vmware`** collection.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Python | 3.9 | 3.11+ |
| Ansible | 2.14 | 2.17+ |
| OS | Linux / macOS / WSL2 | Ubuntu 22.04 LTS |
| vCenter | 7.0 | 8.0+ |

---

## Installation

### Step 1 — Install Python 3 and pip

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

### Step 4 — Install required collections

```bash
# VMware community collection (core of NUCLab playbooks)
ansible-galaxy collection install community.vmware

# Community general (used in some helper tasks)
ansible-galaxy collection install community.general

# Verify
ansible-galaxy collection list | grep -E "community\.(vmware|general)"
```

### Step 5 — Install Python dependencies for community.vmware

```bash
pip install PyVmomi requests

# Verify
python3 -c "import pyVmomi; print('PyVmomi OK')"
```

---

## Credential Setup — Ansible Vault

**Never store passwords in plain text.** All credentials should be Ansible Vault encrypted.

```bash
# Create vault file
ansible-vault create group_vars/all/vault.yml
```

Inside `vault.yml`:

```yaml
vault_vcenter_hostname: vcenter.lab.local
vault_vcenter_username: administrator@vsphere.local
vault_vcenter_password: YourPasswordHere
vault_esxi_password:    ESXiRootPassword
vault_domain_admin_password: DomainAdminPass
```

```bash
# Edit an existing vault
ansible-vault edit group_vars/all/vault.yml

# Encrypt a plain-text vars file
ansible-vault encrypt vars.yml
```

---

## Inventory Setup

NUCLab playbooks may use direct ESXi host connections for initial bootstrapping and localhost for vCenter API tasks.

```ini
# inventory/hosts.ini

[localhost]
localhost ansible_connection=local

[esxi_hosts]
nuc01.lab.local ansible_user=root ansible_password={{ vault_esxi_password }}
nuc02.lab.local ansible_user=root ansible_password={{ vault_esxi_password }}
nuc03.lab.local ansible_user=root ansible_password={{ vault_esxi_password }}
```

---

## Playbooks in This Folder

| Playbook | Order | Description |
|---|---|---|
| `00_MainInstaller.yml` | 1 | Master orchestrator — calls all other playbooks in sequence |
| `01_ESXi_Config.yml` | 2 | Configures ESXi hosts (NTP, DNS, SSH, VDS, storage) |
| `02_DC_Deploy.yml` | 3 | Deploys the domain controller VM |
| `02_DC_Config.yml` | 4 | Configures Active Directory, DNS, and DHCP |
| `03_VC_Deploy.yml` | 5 | Deploys the vCenter Server Appliance (VCSA) |
| `03_VC_Config.yml` | 6 | Configures vCenter clusters, permissions, and settings |
| `04_OTS_Deploy.yml` | 7 | Deploys OTS (Operations Tools Server) VM |
| `04_OTS_Configure.yml` | 8 | Configures OTS post-deployment |
| `05_Integration.yml` | 9 | Integrates components (AD join, vCenter registration) |
| `06_Portal.yml` | 10 | Deploys and configures the lab portal |
| `vars.yml` | — | Lab variables (non-sensitive) |
| `vars.hl2.yml` | — | Hardware Lab 2 variant variables |
| `vcenter-properties.yml` | — | vCenter configuration properties |

---

## How to Run

### Full Lab Build (recommended starting point)

```bash
# Syntax check all playbooks
ansible-playbook 00_MainInstaller.yml --syntax-check

# Dry run — see what would change
ansible-playbook 00_MainInstaller.yml --check --ask-vault-pass

# Full lab build
ansible-playbook 00_MainInstaller.yml --ask-vault-pass

# With vault password file
ansible-playbook 00_MainInstaller.yml --vault-password-file ~/.vault_pass
```

### Run Individual Stages

```bash
# Configure ESXi hosts only
ansible-playbook 01_ESXi_Config.yml --ask-vault-pass

# Deploy vCenter only
ansible-playbook 03_VC_Deploy.yml --ask-vault-pass

# Run from a specific playbook (skip earlier stages)
ansible-playbook 03_VC_Config.yml --ask-vault-pass
```

### Verbose Output and Debugging

```bash
# Verbose (one level)
ansible-playbook 01_ESXi_Config.yml -v --ask-vault-pass

# Very verbose (shows module return values)
ansible-playbook 01_ESXi_Config.yml -vvv --ask-vault-pass

# Run specific tags (if defined in playbooks)
ansible-playbook 01_ESXi_Config.yml --tags "ntp,dns" --ask-vault-pass
```

---

## Lint and Validation

```bash
pip install ansible-lint

# Lint a single playbook
ansible-lint 01_ESXi_Config.yml

# Lint all playbooks
ansible-lint *.yml
```

---

## References

- [community.vmware on Ansible Galaxy](https://galaxy.ansible.com/community/vmware)
- [community.vmware GitHub](https://github.com/ansible-collections/community.vmware)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/vault_guide/index.html)
- [PyVmomi on PyPI](https://pypi.org/project/PyVmomi/)
