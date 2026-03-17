# NUCLab Domain — Context

This folder contains Ansible playbooks for automating the Intel NUC home lab environment.

Refer to the top-level `CLAUDE.md` for full role definition, coding standards, and core philosophy. This file provides NUCLab-specific context.

---

## Folder Structure

```
NUCLab/
└── Ansible/
    └── unattend/    - Unattended / automated deployment playbooks
```

---

## Environment Context

The NUCLab is an **Intel NUC-based home lab** used for learning, development, and testing infrastructure automation. It runs a nested virtualization stack and supports configurations that would not be permitted in production environments.

### Lab Stack (typical)

- **Hypervisor**: VMware ESXi (nested capable) on NUC hardware
- **Management**: vCenter Server deployed as VM
- **Storage**: Local datastore and/or NFS from Synology NAS (`Linux/Synology/`)
- **Networking**: Simple flat or VLAN-segmented home network
- **Automation Control Node**: Ubuntu VM or direct from Mac running Ansible

### Lab Policies

- **Nested virtualization is acceptable** in this environment
- **Unsupported configurations may be used** for learning purposes
- Credentials for the lab should still use **Ansible Vault** for good habits
- Lab is separate from any production systems

---

## Ansible Context

### Inventory Pattern

```ini
# inventory/hosts
[esxi_hosts]
nuc01.lab.local
nuc02.lab.local

[vcenter]
vcenter.lab.local

[linux]
ubuntu01.lab.local
```

### Unattended Deployment Playbooks

The `Ansible/unattend/` directory contains numbered playbooks following the NUCLab deployment workflow (mirrors the NUCLab build order):

| Playbook | Purpose |
|----------|---------|
| `00_MainInstaller.yml` | Master installer — calls sub-playbooks in order |
| `01_ESXi_Config.yml` | ESXi host baseline configuration |
| `02_DC_Config.yml` / `02_DC_Deploy.yml` | Domain controller deploy + config |
| `03_VC_Config.yml` / `03_VC_Deploy.yml` | vCenter deploy + config |
| `04_OTS_Configure.yml` / `04_OTS_Deploy.yml` | OTS (Object/Target Storage) deploy + config |
| `05_Integration.yml` | Platform integration tasks |
| `06_Portal.yml` | Portal / dashboard deployment |

### Variable Files

- `vars.yml` — main variable file (do not commit with real credentials)
- `vars.hl2.yml` — environment-specific overrides
- `vcenter-properties.yml` — vCenter deployment properties
- `unattend/unattend` — OS unattend configuration files

### Running the Lab Installer

```bash
# Full lab build
ansible-playbook 00_MainInstaller.yml -i inventory/hosts --ask-vault-pass

# Single component
ansible-playbook 03_VC_Deploy.yml -i inventory/hosts --ask-vault-pass

# Dry run (check mode)
ansible-playbook 01_ESXi_Config.yml -i inventory/hosts --check --ask-vault-pass
```

---

## NUCLab Best Practices

- Always use **Ansible Vault** for credentials even in the lab — builds good production habits
- Use `vars.yml` for environment variables; never hardcode IPs or passwords in playbooks
- Run `--check` mode before executing destructive playbooks
- Tag plays for selective execution: `ansible-playbook site.yml --tags "network"`
- Document lab IP addressing and hostname scheme in a `README.md` per major subdirectory
- Keep playbooks **idempotent** — re-running should produce the same result without errors

---

## Validation Commands

```bash
# Ansible connectivity test
ansible all -i inventory/hosts -m ping

# Gather facts from ESXi hosts
ansible esxi_hosts -i inventory/hosts -m gather_facts

# Check playbook syntax
ansible-playbook 00_MainInstaller.yml --syntax-check

# List tasks in a playbook
ansible-playbook 01_ESXi_Config.yml --list-tasks
```
