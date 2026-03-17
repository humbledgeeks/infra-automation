# VMware ESXi — Hardening Scripts

PowerShell scripts for applying security hardening settings to ESXi hosts via VMware PowerCLI.

See the parent [VMware/ESXi/PowerShell/README.md](../README.md) for prerequisites, installation, and credential setup.

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `ESXi_Hardening_V6h.ps1` | **Current recommended version.** Interactive hardening with dry-run→apply flow, set/verify/fallback logic, themed HTML KPI report. |
| `ESXi_Hardening_V4.ps1` | Earlier version with menu, dry-run, color output, and HTML summary. Superseded by V6h. |
| `ESXi_Hardening_Verbose.ps1` | Verbose hardening run — applies settings with detailed per-setting console output. |

---

## Quick Start

```powershell
# Run the current recommended version
.\ESXi_Hardening_V6h.ps1
```

Script prompts for: dry-run mode, connection method (vCenter / standalone / CSV), log directory, and credentials.

**Always run in dry-run mode first** to see what would change before applying.

---

## Settings Applied

All scripts target the same VMware-recommended advanced settings:

| Setting | Value |
|---|---|
| `Config.HostAgent.log.level` | `info` |
| `Config.HostAgent.plugins.solo.enableMob` | `False` |
| `Mem.ShareForceSalting` | `2` |
| `Security.AccountLockFailures` | `5` |
| `Security.AccountUnlockTime` | `900` |
| `Security.PasswordHistory` | `5` |
| `Security.PasswordQualityControl` | `similar=deny retry=3 min=disabled,...,15` |
| `UserVars.ESXiShellInteractiveTimeOut` | `900` |
| `UserVars.ESXiShellTimeOut` | `900` |
| `UserVars.ESXiVPsDisabledProtocols` | `sslv3,tlsv1,tlsv1.1` |
