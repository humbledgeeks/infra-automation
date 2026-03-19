#Requires -Version 5.1
<#
.SYNOPSIS
    Section 09 – FC Zone Profile and single-initiator zones for FlexPod ASA A30
.DESCRIPTION
    Pre-builds all 16 FC zones (8 blades × 2 fabrics) in UCSM using single-initiator
    zoning — the FlexPod best practice. Each zone contains exactly one ESXi initiator
    WWPN and all ASA A30 target WWPNs for that fabric.

    All WWPNs are hard-coded from values known before the ASA A30 is cabled:
      • Initiator WWPNs  — assigned by UCSM from hg-wwpn-a/b pools at SP creation
                           (UCSM assigns from pool at service profile creation time,
                            not at blade association — so these are stable immediately)
      • Target WWPNs     — pulled from NetApp System Manager FC port screen

    The zone profile is created with AdminState = DISABLED so running this script
    is completely safe before the ASA A30 is physically connected. Nothing activates
    until you run:  .\09-fc-zoning.ps1 -Enable

    ─────────────────────────────────────────────────────────────────────────────
    ASSUMED CABLING (edit $fabricATargets / $fabricBTargets if yours differs):
      ASA30-01 port 1a  →  FI-A storage port 29   (Fabric A)
      ASA30-01 port 1b  →  FI-B storage port 29   (Fabric B)
      ASA30-01 port 1c  →  FI-A storage port 30   (Fabric A)
      ASA30-01 port 1d  →  FI-B storage port 30   (Fabric B)
      ASA30-02 port 1a  →  FI-A storage port 31   (Fabric A)
      ASA30-02 port 1b  →  FI-B storage port 31   (Fabric B)
      ASA30-02 port 1c  →  FI-A storage port 32   (Fabric A)
      ASA30-02 port 1d  →  FI-B storage port 32   (Fabric B)
    ─────────────────────────────────────────────────────────────────────────────

    UCSM name limits: zone profile and zone names max 16 characters.
    Zone profile : hg-fc-zones
    Zone naming  : hg-esx-01-fab-a  /  hg-esx-01-fab-b  (15 chars)

.PARAMETER Enable
    When present, sets zone profile AdminState → 'enabled'.
    Run ONLY after the ASA A30 is cabled and blade profiles are associated.
    Example:  .\09-fc-zoning.ps1 -Enable
.NOTES
    Run 07-deploy-service-profiles.ps1 first (vHBA WWPNs must be assigned).
    Safe to run pre-cable: profile is disabled until -Enable is passed.
#>

param([switch]$Enable)

. "$PSScriptRoot\00-prereqs-and-connect.ps1"
$h = $global:UcsHandle

Write-Host "`n========== 09 – FC Zoning ==========" -ForegroundColor Cyan

# ══════════════════════════════════════════════════════════════════════════════
# WWPN TABLES
# ══════════════════════════════════════════════════════════════════════════════

# ── ASA A30 Target WWPNs ──────────────────────────────────────────────────────
# From NetApp System Manager → Storage → FC Ports (captured 2026-03)
# Cabling: ports 1a/1c from each node → Fabric A; ports 1b/1d → Fabric B

$fabricATargets = @(
    @{ Name = 'asa30-01-1a'; Wwpn = '50:0a:09:81:80:11:46:8e' },   # ASA30-01 port 1a → FI-A
    @{ Name = 'asa30-01-1c'; Wwpn = '50:0a:09:83:80:11:46:8e' },   # ASA30-01 port 1c → FI-A
    @{ Name = 'asa30-02-1a'; Wwpn = '50:0a:09:81:80:f1:42:98' },   # ASA30-02 port 1a → FI-A
    @{ Name = 'asa30-02-1c'; Wwpn = '50:0a:09:83:80:f1:42:98' }    # ASA30-02 port 1c → FI-A
)

$fabricBTargets = @(
    @{ Name = 'asa30-01-1b'; Wwpn = '50:0a:09:82:80:11:46:8e' },   # ASA30-01 port 1b → FI-B
    @{ Name = 'asa30-01-1d'; Wwpn = '50:0a:09:84:80:11:46:8e' },   # ASA30-01 port 1d → FI-B
    @{ Name = 'asa30-02-1b'; Wwpn = '50:0a:09:82:80:f1:42:98' },   # ASA30-02 port 1b → FI-B
    @{ Name = 'asa30-02-1d'; Wwpn = '50:0a:09:84:80:f1:42:98' }    # ASA30-02 port 1d → FI-B
)

# ── ESXi Initiator WWPNs ──────────────────────────────────────────────────────
# Assigned from hg-wwpn-a (vmhba0/Fabric A) and hg-wwpn-b (vmhba1/Fabric B) pools.
# KEY: UCSM assigns WWPNs from pool at service profile creation — NOT at blade
# association. So these are stable as soon as 07-deploy-service-profiles.ps1 runs.
# Verified live from UCSM March 2026.

$initiators = @(
    @{ Sp='hg-esx-01'; FabA='20:00:00:25:B5:11:1A:01'; FabB='20:00:00:25:B5:11:1B:01' },
    @{ Sp='hg-esx-02'; FabA='20:00:00:25:B5:11:1A:02'; FabB='20:00:00:25:B5:11:1B:02' },
    @{ Sp='hg-esx-03'; FabA='20:00:00:25:B5:11:1A:03'; FabB='20:00:00:25:B5:11:1B:03' },
    @{ Sp='hg-esx-04'; FabA='20:00:00:25:B5:11:1A:04'; FabB='20:00:00:25:B5:11:1B:04' },
    @{ Sp='hg-esx-05'; FabA='20:00:00:25:B5:11:1A:05'; FabB='20:00:00:25:B5:11:1B:05' },
    @{ Sp='hg-esx-06'; FabA='20:00:00:25:B5:11:1A:06'; FabB='20:00:00:25:B5:11:1B:06' },
    @{ Sp='hg-esx-07'; FabA='20:00:00:25:B5:11:1A:07'; FabB='20:00:00:25:B5:11:1B:07' },
    @{ Sp='hg-esx-08'; FabA='20:00:00:25:B5:11:1A:08'; FabB='20:00:00:25:B5:11:1B:08' }
)

