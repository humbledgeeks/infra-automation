# Changelog

All notable changes to the infra-automation repo are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### In Progress
- Script clean-up pass across all vendors (headers, credential pattern, naming)

---

## [2.0.0] — 2026-03-16

### Added — Claude Code Agents & Skills
- **15 Claude Code slash commands** in `.claude/commands/`:
  - Vendor SME agents: `/vmware-sme`, `/netapp-sme`, `/hpe-sme`, `/veeam-sme`, `/cisco-sme`
  - Utility agents: `/health-check`, `/script-polish`, `/script-validate`, `/runbook-gen`, `/infra-orchestrate`
  - Operational skills: `/change-report`, `/onboard-vendor`, `/incident-triage`, `/report-gen`
  - Subagents: `/_sub-credential-scan`, `/_sub-script-validate`, `/_sub-ansible-lint`, `/_sub-doc-gen`, `/_sub-fix-errors`, `/_sub-version-check`
- **CI/CD pipeline** (`.github/workflows/lint.yml`) — PSScriptAnalyzer, ansible-lint, credential scan, header compliance
- **CONTRIBUTING.md**, **CHANGELOG.md**, **SECURITY.md** — standard repo documentation
- **9 CLAUDE.md context files** (root + per-vendor) providing Claude Code SME context

### Added — HPE Vendor Support
- `HPE/Synergy/PowerShell/` — HPEOneView.800 scripts and README
- `HPE/Synergy/Ansible/` — hpe.oneview collection playbooks and README
- `HPE/Compute/PowerShell/` — HPEiLOCmdlets scripts and README
- `HPE/Compute/Ansible/` — Redfish REST API playbooks and README

### Added — Veeam Vendor Support
- `Veeam/PowerShell/` — VBR PowerShell automation
- `Veeam/Ansible/` — VBR REST API playbooks

### Added — Documentation Coverage
- 47 README.md files across all vendor and tool subfolders
- Every folder with scripts now has a README with prerequisites, authentication, and examples

### Changed
- **Removed duplicate scripts**: `Configure_ESX_Hosts.ps1` (superseded by v2), `ESXI_NFS_BestPractices.ps1` (superseded by V4)
- **Removed ChatGPT attributions** from all script headers — standardised to "HumbledGeeks / Allen Johnson"
- **Fixed 56 PowerShell script headers** — all scripts now have `.SYNOPSIS` / `.NOTES` blocks
- **Fixed 38 Ansible playbook headers** — all playbooks now have the standard `# ===` comment block
- **Renamed**: `script-migrate` → `/script-polish`, `script-test` → `/script-validate`
- **Updated** top-level README.md with HPE, Veeam, agents table, and prerequisites table

---

## [1.0.0] — 2025-07-01

### Added
- Initial repository structure across VMware, NetApp, Cisco, NUCLab, Linux vendors
- VMware ESXi PowerShell scripts: hardening (V4/V6h), NFS best practices (V4), host configuration
- NetApp ONTAP Ansible learning series (00–08 modules)
- NUCLab Ansible automation suite (00–06 + portal playbooks)
- VMware vCenter PowerShell vLab automation framework
- Cisco UCS PowerShell and Ansible scripts

---

## Version History Summary

| Version | Date | Highlights |
|---------|------|-----------|
| 2.0.0 | 2026-03-16 | Claude Code agents, CI/CD, HPE/Veeam support, full documentation pass |
| 1.0.0 | 2025-07-01 | Initial repo — VMware, NetApp, Cisco, NUCLab |
