# SSW-Lab

**Hyper-V lab voor MD-102 op een Sogeti laptop met MSDN-licenties.**  
Gebouwd door en voor Sogeti SSW collega's — geen eigen domein of dedicated hardware vereist.

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
