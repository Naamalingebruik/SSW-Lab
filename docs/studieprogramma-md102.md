# Studieprogramma MD-102 — Endpoint Administrator

> 🌐 **Taal:** Nederlands | [English](study-guide-md102.md)

**Duur:** 7 weken · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02) + W11-AUTOPILOT voor week 5
**MS Learn pad:** [Endpoint Administrator](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/md-102)
**Examengewicht:**

| Domein | Gewicht |
|---|---|
| Infrastructuur voor devices voorbereiden | 25–30% |
| Devices beheren en onderhouden | 30–35% |
| Applicaties beheren | 15–20% |
| Devices beveiligen | 15–20% |

> **Bijgewerkt:** Skills gemeten per 23 januari 2026. De domeinstructuur is ingrijpend veranderd — "Deployen en upgraden" en "Identiteit en compliance" zijn samengevoegd tot **Infrastructuur voor devices voorbereiden**. "Beheren, onderhouden en beveiligen" is gesplitst in twee aparte domeinen.

> **Voorwaarde:** MSDN/Visual Studio-subscriptie met Microsoft 365 E5/E3 developer tenant (voor Intune, Entra ID)
> **Tenantnotitie:** als een oefening Intune, Entra of portalstappen noemt, voer je die uit in de Microsoft 365 / Entra dev-tenant en gebruik je de lokale VM's als testdevices. De testdata komt uit de standaardinhoud van die dev-tenant.
> **Domeinnotitie:** een eigen geverifieerd domein in je dev-tenant is niet verplicht, maar wel nuttig als je realistischer wilt oefenen met UPN's, Entra Connect en hybrid identity.

## Zo gebruik je dit studieprogramma

- Lees per week eerst de leerdoelen en MS Learn modules, zodat je weet welke examenscope je afdekt voordat je het lab start.
- Voer daarna de lab-oefeningen uit op de genoemde VM's en noteer onderweg wat je ziet in portal, PowerShell en clientgedrag.
- Maak de kennischeck pas nadat je de theorie en het lab hebt afgerond; gebruik de antwoorden om gaten in begrip op te sporen, niet alleen om te controleren of je iets letterlijk hebt onthouden.
- Werk je met Nederlandstalige en Engelstalige collega's samen, houd dan bewust beide termen bij: bijvoorbeeld *compliancebeleid / compliance policy* en *hybride join / hybrid join*.

## Labdekking en verwachtingen

- **Sterke dekking in SSW-Lab:** Windows deployment, Intune enrollment, Autopilot-basis, configuration profiles, compliance, updatebeheer, app deployment, endpoint security en LAPS.
- **Gedeeltelijke dekking:** co-management, Windows 365, Endpoint Privilege Management, geavanceerde reporting en sommige Intune Suite-onderdelen vereisen extra tenantfunctionaliteit of zijn vooral conceptueel.
- **Niet volledig lokaal af te dwingen:** actuele Microsoft UI-wijzigingen, licentie-afhankelijke features en onderdelen die alleen in een volledig uitgeruste M365-tenant zichtbaar zijn.
- Gebruik dit document daarom als complete studiegids, maar wees eerlijk naar jezelf: als een onderdeel als "gedeeltelijk" aanvoelt, herhaal dan ook de bijbehorende MS Learn-module in de portal.

## Werkwijze voor kennischecks

- Beantwoord elke vraag eerst zonder spieken.
- Leg je antwoord hardop uit alsof je het aan een collega overdraagt.
- Herhaal alleen de vragen die je fout had of onzeker beantwoordde.
- Let extra op scenario-vragen: het examen toetst vaak of je de juiste techniek kiest, niet alleen of je de term herkent.

---

## Week 1 — Windows client deployment
> **Examendomein:** Infrastructuur voor devices voorbereiden · **Gewicht:** 25–30%

> **Praktijkscenario:** Een consultant bij een middelgrote financiële dienstverlener moet Windows 11 uitrollen naar 400 desktops die nog op Windows 10 21H2 draaien. De IT-manager wil bestaande applicaties en gebruikersprofielen behouden, maar voor 50 nieuwe OEM-machines is een schone deployment nodig. Je kiest tussen in-place upgrade en wipe-and-load, bereidt answer files voor de nieuwe hardware voor en controleert vooraf of alle apparaten aan de Windows 11-eisen voldoen.

### Leerdoelen
- [ ] De minimale systeemvereisten voor Windows 11 kunnen opnoemen (TPM 2.0, UEFI/Secure Boot, 64 GB opslag, 4 GB RAM)
- [ ] Het verschil uitleggen tussen wipe-and-load, in-place upgrade, en fresh start deployment
- [ ] De rol van Windows ADK, DISM en Sysprep begrijpen in imaging workflows
- [ ] Een antwoordbestand (`autounattend.xml`) in opzet begrijpen en benoemen welke secties geautomatiseerd worden
- [ ] Uitleggen waarvoor `oscdimg.exe` gebruikt wordt en wanneer je een bootable ISO nodig hebt
- [ ] De minimale Windows-build voor Intune-enrollment kennen (Windows 11 build 22000+)

### MS Learn modules
- [Deploy Windows 11](https://learn.microsoft.com/en-us/training/modules/deploy-windows-client/)
- [Upgrade Windows client](https://learn.microsoft.com/en-us/training/modules/upgrade-windows-client/)
- [Windows Deployment Services en imaging](https://learn.microsoft.com/en-us/training/modules/configure-windows-deployment-services/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Wipe-and-load | Volledige herinstallatie van Windows; alle bestaande data en apps worden verwijderd |
| In-place upgrade | Windows-versie-upgrade waarbij apps, instellingen en data behouden blijven |
| Windows ADK | Assessment and Deployment Kit — toolset voor Windows-imaging (DISM, SIM, WinPE) |
| DISM | Deployment Image Servicing and Management — beheert WIM-images (drivers, pakketten, configuratie) |
| Sysprep | System Preparation Tool — generaliseert een Windows-installatie voor klonen (verwijdert SID en machinespecifieke data) |
| autounattend.xml | Antwoordbestand voor onbeheerde Windows-installaties — automatiseert taalinstelling, partitionering, productiecode en gebruikersaanmaak |
| oscdimg.exe | Onderdeel van Windows ADK — maakt bootable ISO-bestanden van een map met Windows-installatiebestanden |
| WinPE | Windows Preinstallation Environment — minimale Windows-omgeving die gestart wordt vóór de eigenlijke installatie |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-DC01** | Controleer domain `ssw.lab` — voer `Get-ADDomain` uit in PowerShell |
| **LAB-MGMT01** | Installeer Windows ADK + Deployment Tools via `Build-UnattendedIsos.ps1` |
| **LAB-W11-01** | Verifieer Windows 11 versie: `winver` → noteer build nummer |
| **LAB-W11-01** | Voer in-place upgrade-simulatie uit: `Get-WindowsUpdateLog` analyseren |
| **LAB-MGMT01** | Maak een antwoord-bestand aan met Windows System Image Manager (SIM) |

### Labcommando's

```powershell
# Controleer het huidige Windows-buildnummer
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild

# Mount een WIM-image met DISM voor offline servicing
dism /Mount-Image /ImageFile:"C:\Images\install.wim" /Index:1 /MountDir:"C:\Mount"

# Unmount de image en commit de wijzigingen
dism /Unmount-Image /MountDir:"C:\Mount" /Commit

# Generaliseer de referentiemachine voor het capturen
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown

# Maak een opstartbare ISO vanuit een map (Windows ADK)
oscdimg.exe -n -m -bC:\WinPE\boot\etfsboot.com C:\WinPE_x64 C:\Output\WinPE.iso
```

### Kennischeck
1. Wat is het verschil tussen een *wipe-and-load* en een *in-place upgrade*?
2. Welke minimale build heeft Windows 11 nodig voor Intune-enrollment?
3. Wat doet `oscdimg.exe` en waarom is het nodig voor unattended deployments?
4. Wanneer gebruik je DISM versus sysprep?

<details>
<summary>Antwoorden</summary>

1. **Wipe-and-load** verwijdert alle bestaande data, apps en het besturingssysteem voordat een schone Windows-installatie geplaatst wordt — de schijf wordt geformatteerd. Geschikt voor vervanging van een image of bij zwaar beschadigde systemen. **In-place upgrade** upgradet het besturingssysteem (bijv. Windows 10 naar Windows 11) terwijl alle gebruikersdata, applicaties en instellingen bewaard blijven — minder verstorend voor eindgebruikers, maar potentieel meer "bagage" meegenomen.

2. Windows 11 vereist build **22000** of hoger (Windows 11 21H2) voor Intune MDM-enrollment. Controleer via `winver` of via PowerShell: `(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild`.

3. `oscdimg.exe` is een commandlinetool (onderdeel van Windows ADK) die een map met Windows-installatiebestanden omzet naar een bootable ISO-bestand. Het is nodig voor unattended deployments omdat je een ISO nodig hebt die via Hyper-V, USB of PXE gestart kan worden — de bootloader-informatie en het el-Torito-bootrecord worden door oscdimg aan de ISO toegevoegd.

4. **DISM** gebruik je voor het beheren van Windows-images (WIM/ESD-bestanden): stuurprogramma's toevoegen, updatepakketten injecteren, features in- of uitschakelen, en een bestaand image monteren om te inspecteren of aan te passen. **Sysprep** gebruik je om een volledig geïnstalleerd en geconfigureerd Windows-systeem voor te bereiden op klonen — het verwijdert de unieke machine-SID, computernaam en hardwarespecifieke configuratie zodat het image op meerdere systemen uitgerold kan worden. DISM werkt op images; sysprep werkt op een lopende installatie.

</details>

---

**Scenario-vragen:**

5. Een bedrijf migreert 300 laptops van Windows 10 naar Windows 11. De bestaande laptops hebben allemaal hun originele OEM-software, domein-gekoppelde profielen en aangepaste applicatieconfiguraties die maanden hebben gekost om op te zetten. De projecttijdlijn is krap. Welke deploymentmethode is het meest geschikt?
   - A) Wipe-and-load met een nieuw masterimage
   - B) In-place upgrade via Windows Setup
   - C) Fresh start via de Windows Reset-optie
   - D) Autopilot Reset

