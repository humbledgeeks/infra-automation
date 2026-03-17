# infra-automation

A collection of automation scripts and playbooks for VMware, NetApp, Cisco, HPE, Veeam, and Linux infrastructure management. Scripts are organized by **technology domain** first, then by **tool** (PowerShell or Ansible) within each domain.

---

## Vendor Overview

| Folder | Description |
|--------|-------------|
| [VMware/](./VMware) | ESXi, vCenter, NSX, vSAN — PowerShell and Ansible |
| [NetApp/](./NetApp) | ONTAP and StorageGRID — PowerShell and Ansible |
| [Cisco/](./Cisco) | UCS Manager and Intersight — PowerShell and Ansible |
| [HPE/](./HPE) | Synergy / OneView (composable) and ProLiant / iLO (compute) — PowerShell and Ansible |
| [Veeam/](./Veeam) | VBR job status and backup repository reporting — PowerShell and Ansible |
| [NUCLab/](./NUCLab) | End-to-end NUC homelab builder — Ansible |
| [Linux/](./Linux) | Ubuntu and Synology — Shell scripts |

---

## VMware

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [VMware/ESXi/PowerShell/Hardening](./VMware/ESXi/PowerShell/Hardening) | PowerShell | Security hardening advanced settings — V4 (menu/dry-run) and V6h (current, verify+fallback) |
| [VMware/ESXi/PowerShell/Host-Config](./VMware/ESXi/PowerShell/Host-Config) | PowerShell | Full host setup: NTP, DNS, vSwitch layout, NFS/iSCSI vmk, scratch location, config backup |
| [VMware/ESXi/PowerShell/NFS](./VMware/ESXi/PowerShell/NFS) | PowerShell | NetApp NFS best-practice settings and VAAI VIB installation |
| [VMware/ESXi/Ansible/Humbled](./VMware/ESXi/Ansible/Humbled) | Ansible | HumbledGeeks lab — ESXi config, DC deploy, vCenter config (single-host and cluster variants) |
| [VMware/ESXi/Ansible/HDC](./VMware/ESXi/Ansible/HDC) | Ansible | Hybrid Data Center lab — ESXi host configuration playbooks |
| [VMware/vCenter/PowerShell](./VMware/vCenter/PowerShell) | PowerShell | VM deployment, snapshot restore, Ubuntu deploy |
| [VMware/vCenter/PowerShell/vLab](./VMware/vCenter/PowerShell/vLab) | PowerShell | vLab management suite — menu, session, credentials, CMDB descriptions (30+ scripts) |
| [VMware/vCenter/Ansible](./VMware/vCenter/Ansible) | Ansible | vCenter inventory gathering — clusters, hosts, and VMs via community.vmware |
| [VMware/NSX/PowerShell](./VMware/NSX/PowerShell) | PowerShell | NSX-T segment inventory via Policy REST API |
| [VMware/NSX/Ansible](./VMware/NSX/Ansible) | Ansible | NSX-T segment gathering via uri module (no collection required) |
| [VMware/vSAN/PowerShell](./VMware/vSAN/PowerShell) | PowerShell | vSAN cluster health, disk group inventory, and capacity reporting |
| [VMware/vSAN/Ansible](./VMware/vSAN/Ansible) | Ansible | vSAN cluster info and datastore capacity via community.vmware |

---

## NetApp

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [NetApp/ONTAP/PowerShell](./NetApp/ONTAP/PowerShell) | PowerShell | Cluster setup, NFS plugin installation, disk serial references |
| [NetApp/ONTAP/Ansible/ONTAP-Learning](./NetApp/ONTAP/Ansible/ONTAP-Learning) | Ansible | Step-by-step Ansible for NetApp ONTAP tutorial series (modules 03–08) |
| [NetApp/StorageGRID/PowerShell](./NetApp/StorageGRID/PowerShell) | PowerShell | StorageGRID grid info via Redfish REST API |
| [NetApp/StorageGRID/Ansible](./NetApp/StorageGRID/Ansible) | Ansible | StorageGRID grid inventory via uri module |

---

## Cisco

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [Cisco/UCS/PowerShell](./Cisco/UCS/PowerShell) | PowerShell | UCS chassis, blade, and service profile inventory via Cisco.UCSManager |
| [Cisco/UCS/Ansible](./Cisco/UCS/Ansible) | Ansible | UCS server and service profile gathering via cisco.ucs collection |

---

