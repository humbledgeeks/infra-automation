# Linux — Synology Automation

Shell scripts for automating **Synology DiskStation Manager (DSM)** NAS appliances.

## Platforms Covered

| Platform | Description |
|----------|-------------|
| Synology DSM 7.x | NAS management — storage, packages, Hyper Backup, user accounts |

## Quick Navigation

| Subfolder | Tool | Description |
|-----------|------|-------------|
| [`Shell/`](./Shell/) | Bash / Shell | DSM shell scripts — scheduled tasks, backup jobs, storage management |

## Prerequisites

- SSH access enabled on the Synology NAS (Control Panel → Terminal & SNMP → Enable SSH)
- Admin or sudo-equivalent account on DSM
- Shell scripts are designed to run directly on the DSM via SSH or as Scheduled Tasks in DSM

## Authentication

```bash
# Connect to Synology via SSH
ssh admin@diskstation.lab.local

# Run scripts as admin
sudo bash /volume1/scripts/your-script.sh
```

## Common Use Cases

- Automate Hyper Backup job scheduling and verification
- Monitor disk and RAID health via `synoinfo` and `mdadm`
- Manage shared folder permissions via DSM shell commands
- Schedule package updates and maintenance tasks
- Storage utilisation reporting across volumes

## Notes

- Synology DSM uses a customised Linux environment — some standard Linux tools may behave differently
- Scripts run in the DSM busybox shell by default; PowerShell is not natively available on DSM
- Use Scheduled Tasks (DSM Control Panel → Task Scheduler) to run scripts automatically

## Related Agent

Use `/vmware-sme` is not applicable here — use general Linux knowledge or the `/infra-orchestrate` agent for cross-platform lab tasks involving Synology.
