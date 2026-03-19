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
# PSGallery publishes the UCS PowerTool suite as three modules:
#   Cisco.UCS.Common   – shared types and utilities
#   Cisco.UCS.Core     – core Ucs session objects
#   Cisco.UCSManager   – UCS Manager cmdlets (Connect-Ucs, Add-UcsServiceProfile, etc.)
$requiredModules = @('Cisco.UCS.Common', 'Cisco.UCS.Core', 'Cisco.UCSManager')
foreach ($mod in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "[INFO] Installing $mod from PSGallery..." -ForegroundColor Cyan
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber -AcceptLicense -Repository PSGallery
    }
    Import-Module $mod -ErrorAction Stop
}
Write-Host "[OK]   Cisco UCS modules loaded  (UCSManager $(Get-Module Cisco.UCSManager | Select-Object -ExpandProperty Version))" -ForegroundColor Green

# ── Connect ────────────────────────────────────────────────────────────────
if (-not $global:DefaultUcs) {
    # Non-interactive: set $env:UCSM_PASSWORD before running, or fall back to Get-Credential
    if ($env:UCSM_PASSWORD) {
        $secPwd = ConvertTo-SecureString $env:UCSM_PASSWORD -AsPlainText -Force
        $cred   = New-Object System.Management.Automation.PSCredential('admin', $secPwd)
        Write-Host "[INFO] Using UCSM_PASSWORD env var for authentication" -ForegroundColor DarkGray
    } else {
        $cred = Get-Credential -UserName 'admin' -Message "Enter UCSM credentials for $UCSMHost"
    }
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
