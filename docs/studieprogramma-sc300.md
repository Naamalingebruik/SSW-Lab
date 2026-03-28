# Studieprogramma SC-300 — Identity and Access Administrator

> 🌐 **Taal:** Nederlands | [English](study-guide-sc300.md)

**Duur:** 7 weken · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02)
**MS Learn pad:** [Identity and Access Administrator](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-300)
**Examengewicht (bijgewerkt november 2025):**

| Domein | Gewicht |
|---|---|
| Gebruikersidentiteiten implementeren en beheren | 20–25% |
| Authenticatie en toegangsbeheer implementeren | 25–30% |
| Workload-identiteiten plannen en implementeren | 20–25% |
| Identity governance plannen en automatiseren | 20–25% |

> **Bijgewerkt:** Skills gemeten per 7 november 2025. Domeinen hernoemd en opnieuw gewogen. „Implement access management for Azure resources by using Azure roles" is **verwijderd** uit het examen. **Global Secure Access** is toegevoegd als nieuw onderdeel.

> **Voorwaarde:** Microsoft 365 E5 developer tenant + Azure subscription (MSDN)
> SC-300 heeft meer Azure-portal werkzaamheden dan MD-102/MS-102
> **Tenantnotitie:** gebruik de lokale VM's voor hybride identiteit en de gedeelde dev-tenant voor Entra-, governance- en portalwerk. Zodra een oefening tenantbeleid of Entra-portalstappen noemt, hoort die in de tenant thuis.

