#Requires -Version 5.1
<#
.SYNOPSIS
    Section 00 – Prerequisites check and UCSM connection
.DESCRIPTION
    Verifies the Cisco.UCS PowerShell module is installed, prompts for
    credentials, and opens a persistent session to the HumbledGeeks UCSM.
    All other scripts in this series dot-source this file.
.NOTES
    Repo   : infra-automation / Cisco / UCS / PowerShell / HumbledGeeks
    Author : HumbledGeeks Infrastructure Team
    Tested : Cisco.UCS module v4.x  |  PowerShell 5.1 / 7.x
#>

# ── Config ────────────────────────────────────────────────────────────────
$UCSMHost   = '10.103.12.20'
$OrgName    = 'HumbledGeeks'
$OrgDN      = "org-root/org-$OrgName"

# ── Module check ─────────────────────────────────────────────────────────
if (-not (Get-Module -ListAvailable -Name 'Cisco.UCS')) {
    Write-Host '[INFO] Cisco.UCS module not found. Installing from PSGallery...' -ForegroundColor Cyan
    Install-Module -Name 'Cisco.UCS' -Scope CurrentUser -Force -AllowClobber
}
Import-Module Cisco.UCS -ErrorAction Stop
Write-Host "[OK]   Cisco.UCS module loaded  ($(Get-Module Cisco.UCS | Select-Object -ExpandProperty Version))" -ForegroundColor Green

# ── Connect ────────────────────────────────────────────────────────────────
if (-not $global:DefaultUcs) {
    $cred = Get-Credential -UserName 'admin' -Message "Enter UCSM credentials for $UCSMHost"
    $global:UcsHandle = Connect-Ucs -Name $UCSMHost -Credential $cred -NotDefault
    Write-Host "[OK]   Connected to UCSM $UCSMHost" -ForegroundColor Green
} else {
    Write-Host "[OK]   Reusing existing UCSM session" -ForegroundColor Green
    $global:UcsHandle = $global:DefaultUcs
}

# ── Verify org exists ─────────────────────────────────────────────────────
$org = Get-UcsOrg -Ucs $global:UcsHandle | Where-Object { $_.Name -eq $OrgName }
if (-not $org) {
    Write-Warning "Org '$OrgName' not found — creating it..."
    $org = Add-UcsOrg -Ucs $global:UcsHandle -Name $OrgName `
               -Descr "HumbledGeeks sub-organisation" -ModifyPresent
    Write-Host "[OK]   Org $OrgName created" -ForegroundColor Green
} else {
    Write-Host "[OK]   Org $OrgName verified  (DN: $($org.Dn))" -ForegroundColor Green
}

$global:HgOrg = $org
Write-Host "`n[READY] Use `$global:UcsHandle and `$global:HgOrg in subsequent scripts.`n"
