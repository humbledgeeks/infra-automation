<#
.SYNOPSIS
    Deploys an Ubuntu Server VM to the h615c cluster from a template.
.DESCRIPTION
    Variant of DeployUbuntu.ps1 targeting the h615c cluster. Clones the
    Ubuntu template (dc3-srv-ubuntu00) to create dc3-xmr-ubuntu01, applies
    the "ubuntu-script" OS customization spec, configures CPU/memory/network,
    powers on the VM, waits for customization to complete (VM powers off),
    takes a post-customization snapshot, then powers the VM back on.
    Hard-coded values (vCenter IP, cluster, template) should be parameterized
    before production reuse — run /script-migrate to standardize.
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : VMware.PowerCLI
    Repo    : infra-automation/VMware/vCenter/PowerShell
    Warning : Contains hardcoded vCenter IP (10.103.16.10) and VM names.
              Use /script-migrate to convert to parameters before reuse.
    Prereq  : PowerCLI installed; OS customization spec "ubuntu-script"
              must exist in vCenter; template "dc3-srv-ubuntu00" must exist;
              cluster "h615c" must exist.
#>

Import-Module VMware.PowerCLI
#Set the participation to false and ignore invalid certificates for all users
Set-PowerCLIConfiguration -Scope AllUsers -ParticipateInCeip $false -InvalidCertificateAction Ignore
Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $true
#Connect to our vCenter Server using the logged in credentials
Connect-VIServer 10.103.16.10

$VM_Name = 'dc3-xmr-ubuntu01'
$VM_NumCPU = '8'
$VM_CoresPerSocket = '4'
$VM_MemoryGB = '16'
$VDS_Network = 'dc3-docker (vSAN)'
$Cluster = 'h615c'
$Datastore = 'vsanDatastore'
$VM_Template = 'dc3-srv-ubuntu00'




New-VM -Name $VM_Name -VM $VM_Template -OSCustomizationSpec ubuntu-script -ResourcePool $Cluster -Datastore $Datastore -DiskStorageFormat Thin
sleep 5
Get-VM -Name $VM_Name | Get-NetworkAdapter | Select-Object Parent,MacAddress
Get-VM -Name $VM_Name | Set-VM -MemoryGB $VM_MemoryGB -NumCPU $VM_NumCPU -CoresPerSocket $VM_CoresPerSocket -Confirm:$false
Get-VM -Name $VM_Name | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $VDS_Network -Confirm:$false
Get-VM -Name $VM_Name | Start-VM
Get-VM -Name $VM_Name | Get-NetworkAdapter | Set-NetworkAdapter -Connected:$true -Confirm:$false
Get-VM -Name $VM_Name | Where-Object {$_.powerstate -eq "poweredon"} | Get-NetworkAdapter | Where-object {$_.ConnectionState.StartConnected -ne "True"} | set-networkadapter -startconnected:$true -Confirm:$false
do {
        Start-Sleep -Seconds 10
        $VMStatus = (Get-VM $VM_Name).PowerState
	Write-Host "$($VM_Name) customization is in progress"
    } while ($VMStatus -ne "PoweredOff")
Get-VM -Name $VM_Name | New-Snapshot -Name ClonedCustomized
sleep 5
Get-VM -Name $VM_Name | Start-VM
