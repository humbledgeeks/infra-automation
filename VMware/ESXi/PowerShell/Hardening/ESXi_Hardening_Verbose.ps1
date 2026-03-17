<#
.SYNOPSIS
    Applies recommended VMware security hardening advanced settings to ESXi hosts.
.DESCRIPTION
    Reads a list of ESXi hosts from C:\ESXi_Hardening\hosts.csv, connects to each
    host, and applies recommended security advanced settings including:
      Config.HostAgent.log.level, Config.HostAgent.plugins.solo.enableMob,
      Mem.ShareForceSalting, Security.AccountLockFailures,
      Security.AccountUnlockTime, Security.PasswordHistory,
      UserVars.DcuiTimeOut, UserVars.ESXiShellInteractiveTimeOut,
      UserVars.ESXiShellTimeOut, UserVars.ESXiVPsDisabledProtocols,
      VMkernel.Boot.execInstalledOnly, Misc.BlueScreenTimeout
    Produces three timestamped output files per run in C:\ESXi_Hardening\:
      - ESXi_AdvancedSettings_Changes_<ts>.csv   : settings modified
      - ESXi_AdvancedSettings_Baseline_<ts>.csv  : pre-change values snapshot
      - ESXi_AdvancedSettings_Log_<ts>.txt        : human-readable run log
    Color output: Yellow = changed, Green = compliant, Red = error.
    For production use, prefer ESXi_Hardening_V6h.ps1 which adds dry-run
    mode, KPI dashboard, themed UI, and per-setting override capability.
.PARAMETER None
    No parameters. Host list is driven by C:\ESXi_Hardening\hosts.csv.
    CSV must contain a column named "HostName".
.EXAMPLE
    .\ESXi_Hardening_Verbose.ps1
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : VMware.PowerCLI
    Repo    : infra-automation/VMware/ESXi/PowerShell/Hardening
    Prereq  : PowerCLI installed; C:\ESXi_Hardening\hosts.csv present with
              a "HostName" column. Prompts for credentials once at runtime.
    See also: ESXi_Hardening_V6h.ps1 (recommended for new deployments)
#>

#====================================================================================================================
#  Apply Recommended Advanced Settings to ESXi Hosts
#  Yellow = changed, Green = compliant, Red = error
#  Logs: Changes CSV, Baseline CSV, and Human-Readable TXT
#====================================================================================================================

[CmdletBinding()]
param ()

function Write-ChangedSetting {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
    $Message | Out-File -FilePath $textLogPath -Append -Encoding UTF8
}

function Write-CompliantSetting {
    param ([string]$Message)
    Write-Host $Message -ForegroundColor Green
    $Message | Out-File -FilePath $textLogPath -Append -Encoding UTF8
}

# Recommended advanced settings
$recommendedSettings = @{
    "Config.HostAgent.log.level"              = "info"
    "Config.HostAgent.plugins.solo.enableMob" = "False"
    "Mem.ShareForceSalting"                   = "2"
    "Security.AccountLockFailures"            = "5"
    "Security.AccountUnlockTime"              = "900"
    "Security.PasswordHistory"                = "5"
    "UserVars.DcuiTimeOut"                    = "600"
    "UserVars.ESXiShellInteractiveTimeOut"    = "900"
    "UserVars.ESXiShellTimeOut"               = "900"
    "UserVars.ESXiVPsDisabledProtocols"       = "sslv3,tlsv1,tlsv1.1"
    "VMkernel.Boot.execInstalledOnly"         = "True"
    "Misc.BlueScreenTimeout"                  = "60"
}

# Paths and logs
$basePath = "C:\ESXi_Hardening"
$csvPath = Join-Path $basePath "hosts.csv"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$changeLogCsv = Join-Path $basePath "ESXi_AdvancedSettings_Changes_${timestamp}.csv"
$baselineCsv  = Join-Path $basePath "ESXi_AdvancedSettings_Baseline_${timestamp}.csv"
$textLogPath  = Join-Path $basePath "ESXi_AdvancedSettings_Log_${timestamp}.txt"

# Initialize output files
"Timestamp,HostName,Setting,OldValue,NewValue,Result" | Out-File -FilePath $changeLogCsv -Encoding UTF8
"Timestamp,HostName,Setting,CurrentValue"             | Out-File -FilePath $baselineCsv  -Encoding UTF8
"[{0}] Starting ESXi Hardening Run" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Out-File -FilePath $textLogPath -Encoding UTF8

# Validate CSV
if (-not (Test-Path $csvPath)) {
    Write-Host "CSV file not found at: $csvPath" -ForegroundColor Red
    exit
}
$hosts = Import-Csv -Path $csvPath

# Prompt once for credentials
$cred = Get-Credential -Message "Enter ESXi root/admin credentials"

foreach ($hostEntry in $hosts) {
    $hostName = $hostEntry.HostName
    $startMsg = "`n[{0}] Connecting to {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $hostName
    Write-Host $startMsg -ForegroundColor Cyan
    $startMsg | Out-File -FilePath $textLogPath -Append -Encoding UTF8

    try {
        Connect-VIServer -Server $hostName -Credential $cred -ErrorAction Stop | Out-Null
        $vmhost = Get-VMHost -Name $hostName -ErrorAction Stop
        $time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        foreach ($setting in $recommendedSettings.Keys) {
            $desiredValue = $recommendedSettings[$setting]
            $currentSetting = Get-AdvancedSetting -Entity $vmhost -Name $setting -ErrorAction SilentlyContinue

            if ($currentSetting) {
                $currentValue = $currentSetting.Value

                # Log baseline
                "$time,${hostName},${setting},${currentValue}" | Out-File -FilePath $baselineCsv -Append -Encoding UTF8

                if ($currentValue -ne $desiredValue) {
                    Set-AdvancedSetting -AdvancedSetting $currentSetting -Value $desiredValue -Confirm:$false -ErrorAction Stop | Out-Null
                    $log = "${hostName} - CHANGED: ${setting} from '${currentValue}' to '${desiredValue}'"
                    Write-ChangedSetting $log
                    "$time,${hostName},${setting},${currentValue},${desiredValue},Updated" | Out-File -FilePath $changeLogCsv -Append -Encoding UTF8
                } else {
                    $log = "${hostName} - COMPLIANT: ${setting} = '${currentValue}'"
                    Write-CompliantSetting $log
                    "$time,${hostName},${setting},${currentValue},${desiredValue},Already compliant" | Out-File -FilePath $changeLogCsv -Append -Encoding UTF8
                }
            }
        }

        ("[{0}] Finished processing {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $hostName) | Out-File -FilePath $textLogPath -Append -Encoding UTF8
        Disconnect-VIServer -Server $hostName -Confirm:$false | Out-Null
    }
    catch {
        $errMsg = "[{0}] ERROR with {1}: {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $hostName, $_.Exception.Message
        Write-Host $errMsg -ForegroundColor Red
        $errMsg | Out-File -FilePath $textLogPath -Append -Encoding UTF8
    }
}

# Final message
Write-Host "`n✅ Configuration complete." -ForegroundColor Cyan
Write-Host "📄 Changes CSV:     $changeLogCsv" -ForegroundColor Cyan
Write-Host "📄 Baseline CSV:    $baselineCsv" -ForegroundColor Cyan
Write-Host "📄 Log file (TXT):  $textLogPath" -ForegroundColor Cyan
