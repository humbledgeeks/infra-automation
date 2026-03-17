<#
.SYNOPSIS
    Reads and returns the vLab configuration settings from settings.cfg.
.DESCRIPTION
    Loads the key=value pairs from the settings.cfg file located in the same
    directory as this script and returns them as a hashtable. Used by other
    vLab scripts (set-vlabsettings.ps1, set-vlabcreds.ps1, start-vlabmenu.ps1)
    to retrieve vCenter FQDN, ONTAP cluster management IP, and other lab
    configuration values without hardcoding them.
.EXAMPLE
    $conf = .\get-vlabsettings.ps1
    $conf.vcenter
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : None (built-in PowerShell only)
    Repo    : infra-automation/VMware/vCenter/PowerShell/vLab
    Prereq  : settings.cfg must exist in the same directory as this script.
              Format: key=value, one per line.
#>

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$configfile="$ScriptDirectory\settings.cfg"

#load settings from file
$settings = Get-Content $configfile | Out-String | ConvertFrom-StringData

$settings
