# VMware ESXi Ansible — Humbled Lab

Ansible playbooks for configuring ESXi hosts and vCenter in the **Humbled Lab** (humbledgeeks home lab) environment.

See the parent [VMware/ESXi/Ansible/README.md](../README.md) for prerequisites, collection install, and credential setup.

---

## Playbook Order

Run playbooks in numbered order for a fresh environment build:

| Order | Playbook | Description |
|---|---|---|
| 1 | `01_ESXi_Config.yml` | Configure all ESXi hosts (NTP, DNS, hardening, networking) |
| 1a | `01_ESXi_Config_Single.yml` | Same as above — targets a single host only |
| 1b | `01_ESXi_Config_Inventory.yml` | ESXi config using dynamic inventory |
| 2 | `02_DC_Deploy.yml` | Create datacenter and cluster objects in vCenter |
| 3 | `03_VC_Config.yml` | Apply vCenter settings and permissions |

---

## Quick Start

```bash
# Configure a single ESXi host
ansible-playbook 01_ESXi_Config_Single.yml --ask-vault-pass

# Full environment build
ansible-playbook 01_ESXi_Config.yml --ask-vault-pass
ansible-playbook 02_DC_Deploy.yml --ask-vault-pass
ansible-playbook 03_VC_Config.yml --ask-vault-pass
```

---

## Vars

Edit `vcenter-properties.yml` and `vars.yml` with your lab-specific values (vCenter FQDN, datacenter name, cluster name, NTP/DNS servers) before running any playbooks.
