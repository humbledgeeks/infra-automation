#Requires -Version 5.1
<#
.SYNOPSIS
    Section 07b – Associate Service Profiles to physical blades
.DESCRIPTION
    Binds the 8 hg-esx-* service profiles (created by 07-deploy-service-profiles.ps1)
    to physical blades in chassis 1.

    Default blade-to-SP mapping (edit $bladeMap below to match your slot layout):
      hg-esx-01  →  chassis-1 / blade-1   (Management Domain)
      hg-esx-02  →  chassis-1 / blade-2   (Management Domain)
      hg-esx-03  →  chassis-1 / blade-3   (Management Domain)
      hg-esx-04  →  chassis-1 / blade-4   (Management Domain)
      hg-esx-05  →  chassis-1 / blade-5   (VI Workload Domain)
      hg-esx-06  →  chassis-1 / blade-6   (VI Workload Domain)
      hg-esx-07  →  chassis-1 / blade-7   (VI Workload Domain)
      hg-esx-08  →  chassis-1 / blade-8   (VI Workload Domain)

    Pre-requisites before running:
      - 07-deploy-service-profiles.ps1 has been run (profiles exist)
      - ASA A30 is physically cabled to FI storage ports 29–32
      - FC Zoning is configured in UCSM (see 09-fc-zoning.ps1 — upcoming)
      - Blades are discovered in UCSM with assocState = 'unassociated'

    After association, UCSM will apply all policies (BIOS, boot, networking,
    storage) which triggers a user-ack pending change. Acknowledge it in UCSM
    to allow the blade to power-cycle and come up with the new identity.
.PARAMETER DeployCount
    Number of service profiles to associate (1–8). Defaults to 8.
.NOTES
    Run 07-deploy-service-profiles.ps1 first.
    FC Zoning must be in place before ESXi can see the ASA A30 datastores.
#>

param([int]$DeployCount = 8)

. "$PSScriptRoot\00-prereqs-and-connect.ps1"
$h   = $global:UcsHandle
$org = $global:HgOrg

Write-Host "`n========== 07b – Associate Service Profiles to Blades ==========" -ForegroundColor Cyan

# ── Blade map — edit slot numbers to match your physical layout ──────────────
$bladeMap = @(
    @{ Sp = 'hg-esx-01'; Chassis = 1; Blade = 1; Role = 'Management Domain' },
    @{ Sp = 'hg-esx-02'; Chassis = 1; Blade = 2; Role = 'Management Domain' },
    @{ Sp = 'hg-esx-03'; Chassis = 1; Blade = 3; Role = 'Management Domain' },
    @{ Sp = 'hg-esx-04'; Chassis = 1; Blade = 4; Role = 'Management Domain' },
    @{ Sp = 'hg-esx-05'; Chassis = 1; Blade = 5; Role = 'VI Workload Domain' },
    @{ Sp = 'hg-esx-06'; Chassis = 1; Blade = 6; Role = 'VI Workload Domain' },
    @{ Sp = 'hg-esx-07'; Chassis = 1; Blade = 7; Role = 'VI Workload Domain' },
    @{ Sp = 'hg-esx-08'; Chassis = 1; Blade = 8; Role = 'VI Workload Domain' }
)

for ($i = 0; $i -lt $DeployCount; $i++) {
    $bm = $bladeMap[$i]
    Write-Host "`n[ASSOC] $($bm.Sp)  →  chassis-$($bm.Chassis)/blade-$($bm.Blade)  ($($bm.Role))"

    # Retrieve the service profile
    $sp = Get-UcsServiceProfile -Ucs $h | Where-Object {
        $_.Dn -like "*$($org.Name)*" -and $_.Name -eq $bm.Sp
    } | Select-Object -First 1

    if (-not $sp) {
        Write-Warning "  Service profile '$($bm.Sp)' not found — run 07-deploy-service-profiles.ps1 first"
        continue
    }
    if ($sp.AssocState -eq 'associated') {
        Write-Host "  [SKIP] $($bm.Sp) is already associated to $($sp.PnDn)" -ForegroundColor DarkYellow
        continue
    }

    # Retrieve the physical blade
    $blade = Get-UcsBlade -Ucs $h -ChassisId $bm.Chassis -ServerId $bm.Blade
    if (-not $blade) {
        Write-Warning "  Blade chassis-$($bm.Chassis)/blade-$($bm.Blade) not found — check discovery"
        continue
    }
    if ($blade.AssocState -ne 'unassociated') {
        Write-Warning "  Blade $($blade.Dn) assocState=$($blade.AssocState) — cannot associate"
        continue
    }

    # Bind SP to blade
    Add-UcsLsBinding -ServiceProfile $sp -Ucs $h -PnDn $blade.Dn | Out-Null
    Write-Host "  [OK]   $($bm.Sp) bound to $($blade.Dn)  (user-ack pending)" -ForegroundColor Green
}

# ── Post-association state ────────────────────────────────────────────────────
Write-Host "`n--- Service Profile States after Association ---" -ForegroundColor Yellow
Get-UcsServiceProfile -Ucs $h | Where-Object { $_.Dn -like "*$($org.Name)*" } |
    Select-Object Name, Type, AssocState, OperState, PnDn |
    Format-Table -AutoSize

Write-Host "`n[DONE] Section 07b – Association complete.`n" -ForegroundColor Green
Write-Host "       IMPORTANT: Acknowledge user-ack pending changes in UCSM:" -ForegroundColor Yellow
Write-Host "       Service Profiles → [SP name] → Pending Changes → Acknowledge" -ForegroundColor DarkGray
Write-Host "       Each blade will power-cycle and come up with its new identity." -ForegroundColor DarkGray
Write-Host "`n       After blades are up, run 08-verify.ps1 to confirm pool utilisation." -ForegroundColor DarkGray