<details>
<summary>Antwoord</summary>

**B) In-place upgrade via Windows Setup.** Een in-place upgrade behoudt alle bestaande applicaties, instellingen en gebruikersdata, wat het de juiste keuze maakt als herinstallatie tijdrovend en verstorend zou zijn. Wipe-and-load (A) vereist migratie van applicaties en data. Fresh start (C) verwijdert applicaties. Autopilot Reset (D) vereist dat het apparaat al Autopilot-geregistreerd is en wist gebruikersdata.

</details>

6. Een endpoint engineer moet een Windows 11-referentieimage voorbereiden voor uitrol naar 200 nieuwe desktops. Na volledige configuratie van de referentiemachine, wat moet hij doen vóór het capturen van het image met DISM?
   - A) `Get-WindowsUpdateLog` uitvoeren om de patchstatus te controleren
   - B) `Sysprep /generalize /oobe /shutdown` uitvoeren
   - C) `DISM /CheckHealth` uitvoeren op het live systeem
   - D) De machine koppelen aan het domein vóór het capturen

<details>
<summary>Antwoord</summary>

**B) `Sysprep /generalize /oobe /shutdown` uitvoeren.** Sysprep moet uitgevoerd worden vóór het capturen van een referentieimage om machinespecifieke identifiers te verwijderen (SID, computernaam, hardwarespecifieke drivers). Zonder generalisatie zouden alle uitgerolde machines dezelfde SID delen, wat identiteitsconflicten veroorzaakt. De machine mag NIET aan het domein gekoppeld zijn vóór generalisatie (D), omdat Sysprep met generalize de domainkoppeling toch verwijdert.

</details>

7. Een deployment engineer gebruikt `DISM /Mount-Image` om een WIM-bestand te inspecteren en bijgewerkte drivers toe te voegen. Na het aanbrengen van wijzigingen voert de engineer `DISM /Unmount-Image /Discard` uit in plaats van `/Commit`. Wat is het resultaat?
   - A) Alle wijzigingen inclusief de geïnjecteerde drivers worden opgeslagen in het WIM
   - B) Alleen de driver-injectie wordt opgeslagen; overige wijzigingen worden genegeerd
   - C) Alle wijzigingen worden genegeerd en het WIM keert terug naar de originele staat
   - D) Het WIM-bestand wordt van schijf verwijderd

<details>
<summary>Antwoord</summary>

**C) Alle wijzigingen worden genegeerd en het WIM keert terug naar de originele staat.** De `/Discard`-vlag ontkoppelt het image zonder de aangebrachte wijzigingen door te voeren — het WIM is precies zoals het was vóór het mounten. Om wijzigingen op te slaan, moet `/Commit` gebruikt worden.

</details>

---

## Week 2 — Intune enrollment en device management
> **Examendomein:** Infrastructuur voor devices voorbereiden · **Gewicht:** 25–30%

> **Praktijkscenario:** Een Sogeti-consultant onboardt een nieuwe klant van 200 medewerkers zonder on-premises domeininfrastructuur. Alle Windows 11-laptops moeten via Intune beheerd worden en BitLocker moet op elk device verplicht zijn. Nieuwe medewerkers krijgen hun laptop rechtstreeks van de leverancier en moeten zichzelf zonder helpdesk kunnen provisionen. Jij kiest de juiste enrollmentmethode, richt BitLocker-beleid in en zorgt dat het compliance-overzicht voor livegang bruikbaar is.

### Leerdoelen
- [ ] De verschillende Intune-enrollmentmethoden kennen: handmatig, Autopilot, bulk enrollment (PPKG), co-management
- [ ] Het verschil uitleggen tussen MDM-enrollment en MAM (App Protection Policies zonder enrollment)
- [ ] Een compliance policy aanmaken en de statussen *Compliant*, *Not compliant* en *In grace period* interpreteren
- [ ] Een configuration profile aanmaken (bijv. BitLocker enforced) en de toewijzing aan een apparaatgroep uitleggen
- [ ] Uitleggen wat de Enrollment Status Page doet bij Autopilot-provisioning
- [ ] Hybrid Azure AD Join onderscheiden van puur Entra ID Join in de context van enrollment

### MS Learn modules
- [Enroll devices in Microsoft Intune](https://learn.microsoft.com/en-us/training/modules/enroll-devices/)
- [Manage device profiles with Intune](https://learn.microsoft.com/en-us/training/modules/manage-device-profiles/)
- [Monitor devices with Intune](https://learn.microsoft.com/en-us/training/modules/monitor-devices-microsoft-intune/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| MDM-enrollment | Het apparaat wordt volledig beheerd via Intune: policies, apps, remote actions, wipe |
| MAM (zonder enrollment) | App Protection Policies beschermen alleen app-data op niet-enrolled (BYOD) apparaten — geen apparaatbeheer |
| Hybrid Azure AD Join | Apparaat is lid van on-premises AD én geregistreerd in Entra ID via Azure AD Connect — beheert via GPO en/of Intune |
| Entra ID Join | Apparaat is uitsluitend in Entra ID geregistreerd — geen on-premises domein nodig |
| Compliance policy | Intune-beleid dat bepaalt wanneer een apparaat "compliant" is (bijv. minimale OS-versie, BitLocker aan, Defender actief) |
| Enrollment Status Page (ESP) | Scherm dat tijdens Autopilot-provisioning de voortgang van app- en profielinstallatie toont; blokkeert het bureaublad totdat alles gereed is |
| Configuration profile | Intune-beleid dat apparaatinstellingen configureert (bijv. BitLocker, VPN, Wi-Fi, screensaver) |
| Intune check-in | Periodiek contactmoment (standaard elke 8 uur) waarop het apparaat policies en app-opdrachten ophaalt |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-W11-01** | Enroll device in Intune via **Instellingen → Accounts → Werk of school** |
| **LAB-W11-02** | Enroll second device — observeer verschil in Intune-portal |
| **LAB-MGMT01** | Open Intune-portal (intune.microsoft.com) → controleer beide devices onder **Devices → All devices** |
| **LAB-MGMT01** | Maak een *Configuration profile* aan: BitLocker enforced op W11-01 |
| **LAB-W11-01** | Verifieer BitLocker-status: `manage-bde -status` |
| **LAB-MGMT01** | Bekijk **Device compliance** — maak een compliance policy aan (minimale OS-versie) |

### Labcommando's

```powershell
# Controleer de BitLocker-versleutelingsstatus van schijf C:
manage-bde -status C:

# Forceer direct een Intune-beleidssynchronisatie vanaf het apparaat
Start-Process "ms-device-enrollment://enroll"
# Of start de synchronisatie via een Scheduled Task:
Start-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\" -TaskName "Schedule to run OMADMClient by client"

# Verzamel een MDM-diagnosepakket voor enrollment-troubleshooting
MdmDiagnosticsTool.exe -out C:\Temp\MdmDiag

# Controleer de Intune-enrollmentstatus in het register
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Enrollments\*" | Select PSChildName, EnrollmentType, UPN
```

### Kennischeck
1. Wat is het verschil tussen MDM-enrollment en Hybrid Azure AD Join?
2. Welke enrollment-methodes bestaan in Intune en wanneer gebruik je welke?
3. Wat betekent een *Compliant* versus *Not compliant* status in Intune?
4. Hoe werkt de *Enrollment Status Page* bij Autopilot?

<details>
<summary>Antwoorden</summary>

1. **MDM-enrollment** is het proces waarbij een apparaat onder Intune-beheer komt — Intune kan policies pushen, apps installeren, remote actions uitvoeren en het apparaat wipen. **Hybrid Azure AD Join** is een apparaatstatus waarbij het device zowel lid is van een on-premises Active Directory-domein als geregistreerd is in Entra ID. Een Hybrid AADJ-apparaat kan ook MDM-enrolled zijn via Intune (via automatische MDM-enrollment op basis van GPO), maar de twee begrippen zijn niet hetzelfde: join-status beschrijft de identiteitsregistratie; enrollment beschrijft het beheerkanaal.

2. Enrollmentmethoden in Intune voor Windows:
   - **Handmatig (BYOD):** Instellingen → Accounts → Werk of school → Verbinden. Geschikt voor persoonlijke apparaten.
   - **Windows Autopilot:** Zero-touch provisioning via hardware hash registratie. Geschikt voor nieuwe bedrijfsapparaten.
   - **Bulk enrollment via PPKG:** Provisioning package (Windows Configuration Designer). Geschikt voor bestaande apparaten zonder Intune-licentie of internet.
   - **Automatische enrollment via GPO:** Voor Hybrid AADJ-apparaten die al domeinlid zijn — GPO triggert automatische MDM-enrollment.
   - **Co-management:** Bestaande ConfigMgr-clients enrollen naast ConfigMgr ook in Intune.

3. **Compliant:** het apparaat voldoet aan alle ingestelde compliance-vereisten (bijv. BitLocker aan, Defender actief, juiste OS-versie). Intune rapporteert "Compliant" en Conditional Access policies die compliance vereisen laten de gebruiker door. **Not compliant:** het apparaat voldoet niet aan één of meer vereisten. Afhankelijk van de ingestelde grace period wordt toegang geblokeerd via CA na het verstrijken van die periode. De gebruiker ziet in Company Portal welke vereisten niet voldaan zijn.

4. De **Enrollment Status Page (ESP)** toont de eindgebruiker tijdens de Autopilot-provisioning de voortgang van drie fases: apparaatvoorbereiding, apparaatinstallatie (profielen en apps die vereist zijn voor het apparaat) en accountinstallatie (profielen en apps voor de gebruiker). Het bureaublad wordt geblokkeerd totdat alle verplichte items geïnstalleerd zijn — dit voorkomt dat gebruikers het apparaat gaan gebruiken voordat het correct geconfigureerd is. De ESP is configureerbaar: je kunt een timeout instellen en beslissen of gebruikers de installatie mogen overslaan.

</details>

---

**Scenario-vragen:**

5. Een bedrijf wil bestaande Windows 11-laptops enrollen die momenteel lid zijn van een on-premises Active Directory-domein. Het IT-team wil dat gebruikers geen handmatige stappen hoeven te nemen. Welke enrollmentmethode is het meest geschikt?
   - A) Handmatig enrollen via Instellingen → Accounts → Werk of school
   - B) Windows Autopilot User-Driven mode
   - C) GPO-gestuurde automatische MDM-enrollment voor Hybrid Azure AD Joined devices
   - D) Bulk enrollment via Provisioning Package (PPKG)

