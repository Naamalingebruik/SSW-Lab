# SSW-Lab — Hyper-V Lab Deployer

> 🌐 **Taal:** Nederlands | [English](wiki-Home-EN.md)

Geautomatiseerde lab-omgeving voor Microsoft-certificeringen op een Sogeti-laptop met MSDN-licenties.

**Ondersteunde certificeringen:** MD-102 · MS-102 · SC-300 · AZ-104

---

## Studieprogramma's

Per certificering is een volledig studieprogramma beschikbaar met MS Learn modules, lab-oefeningen en kennischecks:

| Certificering | Omschrijving | Preset | Duur | Lab-scripts |
|---|---|---|---|---|
| [MD-102](studieprogramma-MD102.md) | Endpoint Administrator | Standard + Autopilot | 7 weken | 6 (week 1–6) |
| [MS-102](studieprogramma-MS102.md) | Microsoft 365 Administrator | Standard | 8 weken | 7 (week 1–7) |
| [SC-300](studieprogramma-SC300.md) | Identity and Access Administrator | Standard | 7 weken | 6 (week 1–6) |
| [AZ-104](studieprogramma-AZ104.md) | Azure Administrator | Minimal + Azure cloud | 8 weken | 7 (week 1–7) |

Elk lab-script (`scripts/labs/<CERT>/lab-week<N>-*.ps1`) heeft een WPF-GUI met Dry Run-modus, stapsgewijze begeleiding en een kennischeck. De scripts linken automatisch door naar het volgende lab.

> **Sogeti High Flex:** Start lab-scripts via *Uitvoeren als andere gebruiker* met je High Flex-account. Zscaler SSL-inspectie werkt transparant op beheerde Sogeti-laptops.

---

## Inhoudsopgave

