# SSW-Lab — beslissingen & wijzigingen

Dit document legt vast welke keuzes zijn gemaakt, waarom, en wat er gewijzigd is. Niet auto-gegenereerd — handmatig bijgehouden.

---

## 2026-03-21

## 2026-03-28

### Studiegidsen verrijkt voor examengerichte voorbereiding

**Beslissing:** De studiegidsen in `docs/` zijn aangescherpt als de primaire, deelbare examvoorbereiding voor collega's. Ze moeten zelfstandig bruikbaar zijn zonder toegang tot het private `M365-Lab`, maar wel in combinatie met de gedeelde MSDN / Microsoft 365 dev-tenant die voor collega's beschikbaar is.

**Doel:** Collega's moeten zich met alleen `SSW-Lab` inhoudelijk kunnen voorbereiden op de examens, inclusief:
- weekopbouw per examendomein
- realistische praktijkscenario's
- lab-oefeningen die echt uitvoerbaar zijn in `SSW-Lab`
- kennischecks en controlevragen
- consistente Nederlandse en Engelse versies

**Inhoudelijke keuzes:**
- De officiële Microsoft Learn study guides zijn de referentie voor domeinen, accenten en examscope.
- De Nederlandse studiegidsen zijn gelijkgetrokken met de Engelse versies qua scenario-opbouw en `Labcommando's`.
- Waar `SSW-Lab` een onderwerp niet volledig kan afdekken, wordt dat expliciet benoemd in plaats van impliciet verondersteld.
- Waar tenant- of portalwerk vereist is, moet dat expliciet benoemd worden zodat collega's weten wanneer ze naar de gedeelde dev-tenant of Azure-portal moeten.
- Real-world scenario's zijn bewust toegevoegd zodat de gidsen niet alleen theorie opsommen, maar ook ontwerpkeuzes en operationele context trainen.

**Gevolg:** `SSW-Lab` is nu de publieke bron van waarheid voor de gedeelde studiegidsen. Het private `M365-Lab` mag nog als inspiratiebron dienen, maar is geen vereiste meer voor collega's om de studieroute te volgen; de gedeelde dev-tenant blijft wel onderdeel van de beoogde leeromgeving.

**Bestanden geraakt:**
- `docs/studieprogramma-AZ104.md`
- `docs/studieprogramma-MD102.md`
- `docs/studieprogramma-MS102.md`
- `docs/studieprogramma-SC300.md`
- bijbehorende Engelstalige `study-guide-*.md` bestanden als referentiepunt voor consistentie

---

### Switch-Lab GUI verplaatst naar M365-Lab

**Beslissing:** `scripts/Switch-Lab.ps1` is verwijderd uit de SSW-Lab repo. De centrale GUI-switcher staat nu in `M365-Lab/scripts/host/Switch-Lab.ps1`.

**Aanleiding:** Er waren meerdere varianten van `Switch-Lab.ps1` in omloop. Dat gaf dubbel onderhoud en vergrootte de kans dat start/stop-logica en VM-namen uit elkaar gingen lopen.

**Nieuwe werkwijze:**
- SSW-Lab blijft eigenaar van de SSW-config en VM-profielen
- De centrale switcher leest die gegevens nu direct uit `config.ps1` en `profiles/vm-profiles.json`
- Er is daarmee nog maar één GUI-script dat beide labs beheert

**Gevolg:** Naamswijzigingen van SSW-VMs hoeven nog maar in de SSW-config / profielen bijgehouden te worden; de centrale switcher neemt die automatisch over.

---

### VM-namen: SSW-* → LAB-*

**Aanleiding:** De prefix `SSW-` was verwarrend omdat SSW ook de naam is van de Sogeti-businessunit en het Sogeti-platform. VM-namen zouden lokaal uniek en herkenbaar moeten zijn.

**Beslissing:** Alle Hyper-V VM-namen hernoemd van `SSW-DC01` / `SSW-MGMT01` etc. naar `LAB-DC01` / `LAB-MGMT01` etc.

**Gewijzigde namen:**
| Oud | Nieuw |
|-----|-------|
| SSW-DC01 | LAB-DC01 |
| SSW-MGMT01 | LAB-MGMT01 |
| SSW-W11-01 | LAB-W11-01 |
| SSW-W11-02 | LAB-W11-02 |
| SSW-W11-AUTOPILOT | LAB-W11-AUTOPILOT |

