#Requires -Version 5.1
<#
.SYNOPSIS
    Section 07 – Create Service Profiles from template (no blade association)
.DESCRIPTION
    Instantiates 8 named Service Profiles from hg-esx-template.
    Profiles are created in an unassociated state — blade binding is intentionally
    deferred so you can assign blades manually via the UCSM GUI (or run
    07b-associate-service-profiles.ps1 when ready).

    VCF 4+4 role mapping:
      hg-esx-01 … hg-esx-04  →  Management Domain  (vCenter, NSX Mgr, SDDC Manager)
      hg-esx-05 … hg-esx-08  →  VI Workload Domain  (first workload cluster)

    Re-running this script is idempotent — ModifyPresent skips profiles that
    already exist.
.NOTES
    Run 06-service-profile-template.ps1 first.
    To associate profiles to blades: use the UCSM GUI or 07b-associate-service-profiles.ps1
#>

. "$PSScriptRoot\00-prereqs-and-connect.ps1"
$h   = $global:UcsHandle
$org = $global:HgOrg

Write-Host "`n========== 07 – Create Service Profiles ==========" -ForegroundColor Cyan

# ── VCF role labels (informational only — not written to UCSM) ──────────────
$spDefs = @(
    @{ Name = 'hg-esx-01'; Role = 'Management Domain' },
    @{ Name = 'hg-esx-02'; Role = 'Management Domain' },
    @{ Name = 'hg-esx-03'; Role = 'Management Domain' },
    @{ Name = 'hg-esx-04'; Role = 'Management Domain' },
    @{ Name = 'hg-esx-05'; Role = 'VI Workload Domain' },
    @{ Name = 'hg-esx-06'; Role = 'VI Workload Domain' },
    @{ Name = 'hg-esx-07'; Role = 'VI Workload Domain' },
    @{ Name = 'hg-esx-08'; Role = 'VI Workload Domain' }
)

Write-Host "`n  Template  : hg-esx-template (updating-template)"
Write-Host "  Org       : $($org.Dn)"
Write-Host "  Profiles  : $($spDefs.Count) (unassociated)`n"

foreach ($def in $spDefs) {
    Write-Host "[SP] $($def.Name)  ($($def.Role))"

    $sp = Add-UcsServiceProfile -Org $org -Ucs $h `
        -Name         $def.Name `
        -SrcTemplName 'hg-esx-template' `
        -Type         'instance' `
        -ModifyPresent

    if ($sp) {
        Write-Host "  [OK]   $($def.Name)  created/verified  assocState=$($sp.AssocState)" -ForegroundColor Green
    } else {
        Write-Warning "  $($def.Name) — Add-UcsServiceProfile returned null; check UCSM for errors"
    }
}

# ── Summary ───────────────────────────────────────────────────────────────
Write-Host "`n--- Service Profile Summary ---" -ForegroundColor Yellow
Get-UcsServiceProfile -Ucs $h | Where-Object { $_.Dn -like "*$($org.Name)*" } |
    Select-Object Name, Type, SrcTemplName, AssocState, OperState |
    Format-Table -AutoSize

Write-Host "[DONE] Section 07 – 8 service profiles created (unassociated).`n" -ForegroundColor Green
Write-Host "       Next steps:" -ForegroundColor DarkGray
Write-Host "       1. Associate blades via UCSM GUI  OR  run 07b-associate-service-profiles.ps1" -ForegroundColor DarkGray
Write-Host "       2. Acknowledge any user-ack pending-changes in UCSM after association" -ForegroundColor DarkGray
Write-Host "       3. Run 08-verify.ps1 to confirm pool utilisation and SP states" -ForegroundColor DarkGray
