# SSW-Lab — beslissingen & wijzigingen

Dit document legt vast welke keuzes zijn gemaakt, waarom, en wat er gewijzigd is. Niet auto-gegenereerd — handmatig bijgehouden.

Voor oude scriptpaden die bewust als compatlaag blijven bestaan: zie `docs/compatibility-wrappers.md`.

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
- Waar een eigen geverifieerd domein extra waarde geeft voor realismere Entra Connect- of hybrid identity-oefeningen, mag dat als aanbevolen uitbreiding genoemd worden, maar niet als harde voorwaarde.
- Real-world scenario's zijn bewust toegevoegd zodat de gidsen niet alleen theorie opsommen, maar ook ontwerpkeuzes en operationele context trainen.

**Gevolg:** `SSW-Lab` is nu de publieke bron van waarheid voor de gedeelde studiegidsen. Het private `M365-Lab` mag nog als inspiratiebron dienen, maar is geen vereiste meer voor collega's om de studieroute te volgen; de gedeelde dev-tenant blijft wel onderdeel van de beoogde leeromgeving.

**Bestanden geraakt:**
- `docs/studieprogramma-az104.md`
- `docs/studieprogramma-md102.md`
- `docs/studieprogramma-ms102.md`
- `docs/studieprogramma-sc300.md`
- bijbehorende Engelstalige `study-guide-*.md` bestanden als referentiepunt voor consistentie

---

### Eerste stap gezet naar module-architectuur, veiliger secret-gebruik en tests

**Beslissing:** Een eerste deel van de pure logica is uit GUI-scripts gehaald en ondergebracht in `modules/SSWLab/`. Secrets blijven backward compatible met handmatige invoer en `config.local.ps1`, maar hebben nu een veiliger voorkeursroute via environment variables of `SecretManagement` wanneer beschikbaar.

**Wat nu centraal staat in de module:**
- VM-profielen laden en opzoeken
- RAM-berekening voor VM-selecties
- secret-resolutie via GUI → config → environment variable → `Get-Secret`
- credential-opbouw
- basis secret policy-validatie

**Concreet toegepast in scripts:**
- `scripts/New-LabVMs.ps1` gebruikt nu modulelogica voor profielinlees en RAM-berekening
- `scripts/Build-UnattendedIsos.ps1` kan `LabPassword` automatisch ophalen uit `SSW_LAB_PASSWORD`, `config.local.ps1` of `Get-Secret`
- `scripts/Initialize-DomainController.ps1` gebruikt dezelfde secret-flow voor lokaal adminwachtwoord en optioneel `SSW_DSRM_PASSWORD` voor DSRM

**Test- en kwaliteitskeuze:**
- Pester-basis toegevoegd in `tests/SSWLab.Tests.ps1`
- Quality-check runner toegevoegd in `build/Invoke-QualityChecks.ps1`
- `PSScriptAnalyzer` is inmiddels ook geïnstalleerd en wordt actief meegenomen in de kwaliteitsrun

**Validatie:** Op 2026-03-28 succesvol geverifieerd met:
- `.\build\Invoke-QualityChecks.ps1`
- tests: `Passed: 6 Failed: 0`
- linting: uitgevoerd; bevindingen uit de kern setup-flow zijn daarna gericht opgeschoond

**Bestanden geraakt:**
- `modules/SSWLab/SSWLab.psm1`
- `modules/SSWLab/SSWLab.psd1`
- `tests/SSWLab.Tests.ps1`
- `build/Invoke-QualityChecks.ps1`
- `scripts/New-LabVMs.ps1`
- `scripts/Build-UnattendedIsos.ps1`
- `scripts/Initialize-DomainController.ps1`
- `config.local.ps1.example`
- `README.md`

---

### Parser-cleanup voor kern setup-flow

**Beslissing:** De primaire setup-scripts voor hostnetwerk, unattended ISO's en domain controller zijn opgeschoond naar parser-veilige PowerShell 5.1 syntax, zodat tooling niet meer strandt op encoding-/tekstissues in de hoofdflow.