**Bestanden gewijzigd:**
- `profiles/vm-profiles.json` — alle VM-namen bijgewerkt
- `scripts/03-VMS.ps1`, `04-SETUP-DC.ps1`, `05-JOIN-DOMAIN.ps1` — referenties bijgewerkt
- `scripts/05-JOIN-DOMAIN.ps1` — VM-filter aangepast van `SSW-*` naar `LAB-*`

---

### NetBIOS-naam: SSW → LAB

**Aanleiding:** Na de initiële forest-promotie had het domein `ssw.lab` de NetBIOS-naam `SSW`. Dit botste met de naamgeving van het Sogeti SSW-platform en creëerde verwarring bij `LAB\gebruiker`-notaties.

**Beslissing:** Forest herbouwd met `DomainNetbiosName = "LAB"`.

**Proces:**
1. Forest gedemote: `Uninstall-ADDSDomainController -LastDomainControllerInDomain -RemoveApplicationPartitions -Force` → `Status: Success`
2. DC herstart
3. Nieuwe promotie: `Install-ADDSForest -DomainName 'ssw.lab' -DomainNetbiosName 'LAB'`
4. Verificatie: `Forest=ssw.lab NetBIOS=LAB NTDS=Running`

**Gevolg:** AD-accounts zijn nu `LAB\Administrator`, `LAB\labadmin` etc.

**Bestanden gewijzigd:**
- `config.ps1` — `DomainNetBIOS = "LAB"` (was `"SSW"`)

---

### Domain admin: labadmin aangemaakt

**Beslissing:** Naast de ingebouwde `Administrator` is `labadmin` aangemaakt als dedicated domain admin — aanbevolen werkwijze (ingebouwde Administrator zo min mogelijk gebruiken).

**Account-eigenschappen:**
- `SamAccountName`: `labadmin`
- `UPN`: `labadmin@ssw.lab`
- `PasswordNeverExpires`: true
- Lid van: `Domain Admins`
- Wachtwoord: zelfde als labwachtwoord (zie `config.local.ps1`)

---

### local override: config.local.ps1 (gitignored)

**Beslissing:** Persoonlijke waarden die niet in de repo horen (EntraUPN, productiepadden) worden opgeslagen in `config.local.ps1`. Dit bestand wordt door `.gitignore` uitgesloten.

**Patroon:**
```powershell
# config.local.ps1 (maak zelf aan, niet committen)
$SSWConfig.EntraUPN = "lab.jouwdomein.nl"
```

`config.ps1` laadt dit bestand automatisch aan het einde als het bestaat.

**Bestanden gewijzigd:**
- `.gitignore` — `config.local.ps1` toegevoegd

---

### Entra Connect voorbereiding: lab.stts.nl als UPN-suffix

**Beslissing:** Entra Connect wordt geconfigureerd met een geverifieerd custom domein (`lab.stts.nl`) uit een MSDN dev-tenant. Dit maakt Hybrid Entra ID Join mogelijk voor de on-prem AD-devices.

**Flow:**
1. `config.local.ps1` bevat `$SSWConfig.EntraUPN = "lab.stts.nl"`
2. `Install-EntraConnect.ps1` voegt `lab.stts.nl` als UPN-suffix toe aan AD
3. Entra Connect MSI wordt gekopieerd naar DC01 en geïnstalleerd
4. Handmatige wizard-configuratie daarna (Express of Custom)

**Vereisten:**
- MSI gedownload op host: `D:\SSW-Lab\AzureADConnect.msi`
- `lab.stts.nl` geverifieerd in Entra-portal van dev-tenant
- DC01 heeft internettoegang (via NAT op host)

**Bestand:** `scripts/Install-EntraConnect.ps1` (nieuw)

---

### W11-02 als pure Entra ID device (niet on-prem gejoined)

**Beslissing:** `LAB-W11-02` wordt **niet** via `Add-Computer` aan `ssw.lab` gejoined, maar via Windows OOBE ingeschreven als pure Entra ID-device via Intune.

**Reden:** Dit simuleert een BYOD/cloud-only scenario naast de hybrid-joined machines — relevant voor MD-102 en MS-102 examenstof.

**Gevolg:**
- W11-01 + MGMT01 → Hybrid Entra Join (on-prem AD + Entra Connect sync)
- W11-02 → pure Entra ID Join (via OOBE / werk- of schoolaccount)
- W11-AUTOPILOT → Autopilot-flow via Intune (cloud OOBE)

