# infra-automation — Claude Code Agents & Commands

This folder contains all Claude Code slash commands (agents) for the infra-automation repository. These commands are available in VS Code when using Claude Code.

## How to use a command

In Claude Code (VS Code), type `/` followed by the command name:
```
/vmware-sme write a PowerShell script to disable SSH on all ESXi hosts
/health-check
/runbook-gen VMware/ESXi/PowerShell/Hardening/ESXi_Hardening_V6h.ps1
```

---

## Main Agents (User-Facing)

These are commands you invoke directly.

### Vendor SME Agents
| Command | Purpose | Example |
|---------|---------|---------|
| `/netapp-sme` | NetApp Storage SME — scripts, architecture, troubleshooting | `/netapp-sme create an NFS volume on prod-svm` |
| `/vmware-sme` | VMware / Broadcom SME — vSphere, vSAN, NSX, vCenter | `/vmware-sme harden all ESXi hosts` |
| `/cisco-sme` | Cisco UCS SME — UCSM, Service Profiles, Intersight | `/cisco-sme report all service profile associations` |
| `/veeam-sme` | Veeam SME — backup jobs, SOBR, recovery, reporting | `/veeam-sme check failed jobs in the last 24 hours` |
| `/hpe-sme` | HPE SME — Synergy/OneView composable infra AND ProLiant/iLO rack servers | `/hpe-sme check server profile compliance` or `/hpe-sme gather DL380 iLO health` |

### Utility Agents
| Command | Purpose | Example |
|---------|---------|---------|
| `/health-check` | Audit the repo for credentials, missing headers, naming violations, stubs | `/health-check` or `/health-check VMware` |
| `/script-polish` | Standardize an existing script to repo conventions (headers, naming, credentials) | `/script-polish VMware/ESXi/PowerShell/Host-Config/Configure_ESX_Hosts.ps1` |
| `/script-validate` | **Test any script or playbook** — syntax check, static analysis, auto-fix loop | `/script-validate VMware/ESXi/PowerShell/Host-Config/Set-ESXiNTP.ps1 --fix` |
| `/runbook-gen` | Generate an operational runbook from a script or task | `/runbook-gen NetApp/ONTAP/Ansible/ONTAP-Learning/05-Complete Workflow` |
| `/infra-orchestrate` | Multi-vendor workflow orchestration across all platforms | `/infra-orchestrate provision a new VMware cluster with NetApp storage and Veeam backup` |

### Operational Skills
| Command | Purpose | Example |
|---------|---------|---------|
| `/change-report` | Analyse a script in dry-run mode and produce a formatted pre-change report for CAB/manager review | `/change-report VMware/ESXi/PowerShell/Hardening/ESXi_Hardening_V6h.ps1` |
| `/onboard-vendor` | Scaffold the complete folder structure, READMEs, templates, and SME agent for a new vendor | `/onboard-vendor Palo Alto` or `/onboard-vendor Nutanix --platforms AHV,Prism` |
| `/incident-triage` | Guide structured triage of a live infrastructure incident — diagnoses, points to repo scripts, builds response plan | `/incident-triage ESXi host disconnected in vCenter` |
| `/report-gen` | Generate a professional report (Markdown, Word, or HTML) from health check output, change windows, or environment data | `/report-gen health VMware/ESXi/PowerShell/Hardening/` or `/report-gen environment --format docx` |

---

## Subagents (Internal Use)

> **Subagents are called BY other agents, not directly by you.** They are prefixed with `_sub-` so they're easy to identify.

You can call them directly for targeted tasks, but their primary purpose is to be invoked automatically during orchestration and validation workflows.

