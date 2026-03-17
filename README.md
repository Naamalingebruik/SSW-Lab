# SSW-Lab

**Hyper-V lab voor Microsoft-certificeringen (MD-102, MS-102, SC-300, AZ-104) op een Sogeti laptop met MSDN-licenties.**  
Gebouwd door en voor Sogeti SSW collega's — geen eigen domein of dedicated hardware vereist.

> **Beveiligingsnotitie:** Dit lab gebruikt lokale wachtwoorden die via unattend.xml in ISO's worden opgeslagen.  
> Gebruik **nooit** productiewachtwoorden of bedrijfsaccounts. Gebruik uitsluitend MSDN-testaccounts en wachtwoorden die je specifiek voor dit lab aanmaakt.

---

## Vereisten

| Item | Minimum | Aanbevolen |
|------|---------|------------|
| RAM | 16 GB | 32 GB |
| Vrije schijfruimte | 80 GB | 150 GB+ |
| OS | Windows 10/11 | Windows 11 |
| Hyper-V | Vereist | — |
| Licenties | MSDN | MSDN |

> **Geen eigen domein nodig.** Het lab gebruikt `ssw.lab` als intern domein. Activering verloopt via MSDN — geen productkeys in scripts.

> **Sogeti-laptop (High Flex):** Start lab-scripts als Administrator via *Uitvoeren als andere gebruiker* met je High Flex-beheerdersaccount (`admin-xxx@sogeti.com`). Zscaler SSL-inspectie is transparant — de Sogeti-root CA is vertrouwd op beheerde laptops, dus cloud-verbindingen (`Connect-AzAccount`, `Connect-MgGraph`) werken zonder aanpassing. Installeer benodigde PS-modules (`Az`, `Microsoft.Graph.*`, `ExchangeOnlineManagement`) eenmalig vooraf.

---

## Snelstart

```powershell
# 1. Controleer systeem
.\scripts\00-PREFLIGHT.ps1

# 2. Maak netwerk aan
.\scripts\01-NETWORK.ps1

# 3. Bereid ISO's voor (MSDN ISO's als bron)
.\scripts\02-MAKE-ISOS.ps1

# 4. Maak VMs aan
.\scripts\03-VMS.ps1

# 5. Richt DC in
.\scripts\04-SETUP-DC.ps1

# 6. Join clients aan domein
.\scripts\05-JOIN-DOMAIN.ps1
```

Elk script heeft een GUI en een knop om door te gaan naar het volgende.

Voor een minimale gebruikershandleiding met stap-voor-stap flow, zie:
- NL: [docs/end-to-end-smoke-test.md](docs/end-to-end-smoke-test.md)
- EN: [docs/end-to-end-smoke-test-en.md](docs/end-to-end-smoke-test-en.md)

Engelse scriptvarianten staan in: `scripts-en/`

---

## Presets

| Preset | VMs | RAM |
|--------|-----|-----|
| **Minimal** | DC01 + W11-01 | ~6 GB |
| **Standard** | DC01 + MGMT01 + 2x W11 | ~14 GB |
| **Full** | Standard + W11-AUTOPILOT | ~18 GB |

`03-VMS.ps1` stelt automatisch een preset voor op basis van beschikbaar RAM.

---

## Netwerk

```
Laptop (Hyper-V host)
└── SSW-Internal (vSwitch, intern)
    ├── 10.50.10.1   → Gateway / NAT
    ├── 10.50.10.10  → SSW-DC01
    ├── 10.50.10.20  → SSW-MGMT01
    └── 10.50.10.30+ → W11 clients (DHCP)
```

Internettoegang via NAT op de host. Geen Tailscale nodig.

---

## Configuratie aanpassen

Pas `config.ps1` aan voor jouw omgeving:

```powershell
$SSWConfig = @{
    DomainName  = "ssw.lab"          # Aanpasbaar
    VMPath      = "D:\SSW-Lab\VMs"   # Aanpasbaar
    NATSubnet   = "10.50.10.0/24"    # Aanpasbaar
    ...
}
```

---

## Licenties en activering

- VMs worden aangemaakt zonder productkey.
- Activeer handmatig via MSDN portal of Visual Studio Subscriptions na installatie.
- Geen KMS, geen MAK in scripts.

