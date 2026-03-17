# Linux Domain — Context

This folder contains shell scripts and automation for Linux-based systems in the environment.

Refer to the top-level `CLAUDE.md` for full role definition, coding standards, and core philosophy. This file provides Linux-specific context.

---

## Folder Structure

```
Linux/
├── Synology/
│   └── Shell/    - Synology NAS shell scripts (BusyBox/ash compatible)
└── Ubuntu/
    └── Shell/    - Ubuntu server shell scripts (bash)
```

---

## Technology Context

### Synology NAS

Synology devices run **DSM (DiskStation Manager)**, which uses a customized Linux environment with **BusyBox** shell (`/bin/ash`).

Key considerations:
- Scripts must be **BusyBox/ash compatible** — avoid bash-only syntax (`[[ ]]`, `$'...'`, bash arrays, etc.)
- Use `#!/bin/sh` shebang, not `#!/bin/bash`
- Common tools available: `awk`, `sed`, `grep`, `find`, `curl`, `jq` (may need to install via Package Center or `ipkg`)
- Synology-specific CLI tools: `synowebapi`, `synodiskport`, `synopkg`, `synorelayd`
- SSH access required; enable via DSM Control Panel → Terminal & SNMP

```sh
#!/bin/sh
# =============================================================================
# Script: script-name.sh
# Description: Brief purpose
# Author: humbledgeeks-allen
# Date: YYYY-MM-DD
# Compatibility: Synology DSM / BusyBox ash
# =============================================================================
```

Common Synology automation tasks:
- Scheduled backup validation via `synowebapi`
- Volume / disk health checks via `synodiskport`
- Package management via `synopkg`
- Log parsing from `/var/log/messages`

### Ubuntu Server

Ubuntu scripts target **Ubuntu Server LTS** (22.04 / 24.04) and use **bash**.

Key considerations:
- Use `#!/bin/bash` shebang
- Prefer `systemctl` for service management
- Use `apt` for package management (avoid `apt-get` in scripts — use `apt-get` for non-interactive scripting)
- Scripts may use `curl`, `jq`, `python3`, `ansible` where installed

```bash
#!/bin/bash
# =============================================================================
# Script: script-name.sh
# Description: Brief purpose
# Author: humbledgeeks-allen
# Date: YYYY-MM-DD
# Compatibility: Ubuntu 22.04 LTS / bash
# =============================================================================
set -euo pipefail   # Fail fast: exit on error, unbound var, pipe failures
```

Common Ubuntu automation tasks:
- System configuration and hardening
- Package installation and service setup
- Network interface configuration
- Integration with infrastructure platforms (VMware tools, NetApp NFS mounts)

---

## Linux Best Practices (This Repo)

- Include a **compatibility comment** in script headers (Synology vs. Ubuntu)
- Use `set -euo pipefail` in all bash scripts for safe error handling
- Quote all variables: `"$var"` not `$var`
- Validate required tools exist before using them:
  ```bash
  command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed."; exit 1; }
  ```
- Do not hardcode credentials — use environment variables or config files excluded via `.gitignore`
- Use `logger` or structured log output for scripts run via cron

---

## Validation Commands

```bash
# Synology — system health
cat /proc/version
df -h
/usr/syno/bin/synodiskport -info
synowebapi --exec api=SYNO.Storage.CGI.Storage method=load_info version=1

# Ubuntu — system health
systemctl status
df -h
free -h
ip addr show
journalctl -n 50 --no-pager
```
