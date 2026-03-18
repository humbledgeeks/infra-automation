#Requires -Version 5.1
<#
.SYNOPSIS
    Section 03 – Org-level policies for HumbledGeeks
.DESCRIPTION
    Creates: Network Control Policy (hg-netcon), QoS policy (hg-qos-be),
    Local Disk Policy (hg-local-disk), Power Policy (hg-power),
    Maintenance Policy (hg-maint), Boot Policy (hg-flexflash),
    and BIOS Policy (hg-bios).
.NOTES
    Run 00-prereqs-and-connect.ps1 first.
    CDP and LLDP are set via XML API (correct attrs: cdp, lldpTransmit, lldpReceive).
    The Cisco.UCS PS module does not expose these directly — they are applied
    via a subsequent Invoke-UcsXml call at the end of the NCP section.
#>

. "$PSScriptRoot\00-prereqs-and-connect.ps1"
$h   = $global:UcsHandle
$org = $global:HgOrg

Write-Host "`n========== 03 – Policies ==========" -ForegroundColor Cyan

# ── Network Control Policy ────────────────────────────────────────────────
Write-Host "`n[POLICY] hg-netcon (Network Control)"
$ncp = Add-UcsNetworkControlPolicy -Org $org -Ucs $h `
    -Name             'hg-netcon' `
    -Descr            'CDP and LLDP enabled, forged MAC deny' `
    -UplinkFailAction 'link-down' `
    -MacRegisterMode  'only-native-vlan' `
    -ModifyPresent
# CDP and LLDP must be set via raw XML API (PS module does not expose these attrs)
$ncpDn = "org-root/org-HumbledGeeks/nwctrl-hg-netcon"
$cdpXml = @"
<configConfMos cookie="$($h.Cookie)" inHierarchical="false">
  <inConfigs>
    <pair key="$ncpDn">
      <nwctrlDefinition dn="$ncpDn"
        cdp="enabled" lldpTransmit="enabled" lldpReceive="enabled"
        status="modified"/>
    </pair>
  </inConfigs>
</configConfMos>
"@
Invoke-UcsXml -Ucs $h -Xml $cdpXml | Out-Null
Write-Host "  [OK]   hg-netcon: CDP=enabled, LLDP Tx/Rx=enabled" -ForegroundColor Green

# ── QoS Policy ────────────────────────────────────────────────────────────
Write-Host "`n[POLICY] hg-qos-be (QoS – Best Effort)"
$qos = Add-UcsQosPolicy -Org $org -Ucs $h `
    -Name  'hg-qos-be' `
    -Descr 'HumbledGeeks QoS — best effort' `
    -ModifyPresent
# Set the egress priority to best-effort
$qos | Get-UcsChild -ClassId 'EpqosEgress' | Set-UcsEgressPolicy `
    -Prio       'best-effort' `
    -Burst      '10240' `
    -Rate       'line-rate' `
    -HostControl 'none' `
    -Force
Write-Host "  [OK]   hg-qos-be" -ForegroundColor Green

# ── Local Disk Policy ─────────────────────────────────────────────────────
Write-Host "`n[POLICY] hg-local-disk"
$ldp = Add-UcsLocalDiskConfigPolicy -Org $org -Ucs $h `
    -Name              'hg-local-disk' `
    -Descr             'HumbledGeeks — any-config, FlexFlash enabled for SD card boot' `
    -Mode              'any-configuration' `
    -FlexFlashState    'enable' `
    -FlexFlashRAIDReportingState 'enable' `
    -ProtectConfig     'yes' `
    -ModifyPresent
Write-Host "  [OK]   hg-local-disk (mode=any-configuration, FlexFlash=enabled)" -ForegroundColor Green

# ── Power Policy ──────────────────────────────────────────────────────────
Write-Host "`n[POLICY] hg-power"
$pwr = Add-UcsPowerPolicy -Org $org -Ucs $h `
    -Name  'hg-power' `
    -Descr 'HumbledGeeks power policy — no cap' `
    -Prio  'no-cap' `
    -ModifyPresent