---

## Auteur

**Etienne Dankfort** — Sogeti SSW  
Dit project is een persoonlijk community-initiatief en een **niet-officieel Sogeti-product**.  
Gebruik uitsluitend in een persoonlijke MSDN-testomgeving.

---

## Licentie

MIT — zie [LICENSE](LICENSE)

---

## Disclaimer

Dit is een community-initiatief van SSW-collega's en **geen officieel Sogeti- of Capgemini-product**.  
De auteur aanvaardt geen aansprakelijkheid voor schade die voortvloeit uit het gebruik van deze scripts.  
Gebruik uitsluitend in een geïsoleerde testomgeving met MSDN-licenties — nooit in productie.

---

## Documentatie

| Document | Omschrijving |
|----------|--------------|
| [docs/lab-waarde.pdf](docs/lab-waarde.pdf) | Waarom een eigen labomgeving effectiever is dan cloud-sandboxes — onderbouwd met leeronderzoek en kostenanalyse || [docs/lab-waarde-management.pdf](docs/lab-waarde-management.pdf) | Management-samenvatting: ROI en leerwinst van het SSW-Lab voor Sogeti SSW |
---

## Structuur

```
SSW-Lab/
├── config.ps1
├── README.md
├── scripts/
│   ├── 00-PREFLIGHT.ps1          # Systeemcheck
│   ├── 01-NETWORK.ps1            # vSwitch en NAT
│   ├── 02-MAKE-ISOS.ps1          # Unattended ISO's bouwen
│   ├── 03-VMS.ps1                # VMs aanmaken
│   ├── 04-SETUP-DC.ps1           # Domain Controller inrichten
│   ├── 05-JOIN-DOMAIN.ps1        # Clients aan domein koppelen
│   └── labs/
│       ├── MD102/                # 6 lab-scripts week 1–6
│       ├── MS102/                # 7 lab-scripts week 1–7
│       ├── AZ104/                # 7 lab-scripts week 1–7
│       └── SC300/                # 6 lab-scripts week 1–6
├── profiles/
│   └── vm-profiles.json
└── docs/
    ├── studieprogramma-*.md
    ├── study-guide-*.md
    └── wiki-Home*.md
```

---

## Leerpaden per certificering

Dit lab is bruikbaar als oefenomgeving voor meerdere Microsoft-certificeringen. Hieronder per certificering welke MS Learn-leerpaden je ermee kunt oefenen en welke VMs je daarvoor nodig hebt.

---

### MD-102 — Microsoft 365 Certified: Endpoint Administrator Associate
> **Primaire doelstelling van dit lab.**

