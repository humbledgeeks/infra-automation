#Requires -Version 5.1
<#
.SYNOPSIS
    Section 08 – Remove FC/vHBA configuration for UCS 6224 FI (no FC module)
.DESCRIPTION
    The current Fabric Interconnects (6224) do not support 16 Gb FC SFPs.
    This script cleanly removes all Fibre Channel configuration so the
    service profiles can be re-associated to blades and run on Ethernet/iSCSI
    until the 6332 FIs arrive.

    WHAT THIS SCRIPT REMOVES (in dependency order):
      1. vmhba0 + vmhba1 vHBAs from the SP Template  → cascades to all derived SPs
      2. WWNN pool binding from the SP Template
      3. vHBA templates     : hg-vmhba0, hg-vmhba1
      4. WWPN pools         : hg-wwpn-a, hg-wwpn-b
      5. WWNN pool          : hg-wwnn-pool
      6. VSANs              : hg-vsan-a (ID 10), hg-vsan-b (ID 11)

    WHAT THIS SCRIPT DOES NOT TOUCH:
      - Boot policy  (hg-flexflash) — already local/FlexFlash, no SAN boot targets
      - All vNICs and LAN configuration
      - All other policies (BIOS, power, maintenance, local disk)
      - WWPN/WWNN pool definitions in section 01 (left intact for 6332 redeploy)

    AFTER THIS SCRIPT:
      Run 07-deploy-service-profiles.ps1 then 07b-associate-service-profiles.ps1
      to re-associate the service profiles to the blades.

    REVERSIBILITY:
      When the 6332 FIs arrive, re-run sections 05, 06 (vHBA + SP Template),
      then 07b to re-associate. The WWPN/WWNN pools from section 01 are
      preserved and ready to use.

.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-19
    Version : 1.0
    Repo    : infra-automation/Cisco/UCS/PowerShell/HumbledGeeks/
    Run 00-prereqs-and-connect.ps1 first.
#>

. "$PSScriptRoot\00-prereqs-and-connect.ps1"
$h   = $global:UcsHandle
$org = $global:HgOrg

Write-Host "`n========== 08 – FC Cleanup (6224 → 6332 prep) ==========" -ForegroundColor Cyan
Write-Host "  Removing all FC/vHBA config from SP Template and FC Storage Cloud." -ForegroundColor Yellow
Write-Host "  Boot policy (hg-flexflash) is local-only — no SAN boot to remove.`n" -ForegroundColor Yellow

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Remove vHBAs from the Service Profile Template
#          This cascades automatically to all derived service profiles.
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "[STEP 1] Removing vHBAs from SP Template: hg-esx-template" -ForegroundColor Cyan