<details>
<summary>Antwoord</summary>

**C) GPO-gestuurde automatische MDM-enrollment voor Hybrid Azure AD Joined devices.** De apparaten zijn al domeinlid, dus als ze ook Hybrid Azure AD Joined zijn (gesynchroniseerd via Azure AD Connect), zal een Group Policy die de MDM enrollment-URL target ze stil in Intune enrollen zonder gebruikersinteractie. Handmatig enrollen (A) vereist actie van de gebruiker. Autopilot (B) is bedoeld voor nieuwe of gereset apparaten die door OOBE gaan. PPKG (D) is bedoeld voor offline scenario's of apparaten zonder Intune-licentie.

</details>

6. Een Intune compliance policy vereist dat BitLocker ingeschakeld is en de OS-versie minimaal Windows 11 22H2 is. Een apparaat draait Windows 11 21H2 met BitLocker ingeschakeld. Er is een grace period van 3 dagen ingesteld. Het apparaat heeft 1 dag geleden ingecheckt. Wat is de huidige compliancestatus?
   - A) Compliant
   - B) Not compliant
   - C) In grace period
   - D) Not evaluated

<details>
<summary>Antwoord</summary>

**C) In grace period.** Het apparaat voldoet niet aan de OS-versievereiste (21H2 is lager dan het vereiste 22H2), dus is het technisch niet-compliant. Omdat de grace period van 3 dagen echter nog niet verstreken is (er is pas 1 dag voorbij), wordt het apparaat weergegeven als "In grace period" in plaats van "Not compliant". Na 3 dagen zonder herstel verandert de status naar "Not compliant" en kunnen Conditional Access-blokkades van kracht worden.

</details>

7. Na het aanmaken van een nieuw configuration profile in Intune en het toewijzen aan een apparaatgroep, hoe lang duurt het doorgaans voordat de policy toegepast wordt op een enrolled Windows-apparaat, en hoe kan een engineer directe levering forceren?
   - A) Tot 24 uur; geen mogelijkheid om levering te forceren
   - B) Tot 8 uur; start een Sync remote action vanuit de Intune-portal of vanuit de Company Portal-app op het apparaat
   - C) Direct; Intune pusht policies altijd in real time
   - D) Tot 72 uur; het apparaat moet opnieuw gestart worden

<details>
<summary>Antwoord</summary>

**B) Tot 8 uur; start een Sync remote action vanuit de Intune-portal of vanuit de Company Portal-app op het apparaat.** Intune-apparaten checken standaard ongeveer elke 8 uur in. Om een directe beleidssync te forceren kan een beheerder de **Sync** remote action gebruiken in de Intune-portal (Devices → selecteer apparaat → Sync), of de gebruiker kan de Company Portal openen en **Sync** kiezen op de apparaatdetailspagina. Het standaard check-in interval is 8 uur voor enrolled Windows-apparaten (niet 24 uur, niet direct, niet 72 uur).

</details>

---

## Week 3 — Compliance, Conditional Access en identiteit
> **Examendomein:** Infrastructuur voor devices voorbereiden · **Gewicht:** 25–30%

> **Praktijkscenario:** Een productiebedrijf schakelt Sogeti in nadat een gerichte phishingaanval meerdere accounts heeft gecompromitteerd. De CISO eist MFA voor cloudtoegang buiten kantoor, alleen toegang tot Microsoft 365 vanaf Intune-ingeschreven en compliant devices, en Windows LAPS om laterale beweging met gedeelde lokale admin-wachtwoorden te beperken. Jij richt Conditional Access, Named Locations, LAPS en de hybride synchronisatie via Entra Connect correct in.

### Leerdoelen
- [ ] Een Conditional Access-policy aanmaken met de juiste signalen (gebruiker, apparaat, locatie, risico)
- [ ] Het verschil uitleggen tussen *Block access* en *Grant with controls* (bijv. MFA, compliant device vereisen)
- [ ] Azure AD Connect Sync vergelijken met Entra Cloud Sync en weten wanneer je welke gebruikt
- [ ] Named Locations configureren en gebruiken in een CA-policy
- [ ] Windows LAPS configureren via Intune en het geroteerde wachtwoord opvragen via de portal
- [ ] Het verschil tussen Windows LAPS (modern) en legacy Microsoft LAPS (on-premises AD) uitleggen