**Aanleiding:** Na installatie van `Pester` en `PSScriptAnalyzer` bleek dat meerdere scripts in de kernflow parse-fouten gaven door een combinatie van decoratieve Unicode-tekens en kwetsbare stringconstructies. Daardoor was betrouwbare linting op de kernsetup niet mogelijk.

**Wat is aangepast:**
- Tekststrings in de GUI-logica genormaliseerd naar ASCII-vriendelijke varianten
- kwetsbare stringopbouw vervangen waar dat parserissues gaf
- `Build-UnattendedIsos.ps1` bootdata-string vereenvoudigd
- quality runner bijgewerkt voor moderne `Pester 5` configuratie

**Validatie:** Op 2026-03-28 succesvol geverifieerd:
- `build/Parse-File.ps1` geeft nu `PARSE_OK` voor:
  - `scripts/Build-UnattendedIsos.ps1`
  - `scripts/Configure-HostNetwork.ps1`
  - `scripts/Initialize-DomainController.ps1`
- `build/Invoke-QualityChecks.ps1` blijft groen op tests (`6 passed, 0 failed`)

**Bestanden geraakt:**
- `build/Parse-File.ps1`
- `build/Invoke-QualityChecks.ps1`
- `scripts/Build-UnattendedIsos.ps1`
- `scripts/Configure-HostNetwork.ps1`
- `scripts/Initialize-DomainController.ps1`

---

### Extra testdekking toegevoegd voor config-validatie en unattend XML

**Beslissing:** Nog een deel van de pure logica is uit `Build-UnattendedIsos.ps1` gehaald en verplaatst naar `modules/SSWLab/`, zodat config-validatie en unattend XML-generatie direct testbaar zijn zonder GUI.

**Wat is toegevoegd aan de module:**
- `Test-SSWConfig`
- `New-SSWW11UnattendXml`
- `New-SSWServer2025UnattendXml`
- `ConvertTo-SSWXmlSafeValue`

**Gevolg in scripts:**
- `scripts/Build-UnattendedIsos.ps1` gebruikt nu modulefuncties voor W11- en Server 2025-unattend XML
- XML-escaping en inhoudschecks zijn niet langer alleen impliciet in het GUI-script aanwezig, maar expliciet testbaar

**Validatie:** Op 2026-03-28 succesvol geverifieerd:
- `build/Invoke-QualityChecks.ps1`
- tests: `Passed: 10 Failed: 0`

**Bestanden geraakt:**
- `modules/SSWLab/SSWLab.psm1`
- `modules/SSWLab/SSWLab.psd1`
- `scripts/Build-UnattendedIsos.ps1`
- `tests/SSWLab.Tests.ps1`

---

### Startup- en preflight-scripts parser-clean gemaakt

**Beslissing:** Ook de operationele hostscripts buiten de GUI-setupflow zijn opgeschoond naar parser-veilige PowerShell 5.1 syntax, zodat kwaliteitschecks niet meer vastlopen op preflight- of startup-automatisering.

**Wat is gevalideerd:**
- `scripts/Initialize-Preflight.ps1` geeft nu `PARSE_OK`
- `scripts/utility/Start-LabVMs.ps1` geeft nu `PARSE_OK`
- `scripts/Install-EntraConnect.ps1` geeft nu `PARSE_OK`

**Inhoudelijke lijn:**
- tekststrings en UI-teksten genormaliseerd naar parser-veilige varianten
- `Start-LabVMs.ps1` sluit nu ook beter aan op de gedeelde module voor config/profielen
- kwaliteitsrun blijft groen op tests na deze opschoning

**Validatie:** Op 2026-03-28 succesvol geverifieerd:
- `build/Parse-File.ps1`
- `build/Invoke-QualityChecks.ps1`
- tests: `Passed: 10 Failed: 0`

**Bestanden geraakt:**
- `scripts/Initialize-Preflight.ps1`
- `scripts/Install-EntraConnect.ps1`
- `scripts/utility/Start-LabVMs.ps1`
- `README.md`

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
- `scripts/New-LabVMs.ps1`, `scripts/Initialize-DomainController.ps1`, `scripts/Join-LabComputersToDomain.ps1` — referenties bijgewerkt
- `scripts/Join-LabComputersToDomain.ps1` — VM-filter aangepast van `SSW-*` naar `LAB-*`

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

