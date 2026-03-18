#Requires -Version 5.1
<#
.SYNOPSIS
    Section 02 – VLANs and VSANs
.DESCRIPTION
    Adds the HumbledGeeks VLANs to the fabric LAN cloud (they share the
    existing dc3-* VLANs) and creates dedicated VSANs in the FC Storage
    Cloud for hg-vsan-a (Fabric A) and hg-vsan-b (Fabric B).
.NOTES
    Run 00-prereqs-and-connect.ps1 first.
    The dc3-* VLANs are assumed to already exist in the global LAN cloud.
#>

. "$PSScriptRoot\00-prereqs-and-connect.ps1"
$h = $global:UcsHandle

Write-Host "`n========== 02 – VLANs & VSANs ==========" -ForegroundColor Cyan

# ── VLANs (global LAN cloud – shared across the domain) ──────────────────
Write-Host "`n[VLAN] Verifying required VLANs exist in LAN cloud..."
$requiredVlans = @(
    @{ Id = 1;   Name = 'default'       },
    @{ Id = 13;  Name = 'dc3-iscsi-a'   },
    @{ Id = 14;  Name = 'dc3-iscsi-b'   },
    @{ Id = 15;  Name = 'dc3-nfs'       },
    @{ Id = 16;  Name = 'dc3-mgmt'      },
    @{ Id = 17;  Name = 'dc3-vmotion'   },
    @{ Id = 18;  Name = 'dc3-apps'      },
    @{ Id = 20;  Name = 'dc3-core'      }
)

foreach ($v in $requiredVlans) {
    $exists = Get-UcsVlan -Ucs $h | Where-Object { $_.Id -eq $v.Id }
    if ($exists) {
        Write-Host "  [OK]   VLAN $($v.Id)  ($($v.Name))" -ForegroundColor Green
    } else {
        Write-Warning "  [MISSING] VLAN $($v.Id) ($($v.Name)) — creating..."
        Add-UcsVlan -Ucs $h `
            -Name      $v.Name `
            -Id        $v.Id `
            -DefaultNet 'no' `
            -ModifyPresent
        Write-Host "  [OK]   VLAN $($v.Id) created" -ForegroundColor Green
    }
}

# ── VSANs – FC Storage Cloud ──────────────────────────────────────────────
Write-Host "`n[VSAN] Creating VSANs in FC Storage Cloud..."

# Fabric A: hg-vsan-a  ID=10  FCoE VLAN=1010
try {
    $vsanA = Add-UcsVsan -Ucs $h `
        -Name       'hg-vsan-a' `
        -Id         '10' `
        -FcoeVlan   '1010' `
        -FabricId   'A' `
        -ZoningState 'disabled' `
        -ModifyPresent
    Write-Host "  [OK]   hg-vsan-a  ID=10  FCoE=1010  Fabric=A" -ForegroundColor Green
} catch {
    Write-Warning "  hg-vsan-a: $($_.Exception.Message)"
}

# Fabric B: hg-vsan-b  ID=11  FCoE VLAN=1011
try {
    $vsanB = Add-UcsVsan -Ucs $h `
        -Name       'hg-vsan-b' `
        -Id         '11' `
        -FcoeVlan   '1011' `
        -FabricId   'B' `
        -ZoningState 'disabled' `
        -ModifyPresent
    Write-Host "  [OK]   hg-vsan-b  ID=11  FCoE=1011  Fabric=B" -ForegroundColor Green
} catch {
    Write-Warning "  hg-vsan-b: $($_.Exception.Message)"
}

# ── FC Storage Port VSAN member assignments ────────────────────────────────
# Assign FC storage ports 29-32 on each FI to their respective VSANs.
# NOTE: In UCSM PS module this is done via Set-UcsFabricFcStorageCloud
# or direct MO manipulation. Shown here for reference.
Write-Host "`n[VSAN] FC Storage Port assignments (ports 29–32)..."
Write-Host "  NOTE: Verify in UCSM GUI that FC Storage ports 29–32 on FI-A" -ForegroundColor Yellow
Write-Host "        are members of hg-vsan-a and ports 29–32 on FI-B are" -ForegroundColor Yellow
Write-Host "        members of hg-vsan-b. Configure via CLI if needed:" -ForegroundColor Yellow
Write-Host "        scope fc-storage > scope fabric a > scope vsan hg-vsan-a" -ForegroundColor DarkGray
Write-Host "        create member-port fc a 1 <29|30|31|32>" -ForegroundColor DarkGray

Write-Host "`n[DONE] Section 02 – VLANs & VSANs complete.`n" -ForegroundColor Green
