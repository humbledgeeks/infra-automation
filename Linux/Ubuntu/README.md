# Linux — Ubuntu Automation

Shell scripts for **Ubuntu Server** configuration, hardening, and infrastructure management.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| Ubuntu 20.04 LTS / 22.04 LTS / 24.04 LTS | Server configuration, security hardening, package management, service automation |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`Shell/`](./Shell/) | Bash / Shell | Ubuntu server setup, hardening, and maintenance scripts |

## Prerequisites

- Ubuntu Server 20.04+ (scripts designed for LTS releases)
- `sudo` access or root
- `bash` 5.x (default on Ubuntu 20.04+)
- Scripts may require specific packages — check each script's header for dependencies

## Authentication and Credential Handling

```bash
# Use SSH key authentication — never hardcode passwords in shell scripts
# Generate key pair
ssh-keygen -t ed25519 -C "infra-automation"

# Copy to target server
ssh-copy-id user@ubuntu-server.lab.local

# Use vault or environment variables for any sensitive values
export DB_PASSWORD="$(cat /run/secrets/db_password)"
```

## Common Use Cases

- Initial server hardening (SSH config, UFW firewall, fail2ban, unattended upgrades)
- Package installation and baseline configuration
- User account and sudoers management
- Service health checks and automated restarts
- Log rotation and disk usage monitoring
- Network interface configuration

## Script Standards

All shell scripts in this folder should:
- Include a header block with `# Purpose`, `# Author`, `# Date`, `# Usage`
- Use `set -euo pipefail` for safe execution
- Validate prerequisites before running (check commands exist, check user is root/sudo)
- Use `echo` with colour codes for status output
- Not hardcode passwords, IPs, or environment-specific values

## Related Agent

The Linux scripts complement the NUCLab Ansible playbooks in [`NUCLab/Ansible/`](../../NUCLab/Ansible/) which use Ansible for declarative Ubuntu server configuration.
