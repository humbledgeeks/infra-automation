<#
.SYNOPSIS
    Reports Veeam Backup & Replication job results and repository capacity.
.DESCRIPTION
    Connects to the local VBR server (or a remote one via -VBRServer) and
    retrieves the last 24 hours of backup job results along with a summary
    of repository capacity and free space. Read-only — no changes made.
.PARAMETER VBRServer
    FQDN or IP of the VBR server. Defaults to localhost.
.PARAMETER HoursBack
    How many hours of job history to report on. Defaults to 24.
.PARAMETER Credential
    PSCredential for remote VBR connection. Not required for localhost.
.EXAMPLE
    .\get-vbr-job-status.ps1
.EXAMPLE
    .\get-vbr-job-status.ps1 -VBRServer vbr01.lab.local -HoursBack 48
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : Veeam.Backup.PowerShell (snap-in) — loaded automatically
    Repo    : infra-automation/Veeam/PowerShell
    Prereq  : Run on the VBR server, or with VBR console installed.
              Veeam B&R v12+ recommended.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VBRServer = 'localhost',

    [Parameter(Mandatory = $false)]
    [int]$HoursBack = 24,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Load Veeam snap-in
# ---------------------------------------------------------------------------
if (-not (Get-PSSnapin -Name VeeamPSSnapin -ErrorAction SilentlyContinue)) {
    try {
        Add-PSSnapin VeeamPSSnapin
        Write-Host "[OK]   Veeam PowerShell snap-in loaded" -ForegroundColor Green
    }
    catch {
        Write-Error "[ERROR] Failed to load VeeamPSSnapin. Ensure Veeam B&R console is installed: $_"
        exit 1
    }
}

# ---------------------------------------------------------------------------
# Connect to VBR server
# ---------------------------------------------------------------------------
Write-Host "`n[INFO] Connecting to VBR server: $VBRServer" -ForegroundColor Cyan

$connectParams = @{ Server = $VBRServer }
if ($Credential) { $connectParams['Credential'] = $Credential }

try {
    Connect-VBRServer @connectParams
    Write-Host "[OK]   Connected to $VBRServer" -ForegroundColor Green
}
catch {
    Write-Error "[ERROR] Failed to connect to VBR server: $_"
    exit 1
}

# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------
try {
    $cutoffTime = (Get-Date).AddHours(-$HoursBack)

    # --- Job sessions (last N hours) ---
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " Backup Job Results — Last $HoursBack Hours" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    $sessions = Get-VBRBackupSession | Where-Object { $_.EndTime -ge $cutoffTime } | Sort-Object EndTime -Descending

    if (-not $sessions) {
        Write-Warning "No job sessions found in the last $HoursBack hours"
    }
    else {
        $successCount = ($sessions | Where-Object { $_.Result -eq 'Success' }).Count
        $warningCount = ($sessions | Where-Object { $_.Result -eq 'Warning' }).Count
        $failedCount  = ($sessions | Where-Object { $_.Result -eq 'Failed'  }).Count

        Write-Host ("`nSummary — Total: {0}  |  Success: {1}  |  Warning: {2}  |  Failed: {3}`n" -f `
            $sessions.Count, $successCount, $warningCount, $failedCount)

        foreach ($session in $sessions) {
            $resultColor = switch ($session.Result) {
                'Success' { 'Green'  }
                'Warning' { 'Yellow' }
                'Failed'  { 'Red'    }
                default   { 'Gray'   }
            }
            $duration = if ($session.EndTime -and $session.CreationTime) {
                [math]::Round(($session.EndTime - $session.CreationTime).TotalMinutes, 1)
            } else { 'N/A' }

            Write-Host ("[{0}] {1,-40} Result: {2,-8}  Duration: {3} min  End: {4}" -f `
                $session.Result.Substring(0,1),
                $session.Name,
                $session.Result,
                $duration,
                $session.EndTime.ToString('yyyy-MM-dd HH:mm')
            ) -ForegroundColor $resultColor
        }
    }

    # --- Repository capacity ---
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " Repository Capacity" -ForegroundColor Yellow
    Write-Host "========================================`n" -ForegroundColor Yellow

    $repositories = Get-VBRBackupRepository | Sort-Object Name

    if (-not $repositories) {
        Write-Warning "No backup repositories found"
    }
    else {
        foreach ($repo in $repositories) {
            $totalGB = [math]::Round($repo.GetContainer().CachedTotalSpace.InGigabytes(), 1)
            $freeGB  = [math]::Round($repo.GetContainer().CachedFreeSpace.InGigabytes(), 1)
            $usedGB  = [math]::Round($totalGB - $freeGB, 1)
            $usedPct = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100, 1) } else { 0 }

            $repoColor = if ($usedPct -ge 85) { 'Red' } elseif ($usedPct -ge 70) { 'Yellow' } else { 'Green' }

            Write-Host ("  {0,-35} Total: {1,8} GB   Used: {2,8} GB   Free: {3,8} GB   {4}%" -f `
                $repo.Name, $totalGB, $usedGB, $freeGB, $usedPct) -ForegroundColor $repoColor
        }
    }

    Write-Host "`n[INFO] VBR status report complete" -ForegroundColor Cyan

}
finally {
    Disconnect-VBRServer -ErrorAction SilentlyContinue
    Write-Host "[INFO] Disconnected from $VBRServer`n" -ForegroundColor Cyan
}
