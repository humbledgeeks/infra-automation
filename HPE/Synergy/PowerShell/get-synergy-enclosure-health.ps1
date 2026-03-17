<#
.SYNOPSIS
    Reports enclosure health, compute module status, and server profile compliance from HPE OneView.
.DESCRIPTION
    Connects to HPE OneView and produces a read-only health summary covering:
      - Enclosure and Logical Enclosure status
      - Server hardware (compute module) power state and health
      - Server profile compliance against assigned templates
      - Active OneView alerts (Warning and Critical)
    Read-only — no changes made to the environment.
.PARAMETER OneViewFQDN
    FQDN or IP address of the HPE OneView appliance (or Synergy Composer).
.PARAMETER Credential
    PSCredential for OneView authentication. Prompted if not supplied.
.PARAMETER SkipCertCheck
    Suppress TLS certificate validation. Use only in lab environments.
.EXAMPLE
    .\get-synergy-enclosure-health.ps1 -OneViewFQDN oneview.lab.local
.EXAMPLE
    $cred = Get-Credential
    .\get-synergy-enclosure-health.ps1 -OneViewFQDN oneview.lab.local -Credential $cred
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : HPEOneView.800 (or version-matched to your appliance)
    Repo    : infra-automation/HPE/Synergy/PowerShell
    Prereq  : Install-Module HPEOneView.800 -Scope CurrentUser
              Adjust module version to match your OneView appliance version.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$OneViewFQDN,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [switch]$SkipCertCheck
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Load HPE OneView module (version-match to your appliance)
# ---------------------------------------------------------------------------
$ovModule = Get-Module -ListAvailable -Name 'HPEOneView.*' | Sort-Object Version -Descending | Select-Object -First 1
if (-not $ovModule) {
    Write-Error "[ERROR] No HPEOneView module found. Run: Install-Module HPEOneView.800 -Scope CurrentUser"
    exit 1
}
Import-Module $ovModule.Name -ErrorAction Stop
Write-Host "[OK]   Loaded module: $($ovModule.Name) v$($ovModule.Version)" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Connect to OneView
# ---------------------------------------------------------------------------
Write-Host "`n[INFO] Connecting to HPE OneView: $OneViewFQDN" -ForegroundColor Cyan

if (-not $Credential) {
    $Credential = Get-Credential -Message "Enter HPE OneView credentials"
}

$connectParams = @{
    Hostname   = $OneViewFQDN
    Credential = $Credential
}
if ($SkipCertCheck) { $connectParams['LoginAcknowledgement'] = $true }

try {
    Connect-OVMgmt @connectParams
    Write-Host "[OK]   Connected to $OneViewFQDN" -ForegroundColor Green
}
catch {
    Write-Error "[ERROR] Failed to connect to OneView: $_"
    exit 1
}

# ---------------------------------------------------------------------------
# Main logic
# ---------------------------------------------------------------------------
try {

    # --- Enclosures ---
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " Enclosure Health" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    $enclosures = Get-OVEnclosure
    foreach ($enc in $enclosures) {
        $statusColor = if ($enc.Status -eq 'OK') { 'Green' } elseif ($enc.Status -eq 'Warning') { 'Yellow' } else { 'Red' }
        Write-Host ("  {0,-40} Status: {1,-10} State: {2}" -f $enc.Name, $enc.Status, $enc.State) -ForegroundColor $statusColor
    }

    # --- Server Hardware ---
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " Server Hardware (Compute Modules)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    $servers = Get-OVServer | Sort-Object Name
    $powered  = ($servers | Where-Object { $_.PowerState -eq 'On' }).Count
    $offline  = ($servers | Where-Object { $_.PowerState -ne 'On' }).Count
    Write-Host ("`n  Total: {0}  |  Powered On: {1}  |  Off/Standby: {2}`n" -f $servers.Count, $powered, $offline)

    foreach ($server in $servers) {
        $statusColor = if ($server.Status -eq 'OK') { 'Green' } elseif ($server.Status -eq 'Warning') { 'Yellow' } else { 'Red' }
        Write-Host ("  {0,-45} Power: {1,-8} Health: {2,-10} Profile: {3}" -f `
            $server.Name, $server.PowerState, $server.Status,
            $(if ($server.ServerProfileUri) { 'Assigned' } else { 'Unassigned' })
        ) -ForegroundColor $statusColor
    }

    # --- Server Profile Compliance ---
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " Server Profile Compliance" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    $profiles = Get-OVServerProfile | Sort-Object Name
    $compliant    = ($profiles | Where-Object { $_.TemplateCompliance -eq 'Compliant' }).Count
    $nonCompliant = ($profiles | Where-Object { $_.TemplateCompliance -ne 'Compliant' }).Count
    Write-Host ("`n  Total Profiles: {0}  |  Compliant: {1}  |  Non-Compliant / No Template: {2}`n" -f `
        $profiles.Count, $compliant, $nonCompliant)

    foreach ($profile in $profiles) {
        $compColor = if ($profile.TemplateCompliance -eq 'Compliant') { 'Green' }
                     elseif ($profile.TemplateCompliance -eq 'NonCompliant') { 'Red' }
                     else { 'Yellow' }
        Write-Host ("  {0,-45} Compliance: {1,-15} Status: {2}" -f `
            $profile.Name, $profile.TemplateCompliance, $profile.Status) -ForegroundColor $compColor
    }

    # --- Active Alerts ---
    Write-Host "`n========================================" -ForegroundColor Yellow
    Write-Host " Active Alerts" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Yellow

    $alerts = Get-OVAlert -State Active | Where-Object { $_.Severity -in 'Warning','Critical' } | Sort-Object Created -Descending
    if (-not $alerts) {
        Write-Host "  No active Warning or Critical alerts" -ForegroundColor Green
    }
    else {
        Write-Host ("  Active alerts: {0}`n" -f $alerts.Count)
        foreach ($alert in $alerts | Select-Object -First 20) {
            $alertColor = if ($alert.Severity -eq 'Critical') { 'Red' } else { 'Yellow' }
            Write-Host ("  [{0}] {1}  |  {2}" -f $alert.Severity, $alert.Description, $alert.Created) -ForegroundColor $alertColor
        }
    }

    Write-Host "`n[INFO] Synergy health report complete" -ForegroundColor Cyan

}
finally {
    Disconnect-OVMgmt -ErrorAction SilentlyContinue
    Write-Host "[INFO] Disconnected from $OneViewFQDN`n" -ForegroundColor Cyan
}