Ingesteld via `scripts/utility/Repair-W11-02Network.ps1` op 2026-03-22.

---

### Scriptnamen genormaliseerd

**Beslissing:** De primaire setup-scripts volgen nu een consistente werkwoord-eerst naamgeving.

**Nieuwe primaire namen:**
| Oud | Nieuw |
|-----|-------|
| `00-PREFLIGHT.ps1` | `Initialize-Preflight.ps1` |
| `01-NETWORK.ps1` | `Configure-HostNetwork.ps1` |
| `02-MAKE-ISOS.ps1` | `Build-UnattendedIsos.ps1` |
| `03-VMS.ps1` | `New-LabVMs.ps1` |
| `03A-CLEANUP-VMS.ps1` | `Remove-OrphanedLabVMArtifacts.ps1` |
| `04-SETUP-DC.ps1` | `Initialize-DomainController.ps1` |
| `05-JOIN-DOMAIN.ps1` | `Join-LabComputersToDomain.ps1` |
| `06-SETUP-MGMT.ps1` | `Initialize-ManagementHost.ps1` |
| `utility\\_dhcp-setup.ps1` | `utility\\Initialize-DhcpScope.ps1` |
| `utility\\Fix-W11-02-Network.ps1` | `utility\\Repair-W11-02Network.ps1` |

**Gevolg:** README, wiki, runbooks en build-output gebruiken nu dezelfde functionele namen.

---

### Wrapperlaag verwijderd na standaardisatie op primaire scriptnamen

**Beslissing:** De tijdelijke wrapperlaag met oude genummerde scriptnamen en utility-aliasen is verwijderd uit `SSW-Lab`.

**Aanleiding:** De repo-documentatie, runbooks, wiki en build-uitvoer verwezen al naar de primaire scriptnamen. Omdat de repo nog in actieve verbouwing zit en er geen noodzaak meer was om oude paden te sparen, leverden de wrappers vooral dubbel onderhoud en extra ruis op.

**Verwijderd:**
- `scripts/00-PREFLIGHT.ps1`
- `scripts/01-NETWORK.ps1`
- `scripts/02-MAKE-ISOS.ps1`
- `scripts/03-VMS.ps1`
- `scripts/03A-CLEANUP-VMS.ps1`
- `scripts/04-SETUP-DC.ps1`
- `scripts/05-JOIN-DOMAIN.ps1`
- `scripts/06-SETUP-MGMT.ps1`
- `scripts/utility/_dhcp-setup.ps1`
- `scripts/utility/Fix-W11-02-Network.ps1`
- `scripts-en/02-MAKE-ISOS.ps1`
- `scripts-en/03-VMS.ps1`
- `scripts-en/03A-CLEANUP-VMS.ps1`

**Gevolg:** `SSW-Lab` heeft nu nog maar één operationeel pad per functie. Gebruik alleen de primaire scriptnamen.

---

### Losse historische statusdump onder scripts verwijderd

**Beslissing:** `scripts/status.md` is verwijderd uit `SSW-Lab`.

**Aanleiding:** Dit bestand was een oude gegenereerde voortgangsdump op een niet-logische locatie onder `scripts/`, met zichtbare encoding-schade en zonder actuele operationele verwijzingen. De echte voortgangsflow hoort via de utility-scripts en statusbestanden op repo-niveau te lopen, niet via een losse markdowndump tussen de scripts.

**Gevolg:** Er blijft minder verwarrende ballast over in `scripts/`. Historische status hoort, als die nog relevant is, niet als oud gegenereerd artefact tussen de uitvoerbare scripts te blijven staan.

---

### Oude MD-102 progress-flow vervangen door trajectgestuurde voortgang

**Beslissing:** De oude progress-scripts `scripts/utility/Get-LabProgress.ps1` en `scripts/utility/Register-LabProgressTask.ps1` zijn verwijderd en vervangen door een trajectgestuurde voortgangsflow.

