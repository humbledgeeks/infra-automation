# Linux

Automation scripts for Linux-based infrastructure including Ubuntu servers, Docker deployments, and Synology NAS management.

## Structure

| Folder | Tool | Description |
|--------|------|-------------|
| [Ubuntu/Shell](./Ubuntu/Shell) | Shell | Ubuntu server provisioning, Docker install, and Docker Compose configs |
| [Synology/Shell](./Synology/Shell) | Shell | Synology NAS backup and rsync automation |

Each subfolder contains a `Shell/` directory grouping scripts by tool.

## Notes

- Ubuntu scripts are designed for LTS releases (20.04, 22.04, 24.04) and require `sudo` or root access
- Synology scripts run directly on DSM via SSH or as Scheduled Tasks in the DSM Control Panel
- All scripts should use `set -euo pipefail` and include a header block with Purpose, Author, Date, and Usage

## Related Agent

Use `/infra-orchestrate` in Claude Code for cross-platform tasks that involve Linux alongside VMware or NetApp. For Ansible-based Ubuntu configuration, see the [NUCLab Ansible playbooks](../NUCLab/Ansible/).
