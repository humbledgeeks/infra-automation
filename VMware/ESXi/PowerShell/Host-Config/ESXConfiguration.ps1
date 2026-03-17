<#
.SYNOPSIS
    Full ESXi host configuration for HPE cluster environment: add to vCenter, NTP, DNS, networking, vMotion, NFS.
.DESCRIPTION
    Connects to a vCenter and adds an HPE ProLiant host, then applies full host configuration: DNS, NTP, SSH enable,
    AD join, vSwitch0 NIC teaming, NFS/iSCSI vmk ports, vMotion TCP/IP stack, distributed switch migration,
    NFS datastore mount, scratch location, and NetApp NFS advanced settings. Target: hybriddatacenter.net lab.
.NOTES
    Author  : Adrian Wong and Allen Johnson
    Date    : 2019-01-21
    Version : 1.0
    Module  : VMware.PowerCLI
    Repo    : infra-automation/VMware/ESXi/PowerShell/Host-Config
    WARNING : Contains hardcoded vCenter credentials (vcenteradminpw). Replace with Get-Credential before production use.
              Run /script-migrate on this file to update to repo credential standards.
#>
#====================================================================================================================
# 
# AUTHOR: Adrian Wong and Allen Johnson 
# DATE  : 01/21/2019
# 
# COMMENT: Script to Automate ESX Host and vCenter Configuration
#     
#
# ====================================================================================================================

$vcenterserver = ‘vc01.hybriddatacenter.net’
$vcenteradmin = ‘administrator@homelab.local’
$vcenteradminpw = ‘GNadm!n@12345’
$VMHost = Read-Host -Prompt ‘hpenode1.hybriddatacenter.net’
$VMHostName = "hpenode1"
$esxiuser = ‘root’
$esxiuserpw = ‘******’
$vmwaredatacenter = ‘Datacenter’
$cluster = ‘HPE Cluster’
$dvSwitch = “dvSwitch”
$vmotionpg = “VLAN 131”
$vmotionmask = “255.255.255.0”
$vsanmask = “255.255.255.0”
$provisioningmask = “255.255.255.0”
#$vsanpg = “VLAN 88”
#$managemeNTPServer1g = “VLAN 88”
$DNSServer1 = "192.168.130.10"
$DNSServer2 = "192.168.130.11"
$NTPServer1 = "192.168.130.10"
$NTPServer2 = "192.168.130.11"
$vMotionIP_A = "192.168.131.17"
$vMotionIP_B = "192.168.131.27"
$vmotionmask = "255.255.255.0"
$vmotiongw = "192.168.131.1"
$NFS_IP = "192.168.140.223"
#$iSCSI_A = "192.168.141.223"
#$iSCSI_B = "192.168.142.223"
#$vsanip = “”
#$cachingssd = “”
#$capacitydisk = “”
#$DomainName = "hybriddatacenter.net"

## Restart Host ##
#Restart-VMHost $VMHost -RunAsync -Confirm:$false

##Connect to vCenter##
write-host Connecting to vCenter Server instance $vcenterserver -ForegroundColor Yellow
Connect-VIServer $vcenterserver -User $vcenteradmin -Password $vcenteradminpw -Force

##Add Hosts to vCenter##
write-host Start adding ESXi hosts to the vCenter Server instance $vcenterserver -ForegroundColor Yellow
Add-VMHost $VMHost -Location $vmwaredatacenter -User $esxiuser -Password $esxiuserpw -Force
#Add-VMHost $VMHost -Location(Get-Cluster "Cluster_Name")-User root -Password R0cky@123 -Force

##Add DNS##
Get-VMHost $VMHost | Get-VMHostNetwork | Set-VMHostNetwork -HostName $VMHostName -DomainName $DomainName -SearchDomain $DomainName -DnsAddress 192.168.130.10,192.168.130.11


##Add NTP##
Add-VmHostNtpServer -NtpServer $NtpServer1 -VMHost $VMHost | Out-Null
Add-VmHostNtpServer -NtpServer $NtpServer2 -VMHost $VMHost | Out-Null

##Enable NTP Service##
Get-VmHostService -VMHost $VMHost | Where-Object {$_.key -eq "ntpd"} | Set-VMHostService -Policy On | Restart-VMHostService -Confirm:$false | Out-Null


##Enable SSH##
Get-VMHostService -VMHost $vmhost | Where-Object {$_.Key -eq "TSM-SSH"} | Set-VMHostService -policy "on" -Confirm:$false
Get-VMHostService -VMHost $vmhost | Where-Object {$_.Key -eq "TSM-SSH"} | Restart-VMHostService -Confirm:$false
Get-VMHost $VMHost | Get-AdvancedSetting UserVars.SuppressShellWarning | Set-AdvancedSetting -Value 1 -Confirm:$false