## HPE

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [HPE/Synergy/PowerShell](./HPE/Synergy/PowerShell) | PowerShell | Synergy enclosure health, compute modules, and profile compliance via HPEOneView |
| [HPE/Synergy/Ansible](./HPE/Synergy/Ansible) | Ansible | Synergy enclosure and server profile inventory via hpe.oneview collection |
| [HPE/Compute/PowerShell](./HPE/Compute/PowerShell) | PowerShell | ProLiant iLO health — CPU, memory, storage, fans, PSUs, firmware via HPEiLOCmdlets |
| [HPE/Compute/Ansible](./HPE/Compute/Ansible) | Ansible | ProLiant iLO health via Redfish REST API (uri module — no collection required) |

---

## Veeam

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [Veeam/PowerShell](./Veeam/PowerShell) | PowerShell | VBR job status, session history, and repository capacity via VeeamPSSnapin |
| [Veeam/Ansible](./Veeam/Ansible) | Ansible | VBR job status and session reporting via Veeam REST API (OAuth2, uri module) |

---

## NUCLab

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [NUCLab/Ansible](./NUCLab/Ansible) | Ansible | Full NUC lab build: ESXi → DC → vCenter → OTS → Integration → Portal (playbooks 00–06) |

---

## Linux

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [Linux/Ubuntu/Shell](./Linux/Ubuntu/Shell) | Shell | Ubuntu server setup, Docker installation, and Docker Compose configs |
| [Linux/Synology/Shell](./Linux/Synology/Shell) | Shell | Synology NAS backup and sync scripts |

---

## Agents & Slash Commands

This repo includes Claude Code agents for each vendor. In VS Code with Claude Code, type `/` to access:

| Command | Purpose |
|---------|---------|
| `/vmware-sme` | VMware SME — vSphere, vSAN, NSX, vCenter automation |
| `/netapp-sme` | NetApp SME — ONTAP and StorageGRID automation |
| `/cisco-sme` | Cisco SME — UCS Manager and Intersight automation |
| `/hpe-sme` | HPE SME — Synergy/OneView and ProLiant/iLO automation |
| `/veeam-sme` | Veeam SME — backup jobs, repositories, recovery |
| `/health-check` | Audit the repo for credentials, missing headers, naming violations |
| `/script-polish` | Tidy up an existing script — adds headers, fixes naming, removes hardcoded creds |
| `/script-validate` | Syntax check, static analysis, auto-fix loop |
| `/runbook-gen` | Generate an operational runbook from a script |
| `/infra-orchestrate` | Multi-vendor workflow orchestration |
| `/change-report` | Analyse a script in dry-run mode and produce a CAB-ready pre-change report |
| `/onboard-vendor` | Scaffold complete folder structure, READMEs, and SME agent for a new vendor |
| `/incident-triage` | Structured triage guide for live infrastructure incidents |
| `/report-gen` | Generate professional reports (Markdown, Word, HTML) from script output or repo data |

See [`.claude/commands/README.md`](./.claude/commands/README.md) for full documentation and workflow examples.

---

## Prerequisites by Vendor

| Vendor | PowerShell Module | Ansible Collection | Python Library |
|--------|------------------|-------------------|----------------|
| VMware | `VMware.PowerCLI` | `community.vmware` | `PyVmomi` |
| NetApp ONTAP | `NetApp.ONTAP` | `netapp.ontap` | `netapp-lib` |
| NetApp StorageGRID | *(none — REST API)* | *(none — uri module)* | — |
| Cisco UCS | `Cisco.UCSManager` | `cisco.ucs` | `ucsmsdk` |
| HPE Synergy | `HPEOneView.800+` | `hpe.oneview` | `hpeOneView` |
| HPE Compute | `HPEiLOCmdlets` | *(none — Redfish/uri)* | — |
| Veeam | VeeamPSSnapin *(Windows only)* | *(none — REST API/uri)* | — |

---

## VS Code

Open this repo in VS Code — recommended extensions will be suggested automatically (`.vscode/extensions.json`). Key extensions: `redhat.ansible`, `ms-vscode.powershell`, `redhat.vscode-yaml`.

## Contributing & Documentation

| Document | Purpose |
|----------|---------|
| [`CONTRIBUTING.md`](./CONTRIBUTING.md) | Folder structure rules, header standards, naming conventions, PR process |
| [`CHANGELOG.md`](./CHANGELOG.md) | Version history — what changed and when |
| [`SECURITY.md`](./SECURITY.md) | Credential policy, how to report security issues, what to do if a secret is committed |

Place scripts in the appropriate `Vendor/Component/Tool/` subfolder. All scripts must include:
- PowerShell: `.SYNOPSIS`, `.DESCRIPTION`, `.NOTES` (Author, Date, Version, Module, Repo)
- Ansible: header comment block with Playbook, Description, Author, Date, Version, Collection, Repo
- No hardcoded credentials — use `Get-Credential` / `Import-Clixml` (PowerShell) or Ansible Vault
