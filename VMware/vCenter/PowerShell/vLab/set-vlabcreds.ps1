<#
.SYNOPSIS
    Prompts for vCenter and ONTAP credentials and saves them as encrypted CliXml files.
.DESCRIPTION
    Reads the vCenter FQDN and ONTAP cluster management address from settings.cfg
    via get-vlabsettings.ps1, then prompts the user separately for vCenter
    credentials and ONTAP cluster credentials. Saves each as an encrypted
    CliXml file (vicred.clixml and nccred.clixml) in the script directory.
    These credential files are loaded by other vLab scripts and are encrypted
    to the current Windows user account — they cannot be used on another
    machine or by a different user.
.EXAMPLE
    .\set-vlabcreds.ps1
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : VMware.PowerCLI, NetApp.ONTAP (consumed by other vLab scripts)
    Repo    : infra-automation/VMware/vCenter/PowerShell/vLab
    Output  : vicred.clixml  — encrypted vCenter PSCredential
              nccred.clixml  — encrypted ONTAP PSCredential
    Prereq  : settings.cfg must exist with "vcenter" and "cluster_mgmt" keys.
              Run once per machine/user before using the vLab automation kit.
#>

# set-vlabcreds

# Settings
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$conf=. "$ScriptDirectory\get-vlabsettings.ps1"
$vcenter=$conf.vcenter
$ontap=$conf.cluster_mgmt

Write-Host "Enter Credentials for"$conf.vCenter
$VICred = Get-Credential -message "Enter the credentials for vCenter server $vcenter"
$VICred | Export-CliXml "$ScriptDirectory\vicred.clixml"

Write-Host "Enter Credentials for Cluster:"$conf.cluster_mgmt
$NCCred = Get-Credential -message "Enter the credentials for ONTAP Cluster $ontap"
$NCCred | Export-CliXml "$ScriptDirectory\nccred.clixml"