Get-VMHost | ForEach-Object {Start-VMHostService -HostService ($_| Get-VMHostService | Where-Object {$_.Key -eq "TSM-SSH"} | Set-VMHostService -policy "on") -Confirm:$false}
Get-VMHost | Get-AdvancedSetting UserVars.SuppressShellWarning | Set-AdvancedSetting -Value 1 -Confirm:$false


##Join Active Directory ##
Get-VMHost -Location (Get-Cluster "Cluster") | Get-VMHostAuthentication | Set-VMHostAuthentication -Domain hybriddatacenter.net -User adjoin -Password GNadm!n^^ -JoinDomain -Confirm:$false


##Scan NFS##
Get-VMHost $VMHost | Get-VMHostStorage -RescanVmfs


##Put Host in Maintenance Mode##
write-host Put $VMHost in Maintenance mode
Set-VMhost $VMHost -State Maintenance -RunAsync

##set MTU on vswitch0##
$vs = Get-VMHost $VMHost | get-virtualswitch -name vSwitch0
Set-VirtualSwitch -VirtualSwitch $vs -Add-VirtualSwitchPhysicalNetworkAdapter vmnic0,vmnic1 -Mtu 1500 -Confirm:$false


##set NicTeamingPolicy Management Network##
Get-VMHost $VMHost | get-virtualportgroup -name "Management Network" | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic0 -MakeNicStandby vmnic1


##Adding VMKernel Ports for NFS and iSCSI##

##Create NFS VMkernel##
Get-VMHost $VMHost | Get-VirtualSwitch -Name vSwitch1 | New-VirtualPortGroup -Name ESX_NFS_140 -VLanId 140
$esxcli = Get-EsxCli -VMhost $VMHost
$esxcli.network.ip.interface.add($null, $null, "vmk140", $null, "9000", $null, "ESX_NFS_140")
$esxcli.network.ip.interface.ipv4.set("vmk140", $NFS_IP, "255.255.255.0", $null, "static")

##Create iSCSI_A VMkernel##
Get-VMHost $VMHost | Get-VirtualSwitch -Name vSwitch2 | New-VirtualPortGroup -Name ESX_ISCSIA_141 -VLanId 141
$esxcli = Get-EsxCli -VMhost $VMHost
$esxcli.network.ip.interface.add($null, $null, "vmk141", $null, "9000", $null, "ESX_ISCSIA_141")
$esxcli.network.ip.interface.ipv4.set("vmk141", $iSCSI_A, "255.255.255.0", $null, "static")

##Create NFS VMkernel##
Get-VMHost $VMHost | Get-VirtualSwitch -Name vSwitch3 | New-VirtualPortGroup -Name ESX_ISCSI_142 -VLanId 142
$esxcli = Get-EsxCli -VMhost $VMHost
$esxcli.network.ip.interface.add($null, $null, "vmk142", $null, "9000", $null, "ESX_ISCSI_142")
$esxcli.network.ip.interface.ipv4.set("vmk142", $iSCSI_B, "255.255.255.0", $null, "static")


## Mount NFS ##
Get-VMHost $VMHost | New-Datastore -Nfs -Name HDC_DS01 -Path /HDC_DS01 -NfsHost 192.168.130.243
#Get-VMHost $VMHost | New-Datastore -Nfs -Name PROD_SAS_NFS01 -Path /PROD_SAS_NFS01 -NfsHost 10.16.105.101
#Get-VMHost $VMHost | New-Datastore -Nfs -Name PROD_SAS_NFS02 -Path /PROD_SAS_NFS02 -NfsHost 10.16.105.102
#Get-VMHost $VMHost | New-Datastore -Nfs -Name PROD_SAS_NFS03 -Path /PROD_SAS_NFS03 -NfsHost 10.16.105.103
#Get-VMHost $VMHost | New-Datastore -Nfs -Name PROD_SAS_NFS04 -Path /PROD_SAS_NFS04 -NfsHost 10.16.105.104
#Get-VMHost $VMHost | New-Datastore -Nfs -Name PROD_SAS_NFS05 -Path /PROD_SAS_NFS05 -NfsHost 10.16.105.105
#Get-VMHost $VMHost | New-Datastore -Nfs -Name PROD_SAS_NFS06 -Path /PROD_SAS_NFS06 -NfsHost 10.16.105.106