- [Vereisten](#vereisten)
- [Architectuur](#architectuur)
- [Installatie](#installatie)
- [Workflow stap voor stap](#workflow-stap-voor-stap)
- [Accounts en wachtwoorden](#accounts-en-wachtwoorden)
- [VM Presets](#vm-presets)
- [Netwerkconfiguratie](#netwerkconfiguratie)
- [Dry Run modus](#dry-run-modus)

---

## Vereisten

| Vereiste | Minimum | Aanbevolen |
|---|---|---|
| OS | Windows 10 (build 19041+) | Windows 11 |
| RAM | 16 GB | 32 GB |
| Schijfruimte | 80 GB vrij | 150 GB vrij |
| Hyper-V | Ingeschakeld | Ingeschakeld |
| Windows ADK | Deployment Tools | Deployment Tools |
| MSDN ISO's | W11 Enterprise + WS2025 | W11 Enterprise + WS2025 |

Windows ADK (alleen Deployment Tools, ~80 MB):  
https://go.microsoft.com/fwlink/?linkid=2289980

---

## Architectuur

```
Laptop (Hyper-V host)
  └── SSW-Internal (Hyper-V vSwitch, intern + NAT)
        ├── SSW-DC01        10.50.10.10   Windows Server 2025 — Domain Controller
        ├── SSW-MGMT01          10.50.10.20   Windows 11 Enterprise — Management
        ├── SSW-W11-01          DHCP          Windows 11 Enterprise — Client 1
        ├── SSW-W11-02          DHCP          Windows 11 Enterprise — Client 2
        └── SSW-W11-AUTOPILOT   DHCP          Windows 11 Enterprise — Autopilot
```

**Domein:** `ssw.lab`  
**NAT-subnet:** `10.50.10.0/24`  
**Gateway:** `10.50.10.1`

---

## Installatie

### Optie A — EXEs (aanbevolen)

1. Download de nieuwste release van de [Releases-pagina](../../releases)
2. Pak de zip uit naar een map naar keuze
3. Start de EXEs als administrator in volgorde (zie hieronder)

### Optie B — PowerShell scripts

```powershell
git clone https://github.com/Naamalingebruik/SSW-Lab.git
cd SSW-Lab\scripts
# Start als administrator:
.\00-PREFLIGHT.ps1
```

---

## Workflow stap voor stap

### Stap 1 — Preflight (systeemcheck)
**Script:** `00-PREFLIGHT.ps1` | **EXE:** `Stap1 - Preflight (systeemcheck).exe`

Controleert of het systeem klaar is:
- Hyper-V ingeschakeld
- Virtualisatie in BIOS actief
- Voldoende RAM en schijfruimte
- Windows versie (aanbevolen: Windows 11; Windows 10 werkt met waarschuwing)
- Windows ADK geinstalleerd
- Bestaande SSW vSwitch

Toont een preset-advies op basis van beschikbare resources. Knop **Doorgaan** wordt pas actief als er geen blokkerende fouten zijn.

---

### Stap 2 — Netwerk inrichten
**Script:** `01-NETWORK.ps1` | **EXE:** `Stap2 - Netwerk (vSwitch en NAT).exe`

Maakt aan:
- Interne Hyper-V vSwitch (`SSW-Internal`)
- NAT-adapter met IP `10.50.10.1`
- NetNAT (`SSW-NAT`) voor internettoegang vanuit VMs

Bestaande switch en NAT worden overgeslagen. Kies daarna of je ISO's wilt bouwen of direct door wilt naar VMs aanmaken.

---

### Stap 3 — ISO voorbereiding (unattended)
**Script:** `02-MAKE-ISOS.ps1` | **EXE:** `Stap3 - ISO voorbereiding (unattended).exe`

Injecteert een `autounattend.xml` in MSDN ISO's zodat Windows volledig automatisch installeert:
- Schijfpartitionering (EFI + MSR + Windows)
- Tijdzone: `W. Europe Standard Time`
- Taal: `nl-NL`
- Administrator-wachtwoord instellen
- Extra lokaal account `labadmin` aanmaken (Administrators)

Vereist **Windows ADK** (oscdimg.exe).  
Produceert: `SSW-W11-Unattend.iso` en `SSW-WS2025-Unattend.iso`

---

### Stap 4 — VMs aanmaken
**Script:** `03-VMS.ps1` | **EXE:** `Stap4 - VMs aanmaken.exe`

Maakt Hyper-V Gen2 VMs aan op basis van profielen in `profiles/vm-profiles.json`:
- VHDX aanmaken (dynamisch)
- VM registreren met juiste RAM en vCPU
- Secure Boot uitschakelen
- DVD-drive koppelen aan unattended ISO
- DVD als eerste opstartapparaat instellen

Kies een **preset** of selecteer handmatig welke VMs je wilt.

---

### Stap 5 — Domain Controller inrichten
**Script:** `04-SETUP-DC.ps1` | **EXE:** `Stap5 - Domain Controller inrichten.exe`

Via **PowerShell Direct** (geen netwerk nodig) op SSW-DC01:
1. Statisch IP instellen (`10.50.10.10`)
2. Computernaam instellen (`DC01`)
3. AD DS installeren
4. Nieuw forest aanmaken (`ssw.lab`)
5. Wachten tot DC herstart en online is
6. Extra domain admin `labadmin` aanmaken in AD en toevoegen aan Domain Admins

---

### Stap 6 — Domain Join (clients)
**Script:** `05-JOIN-DOMAIN.ps1` | **EXE:** `Stap6 - Domain Join (clients).exe`

Voegt client-VMs toe aan `ssw.lab` via PowerShell Direct:
- Verbindt als lokale Administrator
- Voert `Add-Computer` uit met domain admin credentials
- VM herstart automatisch na join

Selecteer welke VMs je wilt joinen (DC01 wordt automatisch overgeslagen).

---

## Accounts en wachtwoorden

| Account | Type | Aangemaakt door | Rol |
|---|---|---|---|
| `Administrator` | Lokaal (alle VMs) | Unattend XML (stap 3) | Lokale admin |
| `labadmin` | Lokaal (alle VMs) | Unattend XML (stap 3) | Lokale admin |
| `labadmin` | Domein (ssw.lab) | DC-setup (stap 5) | Domain Admin |

> **Wachtwoord:** het wachtwoord dat je invult in stap 3 wordt gebruikt voor zowel `Administrator` als `labadmin` op alle VMs, en ook voor het `labadmin` AD-account.  
> `DSRM`-wachtwoord stel je apart in tijdens stap 5.

---

## VM Presets

| Preset | VMs | Geschat RAM |
|---|---|---|
| **Minimal** | DC01, W11-01 | ~6 GB |
| **Standard** | DC01, MGMT01, W11-01, W11-02 | ~14 GB |
| **Full** | DC01, MGMT01, W11-01, W11-02, W11-AUTOPILOT | ~18 GB |

VM-profielen (RAM, vCPU, schijfgrootte) zijn aanpasbaar in `profiles/vm-profiles.json`.

---

## Netwerkconfiguratie

| Instelling | Waarde |
|---|---|
| vSwitch | `SSW-Internal` (intern + NAT) |
| NAT naam | `SSW-NAT` |
| Subnet | `10.50.10.0/24` |
| Gateway | `10.50.10.1` |
| DC01 | `10.50.10.10` |
| MGMT01 | `10.50.10.20` |
| W11-01 | DHCP |
| W11-02 | DHCP |
| W11-AUTOPILOT | DHCP |

Alle instellingen zijn centraal aanpasbaar in `config.ps1`.

---

## Dry Run modus

Elk script heeft een **Dry Run** toggle (standaard AAN). In Dry Run worden alle acties gelogd maar niet uitgevoerd — ideaal om te controleren wat er gaat gebeuren voordat je echt uitvoert.

- Groene balk = Dry Run actief
- Rode balk = Live uitvoering


