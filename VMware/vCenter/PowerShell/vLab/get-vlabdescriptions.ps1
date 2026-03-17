<#
.SYNOPSIS
    Reads and returns vLab descriptions from the CMDB descriptions table.
.DESCRIPTION
    Loads the key=value description entries from the cmdb\descriptions.tbl
    file located relative to this script's directory. Returns a hashtable
    mapping vLab names to their human-readable descriptions. Used by the
    vLab catalog display scripts to annotate lab entries with descriptions.
.EXAMPLE
    $descriptions = .\get-vlabdescriptions.ps1
    $descriptions["MyLabName"]
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : None (built-in PowerShell only)
    Repo    : infra-automation/VMware/vCenter/PowerShell/vLab
    Prereq  : cmdb\descriptions.tbl must exist relative to this script.
              Format: LabName=Description text, one per line.
#>

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$configfile="$ScriptDirectory\cmdb\descriptions.tbl"

#load settings from file
$descriptions = Get-Content $configfile | Out-String | ConvertFrom-StringData


$descriptions