## Configure scratch location ##
Get-VMhost hpenode1.hybriddatacenter.net | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | Set-AdvancedSetting -Value "/vmfs/volumes/FRANKJR_DS01/scratch/.locker-hpenode1" -Confirm:$false
Get-VMhost hpenode2.hybriddatacenter.net | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | Set-AdvancedSetting -Value "/vmfs/volumes/FRANKJR_DS01/scratch/.locker-hpenode2" -Confirm:$false
#Get-VMhost hpenode3.hybriddatacenter.net | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | Set-AdvancedSetting -Value "/vmfs/volumes/FRANKJR_DS01/scratch/.locker-hpenode3" -Confirm:$false (Change location)
#Get-VMhost hpenode4.hybriddatacenter.net | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | Set-AdvancedSetting -Value "/vmfs/volumes/FRANKJR_DS01/scratch/.locker-hpenode4" -Confirm:$false
#Get-VMhost hpenode5.hybriddatacenter.net | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | Set-AdvancedSetting -Value "/vmfs/volumes/FRANKJR_DS01/scratch/.locker-hpenode5" -Confirm:$false
#Get-VMhost hpenode6.hybriddatacenter.net | Get-AdvancedSetting -Name "ScratchConfig.ConfiguredScratchLocation" | Set-AdvancedSetting -Value "/vmfs/volumes/FRANKJR_DS01/scratch/.locker-hpenode6" -Confirm:$false

## VSWAP ##
Get-VMhost $VMHost | Set-VMHost -VMSwapfileDatastore HDC_PROD_VSWAP


## Advanced Settings ##
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name Net.TcpipHeapSize -Value 32
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name Net.TcpipHeapMax -Value 512
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name NFS.MaxVolumes -Value 256
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name NFS.HeartbeatMaxFailures -Value 10
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name NFS.HeartbeatFrequency -Value 12
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name NFS.HeartbeatTimeout -Value 5
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name NFS.MaxQueueDepth -Value 64
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name Disk.QFullSampleSize -Value 32
Set-VMHostAdvancedConfiguration -VMHost $VMHost -Name Disk.QFullThreshold -Value 8
Get-AdvancedSetting -Entity $VMHost -Name 'Power.CPUPolicy' | Set-AdvancedSetting -Value 'High Performance' -Confirm:$false
Get-AdvancedSetting -Entity $VMHost -Name 'Power.CPUPolicy' | Set-AdvancedSetting -Value 'High Performance' -Confirm:$false


## Core Dump ##
$esxcli.system.coredump.file.add()




##WebClient Create Default vMotion netstack##
Get-VMHost $VMHost | Get-VirtualSwitch -Name vSwitch0 | New-VirtualPortGroup -Name ESX_VMOTION_A_131 -VLanId 131
Get-VMHost $VMHost | New-VMHostNetworkAdapter -PortGroup ESX_VMOTION_A_131 -VirtualSwitch vSwitch0 -IP $vMotionIP_A -SubnetMask 255.255.255.0 -VMotionEnabled:$true

Get-VMHost $VMHost | Get-VirtualSwitch -Name vSwitch0 | New-VirtualPortGroup -Name ESX_VMOTION_B_132 -VLanId 132
Get-VMHost $VMHost | New-VMHostNetworkAdapter -PortGroup ESX_VMOTION_B_132 -VirtualSwitch vSwitch0 -IP $vMotionIP_B -SubnetMask 255.255.255.0 -VMotionEnabled:$true

Get-VMHost $VMHost | get-virtualportgroup -name ESX_VMOTION_A_131 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic0 -MakeNicStandby vmnic1
Get-VMHost $VMHost | get-virtualportgroup -name ESX_VMOTION_B_132 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive vmnic1 -MakeNicStandby vmnic0
Get-VMHost $VMHost | Get-VMHostNetworkadapter -name vmk1 | Set-VMHostnetworkadapter -Mtu 9000 -Confirm:$false
Get-VMHost $VMHost | Get-VMHostNetworkadapter -name vmk2 | Set-VMHostnetworkadapter -Mtu 9000 -Confirm:$false

##ESXCLI##
$VMHost = ‘hpenode1.hybriddatacenter.net’
$esxcli = Get-EsxCli -VMhost (Get-VMHost $VMHost) -V2

##Create netstack and add VMkernel adapters##
write-host Create Provisioning and vMotion TCP/IP stack and add vMotion and Provisioning VMkernel ports -ForegroundColor Yellow
$esxcli.network.ip.netstack.add.Invoke(@{netstack = ‘vmotion’})
$esxcli.network.ip.netstack.add.Invoke(@{netstack = ‘vSphereProvisioning’})
$esxcli.network.ip.interface.add.Invoke(@{interfacename = ‘vmk1’; portgroupname = ‘VM Network’; netstack = ‘vmotion’})
$esxcli.network.ip.interface.add.Invoke(@{interfacename = ‘vmk2’; portgroupname = ‘VM Network’; netstack = ‘vSphereProvisioning’})


