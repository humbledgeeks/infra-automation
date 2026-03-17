<#
.SYNOPSIS
    Generates vSphere HTML5, VMRC, or WebMKS console URLs for a named VM.
.DESCRIPTION
    Wraps the Get-VMConsoleURL function which generates console access URLs
    for a VM running in vCenter. Supports three URL types:
      - HTML5 console (default) : opens in the vSphere Web Client
      - VMRC URL                : opens in the standalone VMware Remote Console app
      - WebMKS URL              : raw WebSocket ticket URL (wss://)
    You must already be connected to vCenter (Connect-VIServer) before calling
    this function. The generated URL is valid only for the duration of the
    acquired session ticket.
.PARAMETER VMName
    The name of the VM to generate a console URL for.
.PARAMETER vmrcUrl
    Set to $true to generate a VMRC URL instead of HTML5.
.PARAMETER webmksUrl
    Set to $true to generate a WebMKS URL instead of HTML5.
.EXAMPLE
    Get-VMConsoleURL -VMName "dc3-srv-ubuntu01"
.EXAMPLE
    Get-VMConsoleURL -VMName "dc3-srv-ubuntu01" -vmrcUrl $true
.EXAMPLE
    Get-VMConsoleURL -VMName "dc3-srv-ubuntu01" -webmksUrl $true
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : VMware.PowerCLI
    Repo    : infra-automation/VMware/vCenter/PowerShell/vLab
    Credit  : Original function by William Lam (VMware) — www.virtuallyghetto.com
    Prereq  : Must be connected to vCenter via Connect-VIServer before calling.
#>

Function Get-VMConsoleURL {
<#
    .NOTES
    ===========================================================================
     Created by:    William Lam
     Organization:  VMware
     Blog:          www.virtuallyghetto.com
     Twitter:       @lamw
        ===========================================================================
    .DESCRIPTION
        This function generates the HTML5 VM Console URL (default) as seen when using the
        vSphere Web Client connected to a vCenter Server 6.5 environment. You must
        already be logged in for the URL to be valid or else you will be prompted
        to login before being re-directed to VM Console. You have option of also generating
        either the Standalone VMRC or WebMKS URL using additional parameters
    .PARAMETER VMName
        The name of the VM
    .PARAMETER webmksUrl
        Set to true to generate the WebMKS URL instead (e.g. wss://<host>/ticket/<ticket>)
    .PARAMETER vmrcUrl
        Set to true to generate the VMRC URL instead (e.g. vmrc://...)
    .EXAMPLE
        Get-VMConsoleURL -VMName "Embedded-VCSA1"
    .EXAMPLE
        Get-VMConsoleURL -VMName "Embedded-VCSA1" -vmrcUrl $true
    .EXAMPLE
        Get-VMConsoleURL -VMName "Embedded-VCSA1" -webmksUrl $true
        #>
    param(
        [Parameter(Mandatory=$true)][String]$VMName,
        [Parameter(Mandatory=$false)][Boolean]$vmrcUrl,
        [Parameter(Mandatory=$false)][Boolean]$webmksUrl
    )

    Function Get-SSLThumbprint {
        param(
        [Parameter(
            Position=0,
            Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)
        ]
        [Alias('FullName')]
        [String]$URL
        )

        add-type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;

                public class IDontCarePolicy : ICertificatePolicy {
                public IDontCarePolicy() {}
                public bool CheckValidationResult(
                    ServicePoint sPoint, X509Certificate cert,
                    WebRequest wRequest, int certProb) {
                    return true;
                }
                }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = new-object IDontCarePolicy

        # Need to connect using simple GET operation for this to work
        Invoke-RestMethod -Uri $URL -Method Get | Out-Null

        $ENDPOINT_REQUEST = [System.Net.Webrequest]::Create("$URL")
        $SSL_THUMBPRINT = $ENDPOINT_REQUEST.ServicePoint.Certificate.GetCertHashString()

        return $SSL_THUMBPRINT -replace '(..(?!$))','$1:'
    }

    $VM = Get-VM -Name $VMName
    $VMMoref = $VM.ExtensionData.MoRef.Value

    if($webmksUrl) {
        $WebMKSTicket = $VM.ExtensionData.AcquireTicket("webmks")
        $VMHostName = $WebMKSTicket.host
        $Ticket = $WebMKSTicket.Ticket
        $URL = "wss://$VMHostName`:443/ticket/$Ticket"
    } elseif($vmrcUrl) {
        $VCName = $global:DefaultVIServer.Name
        $SessionMgr = Get-View $DefaultViserver.ExtensionData.Content.SessionManager
        $Ticket = $SessionMgr.AcquireCloneTicket()
        $URL = "vmrc://clone`:$Ticket@$VCName`:443/?moid=$VMMoref"
    } else {
        $VCInstasnceUUID = $global:DefaultVIServer.InstanceUuid
        $VCName = $global:DefaultVIServer.Name
        $SessionMgr = Get-View $DefaultViserver.ExtensionData.Content.SessionManager
        $Ticket = $SessionMgr.AcquireCloneTicket()
        $VCSSLThumbprint = Get-SSLThumbprint "https://$VCname"
        $URL = "https://$VCName`:9443/vsphere-client/webconsole.html?vmId=$VMMoref&vmName=$VMname&serverGuid=$VCInstasnceUUID&locale=en_US&host=$VCName`:443&sessionTicket=$Ticket&thumbprint=$VCSSLThumbprint"
    }
    $URL
}