### MS Learn modules
- [Configure device compliance policies](https://learn.microsoft.com/en-us/training/modules/configure-device-compliance-policies/)
- [Configure Conditional Access](https://learn.microsoft.com/en-us/training/modules/configure-conditional-access/)
- [Manage user and device identities](https://learn.microsoft.com/en-us/training/modules/manage-user-device-identities/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Conditional Access (CA) | Toegangsbeleid in Entra ID dat op basis van signalen (gebruiker, apparaat, locatie, risico) toegang verleent of blokkeert |
| Named Locations | Vertrouwde IP-bereiken of landen die in CA als "bedrijfsnetwerk" of "vertrouwde locatie" gemarkeerd zijn |
| Grant controls | CA-actie: verleen toegang mits aan een voorwaarde voldaan is (bijv. MFA, compliant device, Hybrid AADJ) |
| Block access | CA-actie: weiger altijd toegang voor de ingestelde conditions — geen uitzondering voor de gebruiker mogelijk |
| Report-only modus | CA-instelling waarmee je het effect van een policy kunt evalueren zonder daadwerkelijk toegang te blokkeren |
| Azure AD Connect Sync | On-premises server die gebruikers, groepen en apparaten synchroniseert van on-prem AD naar Entra ID |
| Entra Cloud Sync | Lichtgewicht agent (geen volledige AD Connect server) voor AD-naar-Entra synchronisatie — beperkter maar eenvoudiger te beheren |
| Windows LAPS | Ingebouwd in Windows 11 22H2+ — beheert automatisch het wachtwoord van het lokale admin-account en slaat dit op in Entra ID of on-prem AD |
| Legacy LAPS | Aparte agent voor on-premises Active Directory — wachtwoorden opgeslagen in AD-attribuut, niet in Entra ID |
| Primary Refresh Token (PRT) | SSO-token dat bij inloggen op Entra ID-joined apparaten uitgegeven wordt — gebruikt voor naadloze toegang tot alle cloud-apps zonder opnieuw inloggen |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-DC01** | Maak test-gebruikers aan in AD: `New-ADUser -Name "TestUser01" ...` |
| **LAB-DC01** | Sync AD naar Entra ID via Azure AD Connect (installeer op DC01) |
| **LAB-MGMT01** | Configureer een Conditional Access-policy: MFA verplicht buiten het bedrijfsnetwerk |
| **LAB-W11-01** | Test de CA-policy: log in met TestUser01, verifieer MFA-prompt |
| **LAB-MGMT01** | Maak een compliance policy: vereist Defender, BitLocker, en min. W11 22H2 |
| **LAB-W11-02** | Demonstreer niet-compliant device → controleer block in CA-policy |
| **LAB-MGMT01** | Schakel **Windows LAPS** in via Intune: Endpoint security → Account protection → LAPS-policy |
| **LAB-W11-01** | Verifieer LAPS: haal het geroteerde lokale adminwachtwoord op via de Intune-portal |

### Labcommando's

```powershell
# Maak een testgebruiker aan in Active Directory
New-ADUser -Name "TestUser01" -SamAccountName "testuser01" -UserPrincipalName "testuser01@ssw.lab" `
  -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Enabled $true

# Forceer een Azure AD Connect-delta-sync
Start-ADSyncSyncCycle -PolicyType Delta

# Haal het door LAPS beheerde lokale adminwachtwoord op via Microsoft Graph (vereist Az- of Graph-module)
Get-MgDeviceLocalCredentials -DeviceId "<device-object-id>" -IncludeSecrets

# Controleer de Windows LAPS-status op het lokale apparaat
Get-LapsAADPassword -DeviceId (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").DefaultDomainName
```

### Kennischeck
1. Welke signalen gebruikt Conditional Access voor een access-beslissing?
2. Wat is het verschil between *Block* en *Grant with controls* in CA?
3. Hoe verhoudt Azure AD Connect Sync zich tot Cloud Sync?
4. Wat doet de *Named Locations* instelling in CA?
5. Wat is *Windows LAPS* en hoe verschilt het van de legacy LAPS-oplossing?

<details>
<summary>Antwoorden</summary>

1. Conditional Access beoordeelt toegang op basis van de volgende signalen (conditions):
   - **Gebruiker/groep en rol:** op welke gebruiker of rol is het beleid van toepassing
   - **Cloud app of actie:** tot welke app of service probeert de gebruiker toegang te krijgen
   - **Apparaatplatform:** Windows, iOS, Android, macOS
   - **Locatie:** Named Locations (vertrouwde IP-bereiken of landen)
   - **Client-app:** browser, moderne auth-app, legacy auth
   - **Aanmeldrisico (Identity Protection):** laag/gemiddeld/hoog risiconiveau van de inloging
   - **Apparaatstatus:** compliant, Hybrid AADJ, of Entra ID-joined

2. **Block access** weigert altijd toegang voor de ingestelde conditions — de gebruiker kan niets doen om toch toegang te krijgen. **Grant with controls** verleent toegang mits de gebruiker/het apparaat aan aanvullende voorwaarden voldoet, zoals MFA voltooien, een compliant apparaat gebruiken, of een Hybrid AADJ-apparaat gebruiken. De gebruiker kan de controle actief oplossen (bijv. MFA voltooien) en krijgt daarna toegang.

3. **Azure AD Connect Sync** is een volledige on-premises server-installatie die alle AD-objecten (gebruikers, groepen, apparaten, contacten) synchroniseert naar Entra ID — ondersteunt complexe scenario's zoals password hash sync, passthrough auth, federation, en writeback. **Entra Cloud Sync** is een lichtgewicht agent (geen volledige server) die een subset van synchronisatiescenario's ondersteunt. Cloud Sync is eenvoudiger te installeren en beheren, maar biedt minder functionaliteit (bijv. geen device writeback). Kies Cloud Sync voor eenvoudige omgevingen; kies AD Connect voor complexe hybride scenario's of als writeback vereist is.

4. **Named Locations** zijn in Entra ID gedefinieerde sets van vertrouwde IP-adressen (bijv. het bedrijfsnetwerk) of landen/regio's. In een CA-policy gebruik je Named Locations als condition om onderscheid te maken tussen toegang vanuit het kantoor (vertrouwde locatie) versus thuis of onderweg. Voorbeeld: MFA alleen vereisen als de gebruiker zich **buiten** de Named Location bevindt. Zo vermijd je dat medewerkers op kantoor steeds MFA moeten doen.

5. **Windows LAPS (modern)** is ingebouwd in Windows 11 22H2+ en Windows Server 2022, configureert het wachtwoord van het lokale admin-account automatisch, en slaat het op in Entra ID (cloud) of on-premises AD. Beheerd via Intune of Group Policy. **Legacy LAPS** is een aparte agent die je op elk apparaat moet installeren, werkt alleen met on-premises Active Directory (wachtwoord opgeslagen als AD-attribuut), en wordt geconfigureerd via GPO. Microsoft adviseert migratie naar Windows LAPS. Kernverschil: Windows LAPS ondersteunt Entra ID als backup-bestemming; legacy LAPS werkt alleen on-premises.

</details>

---

**Scenario-vragen:**

6. Een bedrijf wil ervoor zorgen dat medewerkers alleen toegang hebben tot Microsoft 365-applicaties (Exchange Online, SharePoint) wanneer ze een apparaat gebruiken dat in Intune enrolled en als compliant gemarkeerd is. Medewerkers die inloggen vanaf persoonlijke, niet-beheerde apparaten moeten volledig geblokkeerd worden. Welke Conditional Access-configuratie bereikt dit?
   - A) Grant access with controls: MFA vereisen
   - B) Grant access with controls: compliant device vereisen
   - C) Block access voor alle locaties behalve Named Locations
   - D) Grant access with controls: Hybrid Azure AD Joined device vereisen

<details>
<summary>Antwoord</summary>

**B) Grant access with controls: compliant device vereisen.** Een compliant device vereisen betekent dat alleen Intune-enrolled apparaten die voldoen aan de compliance policy toegang kunnen krijgen — niet-beheerde persoonlijke apparaten worden geblokkeerd omdat ze niet enrolled zijn en daardoor geen compliancestatus hebben. Optie A (alleen MFA) blokkeert geen niet-beheerde apparaten. Optie C beperkt alleen op basis van locatie, niet op apparaatbeheerstatus. Optie D (Hybrid AADJ) blokkeert cloud-only Entra ID-joined apparaten en is niet de juiste keuze voor een cloud-first omgeving.

</details>

7. Een organisatie heeft recentelijk een migratie naar een cloud-only Entra ID-omgeving voltooid zonder resterende on-premises Active Directory-infrastructuur. Ze willen lokale admin-wachtwoorden op alle Windows 11 22H2-apparaten rouleren en veilig opslaan. Welke oplossing moet de consultant aanbevelen?
   - A) Legacy Microsoft LAPS met wachtwoorden opgeslagen in on-premises AD
   - B) Windows LAPS geconfigureerd om te back-uppen naar Entra ID via Intune-policy
   - C) Een PowerShell-script dat wachtwoorden genereert en e-mailt naar het IT-team
   - D) Het lokale administrator-account op alle apparaten uitschakelen

<details>
<summary>Antwoord</summary>

**B) Windows LAPS geconfigureerd om te back-uppen naar Entra ID via Intune-policy.** Windows LAPS (ingebouwd in Windows 11 22H2+) ondersteunt Entra ID als back-upbestemming, wat precies is wat een cloud-only omgeving vereist. Legacy LAPS (A) vereist on-premises Active Directory en kan geen wachtwoorden opslaan in Entra ID. Een script (C) is geen beheerde, controleerbare oplossing. Het lokale administrator-account uitschakelen (D) verwijdert de break-glass hersteloptie en wordt niet aanbevolen.

</details>

8. Er wordt een Conditional Access-policy aangemaakt om MFA af te dwingen voor alle gebruikers die SharePoint Online benaderen. Het security team wil de impact testen vóór activering, om te voorkomen dat medewerkers onbedoeld buitengesloten worden. Welke CA-instelling moet worden gebruikt tijdens de testfase?
   - A) Stel de policy in op **Uitgeschakeld**
   - B) Stel de policy in op **Report-only** modus
   - C) Stel de policy in op **Block access** voor een pilotgroep
   - D) Schakel de policy in met een Named Location-uitzondering voor het bedrijfsnetwerk

<details>
<summary>Antwoord</summary>

**B) Stel de policy in op Report-only modus.** Report-only modus evalueert elke aanmelding aan de hand van de policycondities en logt wat de policy zou hebben gedaan (verlenen, blokkeren of MFA vereisen), maar handhaaft geen actie. Hiermee kan het security team de aanmeldlogs in Entra ID analyseren en getroffen gebruikers identificeren vóór het inschakelen van de policy. De policy uitschakelen (A) levert geen testdata op. Optie C (blokkeren voor pilotgroep) is handhaving, geen testen. Optie D wijzigt de scope van de policy in plaats van deze veilig te testen.

</details>

---

## Week 4 — Applicatiebeheer met Intune
> **Examendomein:** Applicaties beheren · **Gewicht:** 15–20%

> **Praktijkscenario:** Een retailketen met 600 Windows 11-endpoints gebruikt Intune voor volledig devicebeheer. De IT-afdeling wil een legacy ERP-app met complexe EXE-installer stil uitrollen, Adobe Acrobat Reader optioneel beschikbaar maken via Company Portal en tegelijk voorkomen dat medewerkers op privé-iPhones bedrijfsdata vanuit Outlook naar persoonlijke apps kopiëren. Jij verpakt de Win32-app, bepaalt assignment-intents en configureert App Protection Policies voor BYOD.

### Leerdoelen
- [ ] De verschillende app-typen in Intune kennen: Win32, MSI/MSIX, Microsoft Store, LOB, webapplicatie, M365 Apps
- [ ] Een Win32-app verpakken met de IntuneWinAppUtil en uploaden naar Intune inclusief detectieregel
- [ ] Het verschil uitleggen tussen een *Required* en een *Available* app-toewijzing
- [ ] Een App Protection Policy (MAM) aanmaken en de werking beschrijven voor BYOD-scenario's
- [ ] De `IntuneManagementExtension.log` localiseren en gebruiken voor troubleshooting van app-installaties
- [ ] Microsoft 365 Apps deployen via Intune en de rol van ODT en OCT uitleggen

### MS Learn modules
- [Deploy and update applications with Intune](https://learn.microsoft.com/en-us/training/modules/deploy-applications/)
- [Manage Win32 apps with Intune](https://learn.microsoft.com/en-us/training/modules/manage-win32-apps/)
- [Configure Microsoft 365 Apps deployment](https://learn.microsoft.com/en-us/training/modules/configure-microsoft-365-apps/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Win32 app | App verpakt als `.intunewin` bestand — het meest flexibele app-type voor complexe installaties met custom detect- en installatiecommando's |
| IntuneWinAppUtil | Gratis Microsoft-tool die een installatiemap omzet naar een `.intunewin` pakket voor Intune |
| Detectieregel | Regel die Intune gebruikt om te bepalen of een app al geïnstalleerd is (bestandspad, registry-sleutel of MSI product code) |
| Required deployment | Geforceerde installatie — het apparaat ontvangt en installeert de app automatisch, de gebruiker kan niet weigeren |
| Available deployment | App verschijnt in Company Portal — de gebruiker kiest zelf of en wanneer de app geïnstalleerd wordt |
| App Protection Policy (MAM) | Beveiligingsbeleid op app-niveau: versleutelt app-data, blokkeert kopiëren naar persoonlijke apps, vereist PIN bij openen — werkt ook zonder enrollment |
| MAM-WE | MAM Without Enrollment — App Protection Policies op niet-enrolled BYOD-apparaten |
| IntuneManagementExtension.log | Logbestand op `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\` — bevat gedetailleerde status van Win32-app-installaties en PowerShell-scripts |
| ODT | Office Deployment Tool — commandlinetool voor installatie, update en verwijdering van Microsoft 365 Apps via een XML-configuratiebestand |
| OCT | Office Customization Tool — webgebaseerde GUI op config.office.com om de ODT XML-configuratie te genereren |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-MGMT01** | Pak een `.exe` app in als `.intunewin` met de **Intune Win32 Content Prep Tool** |
| **LAB-MGMT01** | Upload de Win32 app naar Intune → assign aan W11-01 (Required) |
| **LAB-W11-01** | Controleer installatie via **Company Portal** of eventlog (`IntuneManagementExtension`) |
| **LAB-MGMT01** | Maak een Microsoft 365 Apps deployment aan via Intune (Office-suite) |
| **LAB-W11-02** | Verifieer Office-installatie na sync (`imdssync` of wacht op Intune check-in) |
| **LAB-MGMT01** | Configureer een *App protection policy* (MAM) voor Microsoft Edge |

### Labcommando's

```powershell
# Verpak een Win32-appinstaller naar .intunewin-formaat
.\IntuneWinAppUtil.exe -c "C:\AppSource\MyApp" -s "setup.exe" -o "C:\IntunePackages"

# Volg het IntuneManagementExtension-log realtime voor troubleshooting
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Wait -Tail 50

# Controleer of een specifieke app wordt gedetecteerd (simuleer detection rule op bestandspad)
Test-Path "C:\Program Files\MyApp\myapp.exe"

# Start een IME-herbeoordeling van apps (herstart de service)
Restart-Service -Name IntuneManagementExtension
```

### Kennischeck
1. Wat is het verschil tussen een *Required* en *Available* app-assignment?
2. Wanneer gebruik je Win32 app packaging versus Microsoft Store for Business?
3. Wat doet de `IntuneManagementExtension.log` en waar staat die?
4. Wat zijn de voordelen van MAM zonder MDM-enrollment?

<details>
<summary>Antwoorden</summary>

1. **Required:** Intune installeert de app automatisch op het toegewezen apparaat of voor de toegewezen gebruiker — zonder interactie van de gebruiker. De installatie vindt plaats bij de volgende Intune check-in. De gebruiker kan de installatie niet weigeren of uitstellen. Geschikt voor verplichte bedrijfssoftware. **Available:** De app verschijnt in de Company Portal-app. De gebruiker kiest zelf of en wanneer de app geïnstalleerd wordt. Geschikt voor optionele of aanvullende software.

2. **Win32 app packaging** gebruik je wanneer: de app een complex installatieprogramma heeft (`.exe` met switches), je aangepaste detectieregels nodig hebt, de app pre- of post-installatiescripts vereist, of de app niet beschikbaar is in de Microsoft Store. **Microsoft Store for Business** (of de nieuwe Microsoft Store in Intune) gebruik je wanneer: de app beschikbaar is in de Store, je geen extra verpakking wilt doen, en automatische updates via de Store gewenst zijn. Store-apps hebben geen eigen detectieregel nodig.

3. De `IntuneManagementExtension.log` staat op `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`. Het bevat gedetailleerde stap-voor-stap logging van: Win32 app-installaties (download, detectie, uitvoering van het installatiecommando, detectie na installatie), PowerShell-scripts die via Intune uitgevoerd worden, en Proactive Remediations (detectie en herstelscripts). Het is het primaire troubleshootingbestand voor "waarom is mijn app niet geïnstalleerd?".

4. **MAM zonder MDM-enrollment (MAM-WE)** heeft de volgende voordelen voor BYOD-scenario's:
   - **Privacy:** het persoonlijke apparaat wordt niet beheerd door IT — geen remote wipe van het hele apparaat mogelijk
   - **Eenvoud:** de gebruiker hoeft het apparaat niet formeel in te schrijven
   - **Beveiliging van bedrijfsdata:** app-data (bijv. e-mail in Outlook, bestanden in OneDrive) wordt versleuteld en afgeschermd, kopiëren naar persoonlijke apps wordt geblokkeerd
   - **Flexibiliteit:** werkt op iOS, Android en Windows zonder volledige MDM-controle
   - **Acceptatie:** medewerkers accepteren MAM-WE eerder dan volledige MDM-enrollment op een persoonlijk apparaat

</details>

---

**Scenario-vragen:**

5. Een bedrijf implementeert een Win32-app naar een apparaatgroep in Intune met een Required-toewijzing. De app installeert niet op één apparaat en er is geen foutmelding zichtbaar in de Intune-portal. Waar moet de engineer als eerste kijken om het probleem te diagnosticeren?
   - A) Windows Event Viewer → Application-log
   - B) `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
   - C) Het Microsoft Endpoint Manager-beheercentrum → Troubleshooting + support
   - D) Het Windows Update-log (`Get-WindowsUpdateLog`)

<details>
<summary>Antwoord</summary>

**B) `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.** Dit is altijd het eerste bestand om te controleren bij mislukte Win32-app-implementaties. Het bevat de volledige uitvoer van het installatieprogramma, het resultaat van de detectieregel-evaluatie, de exitcode van het installatieprogramma en eventuele nieuwe pogingen. De Intune-portal toont vaak een generieke foutcode; het IME-log onthult de specifieke oorzaak. Windows Event Viewer (A) en het Windows Update-log (D) bevatten geen Win32-app-implementatiedetails.

</details>

6. Een bedrijf wil Microsoft Outlook-data op privé-iPhones van medewerkers beschermen zonder de apparaten in Intune te enrollen. Medewerkers moeten hun persoonlijke iPhones kunnen gebruiken voor zakelijke e-mail, maar het kopiëren van zakelijke e-mails naar persoonlijke notities of apps van derden moet geblokkeerd worden. Welke Intune-functie moet de consultant configureren?
   - A) Device compliance policy voor iOS
   - B) Device configuration profile: e-mailinstellingen voor iOS
   - C) App Protection Policy (MAM zonder enrollment) voor Outlook op iOS
   - D) Conditional Access policy die een compliant device vereist

<details>
<summary>Antwoord</summary>

**C) App Protection Policy (MAM zonder enrollment) voor Outlook op iOS.** MAM-WE past App Protection Policies toe op beheerde apps (Outlook) op niet-beheerde persoonlijke apparaten zonder MDM-enrollment te vereisen. Het kan kopiëren/plakken naar niet-beheerde apps beperken, een PIN vereisen bij het openen van Outlook, app-data versleutelen en selectief zakelijke data wissen — allemaal zonder persoonlijke data aan te raken of de gebruiker te verplichten zijn iPhone te enrollen. Een device compliance policy (A) vereist enrollment. Een configuration profile (B) vereist ook enrollment. Een CA-policy die een compliant device vereist (D) zou de toegang volledig blokkeren vanaf niet-beheerde apparaten.

</details>

7. Een engineer uploadt een Win32-app naar Intune en moet een detectieregel configureren. Het installatieprogramma maakt na een geslaagde installatie een registersleutel `HKLM:\SOFTWARE\MijnBedrijf\MijnApp` aan met de waarde `Versie = 2.1`. Welk type detectieregel moet worden gebruikt?
   - A) MSI-productcode detectie
   - B) Bestandspad detectie
   - C) Registersleutel detectie
   - D) PowerShell-script detectie

<details>
<summary>Antwoord</summary>

**C) Registersleutel detectie.** Omdat de geslaagde installatie een specifieke registersleutel en -waarde aanmaakt, is een register-detectieregel de meest directe en betrouwbare aanpak. Configureer deze om te controleren op de aanwezigheid van `HKLM:\SOFTWARE\MijnBedrijf\MijnApp` met waarde `Versie = 2.1`. MSI-productcode detectie (A) is alleen van toepassing op MSI-gebaseerde installatieprogramma's. Bestandspad detectie (B) werkt als de installatie een bekend bestand aanmaakt, maar het scenario specificeert een registersleutel. PowerShell detectie (D) is het meest flexibel maar ook het meest complex — onnodig als een ingebouwd regeltype direct overeenkomt met het bewijs.

</details>

---

## Week 5 — Windows Autopilot
> **Examendomein:** Infrastructuur voor devices voorbereiden · **Gewicht:** 25–30%

> **Praktijkscenario:** Een logistiek bedrijf ontvangt maandelijks 50 nieuwe laptops rechtstreeks van een reseller. Nieuwe medewerkers moeten het apparaat uit de doos kunnen halen, verbinden met internet en binnen 30 minuten een volledig ingericht Windows 11-device hebben zonder tussenkomst van IT. Daarnaast zijn er gedeelde kioskterminals in magazijnen die zonder gebruikerslogin automatisch moeten configureren. Jij richt User-Driven en Self-Deploying Autopilot-scenario's, de Enrollment Status Page en hardware hash-registratie via de reseller in.

### Leerdoelen
- [ ] De vier Autopilot-scenario's kennen en toepassen: User-driven, Self-deploying, Pre-provisioning (White Glove), Existing Device
- [ ] Een hardware hash ophalen via PowerShell en uploaden naar Intune
- [ ] Een Autopilot deployment profile aanmaken en de OOBE-instellingen configureren
- [ ] De Enrollment Status Page (ESP) configureren met een timeout en verplichte apps
- [ ] Autopilot Reset uitleggen en onderscheiden van een volledige fabrieksreset
- [ ] Windows 365 Cloud PC vergelijken met Azure Virtual Desktop op de examendomeinen
- [ ] Een KQL device query uitvoeren in Intune en de beschikbare tabellen benoemen

### MS Learn modules
- [Configure Windows Autopilot](https://learn.microsoft.com/en-us/training/modules/configure-windows-autopilot/)
- [Autopilot deployment scenarios](https://learn.microsoft.com/en-us/training/modules/windows-autopilot-deployment-scenarios/)
- [Troubleshoot Windows Autopilot](https://learn.microsoft.com/en-us/training/modules/troubleshoot-windows-autopilot/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Hardware hash | Unieke apparaat-fingerprint die via PowerShell (`Get-WindowsAutoPilotInfo`) verzameld wordt en in Intune geregistreerd wordt voor Autopilot |
| User-driven mode | Autopilot-scenario waarbij de gebruiker inlogt met een Entra ID-account tijdens OOBE — het apparaat wordt persoonlijk ingericht |
| Self-deploying mode | Autopilot-scenario voor kiosken/shared devices — geen gebruikersinteractie vereist; apparaat authenticeert via TPM 2.0 |
| Pre-provisioning (White Glove) | IT of leverancier doorloopt de technician flow vooraf — apps en profielen worden geïnstalleerd vóór uitgifte aan de gebruiker |
| Autopilot Reset | Herinstalleer Windows terwijl het apparaat Entra ID-joined en Autopilot-geregistreerd blijft — gebruikersdata wordt verwijderd |
| Group Tag | Label op een Autopilot-apparaat om via dynamische Entra ID-groepen automatisch het juiste deployment profile toe te wijzen |
| Windows 365 Cloud PC | Desktop-as-a-Service: volledige persoonlijke Windows-desktop gehost in Microsoft-cloud, beheerd via Intune |
| Azure Virtual Desktop (AVD) | Microsoft-hosted VDI: multi-session mogelijk, pay-per-use Azure-kosten, meer flexibel maar complexer dan Windows 365 |
| KQL Device Query | Kusto Query Language-query direct op één apparaat in Intune — real-time hardware/software-informatie; vereist Intune Advanced Analytics |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-W11-AUTOPILOT** | Haal hardware hash op: `Get-WindowsAutoPilotInfo -OutputFile hash.csv` |
| **LAB-MGMT01** | Upload hash naar Intune: **Devices → Windows → Enrollment → Windows Autopilot devices** |
| **LAB-MGMT01** | Maak een Autopilot deployment profile aan: *User-driven, Microsoft Entra join* |
| **LAB-W11-AUTOPILOT** | Reset de VM (Instellingen → Systeem → Herstel → Reset deze pc) |
| **LAB-W11-AUTOPILOT** | Doorloop de Out-of-Box Experience (OOBE) → verifieer automatische enrollment |
| **LAB-MGMT01** | Analyseer de Autopilot-events in **Event Viewer → Applications and Services → Microsoft → Windows → Autopilot** |
| **LAB-MGMT01** | Verken *Windows 365* in Intune: bekijk Cloud PC-inrichtingsbeleid |
| **LAB-MGMT01** | Voer een *device query* uit met KQL: **Devices → selecteer device → Device query** |

### Labcommando's

```powershell
# Verzamel de hardware-hash en exporteer naar CSV (vereist WindowsAutoPilotIntune-module)
Install-Script -Name Get-WindowsAutoPilotInfo
Get-WindowsAutoPilotInfo -OutputFile C:\Temp\AutopilotHash.csv

# Upload de hardware-hash direct naar Intune (vereist MS Graph / WindowsAutoPilotIntune-module)
Install-Module -Name WindowsAutoPilotIntune
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
Import-AutoPilotCSV -csvFile C:\Temp\AutopilotHash.csv

# Voorbeelden van KQL device queries in Intune Device Query
# Voer deze uit in: Intune → Devices → [select device] → Device query
# InstalledApplications | project ApplicationName, ApplicationVersion | order by ApplicationName asc
# SystemInfo | project DeviceName, Manufacturer, Model, OSVersion, TotalMemory
```

### Kennischeck
1. Wat is het verschil tussen *User-driven* en *Self-deploying* Autopilot mode?
2. Waarvoor dient de *Enrollment Status Page* en hoe configureer je 'm?
3. Hoe reset je een Autopilot-profiel toewijzing als een device al geregistreerd is?
4. Wat is *Windows Autopilot Reset* en wanneer gebruik je het?
5. Wat is *Windows 365* en hoe verschilt het van Azure Virtual Desktop?
6. Hoe voer je een KQL device query uit in Intune en welke data kun je ophalen?

<details>
<summary>Antwoorden</summary>

1. **User-driven:** de gebruiker logt in met zijn Entra ID-account tijdens de OOBE — het apparaat wordt persoonlijk ingericht voor die gebruiker. Vereist: een Autopilot-geregistreerd apparaat, internet, en een Entra ID-account. Geschikt voor persoonlijke werkapparaten. **Self-deploying:** er is geen gebruikersinloggen vereist — het apparaat authenticeert zichzelf via TPM 2.0 en certificaat. Geschikt voor kiosken, shared devices, en digital signage. Vereist: TPM 2.0 (hardware-attestation) en internet. Geen gebruikersaccount wordt aangemaakt.

2. De **Enrollment Status Page (ESP)** toont de voortgang van drie installatiefases (apparaatvoorbereiding, apparaatinstallatie, accountinstallatie) en blokkeert het bureaublad totdat alles gereed is. Configureren via Intune → Devices → Windows → Enrollment → Enrollment Status Page → Create profile. Stel in: naam, tijdlimiet (bijv. 60 minuten), welke apps geblokkeerd totdat ze geïnstalleerd zijn, en of gebruikers de installatie mogen overslaan bij time-out.

3. Als een apparaat al een Autopilot-profiel toegewezen heeft en je wilt dat wijzigen: ga naar Intune → Devices → Windows → Enrollment → Windows Autopilot devices → selecteer het apparaat → Assign user (voor user-driven) of verander de groepstag (Group Tag). Bij een groepstag-wijziging wordt het profiel opnieuw geëvalueerd op basis van de dynamische groep. Voor een volledige deregistratie: selecteer het apparaat → Delete → re-importeer de hardware hash.

4. **Autopilot Reset** (ook: Windows Autopilot Reset) verwijdert alle gebruikersdata, geïnstalleerde apps en persoonlijke instellingen van een apparaat, maar behoudt de Entra ID-enrollment, het Autopilot-profiel en de domein-join-configuratie. Het apparaat start opnieuw op naar de Autopilot-OOBE voor de volgende gebruiker. Gebruik het bij: hergebruik van een apparaat voor een nieuwe medewerker, het "schoon" teruggeven van een apparaat na uit dienst treding van een medewerker, of bij een geïnfecteerd systeem dat gereset moet worden zonder volledige herinstallatie.

5. **Windows 365** is een Desktop-as-a-Service: elke gebruiker krijgt een vaste, persoonlijke Cloud PC (virtuele Windows-desktop in Microsoft-cloud) voor een vaste prijs per gebruiker/maand. Beheerd volledig via Intune. **Azure Virtual Desktop (AVD)** is Microsoft-hosted VDI: multi-session mogelijk (meerdere gebruikers per VM-host), kosten op basis van Azure-verbruik (flexibeler bij laag gebruik), meer complex om op te zetten en te beheren. Sleutelonderscheid: Windows 365 = vaste prijs, altijd persistent, persoonlijk; AVD = variabele kosten, kan gedeeld/niet-persistent zijn, vereist Azure-infrastructuurbeheer.

6. KQL Device Query uitvoeren: Intune → Devices → All devices → selecteer een apparaat → tabblad **Device query**. Typ een KQL-query in het interactieve queryvenster en klik op **Run**. Beschikbare tabellen (voorbeelden): `InstalledApplications` (geïnstalleerde apps), `SystemInfo` (hardware, OS-versie), `LocalUsers` (lokale gebruikersaccounts), `LogicalDrive` (schijfruimte). De resultaten zijn real-time (huidig moment), anders dan de gecachte Intune-hardware-inventory. Vereist: Intune Advanced Analytics (onderdeel van Intune Suite of Plan 2).

</details>

---

**Scenario-vragen:**

7. Een bedrijf implementeert magazijn-kioskterminals met Windows 11. De terminals moeten zichzelf automatisch configureren wanneer ze verbinding maken met het netwerk — geen gebruiker hoeft ooit in te loggen tijdens de provisioning, en er mag geen gebruikersaccount worden gekoppeld aan het apparaat in Entra ID. Welke Autopilot-modus moet worden gebruikt?
   - A) User-Driven mode met Entra ID join
   - B) Pre-Provisioning (White Glove) met technician flow
   - C) Self-Deploying mode
   - D) Autopilot for Existing Devices

<details>
<summary>Antwoord</summary>

**C) Self-Deploying mode.** Self-Deploying mode richt het apparaat in zonder gebruikersinteractie — het apparaat authenticeert via TPM 2.0 hardware-attestation, er is geen gebruikersaccount vereist en User Affinity is ingesteld op Geen. Dit is de juiste modus voor kiosken, shared devices en digital signage. User-Driven mode (A) vereist dat een gebruiker zich authenticeert. White Glove (B) is een tweefasenmodus voor het vooraf inrichten van apparaten vóór uitgifte aan de gebruiker. Autopilot for Existing Devices (D) is voor het migreren van bestaande domeingebonden machines naar Autopilot, niet voor kioskimplementatie.

</details>

8. Een apparaat werd recentelijk gebruikt door een medewerker die het bedrijf heeft verlaten. Het IT-team wil het opnieuw toewijzen aan een nieuwe medewerker. Het apparaat is momenteel enrolled in Intune en geregistreerd in Autopilot. Het IT-team wil de Intune-enrollment en Autopilot-registratie behouden, alle vorige gebruikersdata verwijderen en de nieuwe medewerker de standaard OOBE-provisioning laten doorlopen. Wat is de juiste actie?
   - A) Een Wipe (fabrieksreset) uitvoeren vanuit de Intune-portal
   - B) Een Autopilot Reset uitvoeren vanuit de Intune-portal
   - C) Het apparaat uit Intune verwijderen en de hardware hash opnieuw importeren
   - D) Het apparaat uit Intune pensioneren (Retire) en handmatig opnieuw enrollen

<details>
<summary>Antwoord</summary>

**B) Een Autopilot Reset uitvoeren vanuit de Intune-portal.** Autopilot Reset verwijdert alle gebruikersdata en applicaties, zet Windows terug naar een schone OOBE-ready staat, maar houdt het apparaat geregistreerd in Autopilot en het Entra ID-object intact. De nieuwe medewerker kan vervolgens inloggen tijdens de OOBE en het apparaat richt zichzelf automatisch opnieuw in met alle toegewezen profielen en apps. Een volledige Wipe (A) reset het apparaat ook maar verwijdert het Entra ID-apparaatobject en de Intune-enrollment — het apparaat zou opnieuw geregistreerd moeten worden. Het verwijderen uit Intune (C) of Retire (D) introduceert onnodige complexiteit.

</details>

9. Een Intune-beheerder voert de volgende KQL-query uit op een apparaat via de Device Query-functie: `InstalledApplications | where ApplicationName contains "Chrome"`. De query geeft geen resultaten, maar de beheerder kan Chrome zien in de standaard Intune-hardware-inventory. Wat is de meest waarschijnlijke verklaring?
   - A) KQL device queries werken alleen op apparaten met Windows 11 23H2 of later
   - B) De standaard Intune-inventory is real-time; KQL-queries gebruiken gecachte data
   - C) De KQL-query is succesvol uitgevoerd maar Chrome is verwijderd tussen de inventory-sync en de query
   - D) KQL Device Query vereist Intune Advanced Analytics; het apparaat heeft mogelijk niet de juiste licentie

<details>
<summary>Antwoord</summary>

**D) KQL Device Query vereist Intune Advanced Analytics; het apparaat heeft mogelijk niet de juiste licentie.** Device Query is onderdeel van Intune Advanced Analytics, wat Intune Suite- of Intune Plan 2-licenties vereist. Zonder deze licentie kan het Device Query-tabblad zichtbaar zijn maar geen resultaten retourneren of een fout tonen. Het beschreven scenario waarbij resultaten leeg zijn terwijl de inventory de app wel toont, is het klassieke symptoom van een licentie- of functie-activeringsprobleem. Merk ook op dat KQL-queries *real-time* zijn (niet gecacht) — het tegenovergestelde van optie B — dus de discrepantie die in optie B wordt beschreven is in werkelijkheid omgekeerd.

</details>

---

## Week 6 — Security, updates, Intune Suite en monitoring
> **Examendomein:** Devices beveiligen · **Gewicht:** 15–20%

> **Praktijkscenario:** Een zorgorganisatie schakelt Sogeti in na een ransomware-incident waarbij meerdere fileservers zijn versleuteld. De CISO wil binnen zeven dagen na release updates afdwingen, alle endpoints onboarden naar Microsoft Defender for Endpoint, lokale administratorrechten voor standaardgebruikers wegnemen terwijl bepaalde beheertools verhoogd mogen draaien, en proactieve monitoring invoeren. Jij richt update rings, Defender-onboarding, Endpoint Privilege Management en Endpoint Analytics in.

### Leerdoelen
- [ ] Het verschil uitleggen tussen een Update ring (WUfB) en een Feature update policy en ze naast elkaar configureren
- [ ] Co-management tussen Intune en Configuration Manager beschrijven en de workload-verdeling uitleggen
- [ ] Het Endpoint analytics dashboard interpreteren en anomaliedetectie begrijpen
- [ ] Remote actions (wipe, retire, sync, rotate LAPS password) uitvoeren vanuit de Intune-portal
- [ ] De zes Intune Suite-add-ons benoemen en het probleem dat elk oplost beschrijven
- [ ] Endpoint Privilege Management (EPM) configureren met elevation rules voor specifieke applicaties
- [ ] Een Security Baseline deployen en de status rapporteren via Intune

### MS Learn modules
- [Manage endpoint security with Intune](https://learn.microsoft.com/en-us/training/modules/manage-endpoint-security/)
- [Manage Windows updates with Intune](https://learn.microsoft.com/en-us/training/modules/manage-windows-updates-intune/)
- [Monitor and troubleshoot devices](https://learn.microsoft.com/en-us/training/modules/monitor-troubleshoot-devices/)
- [Intune Suite add-on capabilities](https://learn.microsoft.com/en-us/mem/intune/fundamentals/intune-add-ons)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Update ring (WUfB) | Windows Update for Business-beleid dat de deferral van kwaliteits- en feature-updates instelt (in dagen) |
| Quality Update | Maandelijkse cumulatieve beveiligings- en bugfixpatch (Patch Tuesday) |
| Feature Update | Halfjaarlijkse versie-upgrade van Windows (bijv. 22H2 → 23H2) — apart van kwaliteitsupdates instelbaar |
| Deferral period | Aantal dagen dat een update tegengehouden wordt nadat Microsoft hem uitbrengt |
| Feature update policy | Intune-policy die een specifieke Windows-doelversie vastpint — forceert upgrade naar die versie |
| Co-management | Windows-apparaat beheerd door zowel Configuration Manager als Intune — workloads zijn per functie te verdelen |
| Tenant Attach | ConfigMgr-apparaten zichtbaar in Intune-portal voor remote actions en hardware-inventory — zonder volledige co-management |
| Endpoint analytics | Intune-dashboard voor apparaatprestaties, opstartduur, app-betrouwbaarheid en anomaliedetectie |
| Security Baseline | Vooraf geconfigureerde bundel van Microsoft-aanbevolen beveiligingsinstellingen (Windows, Defender, Edge) |
| Intune Suite | Betaalde add-on bundel met: EPM, Enterprise App Catalog, Remote Help, Advanced Analytics, Cloud PKI, Tunnel for MAM |
| Endpoint Privilege Management (EPM) | Intune Suite-component waarmee standaardgebruikers specifieke apps met verhoogde rechten kunnen starten — zonder permanent lokaal admin-account |
| Elevation rule | EPM-configuratie die bepaalt welk specifiek bestand/proces verheven mag worden, en of dit automatisch of na gebruikersbevestiging gebeurt |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-MGMT01** | Configureer een *Update ring* in Intune: Semi-Annual Channel, 7 dagen defer |
| **LAB-W11-01** | Controleer Windows Update-status: `Get-WindowsUpdateLog` |
| **LAB-MGMT01** | Activeer Microsoft Defender for Endpoint via Intune *Endpoint security → Antivirus* |
| **LAB-W11-01** | Voer een Defender Quick Scan uit: `Start-MpScan -ScanType QuickScan` |
| **LAB-W11-02** | Simuleer een detectie met EICAR testbestand → analyseer alert in Defender portal |
| **LAB-MGMT01** | Bekijk **Device diagnostics** in Intune-portal → download diagnostics van W11-01 |
| **LAB-MGMT01** | Verken *Endpoint Privilege Management* (EPM) in Intune Suite: maak een elevation policy aan |
| **LAB-MGMT01** | Bekijk *Advanced Analytics* in Intune: controleer het anomaliedetectie-dashboard |
| **LAB-MGMT01** | Verken de **Enterprise App Catalog**: zoek een beheerde app en bekijk de metadata |

### Labcommando's

```powershell
# Controleer de status van de Windows Defender-service (SENSE = MDE-sensor)
sc query sense

# Start een Defender Quick Scan
Start-MpScan -ScanType QuickScan

# Controleer de huidige Windows Update-uitstelinstellingen in het register
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Select DeferQualityUpdates, DeferQualityUpdatesPeriodInDays

# Controleer de versie van de Defender-definities
Get-MpComputerStatus | Select AntivirusSignatureVersion, AntispywareSignatureLastUpdated, RealTimeProtectionEnabled

# Start een update van de Defender-signatures
Update-MpSignature
```

### Kennischeck
1. Wat is het verschil tussen een *Update ring* en een *Feature update policy*?
2. Hoe werkt *Co-management* tussen Intune en Configuration Manager?
3. Wat toont het **Endpoint analytics** dashboard in Intune?
4. Hoe gebruik je *Remote actions* (wipe, retire, sync) in Intune?
5. Welke Intune Suite-add-ons bestaan er en welk probleem lost elk op?
6. Wat is *Endpoint Privilege Management* en wanneer gebruik je elevation policies?

<details>
<summary>Antwoorden</summary>

1. **Update ring** (Windows Update for Business) stelt een deferral-periode in: quality updates bijv. 7 dagen vertragen, feature updates 30 dagen. Het apparaat ontvangt de update automatisch nadat de deferral-periode verstreken is — je hebt geen controle over welke versie geïnstalleerd wordt, alleen over het tijdstip. **Feature update policy** pint een specifieke Windows-doelversie vast (bijv. Windows 11 23H2) en forceert apparaten die een oudere versie hebben om naar die versie te upgraden. Gebruik beide naast elkaar: de update ring voor kwaliteitsupdates, de feature update policy om de Windows-versie te beheren.

2. **Co-management** combineert Configuration Manager (on-premises) en Intune (cloud) voor hetzelfde Windows-apparaat. De ConfigMgr-client draait op het apparaat en registreert het ook in Intune. Per workload (bijv. Compliance Policies, Endpoint Protection, Windows Updates, Office Click-to-Run, Resource Access) kies je wie de authority is: ConfigMgr of Intune. Je kunt workloads geleidelijk verschuiven via een pilot-collection. Zo kun je in eigen tempo migreren van ConfigMgr naar volledig cloud-beheer.

3. Het **Endpoint analytics**-dashboard toont: apparaatopstarttijden en prestatiescores (Startup performance), app-betrouwbaarheid (Application reliability — crashes en hangs), Recommended software score (patch-compliance aanbevelingen), anomaliedetectie (apparaten die afwijken van de norm worden gesignaleerd), resource performance (CPU/RAM-gebruik), en de work from anywhere score. Het helpt IT-beheerders proactief prestatieproblemen te identificeren vóórdat gebruikers gaan klagen.

4. **Remote actions** via Intune: ga naar Intune → Devices → All devices → selecteer een apparaat. Beschikbare acties (afhankelijk van platform en OS):
   - **Wipe:** fabrieksreset — verwijdert alle data en herinstalleer Windows; apparaat is niet meer bruikbaar totdat het opnieuw geconfigureerd is
   - **Retire:** verwijdert bedrijfsdata en -profielen, maar laat persoonlijke data intact (voor BYOD)
   - **Sync:** triggert een directe Intune check-in — apparaat haalt onmiddellijk nieuwe policies en apps op
   - **Rotate LAPS password:** rouleert het lokale admin-wachtwoord onmiddellijk
   - **Fresh Start:** herinstalleer Windows maar behoud gebruikersdata

5. De zes **Intune Suite**-add-ons:
   - **Endpoint Privilege Management (EPM):** oplossing voor least-privilege — specifieke apps met admin-rechten zonder gebruiker permanent admin te maken
   - **Enterprise App Catalog:** bibliotheek van ~300+ voorgeconfigureerde Win32-apps met automatische updates
   - **Microsoft Intune Remote Help:** Intune-native remote support met audit-logging en RBAC — vervangt TeamViewer/Quick Assist
   - **Advanced Analytics:** uitgebreide apparaatrapportage, anomaliedetectie en KQL device queries
   - **Microsoft Cloud PKI:** volledig beheerde CA in de cloud — elimineert on-premises ADCS + NDES + Certificate Connector
   - **Microsoft Tunnel for MAM:** VPN-tunnel voor MAM-beheerde apps op niet-enrolled iOS/Android apparaten

6. **Endpoint Privilege Management** stelt standaardgebruikers (zonder lokaal adminrecht) in staat om specifieke, door IT goedgekeurde applicaties te starten met verhoogde (admin) rechten. Je gebruikt **elevation rules** wanneer: gebruikers een specifieke applicatie soms als admin moeten starten (bijv. een legacy installer, een beheertool), maar ze permanent lokaal admin maken te riskant is. Configureer per applicatie: bestandsnaam, eventueel bestandshash (voor extra verificatie), en het elevatietype — *managed elevation* (automatisch, geen gebruikersinteractie) of *user-confirmed elevation* (gebruiker bevestigt via pop-up, genereert audittrail). Vereist Intune Suite of Intune Plan 2.

</details>

---

**Scenario-vragen:**

7. Het security team van een bedrijf vereist dat alle Windows-kwaliteitsupdates (beveiligingspatches) binnen 10 dagen na de releasedatum van Microsoft geïnstalleerd zijn, met verplichte herstart-handhaving na de deadline. Feature updates moeten op de huidige Windows 11-versie blijven totdat ze expliciet goedgekeurd worden. Welke combinatie van Intune-policies bereikt dit?
   - A) Één Update ring met een kwaliteits-deferral van 10 dagen en verplichte herstart; geen Feature update policy nodig
   - B) Één Update ring met een kwaliteits-deferral van 0 dagen; een Feature update policy die de huidige Windows 11-versie vastpint
   - C) Één Update ring met een kwaliteits-deferral van 10 dagen en herstart-handhaving; plus een Feature update policy die de huidige Windows 11-versie vastpint
   - D) Twee Update rings — één voor kwaliteit, één voor feature — met verschillende deferral-instellingen

<details>
<summary>Antwoord</summary>

**C) Één Update ring met een kwaliteits-deferral van 10 dagen en herstart-handhaving; plus een Feature update policy die de huidige Windows 11-versie vastpint.** De Update ring regelt de timing van kwaliteitsupdates en het herstartgedrag. De Feature update policy beheert apart welke Windows-versie apparaten op blijven, waardoor het security team feature updates onafhankelijk van kwaliteitspatches kan goedkeuren. Optie A laat feature updates onbeheerd (ze worden geregeld door de feature-deferral van de update ring, wat niet noodzakelijk een specifieke versie vastpint). Optie B stelt de kwaliteits-deferral in op 0 (direct), wat het 10-dagenvenster niet toestaat. Optie D werkt niet zo — één ring beheert beide updatetypen.

</details>

8. Een medewerker heeft een bedrijf verlaten en zijn persoonlijke iPhone ingeleverd die gebruikt werd voor zakelijke e-mail via een MAM App Protection Policy (geen MDM-enrollment). IT wil alle zakelijke data van het apparaat verwijderen terwijl de persoonlijke foto's en apps van de medewerker intact blijven. Welke Intune-actie moet worden uitgevoerd?
   - A) Het apparaat op afstand wissen (Wipe) vanuit Intune
   - B) Het apparaat pensioneren (Retire) vanuit Intune
   - C) Het apparaat uit Intune verwijderen
   - D) Een selectieve app-wipe uitvoeren via App Protection

<details>
<summary>Antwoord</summary>

**D) Een selectieve app-wipe uitvoeren via App Protection.** Omdat het apparaat niet MDM-enrolled is, zijn de Retire- en Wipe-remote-acties niet van toepassing (ze vereisen MDM-enrollment). Een selectieve app-wipe (beschikbaar voor MAM-beveiligde apps) verwijdert alleen de zakelijke data in de beheerde apps (wist bijv. het Outlook- en OneDrive-zakelijke account) terwijl persoonlijke data, foto's en apps volledig onaangeroerd blijven. Het apparaat uit Intune verwijderen (C) verwijdert de apparaatrecord maar wist geen zakelijke app-data.

</details>

9. Een bedrijf heeft 500 Windows-apparaten die momenteel worden beheerd door Configuration Manager (SCCM). De organisatie wil geleidelijk overstappen naar Intune-beheer. Ze willen ConfigMgr software-deployments en Windows Updates laten beheren, maar direct Intune-compliancerapportage inschakelen. Welke co-management-workload moet als eerste naar Intune worden verschoven?
   - A) Windows Update-policies
   - B) Office Click-to-Run apps
   - C) Compliance policies
   - D) Endpoint Protection

<details>
<summary>Antwoord</summary>

**C) Compliance policies.** Het verschuiven van de Compliance policies-workload naar Intune is de aanbevolen eerste stap bij een co-management-migratie. Het is laagrisico (compliancerapportage verstoort het apparaatgedrag niet), levert direct waarde op (apparaten beginnen compliancestatus te rapporteren aan Intune, wat Conditional Access mogelijk maakt), en stelt het team in staat de Intune-integratie te valideren voordat workloads worden aangeraakt die direct invloed hebben op software-levering of beveiliging. Windows Update-policies (A), Office-apps (B) en Endpoint Protection (D) hebben een grotere operationele impact als ze tijdens de overgang verkeerd worden geconfigureerd.

</details>

---

### Examendekking en verplichte labs

Doel: dit blok dicht de laatste gaten tussen het leerpad en de actuele exam-scope per 23 januari 2026.

### Nog expliciet af te dekken

1. **Niet-Windows deviceprofielen (iOS, Android, macOS):** het examen toetst actief het aanmaken van configuration profiles voor alle platforms. Zorg dat je de profieltypen per platform kent: iOS/iPadOS → Templates (Device restrictions, VPN, Wi-Fi, SCEP-certificaten); macOS → Templates + Settings Catalog; Android Enterprise → meerdere enrollment-modi (Fully managed, Dedicated, Corporate-owned work profile, Personally-owned work profile) met elk eigen profieltypen.

2. **Bulk enrollment en platformspecifieke enrollment-profielen:** provisioning packages (PPKG via Windows Configuration Designer) voor Windows; Apple ADE (Automated Device Enrollment, voorheen DEP) via Apple Business Manager voor iOS; Android zero-touch enrollment voor Android Enterprise fully managed. Weet welke methode vereist is voor welk scenario.

3. **Delivery Optimization en update-monitoring op detailniveau:** Delivery Optimization verdeelt Windows Update-bandbreedte via P2P — geconfigureerd via Intune Settings Catalog. Monitoring via Intune → Devices → Monitor → Windows Update rings report: Last scan time, update state, error codes per apparaat.

4. **Intune Suite-onderdelen die nog niet live getest zijn:** Remote Help (audit-logging, RBAC-rol toewijzen), Microsoft Tunnel for MAM (verschil met reguliere Microsoft Tunnel — enrolled vs. niet-enrolled), Cloud PKI (architectuurverschil met ADCS+NDES). Begrijp de architectuur ook als je de componenten niet live kunt testen.

5. **Security Baselines versus Configuration Profiles:** een security baseline is een vooraf geconfigureerde bundel Microsoft-aanbevelingen (onneembaar als geheel); een configuration profile geeft volledige controle over individuele instellingen. Conflicten tussen een baseline en een profiel worden als "Error" gerapporteerd — de instelling wordt niet toegepast.

6. **App supersedence en de Enterprise App Catalog:** weet hoe app-vervanging (supersedence) werkt in Intune en wat de Enterprise App Catalog toevoegt boven handmatig verpakken (automatische updates, voorgeconfigureerde detectie/install/uninstall-commando's).

### Verplichte labs voor slaagkans

1. Maak minimaal 1 Android enrollment-profiel (Fully managed) aan en documenteer welke instellingen exam-relevant zijn (camera block, copy-paste tussen werk/privé, update behavior).
2. Maak minimaal 1 iOS of macOS configuratieprofiel aan met een filter (bijv. alleen iOS 16+) — oefen hoe filters anders evalueren dan dynamische groepen.
3. Configureer een update ring én een feature update policy naast elkaar en leg schriftelijk vast: wat doet elk, wanneer gebruik je welke, en hoe verifieer je de toestand via register (`HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate`).
4. Voer minimaal drie verschillende KQL device queries uit (InstalledApplications, SystemInfo, LocalUsers) en neem de resultaten op in je samenvatting — vereist Advanced Analytics licentie.
5. Draai 5 volledige scenario-rondes end-to-end: enrollment → compliance policy aanmaken → Conditional Access blokkade simuleren → app deployen (Required) → remote action uitvoeren (Sync of Retire). Documenteer elk scenario.
6. Bouw een Intune Remediation (Proactive Remediation) met een detectie- en herstelscript en verifieer de uitvoering via het Device status rapport in Intune.
7. Configureer Windows LAPS via Intune (backup naar Entra ID), forceer een wachtwoordrotatie en verifieer het nieuwe wachtwoord via de portal en via PowerShell (Microsoft Graph).

### Exit criteria voordat je examen plant

1. Je kunt alle vier exam-domeinen met eigen lab-voorbeelden uitleggen — niet alleen uit het hoofd, maar aan de hand van wat je zelf geconfigureerd hebt.
2. Je hebt per domein minimaal 2 hands-on labs zelf uitgevoerd en de resultaten gedocumenteerd.
3. Je scoort stabiel boven 75% op de officiële MS Learn practice assessment en kunt elk foutantwoord inhoudelijk verklaren (niet: "ik wist het niet"; wel: "ik dacht X maar het is Y omdat...").
4. Je kunt de veelgemaakte examenvalkuilen benoemen zonder te spieken: Self-Deploying vereist geen gebruiker, MAM-WE werkt zonder enrollment, compliance policy blokkeert niet direct (grace period), Security Baseline overschrijft geen config profiles bij conflict (rapporteert Error), Tenant Attach ≠ Co-management.

---

## Week 7 — Examenvoorbereiding

### Activiteiten
- Herhaal zwakke domeinen op basis van het [officiële examenstudiegids](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/md-102)
- Doe de **Microsoft Learn oefenassessment** MD-102: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Herhaal lab-taken die je minder zeker voelde (week 2 Intune enrollment, week 5 Autopilot)
- Maak een samenvatting van alle PowerShell-commando's uit de lab-oefeningen
- Plan je examen via Pearson VUE of Certiport

### Aandachtspunten voor het examen
- **Infrastructuur voorbereiden (25–30%):** Entra join-types, enrollment-methoden, compliance policies, Conditional Access, Windows LAPS
- **Devices beheren & onderhouden (30–35%):** Autopilot deployment modes, configuratieprofielen, Windows 365 vs AVD, KQL device queries, Intune Suite add-ons (EPM, Remote Help, Tunnel for MAM)
- **Applicaties beheren (15–20%):** Win32/LOB/Store/M365 Apps, app protection policies, ODT/OCT, Enterprise App Catalog
- **Devices beveiligen (15–20%):** Security baselines, Defender for Endpoint onboarding, update rings vs feature update policies