**Statisch IP (niet-domain-joined, geen DHCP van DC01):**
- IP: `10.50.10.31` / 24
- Gateway: `10.50.10.1`
- DNS: `10.50.10.10` (DC01)

Ingesteld via `scripts/utility/Fix-W11-02-Network.ps1` op 2026-03-22.

---

### Gateway IP op host: niet persistent na reboot

**Aandachtspunt:** Het IP `10.50.10.1` op `vEthernet (SSW-Internal)` gaat verloren na een host-reboot. `01-NETWORK.ps1` moet opnieuw worden uitgevoerd (of als scheduled task worden geregistreerd) bij elke host-reboot.

**Workaround:** Scheduled task aanmaken of handmatig uitvoeren:
```powershell
.\scripts\01-NETWORK.ps1
```

---

### PS Direct credential nuance

**Bevinding:** Bij PS Direct (`Invoke-Command -VMName`) werkt `.\Administrator` als gebruikersnaam (hostname-onafhankelijk) voor lokale admin-toegang. `VMNaam\Administrator` faalt als de Windows-hostname afwijkt van de Hyper-V VM-naam (wat het geval is na unattended installatie met `<ComputerName>*</ComputerName>`).

**Oplossing:** Altijd `.\Administrator` of `.\labadmin` gebruiken voor lokale PS Direct-sessies tot de machine hernoemd is.

---

## 2026-03-25

### Stop-LabVMs.ps1 toegevoegd

**Beslissing:** `scripts/utility/Stop-LabVMs.ps1` toegevoegd voor graceful shutdown van alle SSW-Lab VMs.

**Volgorde:** LAB-W11-AUTOPILOT → LAB-W11-02 → LAB-W11-01 → LAB-MGMT01 → LAB-DC01 — clients eerst, domeincontroller als laatste.

**Parameters:** `-Force` (forceer shutdown na timeout), `-TimeoutSeconds` (standaard 120).

**Werking:** Laadt VM-namen uit `profiles/vm-profiles.json` (zelfde bron als de andere scripts). Slaat ontbrekende VMs over zonder fout. Logt naar `Stop-LabVMs.log` in de repo-root.

---

### Switch-Lab.ps1 WPF GUI toegevoegd (historisch, verwijderd)

**Historische noot:** `scripts/Switch-Lab.ps1` is eerder toegevoegd als centrale GUI voor wisselen tussen SSW-Lab en M365-Lab op de NUC.

**Stijl:** Catppuccin dark theme WPF GUI, consistent met `scripts/01-NETWORK.ps1`. STA-thread vereist (script start zichzelf opnieuw in STA als nodig). Vereist Administrator-rechten.

**Functionaliteit:**
- Live VM-statuskaarten voor beide labs (● running, ○ off, — absent)
- Force/graceful shutdown toggle
- Bevestigingsdialoog vóór switch
- Logbox in GUI + logbestand
- Roept `Stop-LabVMs.ps1` in het actieve lab aan, start daarna het doellab

**Vereiste paden (NUC):**
- `D:\GitHub\SSW-Lab\scripts\utility\Stop-LabVMs.ps1`
- `D:\GitHub\M365-Lab\scripts\vm\Stop-LabVMs.ps1`

**Status nu:** Verwijderd. De centrale GUI-switcher staat nu in `M365-Lab/scripts/host/Switch-Lab.ps1`.

---

### Rebase conflict opgelost: 02-MAKE-ISOS.ps1 (InstallFrom)

**Aanleiding:** Lokale commit (`2b0bd64`) had `<InstallFrom><MetaData><Key>EDITIONID</Key>...</MetaData></InstallFrom>` terwijl de remote 7 commits vooruit was met `<InstallFrom><MetaData><Key>IMAGE/NAME</Key>...</MetaData></InstallFrom>`.

**Beslissing:** Beide `<MetaData>`-blokken behouden in het `<InstallFrom>`-element. `<WillShowUI>Never</WillShowUI>` overgenomen uit de remote versie. Conflict opgelost in zowel `scripts/02-MAKE-ISOS.ps1` als `scripts-en/02-MAKE-ISOS.ps1`.

**Rebase succesvol afgerond en gepusht naar origin.**