**Nieuwe flow:**
- `scripts/utility/Set-CurrentTrack.ps1`
- `scripts/utility/Set-TrackCheckpoint.ps1`
- `scripts/utility/Get-TrackProgress.ps1`
- `scripts/utility/Register-TrackProgressTask.ps1`
- `profiles/learning-tracks.json`

**Aanleiding:** De vorige statusflow was inhoudelijk hard op MD-102 gecodeerd, schreef historisch wisselende outputbestanden en sloot niet meer aan op hoe de repo inmiddels meerdere certificeringstrajecten ondersteunt. De nieuwe aanpak volgt het actieve traject van de gebruiker en geeft alleen de relevante checkpoints en volgende stap terug.

**Gevolg:** Voortgang wordt nu lokaal bijgehouden per gebruiker en per traject via `profiles/*.local.json`, en gerenderd naar `status.md` en `next-steps.md` in de repo-root. De oude, vaste MD-102-flow is daarmee technisch en inhoudelijk uitgefaseerd.

---

### Wiki-home herschreven als geldende versie

**Beslissing:** `docs/wiki-Home.md` en `docs/wiki-Home-EN.md` zijn herschreven en expliciet gemarkeerd als de geldende wiki-versie vanaf `2026-03-28 23:14 +01:00`.

**Aanleiding:** De oudere wiki-inhoud liep achter op de repo-realiteit na het verwijderen van wrappers en het vervangen van de oude MD-102 progress-flow door trajectgestuurde voortgang. Daardoor bestond het risico dat collega’s nog verouderde operationele paden zouden volgen.

**Gevolg:** De wiki-home pagina’s fungeren nu weer als actuele bron van waarheid voor scriptnamen, voortgangsflow en de status van vervallen onderdelen.

---

### Trajectkeuze uit GUI gekoppeld aan track-state

**Beslissing:** De trajectkeuze in `Initialize-Preflight.ps1` en `Initialize-ManagementHost.ps1` schrijft nu automatisch de actieve track-state weg voor de trajectgestuurde voortgangsflow.

**Aanleiding:** De gebruiker kiest zijn traject al vroeg in de setup. Een extra handmatige stap via `Set-CurrentTrack.ps1` was daardoor inhoudelijk dubbel en verhoogde het risico op afwijkende state tussen GUI-keuze en voortgangsrapportage.

**Gevolg:** GUI-keuzes zoals `MD-102`, `MS-102`, `SC-300` en `AZ-104` worden nu intern genormaliseerd naar de track-ids `MD102`, `MS102`, `SC300` en `AZ104`. De voortgangsflow kan daardoor direct leunen op de trajectkeuze die eerder in het lab is gemaakt.

---

### Gateway IP op host: niet persistent na reboot

**Aandachtspunt:** Het IP `10.50.10.1` op `vEthernet (SSW-Internal)` gaat verloren na een host-reboot. `Configure-HostNetwork.ps1` moet opnieuw worden uitgevoerd (of als scheduled task worden geregistreerd) bij elke host-reboot.

**Workaround:** Scheduled task aanmaken of handmatig uitvoeren:
```powershell
.\scripts\Configure-HostNetwork.ps1
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

**Stijl:** Catppuccin dark theme WPF GUI, consistent met `scripts/Configure-HostNetwork.ps1`. STA-thread vereist (script start zichzelf opnieuw in STA als nodig). Vereist Administrator-rechten.

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

### Rebase conflict opgelost: Build-UnattendedIsos.ps1 (InstallFrom)

**Aanleiding:** Lokale commit (`2b0bd64`) had `<InstallFrom><MetaData><Key>EDITIONID</Key>...</MetaData></InstallFrom>` terwijl de remote 7 commits vooruit was met `<InstallFrom><MetaData><Key>IMAGE/NAME</Key>...</MetaData></InstallFrom>`.

**Beslissing:** Beide `<MetaData>`-blokken behouden in het `<InstallFrom>`-element. `<WillShowUI>Never</WillShowUI>` overgenomen uit de remote versie. Conflict opgelost in zowel `scripts/Build-UnattendedIsos.ps1` als `scripts-en/Build-UnattendedIsos.ps1`.

**Rebase succesvol afgerond en gepusht naar origin.**

