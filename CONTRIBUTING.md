# Contributing to infra-automation

Thank you for contributing to the HumbledGeeks infra-automation repo. This guide covers standards for scripts, playbooks, documentation, and the review process.

---

## Table of Contents

- [Getting Started](#getting-started)
- [Folder Structure](#folder-structure)
- [PowerShell Standards](#powershell-standards)
- [Ansible Standards](#ansible-standards)
- [Documentation Standards](#documentation-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Using Claude Code Agents](#using-claude-code-agents)

---

## Getting Started

1. Clone the repo and create a branch from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
2. Make your changes following the standards below
3. Run validation before committing (see [Validation](#validation))
4. Open a pull request against `main`

---

## Folder Structure

Scripts must be placed in the correct vendor and tool subfolder:

```
<Vendor>/<Platform>/<Tool>/
```

Examples:
- `VMware/ESXi/PowerShell/` — PowerShell scripts for VMware ESXi
- `NetApp/ONTAP/Ansible/` — Ansible playbooks for NetApp ONTAP
- `HPE/Compute/PowerShell/` — PowerShell scripts for HPE iLO servers

Use `/onboard-vendor <VendorName>` in Claude Code to scaffold a new vendor correctly.

---

## PowerShell Standards

### Required Header Block

Every `.ps1` file must begin with a comment-based help block:

```powershell
<#
.SYNOPSIS
    One-line description of what the script does.
.DESCRIPTION
    Full description of the script's purpose, what it connects to,
    and what it changes or reads.
.PARAMETER ParameterName
    Description of each parameter.
.EXAMPLE
    .\Script-Name.ps1 -Parameter Value
    Description of what this example does.
.NOTES
    Author  : HumbledGeeks / Allen Johnson
    Date    : YYYY-MM-DD
    Version : 1.0
    Module  : ModuleName (if applicable)
    Repo    : infra-automation
#>
```

### Credential Rules

- **Never hardcode passwords, API keys, or tokens**
- Use `Get-Credential` + `Export-Clixml` for interactive scripts
- Use `$env:` environment variables for CI/CD contexts
- Reference vault files for Ansible-invoked PowerShell

### Dry-Run Pattern

Scripts that make changes should support a dry-run mode:

```powershell
param(
    [switch]$DryRun
)

if ($DryRun) {
    Write-Host "🧪 DRYRUN: Would change $setting from '$current' to '$desired'" -ForegroundColor Yellow
} else {
    # Apply change
}
```

### Naming Convention

Use `verb-noun.ps1` lowercase with hyphens:
- ✅ `get-esxi-nfs-settings.ps1`
- ✅ `set-esxi-hardening.ps1`
- ❌ `ConfigureESXHosts.ps1`
- ❌ `configure_esx_hosts.ps1`

---

## Ansible Standards

### Required Header Block

Every playbook must begin with a comment header:

```yaml
---
# ============================================================
# Playbook  : playbook-name.yml
# Description: What this playbook does
# Author    : HumbledGeeks / Allen Johnson
# Date      : YYYY-MM-DD
# Version   : 1.0
# Collection: collection.name (if applicable)
# Repo      : infra-automation
# ============================================================
```

### Credential Rules

- Use `ansible-vault` for all sensitive values
- Variable naming convention: `vault_<vendor>_<field>` (e.g., `vault_ontap_password`)
- Always set `no_log: true` on tasks that use credentials
- Store vault variables in `group_vars/all/vault.yml`

### Lint Compliance

All playbooks must pass `ansible-lint` before merging. Run:
```bash
ansible-lint <playbook.yml>
```

---

## Documentation Standards

### README.md Requirements

Every folder containing scripts must have a `README.md` that includes:
- Prerequisites (module/collection install commands)
- Authentication setup
- Script/playbook inventory table
- At least one working example

Use `/_sub-doc-gen <folder-path>` in Claude Code to generate a starter README.

### Updating Existing READMEs

When adding a new script to an existing folder:
1. Add a row to the scripts table in the folder's `README.md`
2. Add an example for the new script

---

## Validation

Before opening a pull request, run these checks:

```powershell
# Validate a PowerShell script
/script-validate <path/to/script.ps1>

# Polish headers and naming on an old script
/script-polish <path/to/script.ps1>

# Run full repo health check
/health-check
```

The CI/CD pipeline (`.github/workflows/lint.yml`) will also run automatically on pull requests:
- PSScriptAnalyzer (PowerShell)
- ansible-lint (Ansible)
- Credential scan
- Header compliance check

---

## Commit Guidelines

Use clear, descriptive commit messages:

```
add: get-ilo-health.ps1 for HPE ProLiant Gen10/11 servers
fix: remove hardcoded credential from Configure_ESX_Hosts_v2.ps1
docs: add README for VMware/NSX/PowerShell
update: expand ESXi hardening script with V6h dry-run support
```

Prefixes: `add`, `fix`, `docs`, `update`, `remove`, `refactor`

---

## Pull Request Process

1. Ensure all CI/CD checks pass
2. Add a description of what the script does and which systems it targets
3. Note any hardcoded values that still need to be resolved
4. Tag the PR with the relevant vendor label (VMware, NetApp, HPE, Veeam, Cisco)

---

## Using Claude Code Agents

This repo includes Claude Code slash commands that help maintain standards:

| Task | Command |
|------|---------|
| Write a new script | `/vmware-sme`, `/netapp-sme`, `/hpe-sme`, etc. |
| Fix up an old script | `/script-polish <path>` |
| Validate a script | `/script-validate <path> --fix` |
| Generate a README | `/_sub-doc-gen <folder>` |
| Full repo audit | `/health-check` |
| Onboard a new vendor | `/onboard-vendor <VendorName>` |

See `.claude/commands/README.md` for the full command reference.
