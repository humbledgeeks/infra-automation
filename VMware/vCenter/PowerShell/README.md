# VMware vCenter — PowerShell

PowerShell and PowerCLI automation scripts for vCenter Server management, including VM deployment, lab management (vLab), and vCenter configuration tasks.

---

## Prerequisites

### System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| PowerShell | 5.1 (Windows) | 7.4+ (cross-platform) |
| VMware PowerCLI | 12.x | 13.x (latest) |
| vCenter | 7.0 | 8.0+ |
| OS | Windows 10 | Windows Server 2022 / Ubuntu 22.04 |

---

## Installation

### Step 1 — Install PowerShell 7

```powershell
# Windows
winget install Microsoft.PowerShell

# Ubuntu
sudo apt update && sudo apt install -y powershell

# macOS
brew install --cask powershell

# Verify
pwsh --version
```

### Step 2 — Install VMware PowerCLI

```powershell
# Install from PowerShell Gallery
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force

# Verify installation
Get-Module -ListAvailable VMware.PowerCLI
(Get-Module VMware.PowerCLI -ListAvailable).Version
```

### Step 3 — Configure PowerCLI for Lab Use

```powershell
# Disable certificate warnings (lab only)
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Opt out of CEIP telemetry
Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false
```

---

## Credential Setup

**Never hardcode credentials.**

```powershell
# Option 1 — Prompt at runtime
$credential = Get-Credential -Message "Enter vCenter credentials"

# Option 2 — Encrypted credential file (per-user, per-machine)
$credential = Get-Credential
$credential | Export-Clixml -Path "$env:USERPROFILE\.vcenter-creds.xml"

# Load saved credential
$credential = Import-Clixml -Path "$env:USERPROFILE\.vcenter-creds.xml"
```

---

## Scripts in This Folder

### Root Level

| Script | Description |
|---|---|
| `DeployUbuntu.ps1` | Deploys an Ubuntu Server VM from OVA/template |
| `Ubuntu_SRV_VM_Deploy.ps1` | Ubuntu Server VM deployment with customization spec |
| `Restore_LAB_VMs.ps1` | Restores lab VMs from backup or snapshot |

### vLab/ (Virtual Lab Management)

| Script | Description |
|---|---|
| `install.ps1` | Install and configure the vLab framework |
| `get-vlabs.ps1` | List all virtual labs |
| `get-vlabcatalog.ps1` | List vLab catalog entries |
| `new-vlabclone.ps1` | Clone a lab from template |
| `new-vlabempty.ps1` | Create an empty vLab environment |
| `new-vlabtemplate.ps1` | Create a vLab template |
| `start-vlab.ps1` | Power on a virtual lab |
| `stop-vlab.ps1` | Power off a virtual lab |
| `remove-vlab.ps1` | Remove a virtual lab |
| `get-vlabsession.ps1` | Get active vLab sessions |
| `get-vlabsettings.ps1` | Get vLab configuration settings |
| `set-vlabsettings.ps1` | Update vLab configuration settings |
| `set-vlabcreds.ps1` | Set vLab credentials |
| `connect-vlabresources.ps1` | Connect to vLab resources |
| `get-vlabstats.ps1` | Get vLab utilization statistics |
| `get-vlabgateway.ps1` | Get vLab gateway configuration |
| `get-vlabdescriptions.ps1` | Get vLab descriptions |
| `GenerateConsoleURL.ps1` | Generate console access URLs |
| `import-vlabtemplate.ps1` | Import a vLab template |
| `rename-vlab.ps1` | Rename a virtual lab |
| `show-vlabs.ps1` | Display vLab list (formatted output) |
| `show-dashboard-html.ps1` | Display vLab dashboard as HTML |
| `show-vlab-html.ps1` | Display vLab details as HTML |
| `show-vlabcatalog.ps1` | Display vLab catalog (formatted) |
| `show-vlabcatalog-html.ps1` | Display vLab catalog as HTML |
| `show-vlabcatalogadmin-html.ps1` | Admin view of vLab catalog as HTML |
| `show-vlabs-html.ps1` | Display vLab list as HTML |
| `start-vlabmenu.ps1` | Launch vLab interactive menu |
| `enable-vlabauthoring.ps1` | Enable vLab authoring mode |
| `disable-vlabauthoring.ps1` | Disable vLab authoring mode |
| `new-vlabnetwork.ps1` | Create vLab network segment |

---

## How to Run

### Connect to vCenter First

```powershell
$cred = Import-Clixml "$env:USERPROFILE\.vcenter-creds.xml"
Connect-VIServer -Server vcenter.lab.local -Credential $cred
```

### DeployUbuntu.ps1

```powershell
.\DeployUbuntu.ps1 -vCenterServer vcenter.lab.local -VMName "ubuntu-srv-01" -OVAPath "C:\OVAs\ubuntu-22.04.ova"
```

### vLab Management Examples

```powershell
# List all vLabs
.\vLab\get-vlabs.ps1

# Create a new lab from the catalog
.\vLab\new-vlabclone.ps1 -LabName "Training-Lab-01" -Template "Base-Template"

# Start a lab
.\vLab\start-vlab.ps1 -LabName "Training-Lab-01"

# Stop a lab
.\vLab\stop-vlab.ps1 -LabName "Training-Lab-01"

# Get active sessions
.\vLab\get-vlabsession.ps1
```

---

## Execution Policy

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## References

- [VMware PowerCLI on PowerShell Gallery](https://www.powershellgallery.com/packages/VMware.PowerCLI)
- [VMware PowerCLI Documentation](https://developer.vmware.com/powercli)
- [VMware vCenter Documentation](https://docs.vmware.com/en/VMware-vSphere/index.html)