$spTempl = Get-UcsServiceProfile -Org $org -Ucs $h -Name 'hg-esx-template' -Type 'updating-template'
if (-not $spTempl) {
    Write-Warning "  SP Template 'hg-esx-template' not found — skipping vHBA removal."
} else {
    foreach ($vhbaName in @('vmhba0', 'vmhba1')) {
        $vhba = Get-UcsVhba -ServiceProfile $spTempl -Ucs $h | Where-Object { $_.Name -eq $vhbaName }
        if ($vhba) {
            try {
                Remove-UcsVhba -Vhba $vhba -Ucs $h -Force
                Write-Host "  [OK]   Removed vHBA '$vhbaName' from hg-esx-template" -ForegroundColor Green
            } catch {
                Write-Warning "  [WARN] Could not remove vHBA '$vhbaName': $($_.Exception.Message)"
            }
        } else {
            Write-Host "  [SKIP] vHBA '$vhbaName' not found in template (already removed?)" -ForegroundColor DarkGray
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — Clear WWNN pool binding from SP Template
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[STEP 2] Clearing WWNN pool binding from SP Template" -ForegroundColor Cyan

if ($spTempl) {
    try {
        $spTempl | Set-UcsServiceProfile -Ucs $h -NodeWwnPoolName '' -Force | Out-Null
        Write-Host "  [OK]   WWNN pool binding cleared from hg-esx-template" -ForegroundColor Green
    } catch {
        Write-Warning "  [WARN] Could not clear WWNN pool: $($_.Exception.Message)"
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Remove vHBA Templates
#          Must come AFTER removing from SP Template (can't delete in-use objects)
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[STEP 3] Removing vHBA Templates" -ForegroundColor Cyan

foreach ($templName in @('hg-vmhba0', 'hg-vmhba1')) {
    $vt = Get-UcsVhbaTemplate -Org $org -Ucs $h | Where-Object { $_.Name -eq $templName }
    if ($vt) {
        try {
            Remove-UcsVhbaTemplate -VhbaTemplate $vt -Ucs $h -Force
            Write-Host "  [OK]   Removed vHBA template '$templName'" -ForegroundColor Green
        } catch {
            Write-Warning "  [WARN] Could not remove vHBA template '$templName': $($_.Exception.Message)"
        }
    } else {
        Write-Host "  [SKIP] vHBA template '$templName' not found" -ForegroundColor DarkGray
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Remove WWPN Pools
#          Pools in section 01 are preserved in the script; we only remove
#          the live objects so the FI is clean.
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[STEP 4] Removing WWPN Pools" -ForegroundColor Cyan

foreach ($poolName in @('hg-wwpn-a', 'hg-wwpn-b')) {
    $pool = Get-UcsWwnPool -Org $org -Ucs $h | Where-Object { $_.Name -eq $poolName -and $_.Purpose -eq 'port-wwn-assignment' }
    if ($pool) {
        try {
            Remove-UcsWwnPool -WwnPool $pool -Ucs $h -Force
            Write-Host "  [OK]   Removed WWPN pool '$poolName'" -ForegroundColor Green
        } catch {
            Write-Warning "  [WARN] Could not remove WWPN pool '$poolName': $($_.Exception.Message)"
        }
    } else {
        Write-Host "  [SKIP] WWPN pool '$poolName' not found" -ForegroundColor DarkGray
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — Remove WWNN Pool
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[STEP 5] Removing WWNN Pool" -ForegroundColor Cyan

$wwnnPool = Get-UcsWwnPool -Org $org -Ucs $h | Where-Object { $_.Name -eq 'hg-wwnn-pool' -and $_.Purpose -eq 'node-wwn-assignment' }
if ($wwnnPool) {
    try {
        Remove-UcsWwnPool -WwnPool $wwnnPool -Ucs $h -Force
        Write-Host "  [OK]   Removed WWNN pool 'hg-wwnn-pool'" -ForegroundColor Green
    } catch {
        Write-Warning "  [WARN] Could not remove WWNN pool 'hg-wwnn-pool': $($_.Exception.Message)"
    }
} else {
    Write-Host "  [SKIP] WWNN pool 'hg-wwnn-pool' not found" -ForegroundColor DarkGray
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 6 — Remove VSANs from FC Storage Cloud
#          Must come AFTER vHBA templates are removed (can't delete referenced VSANs)
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[STEP 6] Removing VSANs from FC Storage Cloud" -ForegroundColor Cyan

foreach ($vsanName in @('hg-vsan-a', 'hg-vsan-b')) {
    $vsan = Get-UcsVsan -Ucs $h | Where-Object { $_.Name -eq $vsanName }
    if ($vsan) {
        try {
            Remove-UcsVsan -Vsan $vsan -Ucs $h -Force
            Write-Host "  [OK]   Removed VSAN '$vsanName'" -ForegroundColor Green
        } catch {
            Write-Warning "  [WARN] Could not remove VSAN '$vsanName': $($_.Exception.Message)"
        }
    } else {
        Write-Host "  [SKIP] VSAN '$vsanName' not found" -ForegroundColor DarkGray
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n========== CLEANUP COMPLETE ==========" -ForegroundColor Green
Write-Host ""
Write-Host "  FC configuration has been removed from the 6224 domain." -ForegroundColor Green
Write-Host "  SP Template 'hg-esx-template' now has 6x vNICs only (no vHBAs)." -ForegroundColor Green
Write-Host ""
Write-Host "  NEXT STEPS:" -ForegroundColor Cyan
Write-Host "    1. Run 07-deploy-service-profiles.ps1  (create/refresh profiles)" -ForegroundColor White
Write-Host "    2. Run 07b-associate-service-profiles.ps1  (associate to blades)" -ForegroundColor White
Write-Host ""
Write-Host "  WHEN 6332 FIs ARRIVE:" -ForegroundColor Cyan
Write-Host "    Re-run sections 05 (vHBA templates), 06 (SP Template), 07b (associate)" -ForegroundColor White
Write-Host "    WWPN/WWNN pool definitions in 01-pools.ps1 are preserved and ready." -ForegroundColor White
Write-Host ""
