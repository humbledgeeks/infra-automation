# HumbledGeeks UCS Deployment — PowerShell Scripts

Automated deployment of the HumbledGeeks sub-org configuration on Cisco UCS Manager,
designed as the compute foundation for a **NetApp FlexPod** running
**Broadcom VMware Cloud Foundation (VCF)** with a **direct-attached NetApp ASA A30**
all-flash array.

## Prerequisites

| Requirement | Details |
|---|---|
| PowerShell | 5.1+ or 7.x |
| Cisco.UCS module | `Install-Module Cisco.UCS -Scope CurrentUser` |
| UCSM | 10.x.x.x (admin access) |

## Script Sections

| Script | Purpose |
|---|---|
| `00-prereqs-and-connect.ps1` | Module check, UCSM login, org verify |
| `01-pools.ps1` | MAC / UUID / WWN / IP address pools |
| `02-vlans-vsans.ps1` | VLAN verification + VSAN creation (FC Storage Cloud) |
| `03-policies.ps1` | Network control (+ CDP/LLDP via XML API), QoS, local disk, power, maintenance, boot, BIOS |
| `04-vnic-templates.ps1` | 6× Ethernet vNIC Updating Templates — all MTU 1500 |
| `05-vhba-templates.ps1` | 2× FC vHBA Updating Templates (path to ASA A30) |
| `06-service-profile-template.ps1` | hg-esx-template SP template + all bindings |
| `07-deploy-service-profiles.ps1` | Derive SPs from template + associate to blades |
| `08-verify.ps1` | Post-deployment verification report |

## Quick Start

```powershell
# Full deployment (sections 01–07 in order)
foreach ($s in 1..7) {
    & "$PSScriptRoot\0$s-*.ps1"
}

# Verification only
& "$PSScriptRoot\08-verify.ps1"
```

## Network Design

### Ethernet — 6 vNICs, MTU 1500 Throughout

Block storage runs over Fibre Channel vHBAs. There is no iSCSI or NFS on the Ethernet
path, so MTU 1500 is used on every vNIC to avoid fragmentation risk.

| vNIC | Fabric | MTU | Purpose | Key VLANs |
|---|---|---|---|---|
| vmnic0 | A | 1500 | ESXi management + vMotion | dc3-mgmt (16), dc3-vmotion (17) |
| vmnic1 | B | 1500 | ESXi management + vMotion | (same as A-side) |
| vmnic2 | A | 1500 | VM workloads trunk | dc3-apps (18), dc3-core (20), dc3-docker (22), dc3-gns3 (32/34) |
| vmnic3 | B | 1500 | VM workloads trunk | (same as A-side) |
| vmnic4 | A | 1500 | VCF overlay / NSX TEP | Set to your NSX TEP VLAN |
| vmnic5 | B | 1500 | VCF overlay / NSX TEP | (same as A-side) |

### Storage — FC Dual-Path to NetApp ASA A30

| vHBA | Fabric | WWPN Pool | VSAN | VSAN ID | FI Storage Ports |
|---|---|---|---|---|---|
| vmhba0 | A | hg-wwpn-a | hg-vsan-a | 10 | 29–32 on FI-A |
| vmhba1 | B | hg-wwpn-b | hg-vsan-b | 11 | 29–32 on FI-B |

### Identity Pools

| Pool | Type | Range | Size |
|---|---|---|---|
| hg-mac-a | MAC | 00:25:B5:A0:00:00 – 01:FF | 512 |
| hg-mac-b | MAC | 00:25:B5:B0:00:00 – 01:FF | 512 |
| hg-uuid-pool | UUID suffix | 0000-000000000001 – 00A0 | 160 |
| hg-wwnn-pool | WWNN | 20:00:00:25:B5:C0:00:00 – 00:9F | 160 |
| hg-wwpn-a | WWPN | 20:00:00:25:B5:A0:00:00 – 00:9F | 160 |
| hg-wwpn-b | WWPN | 20:00:00:25:B5:B0:00:00 – 00:9F | 160 |
| hg-ext-mgmt | IP (KVM) | 10.x.x.x – +9 /24 | 9 |

### Policies

| Policy | Name | Key Settings |
|---|---|---|
| Network Control | hg-netcon | CDP=enabled, LLDP Tx/Rx=enabled, forged MAC deny |
| QoS | hg-qos-be | Best-effort egress, line-rate |
| Local Disk | hg-local-disk | any-configuration, FlexFlash enabled |
| Power | hg-power | no-cap |
| Maintenance | hg-maint | uptimeDisr=user-ack, dataDisr=user-ack |
| Boot | hg-flexflash | UEFI: DVD(1) → SSD(2) → FlexFlash SD(3) |
| BIOS | hg-bios | VT-x, VT-d, C-States disabled, CPU Perf=HPC |

## Verified As-Built State

```
Faults           : 0 unacknowledged active faults
Blades           : 8/8 present (1× B200-M5, 7× B200-M4), 0 associated
Port Channels    : PC1 UP (FI-A, ports 17+18, 10 Gbps)
                   PC2 UP (FI-B, ports 17+18, 10 Gbps)
VSANs            : hg-vsan-a (ID 10) — 4 member ports
                   hg-vsan-b (ID 11) — 4 member ports
SP Template      : hg-esx-template (updating-template)
  Boot Policy    : hg-flexflash — UEFI: DVD(1) SSD(2) FlexFlash(3) ✓
  Maint Policy   : hg-maint — user-ack ✓
  CDP/LLDP       : enabled on hg-netcon ✓
  FlexFlash      : enabled in hg-local-disk ✓
  All vNIC MTUs  : 1500 ✓
```

## Important: XML API Requirements

Two settings require raw XML API calls via `Invoke-UcsXml` — handled automatically in `03-policies.ps1`:

- **CDP + LLDP** — `nwctrlDefinition` attributes `cdp`, `lldpTransmit`, `lldpReceive` are not
  exposed by the Cisco.UCS module.
- **Maintenance policy verification** — always confirm `uptimeDisr` and `dataDisr` are set;
  UCSM silently ignores unknown attributes and may partially apply changes.

## Next Steps (VCF Deployment)

1. **FC Zoning** — Zone ESXi initiator WWPNs to ASA A30 target ports per fabric
2. **ESXi staging** — Mount ISO to virtual KVM DVD or configure PXE on dc3-mgmt (VLAN 16)
3. **Associate SPs** — Run `07-deploy-service-profiles.ps1`; acknowledge user-ack pending changes
4. **VCF bringup** — Use SDDC Manager cloud builder; KVM IPs from `hg-ext-mgmt` become host management IPs

## Mixed Blade Generations Note

Slot 1/1 is a B200-M5 with internal SSD; slots 1/2–1/8 are B200-M4 with FlexFlash SD.
The boot policy handles both: SSD is picked up at order=2 where present; M4s fall through
to FlexFlash at order=3. If adding a firmware management policy, ensure the host firmware
package covers both M4 and M5 blade generations.