Write-Host "  [OK]   hg-power (prio=no-cap)" -ForegroundColor Green

# ── Maintenance Policy ────────────────────────────────────────────────────
Write-Host "`n[POLICY] hg-maint"
$maint = Add-UcsMaintenancePolicy -Org $org -Ucs $h `
    -Name         'hg-maint' `
    -Descr        'User-ack required before disruptive changes' `
    -UptimeDisr   'user-ack' `
    -DataDisr     'user-ack' `
    -TriggerConfig 'on-next-boot' `
    -ModifyPresent
Write-Host "  [OK]   hg-maint (uptimeDisr=user-ack, dataDisr=user-ack)" -ForegroundColor Green

# ── Boot Policy (UEFI: DVD → SSD → FlexFlash SD) ──────────────────────────
Write-Host "`n[POLICY] hg-flexflash (Boot Policy)"
$boot = Add-UcsBootPolicy -Org $org -Ucs $h `
    -Name          'hg-flexflash' `
    -Descr         'UEFI: DVD(1) SSD(2) FlexFlash SD(3)' `
    -BootMode      'uefi' `
    -EnforceVnicName 'yes' `
    -RebootOnUpdate  'no' `
    -ModifyPresent
# Order 1: DVD (read-only virtual media)
Add-UcsLsBootVirtualMedia -BootPolicy $boot -Ucs $h `
    -Access 'read-only' -Order 1 -ModifyPresent | Out-Null
# Order 2: SSD (embedded local disk)
$stor2 = Add-UcsLsBootStorage -BootPolicy $boot -Ucs $h `
    -Order 2 -ModifyPresent
$ls2   = Add-UcsLsBootLocalStorage -LsBootStorage $stor2 -Ucs $h -ModifyPresent
Add-UcsLsBootEmbeddedLocalDiskImage -LsBootLocalStorage $ls2 -Ucs $h `
    -Order 2 -ModifyPresent | Out-Null
# Order 3: FlexFlash SD card
$stor3 = Add-UcsLsBootStorage -BootPolicy $boot -Ucs $h `
    -Order 3 -ModifyPresent
$ls3   = Add-UcsLsBootLocalStorage -LsBootStorage $stor3 -Ucs $h -ModifyPresent
Add-UcsLsBootUsbFlashStorageImage -LsBootLocalStorage $ls3 -Ucs $h `
    -Order 3 -ModifyPresent | Out-Null
Write-Host "  [OK]   hg-flexflash: UEFI DVD(1) SSD(2) FlexFlash(3)" -ForegroundColor Green

# ── BIOS Policy (VMware optimised) ────────────────────────────────────────
Write-Host "`n[POLICY] hg-bios"
$bios = Add-UcsBiosPolicy -Org $org -Ucs $h `
    -Name  'hg-bios' `
    -Descr 'HumbledGeeks BIOS tuned for VMware ESXi' `
    -ModifyPresent
# Key BIOS tokens for virtualisation
$bios | Set-UcsBiosVfIntelVirtualizationTechnology   -VpIntelVirtualizationTechnology   'Enabled'  -Force
$bios | Set-UcsBiosVfIntelVTForDirectedIO             -VpIntelVTForDirectedIO             'Enabled'  -Force
$bios | Set-UcsBiosVfCPUPerformance                   -VpCPUPerformance                   'HPC'      -Force
$bios | Set-UcsBiosVfProcessorCState                  -VpProcessorCState                  'Disabled' -Force
$bios | Set-UcsBiosVfProcessorC1E                     -VpProcessorC1E                     'Disabled' -Force
$bios | Set-UcsBiosVfEnhancedIntelSpeedStep           -VpEnhancedIntelSpeedStep           'Disabled' -Force
$bios | Set-UcsBiosVfProcessorEnergyConfiguration     -VpProcessorEnergyConfiguration     'Performance' -Force
Write-Host "  [OK]   hg-bios (VT-x, VT-d, C-States disabled, Perf mode)" -ForegroundColor Green

Write-Host "`n[DONE] Section 03 – Policies complete.`n" -ForegroundColor Green