# ══════════════════════════════════════════════════════════════════════════════
# ENABLE MODE  (-Enable switch)
# ══════════════════════════════════════════════════════════════════════════════

if ($Enable) {
    Write-Host "`n[ENABLE] Activating hg-fc-zones zone profile" -ForegroundColor Yellow
    Write-Host "         Pre-flight: ASA A30 cabled? Blade profiles associated? [y/N] " -NoNewline -ForegroundColor Yellow
    $confirm = Read-Host
    if ($confirm -notmatch '^[Yy]') { Write-Host "Aborted."; exit 0 }

    $profile = Get-UcsFabricFcZoneProfile -Ucs $h | Where-Object { $_.Name -eq 'hg-fc-zones' }
    if (-not $profile) {
        Write-Error "Zone profile 'hg-fc-zones' not found. Run without -Enable first."
        exit 1
    }
    Set-UcsFabricFcZoneProfile -FabricFcZoneProfile $profile -AdminState 'enabled' -Force | Out-Null
    Write-Host "  [OK]   hg-fc-zones AdminState → ENABLED" -ForegroundColor Green
    Write-Host "         Zones are now active on FI-A and FI-B.`n" -ForegroundColor Green
    Write-Host "  Verify paths on each ESXi host:" -ForegroundColor DarkGray
    Write-Host "  esxcli storage nmp device list" -ForegroundColor DarkGray
    Write-Host "  esxcli storage nmp path list" -ForegroundColor DarkGray
    exit 0
}

# ══════════════════════════════════════════════════════════════════════════════
# CREATE ZONE PROFILE
# ══════════════════════════════════════════════════════════════════════════════

Write-Host "`n[PROFILE] hg-fc-zones  (AdminState=disabled — safe to run pre-cable)"
$profile = Add-UcsFabricFcZoneProfile -Ucs $h `
    -Name       'hg-fc-zones' `
    -AdminState 'disabled' `
    -Descr      'FlexPod ASA A30 SI zones 8x2' `
    -ModifyPresent
Write-Host "  [OK]   $($profile.Dn)  AdminState=$($profile.AdminState)" -ForegroundColor Green

# ══════════════════════════════════════════════════════════════════════════════
# CREATE 16 ZONES  (8 blades × 2 fabrics, single-initiator zoning)
# ══════════════════════════════════════════════════════════════════════════════

$zoneCount = 0

foreach ($init in $initiators) {
    # Shorten 'hg-esx-01' → 'esx-01' for zone name prefix (stays ≤16 chars)
    $short = $init.Sp -replace '^hg-', ''   # esx-01 … esx-08

    foreach ($fab in @('A','B')) {
        $zoneName   = "hg-$short-fab-$($fab.ToLower())"   # hg-esx-01-fab-a  (15 chars)
        $initWwpn   = if ($fab -eq 'A') { $init.FabA } else { $init.FabB }
        $initName   = "$($init.Sp)-vmhba$( if ($fab -eq 'A') { '0' } else { '1' } )"  # hg-esx-01-vmhba0 (16 chars)
        $targets    = if ($fab -eq 'A') { $fabricATargets } else { $fabricBTargets }

        Write-Host "`n[ZONE-$fab] $zoneName  initiator=$initWwpn"

        $zone = Add-UcsFabricFcUserZone -Ucs $h `
            -FabricFcZoneProfile $profile `
            -Name   $zoneName `
            -Path   $fab `
            -ModifyPresent

        # Initiator endpoint
        Add-UcsFabricFcEndpoint -Ucs $h -FabricFcUserZone $zone `
            -Name $initName -Wwpn $initWwpn -ModifyPresent | Out-Null
        Write-Host "  [init]  $initWwpn  ($($init.Sp) vmhba$( if ($fab -eq 'A') { '0' } else { '1' } ))" -ForegroundColor DarkGray

        # Target endpoints (all ASA A30 ports for this fabric)
        foreach ($tgt in $targets) {
            Add-UcsFabricFcEndpoint -Ucs $h -FabricFcUserZone $zone `
                -Name $tgt.Name -Wwpn $tgt.Wwpn -ModifyPresent | Out-Null
            Write-Host "  [tgt]   $($tgt.Wwpn)  ($($tgt.Name))" -ForegroundColor DarkGray
        }

        Write-Host "  [OK]   $zoneName" -ForegroundColor Green
        $zoneCount++
    }
}

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

Write-Host "`n--- Zone Summary ---" -ForegroundColor Yellow
Get-UcsFabricFcUserZone -Ucs $h |
    Where-Object { $_.Dn -like '*hg-fc-zones*' } |
    Select-Object Name, Path | Sort-Object Path, Name | Format-Table -AutoSize

Write-Host "[DONE] $zoneCount zones created.  Profile = DISABLED (pre-cable safe state).`n" -ForegroundColor Green
Write-Host "  ┌─ When ready to go live (ASA A30 cabled + blades associated):" -ForegroundColor DarkGray
Write-Host "  │    .\09-fc-zoning.ps1 -Enable" -ForegroundColor Cyan
Write-Host "  └─────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
