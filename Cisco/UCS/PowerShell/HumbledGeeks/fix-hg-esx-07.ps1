##############################################################################
# fix-hg-esx-07.ps1
# One-shot fix for hg-esx-07 F0332 fault:
#   1. Connect to UCSM (with session-limit retry)
#   2. Clear stale lsBinding at org-root/org-HumbledGeeks/ls-hg-esx-07/pn
#   3. Re-associate service profile to chassis-1/blade-7
#   4. Verify association + fault status
#   5. Disconnect cleanly
##############################################################################

param(
    [string]$UCSMHost = "10.103.12.20",
    [int]$MaxRetries  = 15,
    [int]$RetryDelay  = 30
)

#-- Credentials --------------------------------------------------------------
$user = "admin"
$pass = Read-Host "UCSM password for $user" -AsSecureString
$cred = New-Object System.Management.Automation.PSCredential($user, $pass)

#-- Connect with retry -------------------------------------------------------
Write-Host "`n[1/4] Connecting to UCSM $UCSMHost ..." -ForegroundColor Cyan
$h = $null
for ($attempt = 1; $attempt -le $MaxRetries; $attempt++) {
    try {
        $h = Connect-Ucs -Name $UCSMHost -Credential $cred -NotDefault -ErrorAction Stop
        Write-Host "      Connected on attempt $attempt. Cookie: $($h.Cookie.Substring(0,12))..." -ForegroundColor Green
        break
    } catch {
        if ($_.Exception.Message -match '572|maximum session|session limit') {
            Write-Warning "      Session limit hit (attempt $attempt/$MaxRetries). Waiting ${RetryDelay}s for a slot to free up..."
            Start-Sleep -Seconds $RetryDelay
        } else {
            Write-Error "      Connection failed: $_"
            exit 1
        }
    }
}
if (-not $h) {
    Write-Error "Could not connect after $MaxRetries attempts. Sessions have not expired yet — wait ~30 min and try again."
    exit 1
}

try {
    #-- Step 2: Clear stale lsBinding ----------------------------------------
    Write-Host "`n[2/4] Clearing stale lsBinding for hg-esx-07 ..." -ForegroundColor Cyan

    $bindingDn = "org-root/org-HumbledGeeks/ls-hg-esx-07/pn"
    $delXml = @"
<configConfMo cookie="$($h.Cookie)" inHierarchical="false">
  <inConfig>
    <lsBinding dn="$bindingDn" status="deleted"/>
  </inConfig>
</configConfMo>
"@

    $result = Invoke-UcsXml -Ucs $h -XmlQuery $delXml
    if ($result -match 'errorCode') {
        # If it returns an error the binding may already be gone — check
        if ($result -match 'errorCode="103"') {
            Write-Host "      lsBinding not found — already cleared (that's fine)." -ForegroundColor Yellow
        } else {
            Write-Warning "      Unexpected response: $result"
        }
    } else {
        Write-Host "      lsBinding deleted OK." -ForegroundColor Green
    }

    Start-Sleep -Seconds 3

    #-- Step 3: Re-associate SP to blade 7 -----------------------------------
    Write-Host "`n[3/4] Re-associating hg-esx-07 to chassis-1/blade-7 ..." -ForegroundColor Cyan

    $sp    = Get-UcsServiceProfile -Ucs $h | Where-Object { $_.Name -eq 'hg-esx-07' }
    $blade = Get-UcsBlade -Ucs $h | Where-Object { $_.ChassisId -eq '1' -and $_.SlotId -eq '7' }

    if (-not $sp) {
        Write-Error "Service profile hg-esx-07 not found."
        exit 1
    }
    if (-not $blade) {
        Write-Error "Blade chassis-1/blade-7 not found."
        exit 1
    }

    Write-Host "      SP DN   : $($sp.Dn)"
    Write-Host "      Blade DN: $($blade.Dn)"

    Add-UcsLsBinding -ServiceProfile $sp -Ucs $h -PnDn $blade.Dn -ErrorAction Stop | Out-Null
    Write-Host "      Association triggered." -ForegroundColor Green

    #-- Step 4: Verify -------------------------------------------------------
    Write-Host "`n[4/4] Waiting 20s then verifying association ..." -ForegroundColor Cyan
    Start-Sleep -Seconds 20

    # Check SP assoc state
    $spCheck = Get-UcsServiceProfile -Ucs $h | Where-Object { $_.Name -eq 'hg-esx-07' }
    Write-Host ("      hg-esx-07  AssocState={0}  OperState={1}" -f $spCheck.AssocState, $spCheck.OperState)

    # Check blade availability
    $bladeCheck = Get-UcsBlade -Ucs $h | Where-Object { $_.ChassisId -eq '1' -and $_.SlotId -eq '7' }
    Write-Host ("      Blade 7    Availability={0}  AssocState={1}" -f $bladeCheck.Availability, $bladeCheck.AssocState)

    # Check for remaining F0332 faults on hg-esx-07
    $faults = Get-UcsFault -Ucs $h | Where-Object { $_.Dn -match 'hg-esx-07' -and $_.Severity -ne 'cleared' }
    if ($faults) {
        Write-Warning "      Active faults on hg-esx-07:"
        $faults | Format-Table Severity, Code, Descr, Created -AutoSize
    } else {
        Write-Host "      No active faults on hg-esx-07." -ForegroundColor Green
    }

    # Summary of all 8 blades
    Write-Host "`n--- All blade association status ---" -ForegroundColor Cyan
    Get-UcsBlade -Ucs $h |
        Where-Object { $_.ChassisId -eq '1' } |
        Sort-Object SlotId |
        Select-Object SlotId, Model, Availability, AssocState |
        Format-Table -AutoSize

} finally {
    #-- Always disconnect cleanly --------------------------------------------
    Write-Host "`nDisconnecting from UCSM ..." -ForegroundColor DarkGray
    try { Disconnect-Ucs -Ucs $h -ErrorAction SilentlyContinue } catch {}
    Write-Host "Done." -ForegroundColor Green
}
