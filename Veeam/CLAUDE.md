# Veeam Domain — Context

This folder contains PowerShell scripts and automation for managing Veeam Backup & Replication infrastructure.

Refer to the top-level `CLAUDE.md` for full role definition, coding standards, and core philosophy. This file provides Veeam-specific context.

---

## Folder Structure

```
Veeam/
├── PowerShell/     - Veeam PowerShell Toolkit scripts (job management, reporting, automation)
├── REST/           - Veeam REST API automation scripts
└── Reports/        - Backup reporting and SLA compliance scripts
```

> Note: Subfolders will be created as automation is developed. Match the naming convention above.

---

## Technology Context

### Platform Stack

- **Veeam Backup & Replication (VBR)**: Primary data protection platform for VMware environments
- **Veeam ONE**: Monitoring, reporting, and capacity planning for Veeam environments
- **PowerShell / Veeam PowerShell Toolkit**: Primary automation interface (included with VBR installation)
- **Veeam REST API**: Modern API (VBR 11+) for automation and integration workflows
- **NetApp Integration**: Veeam storage integrations for ONTAP snapshot-based backups

### Veeam PowerShell Toolkit

The Veeam PowerShell module (`VeeamPSSnapin` for older versions; auto-loaded in VBR 12) is the primary automation tool.

```powershell
# Connect to Veeam Backup Server (run on VBR server or remote)
Add-PSSnapin VeeamPSSnapin   # VBR 11 and earlier
# VBR 12+ loads automatically

Connect-VBRServer -Server $vbrServer -Credential $creds

# Core inventory commands
Get-VBRJob                          # All backup jobs
Get-VBRBackupSession | Select-Last 20  # Recent job sessions
Get-VBRRepository                   # All backup repositories
Get-VBRBackup                       # All backup chains
Get-VBRRestorePoint                 # All restore points
```

### Veeam REST API

VBR 11+ exposes a REST API for external automation and orchestration.

```powershell
# Authenticate to Veeam REST API
$body    = @{ username = $user; password = $pass } | ConvertTo-Json
$authUri = "https://$vbrServer:9419/api/v1/token"
$token   = (Invoke-RestMethod -Uri $authUri -Method POST -Body $body -ContentType "application/json").access_token
$headers = @{ "Authorization" = "Bearer $token" }

# Get all jobs
Invoke-RestMethod -Uri "https://$vbrServer:9419/api/v1/jobs" -Headers $headers

# Get all repositories
Invoke-RestMethod -Uri "https://$vbrServer:9419/api/v1/backupInfrastructure/repositories" -Headers $headers

# Trigger a job
Invoke-RestMethod -Uri "https://$vbrServer:9419/api/v1/jobs/$jobId/start" -Headers $headers -Method POST
```

**VBR REST API docs**: `https://<vbr-server>:9419/api/swagger/index.html`

---

## Veeam Architecture — Best Practices (This Repo)

### Backup Strategy: 3-2-1-1-0 Rule

The foundation of all backup architectures in this environment:

| Rule | Requirement |
|------|-------------|
| **3** | At least 3 copies of data (production + 2 backups) |
| **2** | Stored on 2 different media types (e.g., disk + tape or cloud) |
| **1** | At least 1 copy offsite |
| **1** | At least 1 copy air-gapped, offline, or immutable |
| **0** | Zero errors on SureBackup / restore verification |

### Scale-Out Backup Repository (SOBR)

SOBR tiers backup data across extents automatically, based on policy.

```
SOBR
├── Performance Tier    → Fast local disk (NAS / local server)
├── Capacity Tier       → Object storage (S3, Azure Blob, Wasabi, etc.)
└── Archive Tier        → Long-term cold storage (AWS Glacier, Azure Archive)
```

```powershell
# Get SOBR configuration
Get-VBRScaleOutBackupRepository | Select Name, PolicyType

# Get SOBR extents
Get-VBRScaleOutBackupRepository | ForEach-Object {
    $_.Extent | Select Name, Repository, TotalSpaceGB, FreeSpaceGB
}
```

### Backup Job Design

- Use **VMware backup jobs** (not agent-based) for all vSphere-managed VMs
- Enable **application-aware processing** for SQL, Exchange, Oracle, and AD workloads
- Use **Changed Block Tracking (CBT)** — always enabled for VMware jobs; verify CBT is healthy periodically
- Configure **guest processing credentials** per job or globally via managed credentials
- Set appropriate **retention** aligned with business RPO/RTO:
  - Short-term: 7–14 daily restore points (performance tier)
  - Medium-term: 4 weekly, 12 monthly (capacity tier via GFS or SOBR offload)
  - Long-term: 7 yearly (archive tier or tape)

```powershell
# Create a new VMware backup job
Add-VBRViBackupJob -Name "Prod-VMs-Daily" `
    -Entity (Find-VBRViEntity -Name "Production" -DataCenter) `
    -BackupRepository (Get-VBRBackupRepository -Name "SOBR-Primary") `
    -GFSKeepWeekly 4 -GFSKeepMonthly 12 -GFSKeepYearly 7
