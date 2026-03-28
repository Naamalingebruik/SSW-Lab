# SSW-Lab — Hyper-V Lab Deployer

> 🌐 **Language:** English | [Nederlands](wiki-Home.md)

Automated Hyper-V lab environment for Microsoft certifications with MSDN licences.

**Supported certifications:** MD-102 · MS-102 · SC-300 · AZ-104

---

## Study guides

A study guide is available for each certification, including MS Learn modules, lab exercises and knowledge checks:

| Certification | Description | Preset | Duration | Lab scripts |
|---|---|---|---|---|
| [MD-102](study-guide-MD102.md) | Endpoint Administrator | Standard + Autopilot | 7 weeks | 6 (week 1–6) |
| [MS-102](study-guide-MS102.md) | Microsoft 365 Administrator | Standard | 8 weeks | 7 (week 1–7) |
| [SC-300](study-guide-SC300.md) | Identity and Access Administrator | Standard | 7 weeks | 6 (week 1–6) |
| [AZ-104](study-guide-AZ104.md) | Azure Administrator | Minimal + Azure cloud | 8 weeks | 7 (week 1–7) |

Each lab script (`scripts/labs/<CERT>/lab-week<N>-*.ps1`) provides a WPF GUI with Dry Run mode, step-by-step guidance and a knowledge check. Scripts automatically chain to the next lab.

> **Sogeti High Flex:** Launch lab scripts via *Run as different user* with your High Flex admin account. Zscaler SSL inspection works transparently on managed Sogeti laptops.

---

## Table of contents

