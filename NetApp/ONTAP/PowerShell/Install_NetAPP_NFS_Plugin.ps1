<#
.SYNOPSIS
    Install the NetApp NFS VAAI VIB on ESXi hosts via esxcli.
.DESCRIPTION
    Connects to a standalone ESXi host or vCenter and installs the NetApp NAS Plugin VIB
    (NetAppNasPlugin) from a specified datastore path using the esxcli software vib install
    interface. Requires the VIB to be pre-staged on a datastore accessible to the host.
.NOTES
    Author  : HumbledGeeks
    Date    : 2023-06-05
    Version : 1.0
    Module  : VMware.PowerCLI
    Repo    : infra-automation/NetApp/ONTAP/PowerShell
    WARNING : Contains hardcoded ESXi credentials. Replace with Get-Credential before production use.
              Run /script-migrate on this file to update to repo credential standards.
#>
#========================================================================================================================
# 
# AUTHOR: HumbledGeeks  
# DATE  : 06/05/2023
# 
# COMMENT: Script to Automate ESX Host and vCenter Configuration
#     
#
# =======================================================================================================================

#========================================================================================================================
# Specify host variables
#========================================================================================================================

$esxiuser = "root"
$esxipass = "Sclarc$western2500"
$VMHosts = "192.168.10.28"
$NTP1 = "0.pool.ntp.org"
$NTP2 = "1.pool.ntp.org"
$DNS1 = "10.101.16.20"
$DNS2 = "9.9.9.9"
$domainname = "humbledgeeks.com"
$VIBPATH = "/vmfs/volumes/CTX_DS01/NetAppNasPlugin_2.0.1-16.vib"
$datastore = Get-Datastore "CTX_DS01"

#====================================================================================================================
# Connect to each host
#====================================================================================================================

write-host Connecting to vCenter Server instance -ForegroundColor Green
Connect-VIServer -Server $VMHosts -User $esxiuser -Password $esxipass



# Install NETAPP NFS VIBs
Write-host Installing NetApp VAAI NFS VIB -ForegroundColor Green
$arguments = $esxcli.software.vib.install.CreateArgs()
$arguments.viburl = $VIBPATH
$arguments.nosigcheck = $true
$esxcli.software.vib.install.invoke($arguments)


Disconnect-VIServer $VMHosts -Confirm:$false

