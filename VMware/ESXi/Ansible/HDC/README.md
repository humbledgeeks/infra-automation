# VMware ESXi Ansible — HDC (Hybrid Data Center)

Ansible playbooks for configuring ESXi hosts in the **HDC (Hybrid Data Center)** lab environment.

See the parent [VMware/ESXi/Ansible/README.md](../README.md) for prerequisites, collection install, and credential setup.

---

## Scripts in This Folder

| Playbook | Description |
|---|---|
| `01_ESXi_Config.yml` | Configure ESXi hosts: NTP, DNS, hardening, and networking in the HDC lab |

---

## Quick Start

```bash
ansible-playbook 01_ESXi_Config.yml --ask-vault-pass
```

---

## Vars

Edit `vars.yml` to set HDC-specific values (vCenter FQDN, cluster name, NTP/DNS servers, etc.) before running playbooks.
