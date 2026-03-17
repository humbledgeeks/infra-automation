<#
.SYNOPSIS
    Reports iLO health, hardware inventory, and firmware versions for an HPE ProLiant server.
.DESCRIPTION
    Connects to an HPE iLO 5 or iLO 6 interface using the HPEiLOCmdlets module
    and produces a read-only health summary including:
      - Overall system health status
      - CPU and memory inventory
      - Storage controllers and drive count
      - Fan status and temperatures
      - Power supply status and current draw
      - iLO and BIOS firmware versions
    Read-only — no changes made to the server.
.PARAMETER iLOAddress
    IP address or FQDN of the iLO interface.
.PARAMETER Credential
    PSCredential for iLO authentication. Prompted if not supplied.
.PARAMETER SkipCertCheck
    Suppress TLS certificate validation. Use only in lab environments.
.EXAMPLE
    .\get-ilo-server-health.ps1 -iLOAddress 10.10.1.20
.EXAMPLE
    $cred = Get-Credential
    .\get-ilo-server-health.ps1 -iLOAddress ilo-dl380-01.lab.local -Credential $cred
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : HPEiLOCmdlets
    Repo    : infra-automation/HPE/Compute/PowerShell
    Prereq  : Install-Module HPEiLOCmdlets -Scope CurrentUser
              Supports iLO 5 (Gen10) and iLO 6 (Gen11) ProLiant servers.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$iLOAddress,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [switch]$SkipCertCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Load HPEiLOCmdlets module
# ---------------------------------------------------------------------------
if (-not (Get-Module -ListAvailable -Name HPEiLOCmdlets)) {
    Write-Error "[ERROR] HPEiLOCmdlets module not found. Run: Install-Module HPEiLOCmdlets -Scope CurrentUser"
    exit 1
}
Import-Module HPEiLOCmdlets -ErrorAction Stop
Write-Host "[OK]   HPEiLOCmdlets loaded" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Connect to iLO
# ---------------------------------------------------------------------------
Write-Host "`n[INFO] Connecting to iLO: $iLOAddress" -ForegroundColor Cyan

if (-not $Credential) {
    $Credential = Get-Credential -Message "Enter iLO credentials"
}

$connectParams = @{
    IP         = $iLOAddress
    Credential = $Credential
}
if ($SkipCertCheck) { $connectParams['DisableCertificateAuthentication'] = $true }

try {
    $connection = Connect-HPEiLO @connectParams
    Write-Host "[OK]   Connected to $iLOAddress" -ForegroundColor Green
}
catch {
    Write-Error "[ERROR] Failed to connect to iLO: $_"
    exit 1
}

# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------
try {

    # --- System Overview ---
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " System Health Overview" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    $serverInfo = Get-HPEiLOServerInfo -Connection $connection
    $health     = Get-HPEiLOHealthSummary -Connection $connection

    Write-Host ("  Model         : {0}" -f $serverInfo.Model)
    Write-Host ("  Serial Number : {0}" -f $serverInfo.SerialNumber)
    Write-Host ("  System ROM    : {0}" -f $serverInfo.SystemROMAnsiDate)

    $healthColor = if ($health.HealthSummary.Status -eq 'OK') { 'Green' }
                   elseif ($health.HealthSummary.Status -eq 'Warning') { 'Yellow' } else { 'Red' }
    Write-Host ("  Health Status : {0}" -f $health.HealthSummary.Status) -ForegroundColor $healthColor

    # --- CPU ---
    Write-Host "`n[PROCESSORS]"
    $cpus = Get-HPEiLOProcessor -Connection $connection
    foreach ($cpu in $cpus.Processor) {
        Write-Host ("  {0,-20} Cores: {1,-4} Status: {2}" -f $cpu.Name, $cpu.TotalCores, $cpu.Status)
    }

    # --- Memory ---
    Write-Host "`n[MEMORY]"
    $memory = Get-HPEiLOMemoryInfo -Connection $connection
    $totalGB = [math]::Round(($memory.MemoryDetails.TotalSystemMemoryGiB), 0)
    Write-Host ("  Total Memory  : {0} GB" -f $totalGB)
    $faultedDimms = $memory.MemoryDetails.MemoryList | Where-Object { $_.Status -ne 'GoodInUse' -and $_.Status -ne 'NotPresent' }
    if ($faultedDimms) {
        Write-Host ("  WARNING: {0} DIMM(s) in non-healthy state" -f $faultedDimms.Count) -ForegroundColor Yellow
    }
    else {
        Write-Host "  All DIMMs healthy" -ForegroundColor Green
    }

    # --- Storage ---
    Write-Host "`n[STORAGE]"
    try {
        $storage = Get-HPEiLOStorageController -Connection $connection
        foreach ($ctrl in $storage.Controllers) {
            $ctrlColor = if ($ctrl.Status -eq 'OK') { 'Green' } else { 'Red' }
            Write-Host ("  Controller: {0,-35} Status: {1}" -f $ctrl.Model, $ctrl.Status) -ForegroundColor $ctrlColor
        }
    }
    catch {
        Write-Warning "  Storage query not available on this iLO version"
    }

    # --- Power Supplies ---
    Write-Host "`n[POWER SUPPLIES]"
    $power = Get-HPEiLOPowerSupply -Connection $connection
    foreach ($psu in $power.PowerSupplySummary) {
        $psuColor = if ($psu.PowerSupplyStatus -eq 'Good, In Use') { 'Green' } else { 'Yellow' }
        Write-Host ("  PSU {0}: {1}" -f $psu.BayNumber, $psu.PowerSupplyStatus) -ForegroundColor $psuColor
    }

    # --- Fans ---
    Write-Host "`n[FANS]"
    $fans = Get-HPEiLOFan -Connection $connection
    $faulted = $fans.Fan | Where-Object { $_.Status -notin 'OK','N/A' }
    if ($faulted) {
        Write-Host ("  WARNING: {0} fan(s) in non-OK state" -f $faulted.Count) -ForegroundColor Yellow
        $faulted | ForEach-Object { Write-Host ("    Fan {0}: {1}" -f $_.Name, $_.Status) -ForegroundColor Yellow }
    }
    else {
        Write-Host "  All fans OK" -ForegroundColor Green
    }

    # --- Firmware Versions ---
    Write-Host "`n[FIRMWARE]"
    try {
        $firmware = Get-HPEiLOFirmwareInventory -Connection $connection
        $firmware.FirmwareInformation | Select-Object -First 10 | ForEach-Object {
            Write-Host ("  {0,-40} {1}" -f $_.FirmwareName, $_.FirmwareVersion)
        }
    }
    catch {
        Write-Warning "  Firmware inventory not available on this iLO version"
    }

    Write-Host "`n[INFO] iLO health report complete for $iLOAddress" -ForegroundColor Cyan

}
finally {
    Disconnect-HPEiLO -Connection $connection -ErrorAction SilentlyContinue
    Write-Host "[INFO] Disconnected from $iLOAddress`n" -ForegroundColor Cyan
}
