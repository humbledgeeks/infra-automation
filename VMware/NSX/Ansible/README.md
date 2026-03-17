# VMware NSX — Ansible

Ansible playbooks for VMware NSX-T automation. Playbooks use the **`uri` module** for direct REST API calls against the NSX-T Policy API. The **`vmware.ansible_for_nsxt`** collection is also supported for module-based workflows.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| Python | 3.9 | 3.11+ |
| Ansible | 2.14 | 2.17+ |
| NSX-T | 3.x | 4.x (latest) |
| OS | Linux / macOS / WSL2 | Ubuntu 22.04 LTS |
| Network | HTTPS to NSX Manager port 443 | — |

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

### Step 4 — (Optional) Install the NSX-T Ansible collection

Provides dedicated NSX-T modules as an alternative to raw REST calls via `uri`:

```bash
ansible-galaxy collection install vmware.ansible_for_nsxt

# Required Python dependency for collection-based playbooks
pip install PyVmomi

# Verify
ansible-galaxy collection list | grep vmware.ansible_for_nsxt
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
vault_nsx_manager:  nsx-manager.lab.local
vault_nsx_username: admin
vault_nsx_password: YourNSXPassword
```

```bash
# Edit vault later
ansible-vault edit group_vars/all/vault.yml
```

Reference in playbooks:

```yaml
vars:
  nsx_manager:  "{{ vault_nsx_manager }}"
  nsx_username: "{{ vault_nsx_username }}"
  nsx_password: "{{ vault_nsx_password }}"
```

---

## Inventory Setup

NSX playbooks run from **localhost** using `connection: local` — all API calls go directly to the NSX Manager via HTTPS.

```ini
# inventory/hosts.ini
[localhost]
localhost ansible_connection=local
```

---

## Playbooks in This Folder

| Playbook | Description |
|---|---|
| `nsx-gather-segments.yml` | Queries NSX-T Policy API for segments and Tier-1 gateways using `uri` module; ends with assertion validation |

---

## How to Run

### nsx-gather-segments.yml

Retrieves NSX-T segment and Tier-1 gateway inventory via the Policy REST API.

```bash
# Syntax check (no execution)
ansible-playbook nsx-gather-segments.yml --syntax-check

# Run with vault password prompt
ansible-playbook nsx-gather-segments.yml --ask-vault-pass

# Run with vault password file
ansible-playbook nsx-gather-segments.yml --vault-password-file ~/.vault_pass

# Verbose output for troubleshooting
ansible-playbook nsx-gather-segments.yml -vvv --ask-vault-pass
```

---

## NSX-T Collection Module Reference (vmware.ansible_for_nsxt)

```yaml
- nsxt_policy_segment               # Segment (logical switch) management
- nsxt_policy_tier0_interface       # Tier-0 gateway interface config
- nsxt_policy_tier1                 # Tier-1 gateway management
- nsxt_policy_group                 # Security group management
- nsxt_policy_security_policy       # Distributed Firewall policies
- nsxt_policy_gateway_policy        # Gateway firewall policies
```

Example collection-based usage:

```yaml
- name: Create NSX-T segment
  vmware.ansible_for_nsxt.nsxt_policy_segment:
    hostname:       "{{ nsx_manager }}"
    username:       "{{ nsx_username }}"
    password:       "{{ nsx_password }}"
    validate_certs: false
    display_name:   "web-tier-segment"
    state:          present
```

---

## Lint and Validation

```bash
pip install ansible-lint

ansible-lint nsx-gather-segments.yml
ansible-playbook nsx-gather-segments.yml --syntax-check
```

---

## References

- [vmware.ansible_for_nsxt on Ansible Galaxy](https://galaxy.ansible.com/vmware/ansible_for_nsxt)
- [vmware.ansible_for_nsxt GitHub](https://github.com/vmware/ansible-for-nsxt)
- [NSX-T Policy API Documentation](https://developer.vmware.com/apis/nsx-t)
- [Ansible uri module documentation](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)