| Command | Called By | Purpose |
|---------|-----------|---------|
| `/_sub-credential-scan` | `/health-check`, `/infra-orchestrate`, `/script-validate` | Scan files for hardcoded passwords, tokens, API keys |
| `/_sub-script-validate` | `/health-check`, `/script-polish`, `/script-validate`, `/infra-orchestrate` | Validate a script meets all repo standards (score 0–10) |
| `/_sub-ansible-lint` | `/health-check`, `/script-validate`, all vendor SME agents | Lint and validate Ansible playbook structure and security |
| `/_sub-doc-gen` | `/infra-orchestrate`, `/script-polish` | Generate or update README.md and script header blocks |
| `/_sub-fix-errors` | `/script-validate` | Apply targeted fixes from an error list; loops until clean |
| `/_sub-version-check` | `/health-check`, `/report-gen`, all vendor SME agents | Audit module/collection versions; flag unpinned or outdated dependencies |

### When would I call a subagent directly?

If you want a focused check on a single thing:
```
# Just scan one file for credentials
/_sub-credential-scan NetApp/ONTAP/PowerShell/Install_NetAPP_NFS_Plugin.ps1

# Just lint a single Ansible playbook
/_sub-ansible-lint NetApp/ONTAP/Ansible/ONTAP-Learning/05-Complete Workflow/site.yml

# Just generate a README for one folder
/_sub-doc-gen VMware/NSX/PowerShell
```

---

## Common Workflows

### "I need a new automation script"
1. Use the relevant vendor SME agent to generate it
2. The agent validates and adds proper headers automatically
3. Save it to the appropriate subfolder:
   - `VMware/` → `/vmware-sme`
   - `NetApp/` → `/netapp-sme`
   - `Cisco/` → `/cisco-sme`
   - `Veeam/` → `/veeam-sme`
   - `HPE/Synergy/` or `HPE/Compute/` → `/hpe-sme`

### "I just wrote a script and want to make sure it's good before committing"
1. Run `/script-validate <path>` — catches syntax errors, static analysis issues, credential problems
2. Add `--fix` to auto-fix everything it finds: `/script-validate <path> --fix`
3. Review the fix summary, then commit

### "I want to fix up old scripts"
1. Run `/health-check` to find what needs attention
2. Run `/script-polish <path>` on each problem script (standardizes headers/naming)
3. Run `/script-validate <path> --fix` to catch and fix any remaining errors
4. Review the `--dry-run` output, then apply

### "I need to document this procedure"
1. Run `/runbook-gen <script-path>` to generate a runbook
2. Optionally use the `docx` skill to convert to Word format

### "I'm building something that touches multiple platforms"
1. Use `/infra-orchestrate <full description of the task>`
2. The orchestration agent breaks it into phases, applies per-vendor SME knowledge, and coordinates subagents automatically

### "I want a regular health check"
1. Run `/health-check` any time before committing
2. Address any 🔴 CRITICAL items immediately
3. Track 🟡 MODERATE items in your backlog

### "I need to prepare for a maintenance window"
1. Run `/change-report <script-path>` — shows exactly what will change, on which hosts
2. Review the proposed changes table
3. Use the generated report for CAB approval or manager sign-off
4. After the window, run `/report-gen change "maintenance window description"` to document what was done

### "Something is broken in production"
1. Run `/incident-triage <description of the problem>`
2. Follow the triage plan — the agent points you to the right scripts in this repo
3. Use `--sev 1` for critical outages to get immediate stabilisation steps first
4. After resolution: `/report-gen audit` to document the incident

### "I want to add a new vendor to the repo"
1. Run `/onboard-vendor <VendorName>` — creates all folders, READMEs, templates, and SME agent
2. Fill in the TODO placeholders in the generated script template
3. Test with `/script-validate <new-script-path>`
4. Run `/health-check <VendorName>` to confirm everything is in order

### "I need a professional report for my manager or client"
1. Run `/report-gen environment --format docx` for a full overview doc
2. Run `/report-gen health <vendor>/ --format docx` for a vendor-specific health report
3. Run `/report-gen backup --period weekly --format html` for a weekly backup digest

---

## Adding New Commands

To add a new command:
1. Create a `.md` file in this folder
2. The filename (without `.md`) becomes the `/command-name`
3. Prefix with `_sub-` if it's a subagent
4. Use `$ARGUMENTS` in the file to receive user input
5. Follow the structure of existing commands for consistency
