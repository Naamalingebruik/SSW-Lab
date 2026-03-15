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
| [docs/lab-waarde.pdf](docs/lab-waarde.pdf) | Waarom een eigen labomgeving effectiever is dan cloud-sandboxes — onderbouwd met leeronderzoek en kostenanalyse |

---

## Structuur

```
SSW-Lab/
├── config.ps1
├── README.md
├── scripts/
│   ├── 00-PREFLIGHT.ps1
│   ├── 01-NETWORK.ps1
│   ├── 02-MAKE-ISOS.ps1
│   ├── 03-VMS.ps1
│   ├── 04-SETUP-DC.ps1
│   └── 05-JOIN-DOMAIN.ps1
└── profiles/
    └── vm-profiles.json
```

---

## Leerpaden per certificering

Dit lab is bruikbaar als oefenomgeving voor meerdere Microsoft-certificeringen. Hieronder per certificering welke MS Learn-leerpaden je ermee kunt oefenen en welke VMs je daarvoor nodig hebt.

---

### MD-102 — Microsoft 365 Certified: Endpoint Administrator Associate
> **Primaire doelstelling van dit lab.**

📎 [Certificeringspagina op MS Learn](https://learn.microsoft.com/nl-nl/credentials/certifications/modern-desktop/)

| Leerpad (MS Learn) | Lab-gebruik |
|--------------------|-------------|
| [Windows client implementeren](https://learn.microsoft.com/nl-nl/training/paths/deploy-windows-client/) | `03-VMS` + Autopilot ISO's bouwen via `02-MAKE-ISOS` |
| [Intune-beheer en beleid](https://learn.microsoft.com/nl-nl/training/paths/endpoint-manager-fundamentals/) | `SSW-W11-01/02` enrollen in Intune (Entra ID hybrid join) |
| [Windows Autopilot](https://learn.microsoft.com/nl-nl/training/paths/deploy-windows-client/) | `SSW-W11-AUTOPILOT` — specifiek voor Autopilot-scenario's |
| [Identiteit en naleving beheren](https://learn.microsoft.com/nl-nl/training/paths/manage-identity-compliance-microsoft-365/) | `SSW-DC01` voor on-premises AD, sync naar Entra ID |
| [Apparaten beheren en beveiligen](https://learn.microsoft.com/nl-nl/training/paths/manage-maintain-protect-windows-client/) | `SSW-MGMT01` voor RSAT, GPO, compliance-beleid |

**Benodigde preset:** `Full`

---

### MS-102 — Microsoft 365 Certified: Administrator Expert
> Bouwt voort op MD-102. Vereist hybride AD-omgeving — precies wat dit lab biedt.

📎 [Certificeringspagina op MS Learn](https://learn.microsoft.com/nl-nl/credentials/certifications/m365-administrator-expert/)

| Leerpad (MS Learn) | Lab-gebruik |
|--------------------|-------------|
| [Microsoft 365-tenant configureren](https://learn.microsoft.com/nl-nl/training/paths/configure-your-microsoft-365-tenant/) | `SSW-MGMT01` als beheerwerkstation |
| [Identiteitssynchronisatie implementeren](https://learn.microsoft.com/nl-nl/training/paths/implement-identity-synchronization/) | `SSW-DC01` — Microsoft Entra Connect installeren en configureren |
| [Beveiliging en naleving beheren](https://learn.microsoft.com/nl-nl/training/paths/manage-security-microsoft-365/) | Conditional Access, MFA, Defender — testen met `SSW-W11-01/02` |
| [Microsoft 365-apps beheren](https://learn.microsoft.com/nl-nl/training/paths/manage-microsoft-365-apps/) | App-deployment via Intune testen op clients |

**Benodigde preset:** `Standard` of `Full`

---

### SC-300 — Microsoft Certified: Identity and Access Administrator Associate
> Focust op Entra ID en identiteitsbeheer. Het lab levert de on-premises AD-component.

📎 [Certificeringspagina op MS Learn](https://learn.microsoft.com/nl-nl/credentials/certifications/identity-and-access-administrator/)

| Leerpad (MS Learn) | Lab-gebruik |
|--------------------|-------------|
| [Identiteiten implementeren in Microsoft Entra ID](https://learn.microsoft.com/nl-nl/training/paths/implement-identity-microsoft-entra-id/) | `SSW-DC01` als brondomein voor hybride identiteit |
| [Verificatie en toegangsbeheer](https://learn.microsoft.com/nl-nl/training/paths/implement-authentication-access-management/) | MFA, SSPR en Conditional Access testen met lab-gebruikers |
| [Toegang tot apps beheren](https://learn.microsoft.com/nl-nl/training/paths/implement-access-management-for-apps/) | App-registraties en enterprise apps vanuit `SSW-MGMT01` |
| [Rechtenbeheer plannen en implementeren](https://learn.microsoft.com/nl-nl/training/paths/plan-implement-entitlement-management/) | Entra ID Governance configureren voor lab-gebruikers |

**Benodigde preset:** `Minimal` (DC01 is voldoende als AD-bron)

---

### AZ-104 — Microsoft Certified: Azure Administrator Associate
> Minder directe fit, maar het lab is nuttig voor hybride netwerk- en identiteitsscenario's.

📎 [Certificeringspagina op MS Learn](https://learn.microsoft.com/nl-nl/credentials/certifications/azure-administrator/)

| Leerpad (MS Learn) | Lab-gebruik |
|--------------------|-------------|
| [Identiteiten en governance beheren](https://learn.microsoft.com/nl-nl/training/paths/az-104-manage-identities-governance/) | `SSW-DC01` + Entra Connect voor hybride AD-scenario's |
| [Virtuele netwerken implementeren en beheren](https://learn.microsoft.com/nl-nl/training/paths/az-104-manage-virtual-networks/) | NAT-configuratie in `01-NETWORK` als referentie voor Azure VNet-concepten |

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