```

### NetApp Storage Integration

When backing up VMs on NetApp ONTAP-backed datastores:

- Add the NetApp storage system to VBR: **Backup Infrastructure → Storage Infrastructure → Add Storage → NetApp**
- Veeam will leverage **ONTAP storage snapshots** as a primary backup source (no VSS overhead)
- Snapshot-based backups offload I/O from production; backup proxy reads from snapshot, not live data
- Ensure the VBR server or mount server has iSCSI/NFS access to the NetApp SVM for snapshot mounting
- After NetApp integration, the backup job will show **"Storage snapshot"** as the data source in job logs

```powershell
# Verify NetApp storage integration
Get-VBRStorageIntegrationPlugin | Select Name, Address, IsAvailable

# Check snapshot-based backup settings on a job
Get-VBRJob -Name "Prod-VMs-Daily" | Select StorageIntegrationEnabled, SnapshotStorageType
```

---

## Recovery Workflows

### Instant VM Recovery

Instantly powers on a VM from the backup repository without restoring data first:

```powershell
# Start Instant VM Recovery
Start-VBRInstantRecovery -RestorePoint (Get-VBRRestorePoint -Name "VMName" | Sort CreationTime | Select -Last 1) `
    -Server (Get-VBRServer -Name $esxiHost) `
    -Datastore (Get-VBRDatastore -Name "Datastore01")
```

### File-Level Recovery

```powershell
# Mount restore point for file-level recovery
$rp = Get-VBRRestorePoint -Name "VMName" | Sort CreationTime | Select -Last 1
Start-VBRWindowsFileRestore -RestorePoint $rp
```

### Application-Aware Restores

- **SQL**: Use Veeam Explorer for SQL Server — restore individual databases, transaction logs, or specific tables
- **Exchange**: Use Veeam Explorer for Microsoft Exchange — restore mailboxes, items, or full databases
- **AD**: Use Veeam Explorer for Active Directory — restore individual AD objects without domain controller rollback

---

## SureBackup — Automated Restore Verification

SureBackup verifies backup recoverability by booting VMs in an isolated virtual lab.

```powershell
# Get SureBackup jobs
Get-VBRSureBackupJob

# Run a SureBackup job on demand
Start-VBRSureBackupJob -Job (Get-VBRSureBackupJob -Name "SureBackup-Prod")

# Review SureBackup results
Get-VBRSureBackupSession | Select JobName, Result, CreationTime | Sort CreationTime -Descending | Select -First 10
```

> **The 0 in 3-2-1-1-0** = zero errors on SureBackup. Untested backups are not backups.

---

## Reporting and Monitoring

```powershell
# Daily backup job summary report
Get-VBRBackupSession | Where-Object {$_.CreationTime -gt (Get-Date).AddHours(-24)} |
    Select JobName, Result, TotalSize, CreationTime |
    Sort CreationTime -Descending |
    Format-Table -AutoSize

# Failed or warning sessions
Get-VBRBackupSession | Where-Object {$_.Result -in "Failed","Warning"} |
    Select JobName, Result, CreationTime, Details |
    Sort CreationTime -Descending |
    Select -First 20

# Repository capacity
Get-VBRRepository | Select Name,
    @{N="TotalGB";E={[math]::Round($_.GetContainer().CachedTotalSpace.InGigabytes,1)}},
    @{N="FreeGB"; E={[math]::Round($_.GetContainer().CachedFreeSpace.InGigabytes,1)}},
    @{N="UsedPct";E={[math]::Round((1 - ($_.GetContainer().CachedFreeSpace.InBytes / $_.GetContainer().CachedTotalSpace.InBytes)) * 100, 1)}}
```

---

## Validation Checklist

After any change to Veeam configuration, validate:

```powershell
# 1. All jobs succeeded in the last 24 hours
Get-VBRBackupSession | Where-Object {$_.CreationTime -gt (Get-Date).AddHours(-24) -and $_.Result -ne "Success"}

# 2. Repository free space above threshold (alert if < 20%)
Get-VBRRepository | ForEach-Object {
    $free = $_.GetContainer().CachedFreeSpace.InGigabytes
    $total = $_.GetContainer().CachedTotalSpace.InGigabytes
    if ($total -gt 0) { [PSCustomObject]@{ Name=$_.Name; FreeGB=[math]::Round($free,1); FreePct=[math]::Round($free/$total*100,1) } }
}

# 3. SureBackup last result
Get-VBRSureBackupSession | Sort CreationTime -Descending | Select -First 5 | Select JobName, Result, CreationTime

# 4. NetApp storage integration health
Get-VBRStorageIntegrationPlugin | Select Name, Address, IsAvailable

# 5. Proxy server availability
Get-VBRViProxy | Select Name, Host, MaxTasksCount, IsDisabled
```
