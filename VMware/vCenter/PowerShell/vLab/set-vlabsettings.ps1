<#
.SYNOPSIS
    Updates a single key=value pair in the vLab settings.cfg configuration file.
.DESCRIPTION
    Reads the current settings from settings.cfg, updates the specified key
    with the new value, and writes the entire file back. All existing settings
    are preserved. Called interactively from start-vlabmenu.ps1's Settings Menu
    or directly from the command line.
.PARAMETER key
    The configuration key to update (e.g. "vcenter", "cluster_mgmt").
.PARAMETER value
    The new value to set for the specified key.
.EXAMPLE
    .\set-vlabsettings.ps1 -key vcenter -value vcenter.lab.local
.EXAMPLE
    .\set-vlabsettings.ps1 -key cluster_mgmt -value 10.10.10.100
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : None (built-in PowerShell only)
    Repo    : infra-automation/VMware/vCenter/PowerShell/vLab
    Prereq  : settings.cfg must exist in the current directory.
#>

Param(
  [Parameter(Mandatory=$True,Position=1)][string]$key,
  [Parameter(Mandatory=$True,Position=2)][string]$value
)

$configfile=".\settings.cfg"

#load settings from file
$settings = Get-Content $configfile | Out-String | ConvertFrom-StringData

$settings.$key=$value

$result=New-Item $configfile -type file -force
$settings.keys | %{ Add-Content $configfile "$_`=$($settings.$_)"}

$settings
