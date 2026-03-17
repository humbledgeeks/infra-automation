# VMware ESXi — NFS Best Practice Scripts

PowerShell scripts for applying NetApp NFS best-practice advanced settings to ESXi hosts and installing the NetApp VAAI VIB.

See the parent [VMware/ESXi/PowerShell/README.md](../README.md) for prerequisites, installation, and credential setup.

---

## Scripts in This Folder

| Script | Description |
|---|---|
| `ESXI_NFS_BestPractices.ps1` | Apply NetApp NFS best-practice advanced settings — original version |
| `ESXI_NFS_BestPracticesV4.ps1` | Apply NFS best-practice settings — V4 with menu, dry-run, and HTML report |
| `NetAppVIB_Installation.ps1` | Install NetApp NFS VAAI VIB (NetAppNasPlugin) with menu, dry-run, and HTML summary |

---

## Quick Start

```powershell
# Apply NFS best practices (current version with dry-run and HTML report)
.\ESXI_NFS_BestPracticesV4.ps1

# Install NetApp VAAI VIB
.\NetAppVIB_Installation.ps1
```

---

## NFS Settings Applied

| Setting | Recommended Value |
|---|---|
| `Net.TcpipHeapSize` | 32 |
| `Net.TcpipHeapMax` | 1024 |
| `NFS.MaxVolumes` | 256 |
| `NFS41.MaxVolumes` | 256 |
| `NFS.MaxQueueDepth` | 128 |
| `NFS.HeartbeatMaxFailures` | 10 |
| `NFS.HeartbeatFrequency` | 12 |
| `NFS.HeartbeatTimeout` | 5 |
| `Disk.QFullSampleSize` | 32 |
| `Disk.QFullThreshold` | 8 |
| `SunRPC.MaxConnPerIP` | 128 |

---

## VAAI VIB

The `NetAppNasPlugin` VIB enables hardware-accelerated NFS operations (full copy, space reservation) on NetApp storage. Pre-stage the VIB file on a datastore accessible to the target hosts before running `NetAppVIB_Installation.ps1`.