- [Requirements](#requirements)
- [Architecture](#architecture)
- [Installation](#installation)
- [Step-by-step workflow](#step-by-step-workflow)
- [Accounts and passwords](#accounts-and-passwords)
- [VM Presets](#vm-presets)
- [Network configuration](#network-configuration)
- [Dry Run mode](#dry-run-mode)

---

## Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| OS | Windows 10 (build 19041+) | Windows 11 |
| RAM | 16 GB | 32 GB |
| Disk space | 80 GB free | 150 GB free |
| Hyper-V | Enabled | Enabled |
| Windows ADK | Deployment Tools | Deployment Tools |
| MSDN ISOs | W11 Enterprise + WS2025 | W11 Enterprise + WS2025 |

Windows ADK (Deployment Tools only, ~80 MB):  
https://go.microsoft.com/fwlink/?linkid=2289980

---

## Architecture

```
Laptop (Hyper-V host)
  └── SSW-Internal (Hyper-V vSwitch, internal + NAT)
        ├── LAB-DC01            10.50.10.10   Windows Server 2025 — Domain Controller
        ├── LAB-MGMT01          10.50.10.20   Windows 11 Enterprise — Management
        ├── LAB-W11-01          DHCP          Windows 11 Enterprise — Client 1
        ├── LAB-W11-02          DHCP          Windows 11 Enterprise — Client 2
        └── LAB-W11-AUTOPILOT   DHCP          Windows 11 Enterprise — Autopilot
```

**Domain:** `ssw.lab`  
**NAT subnet:** `10.50.10.0/24`  
**Gateway:** `10.50.10.1`

---

## Installation

### Option A — EXEs (recommended)

1. Download the latest release from the [Releases page](../../releases)
2. Extract the zip to a folder of your choice
3. Run the EXEs as administrator in order

### Option B — PowerShell scripts

```powershell
git clone <your-repo-url>/SSW-Lab.git
cd SSW-Lab\scripts
# Run as administrator:
.\00-PREFLIGHT.ps1
```

---

## Step-by-step workflow

### Step 1 — Preflight (system check)
**Script:** `00-PREFLIGHT.ps1` | **EXE:** `Stap1 - Preflight (systeemcheck).exe`

Checks whether the system is ready:
- Hyper-V enabled
- Virtualisation active in BIOS
- Sufficient RAM and disk space
- Windows version (recommended: Windows 11; Windows 10 works with a warning)
- Windows ADK installed
- Existing SSW vSwitch

Select your **certification track** to receive a personalised hardware assessment:

| Certification | Required preset | Min RAM | Min disk |
|---|---|---|---|
| MD-102 | Standard | 14 GB | 300 GB |
| MS-102 | Standard | 14 GB | 300 GB |
| SC-300 | Standard | 14 GB | 300 GB |
| AZ-104 | Minimal | 6 GB | 140 GB |

The **Continue** button only becomes active when there are no blocking errors.

---

### Step 2 — Network setup
**Script:** `01-NETWORK.ps1` | **EXE:** `Stap2 - Netwerk (vSwitch en NAT).exe`

Creates:
- Internal Hyper-V vSwitch (`SSW-Internal`)
- NAT adapter with IP `10.50.10.1`
- NetNAT (`SSW-NAT`) for internet access from VMs

Existing switch and NAT are skipped.

---

### Step 3 — ISO preparation (unattended)
**Script:** `02-MAKE-ISOS.ps1` | **EXE:** `Stap3 - ISO voorbereiding (unattended).exe`

Builds unattended ISOs from your MSDN source ISOs:
- Browse to each MSDN ISO (W11 Enterprise, WS2025)
- An `autounattend.xml` is injected → fully automated OS installation in VMs
- Requires Windows ADK (Deployment Tools)

---

### Step 4 — Create VMs
**Script:** `03-VMS.ps1` | **EXE:** `Stap4 - VMs aanmaken.exe`

Creates VMs based on the selected preset. A preset is suggested automatically based on available RAM:

| Preset | VMs | RAM usage |
|---|---|---|
| **Minimal** | DC01 + W11-01 | ~6 GB |
| **Standard** | DC01 + MGMT01 + W11-01 + W11-02 | ~14 GB |
| **Full** | Standard + W11-AUTOPILOT | ~18 GB |

---

### Step 5 — Set up Domain Controller
**Script:** `04-SETUP-DC.ps1` | **EXE:** `Stap5 - Domain Controller inrichten.exe`

Configures LAB-DC01:
- Promotes to Domain Controller for `ssw.lab`
- Configures DNS
- Creates base OU structure and lab user accounts

---

### Step 6 — Domain Join (clients)
**Script:** `05-JOIN-DOMAIN.ps1` | **EXE:** `Stap6 - Domain Join (clients).exe`

Joins client VMs (MGMT01, W11-01, W11-02) to the `ssw.lab` domain.

---

## Accounts and passwords

> **Security notice:** This lab uses local passwords stored in `autounattend.xml` inside ISOs.  
> **Never** use production passwords or company accounts. Use only MSDN test accounts with passwords created specifically for this lab.

| Account | VM | Role |
|---|---|---|
| `Administrator` | All VMs | Local admin, set interactively |
| `LAB\labadmin` | Domain | Domain admin, set interactively |

Passwords are entered interactively and are **never stored in scripts or config files**.

---

## VM Presets

| Preset | VMs | RAM | Disk | Suitable for |
|---|---|---|---|---|
| **Minimal** | DC01 + W11-01 | ~6 GB | ~140 GB | AZ-104, quick tests |
| **Standard** | DC01 + MGMT01 + W11-01 + W11-02 | ~14 GB | ~300 GB | MD-102, MS-102, SC-300 |
| **Full** | Standard + W11-AUTOPILOT | ~18 GB | ~380 GB | MD-102 (Autopilot labs) |

---

## Network configuration

```
Laptop (Hyper-V host)
└── SSW-Internal (vSwitch, internal)
    ├── 10.50.10.1   → Gateway / NAT
    ├── 10.50.10.10  → LAB-DC01
    ├── 10.50.10.20  → LAB-MGMT01
    └── 10.50.10.30+ → W11 clients (DHCP)
```

Internet access via NAT on the host. No Tailscale required.

---

## Dry Run mode

All scripts support a `-DryRun` flag:

```powershell
.\03-VMS.ps1 -DryRun
```

This shows all planned actions without making any changes.

---

## Customise configuration

Edit `config.ps1` for your environment:

```powershell
$SSWConfig = @{
    DomainName  = "ssw.lab"          # Customisable
    VMPath      = "D:\SSW-Lab\VMs"   # Customisable
    NATSubnet   = "10.50.10.0/24"    # Customisable
    ...
}
```

---

## Licences and activation

- VMs are created without a product key.
- Activate manually via the MSDN portal or Visual Studio Subscriptions after installation.
- No KMS, no MAK in scripts.

---

*SSW-Lab is built by and for Sogeti SSW colleagues. No dedicated hardware or personal domain required.*

---

## Author

**Etienne Dankfort** — Sogeti SSW  
This project is a personal community initiative and is **not an official Sogeti or Capgemini product**.  
For use in personal MSDN test environments only.

---

## Licence

MIT — see [LICENSE](../LICENSE)

---

## Disclaimer

This is a community initiative by SSW colleagues and is **not an official Sogeti or Capgemini product**.  
The author accepts no liability for any damage resulting from the use of these scripts.  
Use exclusively in an isolated test environment with MSDN licences — never in production.
