#Requires -Version 5.1
<#
.SYNOPSIS
    Section 08 – Post-deployment verification
.DESCRIPTION
    Queries UCSM and prints a summary table of all HumbledGeeks objects,
    pool utilisation, active faults, and service profile states.
    Run after any deployment section to confirm expected state.
.NOTES
    Run 00-prereqs-and-connect.ps1 first.
#>

. "$PSScriptRoot\00-prereqs-and-connect.ps1"
$h = $global:UcsHandle

Write-Host "`n========== 08 – Verification Report ==========" -ForegroundColor Cyan

# ── Pools ──────────────────────────────────────────────────────────────────
Write-Host "`n--- Pools ---" -ForegroundColor Yellow
Get-UcsMacPool      -Ucs $h | Where-Object {$_.Dn -like '*HumbledGeeks*'} |
    Select-Object Name, Size, Assigned, AssignmentOrder | Format-Table -AutoSize
Get-UcsUuidSuffixPool -Ucs $h | Where-Object {$_.Dn -like '*HumbledGeeks*'} |
    Select-Object Name, Size, Assigned | Format-Table -AutoSize
Get-UcsFcpoolInitiators -Ucs $h | Where-Object {$_.Dn -like '*HumbledGeeks*'} |
    Select-Object Name, Purpose, Size, Assigned | Format-Table -AutoSize
Get-UcsIpPool -Ucs $h | Where-Object {$_.Dn -like '*HumbledGeeks*'} |
    Select-Object Name, Size, Assigned | Format-Table -AutoSize

# ── VLANs ─────────────────────────────────────────────────────────────────
Write-Host "`n--- VLANs (LAN Cloud) ---" -ForegroundColor Yellow
Get-UcsVlan -Ucs $h | Sort-Object {[int]$_.Id} |
    Select-Object Id, Name, DefaultNet | Format-Table -AutoSize

# ── VSANs ─────────────────────────────────────────────────────────────────
Write-Host "`n--- VSANs (Storage Cloud) ---" -ForegroundColor Yellow
Get-UcsVsan -Ucs $h |
    Select-Object Name, Id, FcoeVlan, FabricId, OperState | Format-Table -AutoSize

# ── vNIC / vHBA Templates ─────────────────────────────────────────────────
Write-Host "`n--- vNIC Templates ---" -ForegroundColor Yellow
Get-UcsVnicTemplate -Ucs $h | Where-Object {$_.Dn -like '*HumbledGeeks*'} |
    Select-Object Name, SwitchId, TemplType, Mtu, IdentPoolName | Format-Table -AutoSize

Write-Host "`n--- vHBA Templates ---" -ForegroundColor Yellow
Get-UcsVhbaTemplate -Ucs $h | Where-Object {$_.Dn -like '*HumbledGeeks*'} |
    Select-Object Name, SwitchId, TemplType, IdentPoolName | Format-Table -AutoSize

# ── Service Profiles ──────────────────────────────────────────────────────
Write-Host "`n--- Service Profiles ---" -ForegroundColor Yellow
Get-UcsServiceProfile -Ucs $h | Where-Object {$_.Dn -like '*HumbledGeeks*'} |
    Select-Object Name, Type, AssocState, OperState, ExtIPState | Format-Table -AutoSize

# ── Active Faults ─────────────────────────────────────────────────────────
Write-Host "`n--- Active Faults (critical/major/warning) ---" -ForegroundColor Yellow
$faults = Get-UcsFault -Ucs $h | Where-Object {
    $_.Severity -in 'critical','major','warning' -and $_.Ack -eq 'no'
}
if ($faults) {
    $faults | Select-Object Severity, Code, Dn, Descr | Format-Table -AutoSize
} else {
    Write-Host "  No unacknowledged critical/major/warning faults.`n" -ForegroundColor Green
}

# ── Port Channels ─────────────────────────────────────────────────────────
Write-Host "`n--- Uplink Port Channels ---" -ForegroundColor Yellow
Get-UcsFabricEthLanPc -Ucs $h |
    Select-Object Name, PortId, OperState, OperSpeed, Transport | Format-Table -AutoSize

Write-Host "`n[DONE] Verification complete.`n" -ForegroundColor Green
