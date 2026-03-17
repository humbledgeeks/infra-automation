<#
.SYNOPSIS
    Establishes or reconnects to the persistent "node-vlab" PowerShell session.
.DESCRIPTION
    Manages a named, persistent PSSession ("node-vlab") on localhost used to
    maintain state across vLab automation operations. If a disconnected session
    exists it reconnects to it; otherwise creates a new one. After connecting,
    invokes Connect-vLabResources.ps1 inside the session to ensure vCenter
    and ONTAP connections are active. Returns the session object for use by
    calling scripts.
.EXAMPLE
    $session = .\get-vlabsession.ps1
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : None (built-in PowerShell remoting)
    Repo    : infra-automation/VMware/vCenter/PowerShell/vLab
    Prereq  : PowerShell remoting enabled on localhost (Enable-PSRemoting).
              Connect-vLabResources.ps1 must exist in the same directory.
#>

# Keep a session to maintain state
$session=""
$session=get-pssession -ComputerName "localhost" -Name "node-vlab" | where { $_.State -eq "Disconnected" } | where { $_.Availability -eq "none" } | select-object -first 1
if ($session) {
    $result=$session | connect-pssession }
else {
    $session=new-pssession -ComputerName "localhost" -Name "node-vlab"
    $result=$session | connect-pssession
}

# Make sure the session is logged into the resources
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
$result=invoke-command -session $session -scriptblock {
    param($ScriptDirectory)
    & "$ScriptDirectory\Connect-vLabResources.ps1"
} -ArgumentList $ScriptDirectory

$session
