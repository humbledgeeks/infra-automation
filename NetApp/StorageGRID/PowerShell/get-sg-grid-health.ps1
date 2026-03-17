<#
.SYNOPSIS
    Retrieves StorageGRID grid health, node status, and tenant summary via REST API.
.DESCRIPTION
    Authenticates to the StorageGRID Admin Node REST API and displays a summary of
    grid node health, active alerts, and tenant account count. Read-only — no changes
    are made to the environment.
.PARAMETER AdminNode
    FQDN or IP of the StorageGRID Admin Node.
.EXAMPLE
    .\get-sg-grid-health.ps1 -AdminNode storagegrid-admin.lab.local
.NOTES
    Author  : humbledgeeks-allen
    Date    : 2026-03-16
    Version : 1.0
    Module  : N/A (StorageGRID REST API via Invoke-RestMethod)
    API     : StorageGRID REST API v3
    Repo    : infra-automation/NetApp/StorageGRID/PowerShell
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$AdminNode,

    [switch]$SkipCertCheck
)

$ErrorActionPreference = "Stop"

# ── Ignore self-signed certs if requested (lab use only) ─────────────────────
if ($SkipCertCheck) {
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $certPolicy = @{ SkipCertificateCheck = $true }
    } else {
        [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        $certPolicy = @{}
    }
} else {
    $certPolicy = @{}
}

# ── Authenticate ─────────────────────────────────────────────────────────────
$creds   = Get-Credential -Message "Enter StorageGRID admin credentials"
$baseUrl = "https://$AdminNode/api/v3"

$authBody = @{
    username   = $creds.UserName
    password   = $creds.GetNetworkCredential().Password
    cookie     = $false
    csrfToken  = $false
} | ConvertTo-Json

Write-Output "Authenticating to StorageGRID: $AdminNode"
$authResponse = Invoke-RestMethod -Uri "$baseUrl/authorize" `
    -Method POST -Body $authBody `
    -ContentType "application/json" @certPolicy
$token   = $authResponse.data
$headers = @{ "Authorization" = "Bearer $token" }

# ── Grid Node Health ──────────────────────────────────────────────────────────
Write-Output "`n=== Grid Node Health ==="
$nodes = Invoke-RestMethod -Uri "$baseUrl/grid/nodes" -Headers $headers @certPolicy
$nodes.data | Select-Object `
    @{N="Node";    E={$_.name}},
    @{N="Type";    E={$_.type}},
    @{N="State";   E={$_.state}},
    @{N="Status";  E={$_.primaryAdminNodeUUID}} |
    Format-Table -AutoSize

# ── Active Alerts ─────────────────────────────────────────────────────────────
Write-Output "`n=== Active Alerts ==="
$alerts = Invoke-RestMethod -Uri "$baseUrl/grid/health/topology?depth=node" `
    -Headers $headers @certPolicy
Write-Output "Grid overall health: $($alerts.data.health)"

# ── Tenant Summary ────────────────────────────────────────────────────────────
Write-Output "`n=== Tenant Accounts ==="
$tenants = Invoke-RestMethod -Uri "$baseUrl/grid/accounts" -Headers $headers @certPolicy
$tenants.data | Select-Object `
    @{N="Tenant";      E={$_.name}},
    @{N="ID";          E={$_.id}},
    @{N="Policy";      E={$_.policy.allowPlatformServices}} |
    Format-Table -AutoSize
Write-Output "Total tenants: $($tenants.data.Count)"

Write-Output "`nStorageGRID health check complete."