# Set vmk1 to obtain IP Address Static
$esxcli = Get-EsxCli -VMhost (Get-VMHost $ucshost.vmhost_name) -V2
#$esxcli.network.ip.interface.ipv4.set.Invoke(@{interfacename = "vmk1"; type = "dhcp"})
$esxcli.network.ip.interface.ipv4.set.Invoke(@{interfacename = ‘vmk1’; --ipv4 = $vMotionIP_A; --netmask = $vmotionmask; type = ‘static’})
Get-VMHost $VMHost | Get-VMHostNetworkadapter -name vmk1 | Set-VMHostnetworkadapter -Mtu 9000 -Confirm:$false


# Configure vMotion TCP/IP stack Gateway
$esx = Get-VMHost -Name $VMHost
$netSys = Get-View -Id $esx.ExtensionData.ConfigManager.NetworkSystem
$stack = $esx.ExtensionData.Config.Network.NetStackInstance | Where-Object{$_.Key -eq "vmotion"}
$config = New-Object VMware.Vim.HostNetworkConfig
$spec = New-Object VMware.Vim.HostNetworkConfigNetStackSpec
$spec.Operation = [VMware.Vim.ConfigSpecOperation]::edit
$spec.NetStackInstance = $stack
$spec.NetStackInstance.RouteTableConfig = New-Object VMware.Vim.HostIpRouteTableConfig
$route = New-Object VMware.vim.HostIpRouteConfig
$route.defaultGateway = "192.168.130.1"
$route.gatewayDevice = "vmk1"
$spec.NetStackInstance.ipRouteConfig = $route
$config.NetStackSpec += $spec
$netsys.UpdateNetworkConfig($config,[VMware.Vim.HostConfigChangeMode]::modify)



##Add Host to Distributed Switch##
Write-host adding $VMHost to the $dvSwitch -ForegroundColor Yellow
Get-VDSwitch -Name $dvSwitch | Add-VDSwitchVMHost -VMHost $VMHost

##Add 2nd NIC to Distributed Switch##
$vmhostnetworkadapter2 = Get-VMhost $VMHost | Get-VMHostNetworkAdapter -Physical -Name vmnic1
Write-host adding $vmhostnetworkadapter2 to $dvSwitch -ForegroundColor Yellow
Get-VDSwitch -Name $dvSwitch | Add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmhostnetworkadapter2 -Confirm:$false | Out-Null

##Migrate MGMT vmk to Distibuted Portgroup##
$destinationmgmtpg = Get-VDPortgroup -Name “VLAN 131”
write-host Migrate Management Network to $dvSwitch -ForegroundColor Yellow
$dvportgroup = Get-VDPortgroup -Name $destinationmgmtpg -VDSwitch $dvSwitch
$vmk = Get-VMHostNetworkAdapter -Name vmk0 -VMHost $VMHost
Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -Confirm:$false | Out-Null

##Migrate vMotion vmk to Distibuted Portgroup##
$destinationvmotionpg = Get-VDPortgroup -Name “VLAN 88”
write-host Migrate vMotion VMkernel to $dvSwitch -ForegroundColor Yellow
$dvportgroup = Get-VDPortgroup -Name $destinationvmotionpg -VDSwitch $dvSwitch
$vmk = Get-VMHostNetworkAdapter -Name vmk1 -VMHost $VMHost
Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -Confirm:$false | Out-Null

##Migrate Provisioning vmk to Distibuted Portgroup##
$destinationprovisioningpg = Get-VDPortgroup -Name “VLAN 88”
write-host Migrate Provisioning VMkernel to $dvSwitch -ForegroundColor Yellow
$dvportgroup = Get-VDPortgroup -Name $destinationprovisioningpg -VDSwitch $dvSwitch
$vmk = Get-VMHostNetworkAdapter -Name vmk2 -VMHost $VMHost
Set-VMHostNetworkAdapter -PortGroup $dvportgroup -VirtualNic $vmk -Confirm:$false | Out-Null

##Add first NIC to Distibuted Switch##
$vmhostnetworkadapter1 = Get-VMhost $VMHost | Get-VMHostNetworkAdapter -Physical -Name vmnic0
Write-host adding $vmhostnetworkadapter1 to $dvSwitch -ForegroundColor Yellow
Get-VDSwitch -Name $dvSwitch | Add-VDSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $vmhostnetworkadapter1 -Confirm:$false | Out-Null

##Remove Virtual Standard Switch##
Write-Host Removing the Virtual Standard Switch -ForegroundColor Yellow
Get-VirtualSwitch -VMHost $VMHost -Name vSwitch0 | Remove-VirtualSwitch -Confirm:$false