> **Nieuw per november 2025:** *Implement Global Secure Access* is toegevoegd aan het examen (vervangt deels de Azure RBAC voor resources scope). SSW-Lab-scripts dekken dit onderdeel nog niet — raadpleeg de [MS Learn module](https://learn.microsoft.com/en-us/training/modules/deploy-configure-microsoft-entra-global-secure-access/) als zelfstandige voorbereiding.

## Zo gebruik je dit studieprogramma

- Lees per week eerst de examendomeinen en leerdoelen; SC-300 draait sterk om keuzes maken tussen vergelijkbare identiteitsopties.
- Voer daarna de lab-oefeningen uit in Entra, Azure en waar nodig op de on-premises VM's zodat je hybride gedrag echt ziet gebeuren.
- Maak de kennischeck pas na theorie en lab, en let vooral op waarom een andere optie onjuist is.
- Werk je met tweetalige collega's, houd de Microsoft-termen bewust in beide talen bij, zoals *guest user / gastgebruiker* en *workload identity / workload-identiteit*.

## Labdekking en verwachtingen

- **Sterke dekking in SSW-Lab:** hybride identiteit, Entra Connect, PHS/PTA, SSPR, Conditional Access, PIM, app-registraties, service principals en identity governance-basics.
- **Gedeeltelijke dekking:** lifecycle workflows, access reviews op grotere schaal, workload identities in complexe applicatieketens en sommige risicosignalen hangen af van tenantlicenties en testdata.
- **Nog apart bestuderen:** Global Secure Access, enkele nieuwste Entra-portalonderdelen en scenario's waarvoor een tweede tenant of productieachtige partnertrust nodig is.
- Gebruik de labstappen om begrip op te bouwen, maar toets jezelf bij elk onderwerp ook op ontwerpkeuzes: wanneer kies je welke identiteit, policy of governance-aanpak?

## Werkwijze voor kennischecks

- Beantwoord eerst welk ontwerp je zou kiezen en daarna pas hoe je het technisch uitvoert.
- Benoem bij elke vraag expliciet welk risico wordt verkleind of welk governanceprobleem wordt opgelost.
- Herhaal fout beantwoorde vragen met focus op terminologie: in SC-300 lijken veel opties op elkaar, maar de randvoorwaarden verschillen.
- Besteed extra aandacht aan guest access, Conditional Access, workload identities en governance, omdat daar veel scenario-vragen uit ontstaan.

---

## Week 1 — Entra ID fundamenten en hybride identiteit
> **Examendomein:** Gebruikersidentiteiten implementeren en beheren · **Gewicht:** 20–25%

> **Praktijkscenario:** Een middelgroot productiebedrijf met 800 on-premises Active Directory-gebruikers migreert naar Microsoft 365. Volgens het securitybeleid mogen wachtwoordhashes niet in de cloud worden opgeslagen. Tegelijk moet SSPR beschikbaar zijn zodat medewerkers hun wachtwoord vanaf het inlogscherm kunnen resetten zonder tussenkomst van de helpdesk. Jij moet de juiste hybride authenticatiemethode kiezen en het selfservice-herstelproces betrouwbaar inrichten.

### Leerdoelen
- [ ] De drie hybride authenticatiemethoden (PHS, PTA, ADFS) benoemen en het juiste scenario voor elk kiezen
- [ ] Entra Connect Sync installeren en Password Hash Synchronization configureren
- [ ] Een handmatige sync-cyclus starten met `Start-ADSyncSyncCycle` en de resultaten interpreteren
- [ ] Seamless SSO uitleggen en de rol van het AZUREADSSOACC-computeraccount beschrijven
- [ ] Password Writeback inschakelen en de relatie met SSPR verklaren
- [ ] Entra ID Audit logs filteren op relevante events zoals gebruikers-aanmaak en rolwijzigingen

### MS Learn modules
- [Implement initial configuration of Microsoft Entra ID](https://learn.microsoft.com/en-us/training/modules/implement-initial-configuration-azure-active-directory/)
- [Create, configure, and manage identities](https://learn.microsoft.com/en-us/training/modules/create-configure-manage-identities/)
- [Implement and manage hybrid identity](https://learn.microsoft.com/en-us/training/modules/implement-manage-hybrid-identity/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Entra Connect Sync | On-premises synchronisatieagent die Active Directory-objecten synchroniseert naar Entra ID |
| Password Hash Sync (PHS) | Gesynchroniseerde wachtwoordhashes in Entra ID — authenticatie vindt in de cloud plaats; werkt ook als on-prem AD offline is |
| Pass-through Authentication (PTA) | Authenticatie wordt via een lokale agent doorgestuurd naar on-prem AD; wachtwoordhash wordt nooit opgeslagen in de cloud |
| Seamless SSO | Automatische inlog voor domain-joined apparaten via Kerberos zonder wachtwoordinvoer; vereist het computeraccount AZUREADSSOACC in AD |
| Password Writeback | Wachtwoordwijzigingen in de cloud worden teruggeschreven naar on-prem AD; vereist voor SSPR in hybride omgevingen |
| Staging mode | Entra Connect staat in passieve modus — berekent sync-wijzigingen maar past ze niet toe; handig voor failover-configuratie |
| Soft delete | Verwijderde gebruiker blijft 30 dagen herstelbaar in de prullenbak van Entra ID |
| Hard delete | Permanente verwijdering; account is niet meer te herstellen |
| Delta sync | Synchronisatiecyclus die alleen gewijzigde objecten verwerkt (snel); tegenoverstelling van Initial (full) sync |
| Entra Connect Health | Monitoringservice die de gezondheid en prestaties van de synchronisatieinfrastructuur bewaakt |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-DC01** | Verifieer AD-structuur: `Get-ADForest`, `Get-ADDomain`, `Get-ADUser -Filter *` |
| **LAB-DC01** | Installeer Azure AD Connect Sync → configureer *Password Hash Sync* |
| **LAB-DC01** | Controleer sync: `Start-ADSyncSyncCycle -PolicyType Delta` |
| **LAB-MGMT01** | Open **Entra admin center** (entra.microsoft.com) → verifieer sync-status |
| **LAB-MGMT01** | Configureer *Custom Security Attributes* voor gebruikersclassificatie |
| **LAB-MGMT01** | Bekijk *Audit logs* in Entra ID → filter op gebruikers-aanmaak events |

### Labcommando's

```powershell
# Start een delta-synccyclus vanaf de AD Connect-server
Start-ADSyncSyncCycle -PolicyType Delta

# Bekijk de status van de syncconnector
Get-ADSyncConnector | Select-Object Name, ConnectorTypeName, LastSyncTime

# Herstel een soft-deleted gebruiker via Microsoft Graph PowerShell
Restore-MgDirectoryDeletedItem -DirectoryObjectId "<object-id>"

# Forceer een volledige synccyclus (spaarzaam gebruiken)
Start-ADSyncSyncCycle -PolicyType Initial
```

### Kennischeck
1. Wat zijn de drie authenticatiemethoden bij hybride identiteit en wanneer gebruik je welke?
2. Hoe werkt *Seamless SSO* en welke Kerberos-component is betrokken?
3. Wat is het verschil tussen *soft delete* en *hard delete* van een Entra ID-gebruiker?
4. Hoe configureer je *password writeback* en waarom is het nodig voor SSPR?

<details>
<summary>Antwoorden</summary>

1. **Password Hash Sync (PHS):** wachtwoordhashes worden gesynchroniseerd naar Entra ID. Authenticatie vindt in de cloud plaats. Aanbevolen door Microsoft als meest robuust — werkt ook als on-prem AD tijdelijk onbereikbaar is. **Pass-through Authentication (PTA):** authenticatie wordt via een lokale PTA-agent doorgezet naar on-prem AD. Wachtwoordhash wordt nooit in de cloud opgeslagen. Faalt als de PTA-agent offline is. **ADFS (Active Directory Federation Services):** authenticatie verloopt volledig via een on-prem ADFS-farm. Meest complex, hoogste beschikbaarheidseisen, afgeraden voor nieuwe deployments. Gebruik PHS tenzij je een harde regulatory eis hebt om hashes nooit in de cloud te zetten.

2. Seamless SSO werkt via Kerberos-delegatie. Bij installatie van Entra Connect wordt het computeraccount **AZUREADSSOACC** aangemaakt in on-prem AD. Domain-joined Windows-apparaten vragen bij inlog automatisch een Kerberos-serviceticket aan voor dit account. Entra ID valideert dit ticket en logt de gebruiker in zonder wachtwoordinvoer. De gebruiker ervaart dit als automatische inlog op Office 365/Microsoft 365.

3. **Soft delete:** een verwijderde gebruiker belandt 30 dagen lang in de Entra ID-prullenbak (Deleted users). In die periode is volledig herstel mogelijk via de portal of PowerShell (`Restore-MgDirectoryDeletedItem`). Na 30 dagen wordt de gebruiker automatisch hard deleted. **Hard delete:** de gebruiker wordt permanent verwijderd en kan niet meer worden hersteld. Licenties worden direct vrijgegeven. Is ook het resultaat van handmatig "Permanently delete" kiezen in de portal vóór de 30-daagse termijn verstrijkt.

4. Password Writeback inschakelen: in Entra Connect wizard → optionele functies → **Password writeback** aanvinken. Ook vereist: de gebruikersaccounts moeten de Entra Connect sync-scope hebben. Waarom nodig voor SSPR: SSPR laat gebruikers hun wachtwoord resetten via de cloud (aka.ms/sspr). Zonder writeback wordt het wachtwoord alleen in Entra ID bijgewerkt — het on-prem AD-wachtwoord blijft ongewijzigd. Met writeback worden de reset en het on-prem AD-wachtwoord gesynchroniseerd, zodat de gebruiker ook op domain-joined apparaten en VPN met het nieuwe wachtwoord kan inloggen.

</details>

---

## Week 2 — Externe identiteiten en Entra B2B
> **Examendomein:** Gebruikersidentiteiten implementeren en beheren · **Gewicht:** 20–25%

> **Praktijkscenario:** Een Sogeti-consultant helpt een financiële klant drie strategische partners toegang te geven tot een gedeelde SharePoint-site en Teams-werkruimte. De securityafdeling eist dat partnergebruikers hun eigen bedrijfsidentiteit gebruiken, dat MFA-claims van een vertrouwde partner-tenant worden geaccepteerd zonder dubbele prompts, en dat accounts met hoog risico direct worden geblokkeerd. Jij ontwerpt B2B-toegang, cross-tenant trust en Identity Protection-beleid dat dit afdwingt.

### Leerdoelen
- [ ] Het verschil tussen B2B Collaboration en B2B Direct Connect uitleggen en het juiste scenario kiezen
- [ ] Cross-tenant access settings configureren: inbound en outbound vertrouwen instellen per partner-tenant
- [ ] Entra ID Protection inschakelen en de risicodetectie-dashboard interpreteren
- [ ] Een User risk policy en Sign-in risk policy aanmaken en testen
- [ ] Risky users en risky sign-ins handmatig remediëren (dismiss, confirm compromise, wachtwoordreset)
- [ ] Identity Protection-signalen verbinden aan het bredere Zero Trust-framework

### MS Learn modules
- [Implement and manage external identities](https://learn.microsoft.com/en-us/training/modules/implement-manage-external-identities/)
- [Implement and manage Microsoft Entra ID Protection](https://learn.microsoft.com/en-us/training/modules/implement-manage-azure-ad-identity-protection/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| B2B Collaboration | Externe gebruikers uitnodigen als gastgebruikers; zij krijgen een guest-object in jouw tenant en authenticeren bij hun eigen tenant of via OTP |
| B2B Direct Connect | Directe vertrouwensrelatie tussen twee tenants zonder guest-objecten; de externe gebruiker verschijnt niet in jouw directory (momenteel primair voor Teams shared channels) |
| Cross-tenant access settings | Beleid waarmee je per externe tenant instelt wat je inbound (wat externen bij jou mogen) en outbound (wat jouw gebruikers bij externen mogen) toestaat |
| Inbound trust | Vertrouwen van MFA-claims of compliant-device-claims van een partner-tenant — voorkomt dubbele MFA-challenges |
| One-time passcode (OTP) | Fallback-authenticatie via e-mailcode voor gasten zonder Azure AD-, Microsoft- of Google-account |
| Sign-in risk | Per inlogpoging berekende kans dat die poging niet door de legitieme gebruiker is gedaan (bijv. anoniem IP, onmogelijk reizen) |
| User risk | Cumulatieve inschatting dat een account gecompromitteerd is (bijv. gelekte credentials op het dark web) |
| Atypical travel | Risicodetectie: inlogpogingen vanuit twee geografisch ver uiteen gelegen locaties in een onmogelijk korte tijd |
| Dismiss risk | Beheerder markeert een risico als vals-positief; risicoscore wordt gecleard |
| Confirm compromise | Beheerder bevestigt dat het account echt gecompromitteerd is; triggert verdere acties zoals accountblokkering |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-MGMT01** | Nodig een externe B2B-gebruiker uit (gebruik een persoonlijk of second tenant-account) |
| **LAB-MGMT01** | Configureer *Cross-tenant access settings*: blokkeer inbound access voor specifieke tenants |
| **LAB-MGMT01** | Schakel *Entra ID Protection* in → bekijk *Risk detections* dashboard |
| **LAB-MGMT01** | Configureer *User risk policy*: hoog risico → wachtwoordwijziging verplicht |
| **LAB-MGMT01** | Configureer *Sign-in risk policy*: medium risico → MFA verplicht |
| **LAB-W11-01** | Simuleer risky sign-in: log in met TestUser01 vanuit anonieme browser-sessie |

### Labcommando's

```powershell
# Nodig een B2B-gastgebruiker uit via Microsoft Graph PowerShell
New-MgInvitation -InvitedUserEmailAddress "partner@contoso.com" `
    -InviteRedirectUrl "https://myapps.microsoft.com" `
    -SendInvitationMessage:$true

# Toon alle gastgebruikers in de tenant
Get-MgUser -Filter "userType eq 'Guest'" | Select-Object DisplayName, Mail, UserPrincipalName

# Verwerp een user risk (markeer als false positive)
Invoke-MgDismissRiskyUser -UserIds "<user-object-id>"

# Bevestig accountcompromittering (start aanvullende beschermingsacties)
Invoke-MgConfirmRiskyUserCompromised -UserIds "<user-object-id>"
```

### Kennischeck
1. Wat is het verschil tussen *B2B direct connect* en *B2B collaboration*?
2. Hoe werkt *Identity Protection* — welke signalen gebruikt het voor risicoscores?
3. Wat is een *risky user* versus een *risky sign-in*? Hoe remedieer je elk?
4. Wat doet een *Conditional Access policy op basis van user risk*?

<details>
<summary>Antwoorden</summary>

1. **B2B Collaboration:** de externe gebruiker krijgt een gastaccount (guest object) in jouw Entra ID-tenant. Zichtbaar in jouw directory, kan worden toegewezen aan groepen en apps. Authenticatie vindt plaats bij de eigen tenant van de gast of via one-time passcode. **B2B Direct Connect:** er wordt geen gastobject aangemaakt in jouw tenant. Externe gebruikers kunnen via een directe vertrouwensrelatie bepaalde resources benaderen. Momenteel beperkt tot Microsoft Teams shared channels. Meer privacy voor de externe partij, maar minder controle-mogelijkheden voor jou.

2. Identity Protection gebruikt machine learning-modellen van Microsoft die zijn getraind op miljarden inlogpogingen per dag. Signalen die worden gebruikt voor risicoscores: anonieme IP-adressen (Tor, VPN), onmogelijk reizen (twee inlogpogingen vanuit ver uiteen gelegen locaties in korte tijd), gelekte credentials (Microsoft scant dark web en breach-databases), malware-gekoppelde IP-adressen, onbekend aanmeldingsgedrag (afwijkend van de normale patronen van die gebruiker), verdachte inbox-manipulatie, mass access to sensitive files.

3. **Risky sign-in:** een specifieke inlogpoging heeft een verhoogd risiconiveau. Remediatie: de gebruiker wordt gevraagd MFA te voltooien (bij medium risico) of de inlogpoging wordt geblokkeerd (bij hoog risico via CA policy). Na succesvolle MFA wordt het sign-in risico gecleard. **Risky user:** het account zelf is mogelijk gecompromitteerd (bijv. wachtwoord gevonden in dark web breach). Remediatie: de gebruiker moet een beveiligde wachtwoordwijziging uitvoeren via SSPR (met MFA). Dit cleared het user risk. Een beheerder kan ook handmatig dismissal of confirm compromise uitvoeren via de portal.

4. Een CA policy op basis van user risk controleert de cumulatieve risicoscore van het account bij elke inlogpoging. Bij een ingesteld drempel (bijv. High) wordt een aanvullende actie afgedwongen als Grant control. Typisch: "Require password change" — de gebruiker moet via SSPR een nieuw wachtwoord instellen met een sterke MFA-verificatie. Na de geslaagde wachtwoordwijziging wordt het user risk automatisch gereset naar None. Dit is essentieel voor geautomatiseerde incidentrespons zonder handmatig beheerdersingrijpen.

</details>

---

## Week 3 — Authenticatiemethoden en MFA
> **Examendomein:** Authenticatie en toegangsbeheer implementeren · **Gewicht:** 25–30%

> **Praktijkscenario:** Een overheidsorganisatie wil phishing-resistente MFA voor 2.500 medewerkers als onderdeel van een Zero Trust-programma. De helpdesk verwerkt wekelijks tientallen wachtwoordresetverzoeken. Jij moet een strategie ontwerpen waarin FIDO2-sleutels voor bevoorrechte gebruikers, Microsoft Authenticator met passkeys voor reguliere medewerkers en Temporary Access Pass voor onboarding en herstel logisch samenkomen in een modern beleid.

### Leerdoelen
- [ ] Het Authentication methods-beleid configureren en de migratie van legacy per-user MFA uitleggen
- [ ] FIDO2, Microsoft Authenticator passwordless en passkeys vergelijken op beveiligingsniveau
- [ ] Een Temporary Access Pass (TAP) aanmaken en de juiste gebruiksscenario's benoemen
- [ ] Windows Hello for Business in een hybride omgeving implementeren en de vereisten beschrijven
- [ ] Authentication Strength beleidsregels aanmaken en koppelen aan een Conditional Access policy
- [ ] Phishing-resistant MFA-methoden identificeren en onderscheiden van niet-phishing-resistente methoden

### MS Learn modules
- [Plan and implement multifactor authentication](https://learn.microsoft.com/en-us/training/modules/plan-implement-administer-multi-factor-authentication/)
- [Implement passwordless authentication](https://learn.microsoft.com/en-us/training/modules/implement-authentication-by-using-microsoft-entra-id/)
- [Manage user authentication](https://learn.microsoft.com/en-us/training/modules/manage-user-authentication/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| FIDO2 | Passwordless hardwaresleutel (bijv. YubiKey, Feitian) — phishing-resistent omdat de sleutel gebonden is aan een specifiek domein; sterkste beschikbare methode |
| Microsoft Authenticator passwordless | Aanmelding via push-notificatie met number matching op de telefoon; geen wachtwoord vereist; phishing-resistent via number matching |
| Passkey | FIDO2-gebaseerde inlogmethode opgeslagen in de Microsoft Authenticator app — combineert gemak van app met FIDO2-sterkte |
| Temporary Access Pass (TAP) | Tijdelijke toegangscode (eenmalig of meerdere keren) voor onboarding, herstel na verlies van MFA-methode, of tijdelijke toegang |
| Authentication Strength | Beleid dat specifieke authenticatiecombinaties vereist (bijv. phishing-resistant MFA); wordt als Grant control gebruikt in Conditional Access |
| Legacy per-user MFA | Verouderd MFA-systeem per gebruiker via de MFA-portal (account.activedirectory.windowsazure.com); moet worden gemigreerd naar Authentication methods policy |
| SSPR | Self-Service Password Reset — gebruikers resetten hun eigen wachtwoord via aka.ms/sspr zonder IT-tussenkomst |
| Combined registration | Gecombineerde registratie van MFA-methoden en SSPR in één workflow via aka.ms/mysecurityinfo |
| Certificate-based authentication (CBA) | Authenticatie met een X.509-certificaat als primaire methode; phishing-resistent; vereist PKI-infrastructuur |
| Password Protection | Blokkeert zwakke en organisatiespecifieke wachtwoorden via een global en custom banned password list |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-MGMT01** | Open **Entra → Security → Authentication methods** → activeer FIDO2 en Authenticator |
| **LAB-W11-01** | Registreer *Microsoft Authenticator* als MFA-methode voor TestUser01 |
| **LAB-W11-01** | Registreer *Windows Hello for Business* op W11-01 |
| **LAB-MGMT01** | Configureer *Authentication strength* in Conditional Access: Phishing-resistant MFA |
| **LAB-MGMT01** | Bekijk *Authentication methods activity* report → analyseer methode-gebruik |
| **LAB-MGMT01** | Schakel *legacy per-user MFA* uit → migreer naar Conditional Access-based MFA |

### Labcommando's

```powershell
# Maak een Temporary Access Pass aan voor een gebruiker
New-MgUserAuthenticationTemporaryAccessPassMethod -UserId "<user-id>" `
    -LifetimeInMinutes 60 -IsUsableOnce:$true

# Toon geregistreerde authenticatiemethoden voor een gebruiker
Get-MgUserAuthenticationMethod -UserId "<user-id>"

# Verwijder een specifieke authenticatiemethode (bijv. een verloren FIDO2-sleutel)
Remove-MgUserAuthenticationFido2Method -UserId "<user-id>" `
    -Fido2AuthenticationMethodId "<method-id>"

# Rapporteer over registraties van authenticatiemethoden in de tenant
Get-MgReportAuthenticationMethodUserRegistrationDetail |
    Select-Object UserPrincipalName, IsMfaRegistered, IsPasswordlessCapable
```

### Kennischeck
1. Wat is *phishing-resistant MFA* en welke methoden vallen hieronder?
2. Hoe werkt *Windows Hello for Business* in hybride omgeving?
3. Wat is het verschil tussen *Authentication methods policy* en *legacy MFA-instellingen*?
4. Wanneer gebruik je *Temporary Access Pass (TAP)*?

<details>
<summary>Antwoorden</summary>

1. Phishing-resistant MFA zijn methoden waarbij de authenticatie cryptografisch gebonden is aan het specifieke domein of de specifieke app, zodat een aanvaller die een gebruiker naar een nepsite lokt geen bruikbare tokens kan onderscheppen. Methoden die hieronder vallen: **FIDO2 security keys** (hardware-gebonden, domeingekoppeld), **Windows Hello for Business** (device-gebonden biometrie/PIN met TPM-beschermde sleutels), **Microsoft Authenticator met passkeys** (FIDO2 in de app), en **Certificate-based authentication**. Methoden die NIET phishing-resistent zijn: TOTP (6-cijferige codes via apps of SMS), spraakoproepen, SMS-codes — deze kunnen worden onderschept of doorgestuurd door een aanvaller via een man-in-the-middle-aanval.

2. Windows Hello for Business (WHfB) in hybride omgevingen werkt als volgt: de gebruiker registreert een PIN of biometrisch gegeven op het apparaat. De privésleutel wordt beschermd door de TPM-chip van het apparaat en verlaat het apparaat nooit. In de hybride variant worden Kerberos-tickets aangevraagd voor toegang tot on-prem resources — hiervoor is **Entra Kerberos** vereist (inschakelen via Entra Connect of PowerShell). Vereisten: Azure AD-joined of Hybrid Azure AD-joined apparaat, TPM 2.0 aanbevolen, Entra Connect Sync actief, voor on-prem Kerberos: Entra Kerberos Server-object aangemaakt in AD.

3. **Authentication methods policy** (nieuwe methode): centraal geconfigureerd in Entra ID → Protection → Authentication methods → Policies. Beheert welke methoden beschikbaar zijn per gebruikersgroep. Inclusief FIDO2, Authenticator, TAP, certificaten, passkeys. Is tenant-breed of per groep. **Legacy per-user MFA** (verouderd): configureerbaar via de afzonderlijke MFA-beheerportal. Instelling per individuele gebruiker (Enabled, Enforced, Disabled). Bevat ook service settings voor allowed methods. Microsoft raadt aan om te migreren naar de Authentication methods policy en legacy MFA uit te schakelen. Na migratie zijn alle MFA-instellingen centraal in één policy beheerd.

4. TAP gebruik je in drie scenario's: **(1) Initiële onboarding:** een nieuwe medewerker heeft nog geen MFA-methode geregistreerd. De beheerder maakt een TAP aan en de gebruiker gebruikt deze om in te loggen en vervolgens zijn permanente MFA-methoden te registreren op aka.ms/mysecurityinfo. **(2) Accountherstel:** een gebruiker heeft toegang tot zijn MFA-methoden verloren (verloren telefoon, vergeten FIDO2-sleutel). De beheerder genereert een TAP die de gebruiker kan gebruiken voor eenmalig inloggen en het opnieuw registreren van methoden. **(3) Tijdelijke toegang:** voor een externe medewerker of tijdelijk scenario waarbij snel toegang nodig is. TAP kan worden ingesteld als eenmalig (isUsableOnce) of met een tijdsvenster.

</details>

---

## Week 4 — Conditional Access en Global Secure Access
> **Examendomein:** Authenticatie en toegangsbeheer implementeren · **Gewicht:** 25–30%

> **Praktijkscenario:** Een advocatenkantoor met 350 gebruikers en veel thuiswerkers wil afdwingen dat alleen beheerde of compliant apparaten bij SharePoint en Teams kunnen, dat toegang van buiten de EU step-up authenticatie vereist en dat het uitschakelen van een Conditional Access-policy altijd een extra goedkeuring nodig heeft. Tegelijk onderzoekt men de overstap van klassieke VPN naar zero-trust toegang per applicatie. Jij vertaalt deze eisen naar Conditional Access, protected actions en Global Secure Access-keuzes.

### Leerdoelen
- [ ] Een Conditional Access-policy aanmaken met signals, conditions en grant/session controls
- [ ] De What If-tool gebruiken om CA-beleid te simuleren en te troubleshooten
- [ ] Named Locations en compliant network definiëren en gebruiken in CA-policies
- [ ] Authentication contexts en Protected Actions configureren voor step-up authenticatie
- [ ] Continuous Access Evaluation (CAE) uitleggen en onderscheiden van standaard tokenlevensduur
- [ ] Global Secure Access uitleggen: de drie verkeersprofielen (Private Access, Internet Access, M365 Access) beschrijven
- [ ] Het verschil tussen Private Access en traditionele VPN verklaren in termen van Zero Trust

### MS Learn modules
- [Plan, implement, and administer Conditional Access](https://learn.microsoft.com/en-us/training/modules/plan-implement-administer-conditional-access/)
- [Implement Conditional Access for cloud app access](https://learn.microsoft.com/en-us/training/modules/implement-conditional-access-cloud-app-protection/)
- [Implement Global Secure Access](https://learn.microsoft.com/en-us/training/modules/implement-global-secure-access/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| CA Signals | De invoerparameters voor de CA-beleidsengine: gebruiker/groep/rol, applicatie, locatie, apparaatcompliance, sign-in risico, user risico |
| Grant control | CA-uitkomst die toegang verleent of weigert, eventueel met voorwaarden: MFA vereisen, compliant device, hybride join, of Block |
| Session control | CA-uitkomst die een bestaande sessie beperkt: sign-in frequency, persistent browser session, app-enforced restrictions, CASB-integratie |
| Named Location | IP-ranges of landen gemarkeerd als vertrouwd of te blokkeren; gebruikt als CA-signal voor locatiegebaseerde beslissingen |
| Compliant network | Verkeerslocatie die via Global Secure Access verloopt en daarmee als vertrouwd netwerk wordt beschouwd in CA |
| Continuous Access Evaluation (CAE) | Real-time intrekking van tokens binnen seconden bij risicogebeurtenissen (bijv. wachtwoordwijziging, locatieverandering, account uitgeschakeld) in plaats van wachten op tokenexpiry |
| Authentication context | Een tag die aan een CA-policy wordt gekoppeld en vervolgens door een app wordt aangevraagd bij een risicovolle actie (step-up authenticatie) |
| Protected Actions | Hoog-privilege Entra-operaties (bijv. CA-policy uitschakelen, PIM-instellingen wijzigen) die altijd extra CA-verificatie vereisen |
| Global Secure Access (GSA) | Microsoft's Security Service Edge-platform — combineert Zero Trust Network Access (ZTNA) en Secure Web Gateway (SWG) |
| Private Access | GSA-component die zero trust-toegang biedt tot on-premises en private apps zonder traditionele VPN; toegang is per-app in plaats van per-netwerk |
| Internet Access for M365 | Geoptimaliseerde GSA-tunnel specifiek voor Microsoft 365-verkeer met beleidshandhaving en verkeerslogboeken |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-MGMT01** | Maak CA-policy: blokkeer toegang tot alle apps van buiten compliance-devices |
| **LAB-MGMT01** | Maak CA-policy: MFA verplicht voor beheerderrollen bij elke sign-in |
| **LAB-MGMT01** | Gebruik *What If* tool in CA om access-beslissingen te simuleren |
| **LAB-W11-01** | Test CA-policy als TestUser01 → verifieer welke controls worden afgedwongen |
| **LAB-W11-02** | Test met niet-enrolled device → verifieer blokkering |
| **LAB-MGMT01** | Schakel *Sign-in frequency* in voor gevoelige applicaties (elke 4 uur re-auth) |
| **LAB-MGMT01** | Bekijk **CA insights and reporting** workbook in Entra ID |
| **LAB-MGMT01** | Open **Global Secure Access** in het Entra admin center → verken Private Access en Internet Access-instellingen |
| **LAB-MGMT01** | Schakel *Internet Access voor Microsoft 365* in via Global Secure Access → bekijk verkeerslogboeken |

### Labcommando's

```powershell
# Toon alle Conditional Access-policies en hun status
Get-MgIdentityConditionalAccessPolicy |
    Select-Object DisplayName, State, CreatedDateTime

# Haal sign-in-logs op gefilterd op CA-policyfouten (vereist Log Analytics of MS Graph)
# Via Microsoft Graph PowerShell:
Get-MgAuditLogSignIn -Filter "conditionalAccessStatus eq 'failure'" -Top 20 |
    Select-Object UserPrincipalName, AppDisplayName, ConditionalAccessStatus

# Toon alle named locations
Get-MgIdentityConditionalAccessNamedLocation | Select-Object DisplayName, Id

# Schakel een CA-policystatus in of werk deze bij (enabled/disabled/enabledForReportingButNotEnforced)
Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId "<policy-id>" `
    -State "enabledForReportingButNotEnforced"
```

### Kennischeck
1. Wat is het verschil tussen *Block* en *Grant with MFA* in Conditional Access?
2. Hoe werkt *Named Locations* en wanneer gebruik je *compliant network*?
3. Wat zijn *Authentication contexts* en wanneer gebruik je ze?
4. Hoe voorkom je *lock-out* bij CA-migratie in productie?
5. Wat is *Global Secure Access* en wat zijn de drie verkeersprofielen (Private, Internet, M365)?
6. Wat is het verschil tussen *Private Access* en een traditionele VPN?

<details>
<summary>Antwoorden</summary>

1. **Block:** de toegang wordt volledig geweigerd — de gebruiker ziet een foutmelding en kan niet inloggen op de betreffende app, ongeacht wat ze verder doen. Er is geen mogelijkheid om door aanvullende verificatie toch toegang te krijgen. **Grant with MFA:** de toegang wordt verleend zodra de gebruiker aan de vereiste controle voldoet (MFA voltooien). Als de gebruiker MFA niet kan voltooien (bijv. geen MFA-methode geregistreerd), wordt de toegang alsnog geweigerd. Block is absoluter en harder; Grant with conditions is flexibeler en biedt de gebruiker een kans om toe te gaan.

2. **Named Locations:** je definieert IP-ranges (bijv. het kantoor-IP) of landen als "vertrouwd" of "onvertrouwd". Deze kun je gebruiken als CA-signal: toegang toestaan als de gebruiker van een vertrouwd IP komt, of juist MFA vereisen buiten die locatie. **Compliant network** is een speciale locatie die verwijst naar verkeer dat via de Global Secure Access-client verloopt. Als een gebruiker verbonden is via de GSA-client, wordt dat als een vertrouwde netwerklocatie beschouwd — dit geeft meer granulariteit dan IP-ranges en is apparaat- en identiteitsgekoppeld.

3. Authentication contexts zijn tags (bijv. `c1`, `c2`) die je aanmaakt in Entra ID en koppelt aan een CA-policy. Een applicatie kan een authentication context opvragen bij het uitvoeren van een specifieke risicovolle actie (bijv. financiële goedkeuring, toegang tot een gevoelig document in SharePoint). Entra ID evalueert dan de bijbehorende CA-policy en vereist eventueel step-up authenticatie (bijv. FIDO2 in plaats van standaard wachtwoord+SMS). Wanneer gebruiken: als je niet voor de volledige app maar voor specifieke acties binnen die app een hogere authenticatiesterkte wilt afdwingen.

4. Strategieën om lock-out te voorkomen bij CA-migratie: (1) Gebruik eerst **Report-only modus** om te zien welke gebruikers worden geraakt zonder echt te blokkeren. (2) Sluit **break-glass accounts** altijd uit van CA-policies. (3) Test met een kleine pilotgroep voordat je de policy op All users zet. (4) Implementeer beleidswijzigingen buiten kantooruren. (5) Houd een emergency-account buiten CA-scope beschikbaar voor ongedaan maken. (6) Gebruik de **What If-tool** intensief vóór activering om scenario's te simuleren.

5. Global Secure Access is Microsoft's Security Service Edge (SSE)-platform dat cloudgebaseerde netwerkbeveiliging biedt geïntegreerd met Entra ID. De drie verkeersprofielen: **Private Access** — Zero Trust-toegang tot on-premises en private apps per applicatie (vervangt VPN voor specifieke apps). **Internet Access** — Secure Web Gateway die internetverkeer filtert, categoriseert en beveiligt. **Microsoft 365 Access** — geoptimaliseerde versleutelde tunnel voor M365-services (Exchange, SharePoint, Teams) met beleidshandhaving en verkeerslogboeken.

6. **Traditionele VPN:** geeft volledige netwerktoegang zodra verbonden — de gebruiker heeft toegang tot alle resources op dat netwerksegment. Geen identiteitsgebaseerde app-granulariteit. Hoge latentie voor clouddiensten omdat verkeer via on-premises gaat. Moeilijk te combineren met least-privilege. **Private Access (GSA):** per-applicatie toegang gebaseerd op identiteit en apparaatstatus — de gebruiker krijgt toegang tot specifiek gedefinieerde apps, niet tot het volledige netwerk. Geïntegreerd met Entra CA voor beleidshandhaving. Betere performance doordat M365-verkeer direct naar de cloud gaat. Geen inkomende firewallpoorten nodig — de connector maakt een uitgaande verbinding.

</details>

---

## Week 5 — Applicatietoegang en app registraties
> **Examendomein:** Workload-identiteiten plannen en implementeren · **Gewicht:** 20–25%

> **Praktijkscenario:** Een Sogeti DevOps-team bouwt voor een bank een intern automatiseringsplatform dat via een Azure Function e-mail uit een shared mailbox leest, resultaten naar SharePoint schrijft en een interne REST-API aanroept. De securityafdeling staat geen wachtwoorden of client secrets toe: alleen managed identities en app-only toestemming met expliciete admin consent zijn toegestaan. Daarnaast moeten bestaande derdepartij-apps met te brede rechten worden opgeschoond. Jij moet workload identities, API-permissies en governance rond enterprise apps correct inrichten.

### Leerdoelen
- [ ] Het verschil tussen een App Registration en een Enterprise Application uitleggen en de relatie beschrijven
- [ ] Delegated en Application API permissions configureren en het effect van admin consent benoemen
- [ ] De OAuth 2.0 authorization code flow beschrijven in de context van Entra ID
- [ ] Een Managed Identity (system-assigned en user-assigned) aanmaken en het gebruik ervan uitleggen
- [ ] Entra Application Proxy configureren voor het publiceren van on-premises webapplicaties
- [ ] SCIM-provisioning instellen voor automatisch gebruikersbeheer in een SaaS-applicatie

### MS Learn modules
- [Manage and implement application access in Azure AD](https://learn.microsoft.com/en-us/training/modules/manage-implement-application-access/)
- [Implement app registrations](https://learn.microsoft.com/en-us/training/modules/implement-app-registrations/)
- [Integrate single sign-on in Microsoft Entra ID](https://learn.microsoft.com/en-us/training/modules/authenticate-external-apps/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| App Registration | Technische registratie van een applicatie bij Entra ID voor OAuth/OIDC; geconfigureerd door de app-ontwikkelaar (redirect URIs, secrets, scopes) |
| Enterprise Application | Serviceprincipal-instantie van een app in jouw tenant; hier beheer je wie toegang heeft, SSO-instellingen en SCIM-provisioning |
| Service Principal | Identiteitsrepresentatie van een applicatie of dienst in Entra ID; elke app registration levert automatisch een service principal op in de tenant |
| Managed Identity | Azure-resource-identiteit zonder beheerdersreferenties; het Azure-platform beheert de tokenuitgifte automatisch — geen wachtwoorden die kunnen lekken |
| System-assigned Managed Identity | Identiteit gekoppeld aan één specifieke Azure-resource; lifecycle is gelijk aan die resource (verwijderd als resource verwijderd wordt) |
| User-assigned Managed Identity | Zelfstandige identiteit die aan meerdere Azure-resources kan worden toegewezen; onafhankelijke lifecycle |
| Delegated permission | API-recht waarbij de app handelt namens een aangemelde gebruiker; de gebruiker zelf moet toestemming geven (of admin namens iedereen) |
| Application permission | API-recht waarbij de app als zichzelf handelt zonder gebruikerscontext (daemon/service); vereist altijd admin consent |
| Entra Application Proxy | Publiceert on-premises webapplicaties veilig via Entra ID zonder inkomende firewallpoorten; connector maakt uitgaande verbinding naar Azure |
| SCIM | System for Cross-domain Identity Management — open standaard voor het automatisch aanmaken, bijwerken en verwijderen van gebruikers in SaaS-applicaties |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-MGMT01** | Registreer een test-app in **Entra → App registrations** |
| **LAB-MGMT01** | Voeg *API permissions* toe: `User.Read` en `Mail.Read` → admin consent verlenen |
| **LAB-MGMT01** | Maak een *client secret* aan → noteer de waarde |
| **LAB-MGMT01** | Configureer SSO voor een gallery-app (bijv. GitHub) via *Enterprise applications* |
| **LAB-MGMT01** | Configureer *App proxy* voor een on-premises app (gebruik MGMT01 als testserver) |
| **LAB-MGMT01** | Wijs de app toe aan een groep → bekijk toegang in *My Apps* portal |

### Labcommando's

```powershell
# Toon alle app registrations in de tenant
Get-MgApplication | Select-Object DisplayName, AppId, CreatedDateTime

# Toon API-permissies voor een specifieke app registration
Get-MgApplicationRequiredResourceAccess -ApplicationId "<app-object-id>"

# Maak een nieuw client secret aan voor een app registration
Add-MgApplicationPassword -ApplicationId "<app-object-id>" `
    -PasswordCredential @{ DisplayName = "LabSecret"; EndDateTime = "2026-01-01" }

# Toon alle enterprise applications (service principals) met app-permissies
Get-MgServicePrincipal -Filter "servicePrincipalType eq 'Application'" |
    Select-Object DisplayName, AppId, AppRoles
```

### Kennischeck
1. Wat is het verschil tussen een *App registration* en een *Enterprise application*?
2. Hoe werkt OAuth 2.0 *authorization code flow* in het kort?
3. Wat is een *managed identity* en wanneer gebruik je system-assigned versus user-assigned?
4. Wat doet *application proxy* en welke ports heeft het nodig?

<details>
<summary>Antwoorden</summary>

1. **App Registration:** het object dat je aanmaakt als app-ontwikkelaar om de applicatie bij Entra ID te registreren. Bevat: client ID, redirect URIs, client secrets/certificaten, OAuth-scopes, app roles. Bestaat in de "home tenant" van de applicatie. **Enterprise Application:** de serviceprincipal-instantie die wordt aangemaakt in jouw tenant wanneer een app (via app registration of vanuit de gallery) aan jouw tenant wordt toegevoegd. Hier configureer je: welke gebruikers/groepen toegang hebben, SSO-methode (SAML/OIDC), SCIM-provisioning, app-toegangsinstellingen. Relatie: één App Registration → kan leiden tot meerdere Enterprise Applications in meerdere tenants (bij multi-tenant apps).

2. OAuth 2.0 Authorization Code Flow (vereenvoudigd): (1) Gebruiker klikt "Inloggen" in de app. (2) App stuurt de browser door naar Entra ID met een authorization request (client_id, redirect_uri, scope, state, code_challenge). (3) Gebruiker authenticeert bij Entra ID en geeft toestemming voor de gevraagde scopes. (4) Entra ID stuurt een eenmalige **authorization code** terug naar de redirect_uri. (5) De app ruilt de authorization code (server-side, niet in de browser) in voor een **access token** en refresh token via de token endpoint. (6) De app gebruikt het access token om Microsoft Graph of andere API's aan te roepen namens de gebruiker.

3. **Managed Identity:** een Azure-resource-identiteit (service principal) beheerd door het Azure-platform — geen wachtwoord of secret vereist. Het platform geeft automatisch tokens uit via de Instance Metadata Service (endpoint op 169.254.169.254). **System-assigned:** aangemaakt voor één specifieke resource (bijv. een Azure VM of Function App). Wordt automatisch verwijderd als die resource verwijderd wordt. Één-op-één relatie. Gebruik als de identiteit uitsluitend voor die ene resource bedoeld is. **User-assigned:** een zelfstandige Azure-resource die aan meerdere resources kan worden toegewezen. Lifecycle is onafhankelijk van de resources waaraan het is gekoppeld. Gebruik als meerdere resources dezelfde identiteit moeten delen of als je de identiteit wilt behouden na verwijdering van een resource.

4. Application Proxy publiceert on-premises webapplicaties veilig via Entra ID zonder dat er inkomende netwerkverbindingen nodig zijn. Architectuur: een lichtgewicht **connector** wordt on-premises geïnstalleerd (bijv. op een server in het interne netwerk). De connector maakt een uitgaande HTTPS-verbinding (poort 443) naar de Entra Application Proxy-dienst in Azure. Externe gebruikers verbinden met een extern gepubliceerde URL op msappproxy.net, authenticeren via Entra ID, en hun verzoeken worden via de connector intern doorgestuurd naar de webapplicatie. **Benodigde poorten:** uitsluitend **poort 443 uitgaand** vanuit de connector naar Azure. Geen inkomende poorten nodig in de firewall — dit is de kernkracht van de oplossing.

</details>

---

## Week 6 — Identity governance: Entitlement en Access Reviews
> **Examendomein:** Identity governance plannen en automatiseren · **Gewicht:** 20–25%

> **Praktijkscenario:** Een zorgorganisatie met 3.000 medewerkers moet identity governance professionaliseren onder strikte NEN 7510- en ISO 27001-eisen. Artsen, verpleegkundigen en stafmedewerkers hebben verschillende access packages nodig die automatisch verlopen als een project eindigt. De complianceafdeling wil kwartaalreviews voor alle bevoorrechte rollen en HR wil uitdiensttreding binnen 24 uur terugzien in toegangsintrekking. Jij ontwerpt access packages, access reviews, lifecycle-automatisering en PIM-governance met goedkeuringsflow.

### Leerdoelen
- [ ] Een Access Package aanmaken met resources, goedkeuringsworkflow en vervaldatum
- [ ] Het verschil tussen Entitlement Management en Access Reviews uitleggen
- [ ] PIM Just-in-Time access configureren voor een Entra-rol met goedkeuringsworkflow
- [ ] Eligible en Active assignments onderscheiden en het effect op de dagelijkse werkpraktijk beschrijven
- [ ] Een Access Review instellen met auto-apply resultaten en herhalingsschema
- [ ] Separation of duties configureren via incompatibele access packages
- [ ] Lifecycle Workflows uitleggen voor geautomatiseerde joiner/mover/leaver-processen

### MS Learn modules
- [Plan and implement entitlement management](https://learn.microsoft.com/en-us/training/modules/plan-implement-entitlement-management/)
- [Plan, implement, and manage access reviews](https://learn.microsoft.com/en-us/training/modules/plan-implement-manage-access-review/)
- [Implement Privileged Identity Management](https://learn.microsoft.com/en-us/training/modules/implement-privileged-identity-management/)

### Kernbegrippen
| Begrip | Uitleg |
|---------|--------|
| Entitlement Management | Governance-framework voor het gestructureerd verlenen van toegang: catalogi, access packages, aanvraagworkflows, vervaldatums |
| Catalog | Container in Entitlement Management die resources groepeert (Entra-groepen, apps, SharePoint-sites) voor gebruik in access packages |
| Access Package | Een bundel van resources die samen als eenheid kan worden aangevraagd, goedgekeurd en ingetrokken via een vastgestelde workflow |
| Access Review | Periodieke controle of huidige toegangstoewijzingen nog gerechtvaardigd zijn; resultaten kunnen automatisch worden toegepast |
| PIM (Privileged Identity Management) | Just-in-Time activering van hoog-privilege rollen; gebruikers activeren een rol wanneer nodig met tijdslimiet en rechtvaardiging |
| Eligible assignment | Gebruiker heeft recht op de rol maar moet hem actief activeren via PIM (met reden, evt. MFA en goedkeuring) |
| Active assignment | Rol is permanent actief voor de gebruiker zonder activering — gebruikt voor break-glass en service accounts |
| Lifecycle Workflow | Geautomatiseerde identiteitsprocesflow voor joiner (onboarding), mover (rolwijziging) en leaver (offboarding) scenarios |
| Separation of duties | Beleid in Entitlement Management dat voorkomt dat een gebruiker toegang heeft tot incompatibele access packages tegelijkertijd |
| Break-glass account | Noodtoegangsaccount met permanente Global Administrator-rol, uitgesloten van alle CA-policies en PIM, voor gebruik bij noodgevallen |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **LAB-MGMT01** | Maak een *Access package* aan via **Entra → Identity Governance → Entitlement management** |
| **LAB-MGMT01** | Configureer *policy*: gebruikers kunnen zelf toegang aanvragen, manager moet goedkeuren |
| **LAB-W11-01** | Vraag het Access package aan als TestUser01 via *My Access* portal (`myaccess.microsoft.com`) |
| **LAB-MGMT01** | Keur de aanvraag goed → verifieer toewijzing |
| **LAB-MGMT01** | Maak een *Access review* aan voor een groep → wijs reviewer aan |
| **LAB-MGMT01** | Activeer **Privileged Identity Management (PIM)** voor de rol *Global Administrator* |
| **LAB-MGMT01** | Activeer de GA-rol *Just-in-time* via PIM → verifieer audit trail |

### Labcommando's

```powershell
# Toon alle PIM-eligible roltoewijzingen
Get-MgRoleManagementDirectoryRoleEligibilitySchedule |
    Select-Object PrincipalId, RoleDefinitionId, Status

# Haal de PIM-activatiegeschiedenis op (audit)
Get-MgRoleManagementDirectoryRoleAssignmentScheduleRequest |
    Select-Object PrincipalId, Action, Status, CreatedDateTime, Justification

# Toon alle access packages in een catalogus
Get-MgEntitlementManagementAccessPackage |
    Select-Object DisplayName, Id, CreatedDateTime

# Haal openstaande access package-toewijzingsaanvragen op
Get-MgEntitlementManagementAssignmentRequest -Filter "state eq 'pendingApproval'" |
    Select-Object Id, RequestType, State
```

### Kennischeck
1. Wat is het verschil tussen *entitlement management* en *access reviews*?
2. Hoe werkt PIM *Just-in-Time access* en waarom is het beter dan permanente roltowijzing?
3. Wat zijn *lifecycle workflows* in Identity Governance?
4. Hoe configureer je *separation of duties* via incompatible access packages?

<details>
<summary>Antwoorden</summary>

1. **Entitlement Management:** een proactief framework voor het verlenen van toegang. Je definieert vooraf welke resources beschikbaar zijn (catalog), maakt access packages aan met goedkeuringsworkflows en lifecycle-instellingen, en gebruikers vragen toegang aan via My Access portal. Focus: toegang verlenen op een gecontroleerde, gestructureerde manier met tijdslimiet. **Access Reviews:** een reactief/periodiek controlemechanisme. Je controleert periodiek of bestaande toegangstoewijzingen nog gerechtvaardigd zijn. Reviewers bevestigen of verwijderen toegang per gebruiker. Focus: toegang die al verleend is opschonen en handhaven. Samen vormen ze een complete identity governance-cyclus: entitlement management verleent, access reviews auditen en corrigeren.

2. PIM Just-in-Time access werkt als volgt: een gebruiker heeft een **eligible assignment** voor een hoog-privilege rol (bijv. Global Administrator). Normaal heeft de gebruiker GEEN actieve rechten van die rol. Wanneer de gebruiker de rechten nodig heeft, activeert hij/zij de rol via de PIM-portal (myaccess.microsoft.com of Entra portal), geeft een rechtvaardiging op, doorloopt eventueel MFA, en wacht op goedkeuring als dat vereist is. Na activering is de rol actief voor een beperkte tijd (bijv. 1–8 uur) waarna de rechten automatisch verlopen. Voordelen boven permanente toewijzing: aanvallers die een account overnemen, hebben géén directe admin-rechten; elke activering wordt gelogd met tijdstip, reden en goedkeurder; het beperkt het aanvalsoppervlak van admin-accounts drastisch.

3. Lifecycle Workflows zijn geautomatiseerde processen in Entra Identity Governance die identiteitsacties uitvoeren op basis van attributen of triggers. Drie hoofdscenario's: **Joiner** (nieuwe medewerker): automatisch aanmaken van account, toewijzen van groups en access packages, sturen van welkomstmail. **Mover** (functiewijziging): aanpassen van groepslidmaatschappen, intrekken van oude toegang, verlenen van nieuwe toegang bij promotie of overplaatsing. **Leaver** (vertrek): deactiveren van account, intrekken van toegang, verwijderen uit groepen, sturen van IT-notificatie, uiteindelijk verwijderen van account na retentieperiode. Workflows worden getriggerd op basis van Entra-attributen zoals `employeeHireDate` en `employeeLeaveDateTime`.

4. Separation of duties in Entitlement Management: ga naar een Access Package → Policies → **Requestor scope** → voeg een incompatibiliteitsregel toe. Je selecteert een ander access package dat niet tegelijk mag worden bezit. Wanneer een gebruiker probeert het tweede, incompatibele access package aan te vragen, wordt de aanvraag automatisch geblokkeerd als de gebruiker het eerste package al heeft. Voorbeeld: een medewerker die toegang heeft tot het "Financieel Goedkeuren" access package, mag niet tegelijk het "Financiële Orders Invoeren" package hebben — vier-ogen-principe afgedwongen via Entitlement Management.

</details>

---

## Week 7 — Examenvoorbereiding

### Examendekking en verplichte labs

Doel: de huidige labs expliciet laten aansluiten op alle exam-doelstellingen.

### Nog expliciet af te dekken
1. Global Secure Access verdieping: clientdeployment, Private Access en Internet Access voor Microsoft 365.
2. Cross-tenant synchronization naast standaard B2B collaboration.
3. Defender for Cloud Apps in workload identity context.
4. Identity monitoring via Log Analytics, KQL, workbooks en Identity Secure Score.

> **Noot over Global Secure Access (toegevoegd november 2025):** GSA is een volledig nieuw examenonderwerp dat per november 2025 is opgenomen in het SC-300-examen. De SSW-Lab-scripts dekken de GSA-clientinstallatie en Private Access-configuratie nog niet volledig. Besteed extra aandacht aan de [MS Learn module voor Global Secure Access](https://learn.microsoft.com/en-us/training/modules/deploy-configure-microsoft-entra-global-secure-access/) als aanvulling op de lab-oefeningen in week 4. Zorg dat je de drie verkeersprofielen, Universal Conditional Access en de rol van de GSA-client kunt uitleggen en configureren.

### Verplichte labs voor slaagkans
1. Voer een end-to-end Global Secure Access test uit met policy, client en logging-resultaat.
2. Configureer cross-tenant synchronization met een testtenant en valideer lifecycle gedrag.
3. Maak een app registration met delegated en application permissions en leg consent impact vast.
4. Bouw 2 KQL queries voor identity logs en presenteer de interpretatie.
5. Oefen 3 PIM-rondes: eligible assignment, activation, audit en break-glass controle.

### Exit criteria voordat je examen plant
1. Je kunt elk SC-300 domein verbinden aan een eigen praktijkvoorbeeld.
2. Je hebt CA, Identity Protection, workload identity en governance daadwerkelijk live getest.
3. Je kunt risico-incidenten inhoudelijk analyseren met logdata in plaats van alleen portal-clicks.

---

### Activiteiten
- Herhaal zwakke domeinen op basis van het [officiële examenstudiegids](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/sc-300)
- Doe de **Microsoft Learn oefenassessment** SC-300: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Herhaal PIM-configuratie, CA What-If scenario's en entitlement management
- Maak een overzicht van alle Identity Protection risicotypes en remediation-stappen
- Plan je examen via Pearson VUE

### Aandachtspunten voor het examen
- **Domeingewichten gewijzigd:** gebruikersidentiteiten 20–25%, workload-identiteiten 20–25%, governance 20–25%
- **Global Secure Access** is een nieuw examenonderwerp — ken Private Access, Internet Access en M365-profielen
- Azure RBAC voor resources („Implement access management for Azure resources") is **verwijderd** uit SC-300
- Conditional Access: *What If* scenario's, authentication strength, continuous access evaluation en protected actions
- PIM: weet het verschil tussen eligible, active en permanent assignments
- Identity governance: entitlement management vs. access reviews vs. lifecycle workflows
- B2B: cross-tenant access settings, cross-tenant synchronization en external collaboration instellingen
- App registrations: ken het verschil delegated vs. application API permissions; managed identities (system vs. user-assigned)
- Identity monitoring: KQL-query's in Log Analytics, Identity Secure Score
