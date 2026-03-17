<#
.SYNOPSIS
    Reverts all VMs in the "lab-scripts" vCenter folder to a named snapshot.
.DESCRIPTION
    Connects to the dc1-hst-mgmt1.humbledgeeks.com vCenter, stops all VMs in
    the "lab-scripts" folder, reverts each VM to the hardcoded snapshot name
    (2023-05-26T2055), and powers them back on. Used to reset the lab
    environment to a known-good baseline after testing or training sessions.
    The snapshot name and vCenter server are hardcoded — update before reuse.
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : VMware.PowerCLI
    Repo    : infra-automation/VMware/vCenter/PowerShell
    Warning : Contains hardcoded snapshot name and vCenter FQDN.
              Update $snapname and the -Server value before reuse.
    Prereq  : PowerCLI installed; snapshot "2023-05-26T2055" must exist on
              all VMs in the "lab-scripts" vCenter folder.
#>

$snapname = '2023-05-26T2055'
Connect-VIServer -Server dc1-hst-mgmt1.humbledgeeks.com
$vms = Get-VM -Location lab-scripts |
    ForEach-Object {$vms.name} {
        Stop-VM $_.name -Confirm:$false
        Set-VM $_.name -Snapshot $snapname -Confirm:$false
        Start-VM $_.name -Confirm:$false
        }
Disconnect-VIServer -Confirm:$false
