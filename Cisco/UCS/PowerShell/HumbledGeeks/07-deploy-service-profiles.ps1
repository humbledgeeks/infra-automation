#Requires -Version 5.1
<#
.SYNOPSIS
    Section 07 – Derive and associate Service Profiles from template
.DESCRIPTION
    Derives N named Service Profiles from hg-esx-template and associates
    each one to a physical blade in chassis 1.

    Blade-to-SP mapping (edit as needed):
      hg-esx-01  → chassis-1/blade-1  (B200 M5)
      hg-esx-02  → chassis-1/blade-2
      hg-esx-03  → chassis-1/blade-3
      ... up to hg-esx-08 / blade-8

    Set $DeployCount to the number of SPs you want to instantiate.
.PARAMETER DeployCount
    How many service profiles to derive and associate (1–8).
.NOTES
    Run 06-service-profile-template.ps1 first.
    Blades must be discovered (assocState=unassociated) before association.
#>

param([int]$DeployCount = 8)

. "$PSScriptRoot\00-prereqs-and-connect.ps1"
$h   = $global:UcsHandle
$org = $global:HgOrg

Write-Host "`n========== 07 – Deploy Service Profiles ==========" -ForegroundColor Cyan

# Blade slot → SP name map (adjust blade numbers to match your chassis)
$bladeMap = @(
    @{ Sp = 'hg-esx-01'; Chassis = 1; Blade = 1 },
    @{ Sp = 'hg-esx-02'; Chassis = 1; Blade = 2 },
    @{ Sp = 'hg-esx-03'; Chassis = 1; Blade = 3 },
    @{ Sp = 'hg-esx-04'; Chassis = 1; Blade = 4 },
    @{ Sp = 'hg-esx-05'; Chassis = 1; Blade = 5 },
    @{ Sp = 'hg-esx-06'; Chassis = 1; Blade = 6 },
    @{ Sp = 'hg-esx-07'; Chassis = 1; Blade = 7 },
    @{ Sp = 'hg-esx-08'; Chassis = 1; Blade = 8 }
)

for ($i = 0; $i -lt $DeployCount; $i++) {
    $bm = $bladeMap[$i]
    Write-Host "`n[SP] $($bm.Sp)  →  chassis-$($bm.Chassis)/blade-$($bm.Blade)"

    # Derive SP from template
    $sp = Add-UcsServiceProfile -Org $org -Ucs $h `
        -Name    $bm.Sp `
        -SrcTemplName 'hg-esx-template' `
        -Type    'instance' `
        -ModifyPresent

    # Associate to blade
    $blade = Get-UcsBlade -Ucs $h -ChassisId $bm.Chassis -ServerId $bm.Blade
    if (-not $blade) {
        Write-Warning "  Blade chassis-$($bm.Chassis)/blade-$($bm.Blade) not found — skipping association"
        continue
    }
    if ($blade.AssocState -ne 'unassociated') {
        Write-Warning "  Blade $($blade.Dn) assocState=$($blade.AssocState) — skipping"
        continue
    }

    Add-UcsLsBinding -ServiceProfile $sp -Ucs $h `
        -PnDn $blade.Dn | Out-Null

    Write-Host "  [OK]   $($bm.Sp) associated to $($blade.Dn)" -ForegroundColor Green
}

Write-Host "`n[DONE] Section 07 – Service Profiles deployed.`n" -ForegroundColor Green
Write-Host "       Monitor association progress:" -ForegroundColor DarkGray
Write-Host "       Get-UcsServiceProfile -Ucs `$global:UcsHandle | Where-Object { `$_.Dn -like '*HumbledGeeks*' } | Select Name,AssocState,OperState" -ForegroundColor DarkGray