📎 [Certificeringspagina op MS Learn](https://learn.microsoft.com/credentials/certifications/modern-desktop/)

| Leerpad (MS Learn) | Nieuw domein (jan 2026) | Lab-gebruik |
|--------------------|------------------------|-------------|
| [Endpoint-infrastructuur voorbereiden](https://learn.microsoft.com/training/paths/execute-device-enrollment/) | Prepare infrastructure (25–30%) | `03-VMS` + Autopilot ISO's via `02-MAKE-ISOS`; co-management in Intune |
| [Windows Autopilot](https://learn.microsoft.com/training/paths/execute-device-enrollment/) | Prepare infrastructure | `SSW-W11-AUTOPILOT` — specifiek voor Autopilot-scenario's |
| [Apparaten beheren en onderhouden](https://learn.microsoft.com/training/paths/authentication-compliance/) | Manage/maintain devices (30–35%) | `SSW-MGMT01` voor update-beheer, RSAT en apparaatinventaris |
| [Apps en app-data beheren](https://learn.microsoft.com/training/paths/examine-application-management/) | Manage apps (15–20%) | `SSW-W11-01/02` voor app-deployment en app protection policies |
| [Apparaten beveiligen](https://learn.microsoft.com/training/paths/manage-endpoint-security/) | Protect devices (15–20%) | `SSW-MGMT01` compliance-policies, Endpoint Security en LAPS |

**Benodigde preset:** `Full`

---

### MS-102 — Microsoft 365 Certified: Administrator Expert
> Bouwt voort op MD-102. Vereist hybride AD-omgeving — precies wat dit lab biedt.

📎 [Certificeringspagina op MS Learn](https://learn.microsoft.com/credentials/certifications/m365-administrator-expert/)

| Leerpad (MS Learn) | Lab-gebruik |
|--------------------|-------------|
| [Microsoft 365-tenant configureren](https://learn.microsoft.com/training/paths/manage-your-microsoft-365-tenant/) | `SSW-MGMT01` als beheerwerkstation |
| [Identiteitssynchronisatie implementeren](https://learn.microsoft.com/training/paths/implement-identity-synchronization/) | `SSW-DC01` — Microsoft Entra Connect installeren en configureren |
| [Beveiliging en naleving beheren](https://learn.microsoft.com/training/paths/implement-threat-protection-use-microsoft-365-defender/) | Conditional Access, MFA, Defender — testen met `SSW-W11-01/02` |
| [Microsoft 365-apps beheren](https://learn.microsoft.com/training/paths/manage-your-microsoft-365-tenant/) | App-deployment via Intune testen op clients |

**Benodigde preset:** `Standard` of `Full`

---

### SC-300 — Microsoft Certified: Identity and Access Administrator Associate
> Focust op Entra ID en identiteitsbeheer. Het lab levert de on-premises AD-component.

📎 [Certificeringspagina op MS Learn](https://learn.microsoft.com/credentials/certifications/identity-and-access-administrator/)

| Leerpad (MS Learn) | Lab-gebruik |
|--------------------|-------------|
| [Identiteiten implementeren in Microsoft Entra ID](https://learn.microsoft.com/training/paths/implement-identity-management-solution/) | `SSW-DC01` als brondomein voor hybride identiteit |
| [Verificatie en toegangsbeheer](https://learn.microsoft.com/training/paths/implement-authentication-access-management-solution/) | MFA, SSPR en Conditional Access testen met lab-gebruikers |
| [Toegang tot apps beheren](https://learn.microsoft.com/training/paths/implement-access-management-for-apps/) | App-registraties en enterprise apps vanuit `SSW-MGMT01` |
| [Rechtenbeheer plannen en implementeren](https://learn.microsoft.com/training/paths/plan-implement-identity-governance-strategy/) | Entra ID Governance configureren voor lab-gebruikers |

**Benodigde preset:** `Minimal` (DC01 is voldoende als AD-bron)

---

### AZ-104 — Microsoft Certified: Azure Administrator Associate
> Minder directe fit, maar het lab is nuttig voor hybride netwerk- en identiteitsscenario's.

📎 [Certificeringspagina op MS Learn](https://learn.microsoft.com/credentials/certifications/azure-administrator/)

| Leerpad (MS Learn) | Lab-gebruik |
|--------------------|-------------|
| [Identiteiten en governance beheren](https://learn.microsoft.com/training/paths/az-104-manage-identities-governance/) | `SSW-DC01` + Entra Connect voor hybride AD-scenario's |
| [Virtuele netwerken implementeren en beheren](https://learn.microsoft.com/training/paths/az-104-manage-virtual-networks/) | NAT-configuratie in `01-NETWORK` als referentie voor Azure VNet-concepten |

**Benodigde preset:** `Minimal`

---

### Overzicht — welk lab-onderdeel dekt welke certificering?

| VM / Component | MD-102 | MS-102 | SC-300 | AZ-104 |
|----------------|:------:|:------:|:------:|:------:|
| SSW-DC01 | ✅ | ✅ | ✅ | ✅ |
| SSW-MGMT01 | ✅ | ✅ | — | — |
| SSW-W11-01/02 | ✅ | ✅ | ✅ | — |
| SSW-W11-AUTOPILOT | ✅ | — | — | — |
| NAT / vSwitch | ✅ | ✅ | — | ✅ |

---

## Labs

Naast de zes setup-scripts bevat de repo **26 begeleide lab-scripts** die stap voor stap de examenstof oefenen. Elk script heeft een WPF GUI met Dry Run-modus, voortgangsbalk en kennischeck.

### MD-102 — Endpoint Administrator (6 labs)
| Script | Onderwerp |
|--------|----------|
| `scripts/labs/MD102/lab-week1-deployment.ps1` | Windows 11 deployment, Hyper-V, AD-join |
| `scripts/labs/MD102/lab-week2-intune.ps1` | Intune-enrollement, Hybrid Azure AD Join |
| `scripts/labs/MD102/lab-week3-compliance-ca.ps1` | Compliance-beleid, Conditional Access |
| `scripts/labs/MD102/lab-week4-apps.ps1` | Win32-apps, IntuneWin32ContentPrepTool, IME |
| `scripts/labs/MD102/lab-week5-autopilot.ps1` | Windows Autopilot, hardware hash, CSV-upload |
| `scripts/labs/MD102/lab-week6-security.ps1` | Defender for Endpoint, EICAR, update rings |

### MS-102 — Microsoft 365 Administrator (7 labs)
| Script | Onderwerp |
|--------|----------|
| `scripts/labs/MS102/lab-week1-tenant.ps1` | Tenant-beheer, ADSync, delta sync, Graph |
| `scripts/labs/MS102/lab-week2-gebruikers.ps1` | OU-structuur, bulk-gebruikers, SSPR |
| `scripts/labs/MS102/lab-week3-hybrid-identity.ps1` | ADSync scheduler, password writeback, MFA |
| `scripts/labs/MS102/lab-week4-exchange.ps1` | Exchange Online, shared mailbox, DKIM |
| `scripts/labs/MS102/lab-week5-sharepoint-teams.ps1` | SharePoint Online, Teams, extern delen |
| `scripts/labs/MS102/lab-week6-defender.ps1` | Defender XDR, MDE onboarding, Secure Score |
| `scripts/labs/MS102/lab-week7-purview.ps1` | Purview, sensitivity labels, DLP, eDiscovery |

### AZ-104 — Azure Administrator (7 labs)
| Script | Onderwerp |
|--------|----------|
| `scripts/labs/AZ104/lab-week1-governance.ps1` | Resource groups, RBAC, Azure Policy, Entra-gebruikers |
| `scripts/labs/AZ104/lab-week2-storage.ps1` | Storage account, blob, SAS-token, file share |
| `scripts/labs/AZ104/lab-week3-compute.ps1` | Azure VM (B2s), data disk, snapshot, Azure Backup |
| `scripts/labs/AZ104/lab-week4-appservices.ps1` | App Service, deployment slot, ACI, autoscale |
| `scripts/labs/AZ104/lab-week5-networking.ps1` | VNet, NSG, VNet peering, Private DNS Zone |
| `scripts/labs/AZ104/lab-week6-loadbalancing.ps1` | Load Balancer, health probe, App Gateway, Traffic Manager |
| `scripts/labs/AZ104/lab-week7-monitoring.ps1` | Log Analytics, VM Insights, KQL, alert rules |

### SC-300 — Identity and Access Administrator (6 labs)
| Script | Onderwerp |
|--------|----------|
| `scripts/labs/SC300/lab-week1-hybrid-identity.ps1` | AD-structuur, Entra Connect, sync-status |
| `scripts/labs/SC300/lab-week2-external-identities.ps1` | B2B, cross-tenant access, Identity Protection |
| `scripts/labs/SC300/lab-week3-authentication.ps1` | Auth Methods, SSPR, FIDO2, WHfB, Auth Strength |
| `scripts/labs/SC300/lab-week4-conditional-access.ps1` | CA-beleid, What-If, Named Location, sign-in logs |
| `scripts/labs/SC300/lab-week5-appregistrations.ps1` | App registraties, API-rechten, client secret, App Proxy |
| `scripts/labs/SC300/lab-week6-governance-pim.ps1` | Access packages, access reviews, PIM JIT-activering |

> **MS Learn alignment (gecontroleerd maart 2026):** Alle scripts zijn afgestemd op de actuele examendoelen. SC-300 heeft per november 2025 *Global Secure Access* als nieuw examenonderdeel; dit onderwerp is nog niet opgenomen in de lab-scripts maar staat beschreven in [docs/studieprogramma-SC300.md](docs/studieprogramma-SC300.md).
