<#
.SYNOPSIS
    Reports the current status of the NUCLab environment — hosts, VMs, and datastores.
.DESCRIPTION
    Connects to the NUCLab vCenter and displays a quick-glance summary of ESXi host
    health, running VMs, and datastore capacity. Useful for a daily lab check before
    starting automation work. Read-only — no changes are made.
.PARAMETER vCenterServer
    FQDN or IP of the NUCLab vCenter Server. Defaults to vcenter.lab.local.
.EXAMPLE
    .\get-nuclab-status.ps1
    .\get-nuclab-status.ps1 -vCenterServer 192.168.1.10
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : VMware.PowerCLI
    Repo    : infra-automation/NUCLab/PowerShell
    Env     : NUCLab (lab environment — nested virtualization supported)
#>

[CmdletBinding()]
param (
    [string]$vCenterServer = "vcenter.lab.local"
)

$ErrorActionPreference = "Stop"

# ── Connect ──────────────────────────────────────────────────────────────────
Write-Output "Connecting to NUCLab vCenter: $vCenterServer"
$creds = Get-Credential -Message "Enter vCenter credentials"
Connect-VIServer -Server $vCenterServer -Credential $creds | Out-Null

# ── Host Summary ──────────────────────────────────────────────────────────────
Write-Output "`n=== ESXi Hosts ==="
Get-VMHost | Select-Object `
    @{N="Host";        E={$_.Name}},
    @{N="State";       E={$_.ConnectionState}},
    @{N="Power";       E={$_.PowerState}},
    @{N="CPU%";        E={[math]::Round($_.CpuUsageMhz / $_.CpuTotalMhz * 100, 1)}},
    @{N="MemUsedGB";   E={[math]::Round($_.MemoryUsageGB, 1)}},
    @{N="MemTotalGB";  E={[math]::Round($_.MemoryTotalGB, 1)}} |
    Format-Table -AutoSize

# ── VM Summary ────────────────────────────────────────────────────────────────
Write-Output "`n=== Virtual Machines ==="
Get-VM | Select-Object `
    @{N="VM";          E={$_.Name}},
    @{N="State";       E={$_.PowerState}},
    @{N="vCPU";        E={$_.NumCpu}},
    @{N="MemGB";       E={[math]::Round($_.MemoryGB, 1)}},
    @{N="Host";        E={$_.VMHost}} |
    Sort-Object State, VM |
    Format-Table -AutoSize

# ── Datastore Summary ─────────────────────────────────────────────────────────
Write-Output "`n=== Datastores ==="
Get-Datastore | Select-Object `
    @{N="Datastore";   E={$_.Name}},
    @{N="TotalGB";     E={[math]::Round($_.CapacityGB, 1)}},
    @{N="FreeGB";      E={[math]::Round($_.FreeSpaceGB, 1)}},
    @{N="Used%";       E={[math]::Round((1 - ($_.FreeSpaceGB / $_.CapacityGB)) * 100, 1)}} |
    Format-Table -AutoSize

# ── Disconnect ────────────────────────────────────────────────────────────────
Disconnect-VIServer -Confirm:$false
Write-Output "`nNUCLab status check complete."
