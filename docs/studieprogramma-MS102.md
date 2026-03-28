# Studieprogramma MS-102 — Microsoft 365 Administrator

> 🌐 **Taal:** Nederlands | [English](study-guide-MS102.md)

**Duur:** 8 weken · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02)
**MS Learn pad:** [Microsoft 365 Administrator](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/ms-102)
**Examengewicht:**

| Domein | Gewicht |
|---|---|
| Microsoft 365 tenant deployen en beheren | 25–30% |
| Microsoft Entra identiteit en toegang implementeren en beheren | 25–30% |
| Beveiliging en bedreigingen beheren via Microsoft Defender XDR | 30–35% |
| Compliance beheren via Microsoft Purview | 10–15% |

> **Bijgewerkt:** Skills gemeten per 10 november 2025. Defender-domein hernoemd naar **Microsoft Defender XDR** (30–35%). Compliance hernoemd naar **Microsoft Purview** (10–15%).

> **Voorwaarde:** Microsoft 365 E5 developer tenant (via MSDN/M365 developer program)
> Registreer op: [developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/microsoft-365/dev-program)

## Zo gebruik je dit studieprogramma

- Begin elke week met de leerdoelen en MS Learn modules; MS-102 beloont overzicht en samenhang meer dan losse feitjes.
- Voer de lab-oefeningen uit in zowel de tenant als op de genoemde VM's, zodat je het verband ziet tussen cloudbeheer en de hybride praktijk.
- Maak de kennischeck pas na de theorie en de praktijk, en markeer expliciet welke vragen je alleen "ongeveer" wist.
- Gebruik bij samenwerking met Nederlandstalige en Engelstalige collega's bewust dezelfde kerntermen in beide talen, bijvoorbeeld *retentiebeleid / retention policy* en *roltoewijzing / role assignment*.

## Labdekking en verwachtingen

- **Sterke dekking in SSW-Lab:** tenantbeheer, Entra Connect, basisrollen, licenties, Conditional Access, Defender for Endpoint, identity hygiene en een deel van Purview-beheer.
- **Gedeeltelijke dekking:** Defender for Office 365, Defender for Cloud Apps, Insider Risk, geavanceerde Purview-workflows en sommige compliancefuncties hangen sterk af van tenantlicenties en portalbeschikbaarheid.
- **Cloud-only of beperkt simuleerbaar:** Microsoft 365 Backup-ervaring, production mailflow-scenario's, externe domeinconfiguratie en sommige cross-workload Defender XDR-koppelingen.
- Zie het lab als primaire oefenomgeving, maar plan voor de gemarkeerde onderdelen altijd ook directe portalverkenning of MS Learn-herhaling in.

## Werkwijze voor kennischecks

- Beantwoord eerst zonder hulpmiddelen wat je in een echte beheerderrol zou doen.
- Controleer daarna of je antwoord niet alleen technisch klopt, maar ook past bij least privilege, governance en operationele realiteit.
- Herhaal zwakke vragen na een dag nog een keer; MS-102 vraagt vaak om ketendenken over meerdere portals heen.
- Let extra op verschillen tussen vergelijkbare termen zoals *security group*, *Microsoft 365 group*, *directory role* en *Azure RBAC role*.

---

## Week 1 — Microsoft 365 tenant inrichten
> **Examendomein:** Microsoft 365 tenant deployen en beheren · **Gewicht:** 25–30%

### Leerdoelen
- [ ] Het Microsoft 365 admin center navigeren en tenantinstellingen configureren
- [ ] Een custom domein toevoegen en de vereiste DNS-records instellen (MX, TXT, CNAME)
- [ ] Het verschil uitleggen tussen een managed domain en een federated domain
- [ ] Azure AD Connect installeren en password hash synchronization (PHS) configureren
- [ ] Microsoft 365 E5-licenties toewijzen aan gesynchroniseerde gebruikers
- [ ] Microsoft 365 Backup inschakelen en onderscheiden van retentiebeleid

### MS Learn modules
- [Explore your Microsoft 365 cloud environment](https://learn.microsoft.com/en-us/training/modules/explore-microsoft-365-cloud-environment/)
- [Configure your Microsoft 365 experience](https://learn.microsoft.com/en-us/training/modules/configure-microsoft-365-experience/)
- [Manage Microsoft 365 tenants](https://learn.microsoft.com/en-us/training/modules/manage-your-microsoft-365-tenant/)

### Kernbegrippen
| Begriff | Uitleg |
|---------|--------|
| Managed domain | Domein waarbij Microsoft 365 direct de authenticatie afhandelt; wachtwoorden worden gesynchroniseerd via PHS of PTA |
| Federated domain | Domein waarbij authenticatie wordt doorverwezen naar een externe identiteitsprovider (bijv. AD FS); Microsoft 365 vertrouwt op een externe STS |
| Password Hash Synchronization (PHS) | Azure AD Connect synchroniseert een hash van het wachtwoord naar Entra ID; authenticatie vindt plaats in de cloud |
| Pass-Through Authentication (PTA) | Authenticatieverzoeken worden doorgestuurd naar on-premises agents; wachtwoorden verlaten nooit het bedrijfsnetwerk |
| DNS-records voor M365 | MX (e-mail routing), TXT (domeinverificatie + SPF), CNAME (Autodiscover, Teams) zijn minimaal vereist |
| Tenant data residency | De geografische regio waarin Microsoft 365-gegevens worden opgeslagen (bijv. EU); controleerbaar via Admin center → Settings → Org profile |
| Microsoft 365 Backup | Ingebouwde back-upservice voor Exchange, OneDrive en SharePoint; herstelt tot 180 dagen terug — los van retentiebeleid |
| Compliance center | Onderdeel van Microsoft Purview — beheer van DLP, retentie, eDiscovery en informatiebeveiliging |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Open **Microsoft 365 admin center** (admin.microsoft.com) in Edge |
| **SSW-MGMT01** | Configureer tenantinformatie: naam, bezochte landsinstellingen, tijdzone |
| **SSW-MGMT01** | Voeg een custom domein toe (of verifieer `ssw.lab`-equivalent in tenant) |
| **SSW-DC01** | Installeer Azure AD Connect → synchroniseer `ssw.lab` AD-gebruikers naar Entra ID |
| **SSW-MGMT01** | Verifieer gesynchroniseerde gebruikers in **Entra admin center → Users** |
| **SSW-MGMT01** | Activeer Microsoft 365 E5-licenties voor gesynchroniseerde gebruikers |
| **SSW-MGMT01** | Schakel **Microsoft 365 Backup** in: stel een back-upbeleid in voor Exchange en OneDrive |

### Kennischeck
1. Wat is het verschil tussen een *managed domain* en een *federated domain* in Microsoft 365?
2. Hoe werkt *password hash synchronization* versus *pass-through authentication*?
3. Welke DNS-records zijn vereist voor een custom domein in Microsoft 365?
4. Wat is het *Microsoft 365 compliance center* en waarvoor gebruik je het?
5. Wat is *Microsoft 365 Backup* en hoe verschilt het van retentiebeleid?

<details>
<summary>Antwoorden</summary>

1. **Managed domain:** authenticatie vindt volledig in de cloud plaats. Azure AD Connect synchroniseert wachtwoordhashes (PHS) of verzendt authenticatieverzoeken via on-premises agents (PTA) — maar er is geen externe STS. **Federated domain:** Microsoft 365 vertrouwt op een externe identiteitsprovider (bijv. AD FS of een externe IdP). Het authenticatieverzoek wordt omgeleid naar die IdP, die een SAML/WS-Fed token uitgeeft. Federated is complexer, maar biedt volledige controle over authenticatielogica.

2. **PHS (Password Hash Synchronization):** Azure AD Connect haalt het wachtwoord-hash op uit on-premises AD, versleutelt het nogmaals en synchroniseert het naar Entra ID. Authenticatie vindt in de cloud plaats; geen on-premises agent vereist na initiële installatie. **PTA (Pass-Through Authentication):** bij inloggen stuurt Entra ID het authenticatieverzoek naar een lichtgewichte on-premises agent, die het wachtwoord valideert tegen het lokale AD. Wachtwoorden verlaten het bedrijfsnetwerk nooit. Vereist dat de on-premises agent altijd bereikbaar is.

3. Minimaal vereiste DNS-records: **TXT-record** voor domeinverificatie (Microsoft voegt een willekeurige waarde toe die je in je DNS plaatst). Daarna voor volledige functionaliteit: **MX-record** (e-mailbezorging naar Exchange Online), **CNAME Autodiscover** (automatische Outlook-configuratie), **CNAME voor Teams/Skype** (optioneel), **SPF TXT-record** (antispam), **DKIM CNAME-records** (e-mailintegriteit). Voor domeinverificatie alleen: alleen het TXT-record.

4. Het **Microsoft 365 compliance center** (nu onderdeel van **Microsoft Purview** via purview.microsoft.com) biedt beheertools voor: Data Loss Prevention (DLP), retentiebeleid en retentielabels, eDiscovery, informatiebeveiliging (sensitivity labels), Insider Risk Management, Communication Compliance en auditlogboeken. Het is het centrale punt voor alles rondom gegevensbescherming en compliance in M365.

5. **Microsoft 365 Backup** is een aparte back-up- en herstelservice voor Exchange Online, OneDrive en SharePoint. Het maakt onafhankelijke momentopnames en herstelt tot 180 dagen terug — ook bij per ongeluk verwijderde of gewijzigde gegevens. **Retentiebeleid** (Purview) bewaart inhoud voor juridische of compliancedoeleinden, maar is geen back-upoplossing: het voorkomt verwijdering, maar stelt de gebruiker niet in staat om een eerdere versie van een bestand te herstellen op een bepaald tijdstip.

</details>

---

## Week 2 — Gebruikers- en groepsbeheer
> **Examendomein:** Microsoft 365 tenant deployen en beheren · **Gewicht:** 25–30%

### Leerdoelen
- [ ] Het principe van *least privilege* toepassen bij het toewijzen van beheerderrollen in M365
- [ ] Het verschil uitleggen tussen beveiligingsgroepen, Microsoft 365-groepen en distributiegroepen
- [ ] Dynamische groepen aanmaken op basis van gebruikersattributen in Entra ID
- [ ] Self-Service Password Reset (SSPR) configureren en testen
- [ ] Privileged Identity Management (PIM) inzetten voor Just-in-Time activering van beheerdersrollen
- [ ] De audit trail van PIM-activaties interpreteren in de Entra-controlegeschiedenis

### MS Learn modules
- [Manage users and groups in Microsoft 365](https://learn.microsoft.com/en-us/training/modules/manage-users-and-groups-in-microsoft-365/)
- [Manage admin roles in Microsoft 365](https://learn.microsoft.com/en-us/training/modules/manage-admin-roles/)
- [Manage password policies](https://learn.microsoft.com/en-us/training/modules/manage-password-policies/)

### Kernbegrippen
| Begriff | Uitleg |
|---------|--------|
| Least privilege | Beheerdersprincipe: geef gebruikers alleen de minimale rechten die nodig zijn voor hun taak — geen onnodige beheerdersrollen |
| Beveiligingsgroep | Entra ID-groep voor toegangsbeheer tot resources (bijv. SharePoint, apps) — geen e-mailadres |
| Microsoft 365-groep | Gecombineerde groep met gedeelde mailbox, Teams-kanaal, SharePoint-site en OneNote — voor samenwerking |
| Distributiegroep | Alleen voor e-maildistributie in Exchange Online; geen Entra ID-rechten of samenwerking |
| Dynamische groep | Lidmaatschap wordt automatisch bepaald op basis van gebruikersattributen (bijv. `department -eq "IT"`) — vereist Entra ID P1 |
| Self-Service Password Reset (SSPR) | Gebruikers kunnen zelf hun wachtwoord resetten via aka.ms/sspr zonder helpdesk — vereist minimaal 1 verificatiemethode |
| Privileged Identity Management (PIM) | Entra ID P2-functie voor Just-in-Time activering van beheerdersrollen — met goedkeuring, tijdslimiet en audittrail |
| Eligible rol (PIM) | Rol die een gebruiker kan activeren wanneer nodig — niet permanent actief; activering vereist MFA en optioneel goedkeuring |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-DC01** | Maak OU-structuur aan: `OU=SSW, OU=Users, DC=ssw, DC=lab` |
| **SSW-DC01** | Bulk-aanmaken van test-accounts via CSV + `Import-Csv | New-ADUser` |
| **SSW-MGMT01** | Wijs rollen toe in M365: maak een *Helpdesk Administrator* aan |
| **SSW-MGMT01** | Maak een dynamische groep aan in Entra ID (attribute-based: `department -eq "IT"`) |
| **SSW-MGMT01** | Activeer *Self-Service Password Reset* (SSPR) voor de IT-afdeling |
| **SSW-W11-01** | Test SSPR als TestUser01 via `aka.ms/sspr` |
| **SSW-MGMT01** | Configureer **Privileged Identity Management (PIM)**: maak de rol Global Administrator *eligible* voor labadmin |
| **SSW-MGMT01** | Activeer de GA-rol Just-in-Time via PIM → verifieer de audit trail onder **Entra → PIM → Controlegeschiedenis** |

### Kennischeck
1. Wat is het principe van *least privilege* bij het toewijzen van beheerderrollen?
2. Wat is het verschil tussen een beveiligingsgroep en een Microsoft 365-groep?
3. Hoe werkt *bulk user creation* via de Microsoft 365 admin center?
4. Wanneer gebruik je *dynamic groups* versus *assigned groups*?
5. Wat is *PIM* en waarom heeft *Just-in-Time* toegang de voorkeur boven een permanente rol?

<details>
<summary>Antwoorden</summary>

1. **Least privilege** betekent dat je gebruikers en beheerders alleen de minimale set rechten geeft die nodig is voor hun specifieke taak. In M365: gebruik *Helpdesk Administrator* in plaats van *Global Administrator* voor wachtwoordresets. Geef nooit een permanente Global Administrator-rol aan accounts die dagelijks worden gebruikt — activeer via PIM wanneer nodig. Dit beperkt de schade bij een gecompromitteerd account.

2. **Beveiligingsgroep:** wordt gebruikt voor toegangsbeheer — toewijzen van rechten tot SharePoint-sites, apps, Intune-policies, enz. Heeft geen eigen e-mailadres. **Microsoft 365-groep:** biedt gedeelde samenwerking — gecombineerde inbox/gedeelde mailbox, Teams-team, SharePoint-teamsite en OneNote-notitieblok. Heeft een e-mailadres. Gebruik beveiligingsgroepen voor toegang, M365-groepen voor samenwerking.

3. Bulk user creation via het admin center: ga naar Users → Active users → klik "Add multiple users" → download de CSV-sjabloon → vul in (weergavenaam, UPN, wachtwoord, licentie) → upload. Alternatief via PowerShell (Graph module): `Import-Csv .\users.csv | ForEach-Object { New-MgUser ... }`. CSV-methode via admin center is limiet aan ~249 gebruikers per keer.

4. **Dynamische groepen** zijn ideaal wanneer het lidmaatschap logisch volgt uit gebruikersattributen (afdeling, locatie, functietitel) — automatisch onderhouden, geen handmatige interventie. Gebruik ze voor: afdelingsgerelateerde policies, automatische licentietoewijzing (group-based licensing). **Assigned groups** zijn geschikt voor vaste, kleine groepen waarbij lidmaatschap niet automatisch te bepalen is (bijv. een projectteam). Dynamische groepen vereisen Entra ID P1-licentie.

5. **PIM (Privileged Identity Management)** maakt beheerdersrollen *eligible* in plaats van permanent actief. **Just-in-Time** activering: beheerder activeert de rol alleen wanneer nodig (tijdgebonden, bijv. 4 uur), met MFA-verificatie en optionele manager-goedkeuring. Voordelen boven permanente rol: (1) beperkt het aanvalsoppervlak bij een gecompromitteerd account, (2) elke activering wordt geauditeerd (wie, wanneer, waarvoor), (3) automatisch verlopen van privileges na de ingestelde tijdsduur.

</details>

---

## Week 3 — Entra ID en hybride identiteit
> **Examendomein:** Microsoft Entra identiteit en toegang implementeren en beheren · **Gewicht:** 25–30%

### Leerdoelen
- [ ] Het verschil uitleggen tussen Entra Connect Sync en Entra Cloud Sync en het juiste scenario kiezen
- [ ] MFA configureren via Entra ID en het verschil begrijpen met Security Defaults
- [ ] Seamless Single Sign-On (SSO) beschrijven en configureren met Azure AD Connect
- [ ] Een B2B-gastuitnodiging versturen en Cross-Tenant Access Settings beheren
- [ ] Sync-fouten in Entra Connect diagnosticeren via Entra Connect Health
- [ ] Entra Password Protection configureren inclusief de on-premises agent

### MS Learn modules
- [Manage identity synchronization with Azure AD Connect and Entra Cloud Sync](https://learn.microsoft.com/en-us/training/modules/manage-azure-active-directory-connect/)
- [Implement multifactor authentication](https://learn.microsoft.com/en-us/training/modules/implement-multifactor-authentication/)
- [Manage external identities](https://learn.microsoft.com/en-us/training/modules/manage-external-identities/)

### Kernbegrippen
| Begriff | Uitleg |
|---------|--------|
| Entra Connect Sync | On-premises server die AD-objecten synchroniseert naar Entra ID; ondersteunt complexe multi-forest topologieën |
| Entra Cloud Sync | Lichtgewichte sync-agent (zonder on-premises server) voor eenvoudige hybride scenario's; beperkte filteropties |
| Seamless SSO | Gebruikers op domein-joined apparaten worden automatisch ingelogd in M365 zonder opnieuw wachtwoord in te voeren — via Kerberos-ticket |
| Security Defaults | Vooraf geconfigureerde basisbeveiligingsinstellingen van Microsoft (MFA voor alle admins, blokkeer legacy auth) — gratis, geen Entra P1 vereist |
| MFA per gebruiker | Legacy-methode: MFA per account inschakelen in het admin center; verouderd ten opzichte van Conditional Access |
| Azure AD B2B | Gastidentiteiten uit externe organisaties uitnodigen voor samenwerking in jouw tenant; ze authenticeren via hun eigen IdP |
| Cross-Tenant Access Settings | Beleid dat bepaalt welke externe Entra ID-tenants gasten mogen sturen of ontvangen en welke vertrouwensinstellingen gelden |
| Entra Connect Health | Bewakingsservice voor Entra Connect Sync — toont sync-fouten, agent-status en prestatiegegevens |
| Entra Password Protection | Blokkeert bekende zwakke en organisatiespecifieke verboden wachtwoorden; on-premises agent valideert bij AD-wachtwoordwijzigingen |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-DC01** | Controleer sync-status: `Get-ADSyncScheduler` → verifieer cycle |
| **SSW-MGMT01** | Configureer MFA via **Entra admin center → Security → Multifactor authentication** |
| **SSW-W11-01** | Registreer MFA-methode als TestUser01 (Authenticator app) |
| **SSW-MGMT01** | Bekijk *Sign-in logs* in Entra ID → filter op MFA-events |
| **SSW-MGMT01** | Nodig een externe gebruiker (B2B guest) uit via Entra ID |
| **SSW-MGMT01** | Configureer *Cross-tenant access settings* voor externe organisaties |
| **SSW-MGMT01** | Controleer **Entra Connect Health** → verifieer sync-agentstatus en foutrapport |
| **SSW-MGMT01** | Schakel **Entra Password Protection** in → configureer verboden wachtwoordenlijst |

### Kennischeck
1. Wat is het verschil tussen MFA per gebruiker en *Security Defaults*?
2. Hoe werkt *Seamless Single Sign-On* (SSO) met Azure AD Connect?
3. Wat is Azure AD B2B en wanneer gebruik je B2B versus B2C?
4. Hoe troubleshoot je een sync-fout in Azure AD Connect?
5. Wat is het verschil tussen *Entra Connect Sync* en *Entra Cloud Sync*?
6. Wat doet *Entra Password Protection* en hoe werkt de on-premises agent?

<details>
<summary>Antwoorden</summary>

1. **MFA per gebruiker** (legacy): individuele instelling per account in de M365 admin center — gebruiker krijgt bij elke inlog een MFA-uitdaging, ongeacht locatie of apparaat. Verouderd en moeilijk op schaal te beheren. **Security Defaults**: Microsoft-voorinstelling die MFA afdwingt voor alle beheerders, legacy-authenticatieprotocollen blokkeert en beveiligde aanmelding voor alle gebruikers vereist. Gratis, geen Entra P1 nodig — maar niet aanpasbaar. De aanbevolen aanpak is Conditional Access (vereist Entra P1/P2) voor granulaire controle.

2. **Seamless SSO** werkt via Kerberos-authenticatie. Tijdens Azure AD Connect-configuratie wordt een computeraccount (`AZUREADSSOACC`) aangemaakt in het on-premises AD. Wanneer een gebruiker op een domein-joined apparaat (Windows, aangemeld bij AD) een M365-service opent, vraagt de browser automatisch een Kerberos-service-ticket op bij de domeincontroller. Dit ticket wordt naar Entra ID gestuurd als bewijs van identiteit — de gebruiker hoeft niet opnieuw in te loggen. Vereist dat de browser Integrated Windows Authentication (IWA) ondersteunt en het M365-domein als intranetzone heeft geconfigureerd.

3. **Azure AD B2B** is voor samenwerking met externe medewerkers uit andere organisaties (partners, leveranciers). Zij krijgen een gastaccount in jouw tenant en authenticeren via hun eigen organisatie-IdP. **Azure AD B2C** is voor klant-authenticatie — consumentaccounts voor jouw eigen applicatie (social login, custom credentials). Gebruik B2B voor zakelijke samenwerking, B2C voor klantgerichte apps.

4. Troubleshooten van sync-fouten: (1) **Synchronization Service Manager** op de Entra Connect-server → tabblad "Operations" voor foutberichten per object; (2) **Entra Connect Health** in de Entra portal → sync errors tab met objectdetails; (3) PowerShell: `Get-ADSyncScheduler` (status), `Start-ADSyncSyncCycle -PolicyType Delta` (handmatige sync); (4) Controleer de specifieke fout (bijv. `AttributeValueMustBeUnique` = duplicaat UPN/proxyAddress; `ObjectTypeMismatch` = conflicterend objecttype). Herstel op het on-premises AD-object en wacht op de volgende sync-cyclus.

5. **Entra Connect Sync:** server-gebaseerde oplossing (vereist een Windows Server on-premises), ondersteunt multi-forest topologieën, geavanceerde filtering, password writeback, device writeback, Exchange hybride en groepsdelegaties. Meer beheerscomplexiteit. **Entra Cloud Sync:** agent-gebaseerd (lichtgewicht agent op DC of member server), eenvoudiger te installeren, geen aparte server, geschikt voor single-forest of eenvoudige hybride scenario's. Ondersteunt geen device writeback of Exchange hybride. Kies Cloud Sync voor eenvoud, Connect Sync voor complexe vereisten.

6. **Entra Password Protection** blokkeert bekende zwakke wachtwoorden (Microsoft-lijst) én organisatiespecifieke verboden woorden (bijv. bedrijfsnaam, projectnamen) bij wachtwoordwijzigingen. **On-premises agent:** een lichtgewichte agent geïnstalleerd op domeincontrollers en een proxy-service op een member server. Wanneer een gebruiker het wachtwoord wijzigt in on-premises AD, roept de DC-extensie de agent aan, die het wachtwoord valideert tegen de gecombineerde verbodenenlijst (van Microsoft + eigen configuratie) voordat de wijziging wordt doorgevoerd.

</details>

---

## Week 4 — Exchange Online beheer
> **Examendomein:** Microsoft 365 tenant deployen en beheren · **Gewicht:** 25–30%

### Leerdoelen
- [ ] Shared mailboxen, room mailboxen en resource mailboxen aanmaken en beheren
- [ ] Mail flow rules (transport rules) configureren voor disclaimers en routering
- [ ] Anti-spam, anti-phishing en anti-malware policies instellen in Defender for Office 365
- [ ] DKIM inschakelen en DMARC-records interpreteren voor e-mailauthenticatie
- [ ] Message trace uitvoeren om bezorgproblemen te diagnosticeren
- [ ] Het verschil uitleggen tussen Safe Attachments en Safe Links in Defender for Office 365

### MS Learn modules
- [Manage Exchange Online recipients and permissions](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-recipients/)
- [Manage Exchange Online mail flow](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-mail-flow/)
- [Manage Exchange Online protection](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-protection/)

### Kernbegrippen
| Begriff | Uitleg |
|---------|--------|
| Shared mailbox | Mailbox zonder eigen licentie die door meerdere gebruikers kan worden geopend; max. 50 GB gratis |
| Room mailbox | Resource mailbox voor vergaderruimtes — kan automatisch afspraken accepteren of weigeren op basis van beschikbaarheid |
| Mail flow rule (transport rule) | Serverregel die e-mailverkeer inspecteert en acties uitvoert (disclaimer toevoegen, doorsturen, blokkeren) |
| Message trace | Diagnostische tool in EAC om de bezorgstatus van een specifiek bericht te achterhalen |
| DKIM | DomainKeys Identified Mail — voegt een digitale handtekening toe aan uitgaande mail via een privésleutel; ontvangers verifiëren via DNS |
| DMARC | Domain-based Message Authentication — beleid dat definieert wat te doen bij SPF/DKIM-mislukking (none, quarantine, reject) |
| Safe Attachments | Defender for Office 365-functie die e-mailbijlagen in een sandbox opent voor malwaredetectie vóór bezorging |
| Safe Links | Herschrijft URL's in e-mails en Office-documenten; controleert reputatie bij elke klik in real-time |
| Anti-phishing policy | Beleid voor detectie van impersonation, spoofing en DMARC-overtredingen in inkomende e-mail |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Maak shared mailboxen aan via Exchange Admin Center (EAC) |
| **SSW-MGMT01** | Configureer een *Distribution list* en *Microsoft 365 Group* |
| **SSW-MGMT01** | Stel een *mail flow rule* in: voeg disclaimer toe aan uitgaande mail |
| **SSW-MGMT01** | Configureer *Anti-spam* en *Anti-phishing* policies in Defender for Office 365 |
| **SSW-W11-01** | Test een *message trace* via EAC → analyseer bezorgstatus |
| **SSW-MGMT01** | Configureer *DKIM* en bekijk DMARC-instellingen voor het tenant-domein |

### Kennischeck
1. Wat is het verschil tussen een *shared mailbox* en een *room mailbox*?
2. Hoe werkt *message trace* en wanneer gebruik je het?
3. Wat doen *Safe Attachments* en *Safe Links* in Defender for Office 365?
4. Wat is het verschil tussen *anti-spam* en *anti-phishing* policies?

<details>
<summary>Antwoorden</summary>

1. **Shared mailbox:** een mailbox die door meerdere gebruikers gedeeld wordt voor centrale communicatie (bijv. info@bedrijf.nl). Vereist geen aparte licentie tot 50 GB; gebruikers krijgen via "Send As" of "Full Access" toegang. **Room mailbox:** een resource mailbox voor een fysieke vergaderruimte of apparatuur. Kan automatisch vergaderverzoeken accepteren/weigeren op basis van beschikbaarheid en ingestelde beleidsregels (max. bezetting, tijdslimiet).

2. **Message trace** is een diagnostische tool in het Exchange Admin Center (EAC → Mail flow → Message trace). Je zoekt op afzender, ontvanger of tijdbestek en ziet de volledige bezorgstatus: ontvangen, doorgestuurd, geleverd, of geblokkeerd — inclusief welke mail flow rules zijn toegepast. Gebruik het bij: klachten van gebruikers over niet-ontvangen mail, vermoedelijke spamfiltering, of verificatie van transport rules.

3. **Safe Attachments:** bijlagen in inkomende e-mails worden gekopieerd naar een sandbox-omgeving waar ze worden uitgevoerd om kwaadaardig gedrag te detecteren. Kan worden ingesteld op Block (houdt mail achter), Dynamic Delivery (levert mail direct, bijlage volgt na scan), of Monitor. **Safe Links:** URL's in e-mails en Office-documenten worden herschreven naar een Microsoft-proxy-URL. Bij elke klik controleert Microsoft in real-time of de URL inmiddels kwaadaardig is — ook na bezorging van de e-mail.

4. **Anti-spam policy:** gericht op het filteren van massaverzendingen, bulk-mail en berichten met spam-kenmerken op basis van reputatie en inhoudsanalyse. Acties: Junk, Quarantine, blokkeren. **Anti-phishing policy:** gericht op geavanceerdere aanvallen zoals impersonation (nep-CEO-mail), spoof-detectie (afzender misbruikt jouw domein) en DMARC-controles. Anti-phishing policies in Defender for Office 365 Plan 2 voegen ook mailbox intelligence toe (leert normale verzendpatronen van executives).

</details>

---

## Week 5 — SharePoint Online en Microsoft Teams
> **Examendomein:** Microsoft 365 tenant deployen en beheren · **Gewicht:** 25–30%

### Leerdoelen
- [ ] Het verschil uitleggen tussen een Group site, Communication site en Hub site in SharePoint
- [ ] Externe delinstellingen beheren op tenant-, site- en documentniveau
- [ ] Sensitivity labels toepassen op Teams-teams en SharePoint-sites
- [ ] Teams-beleid configureren voor vergaderingen, gasten en kanaaldeelname
- [ ] PowerShell (PnP-module en Teams-module) gebruiken voor bulk-beheer
- [ ] Gebruiksrapporten interpreteren via het Microsoft 365 admin center

### MS Learn modules
- [Manage SharePoint Online](https://learn.microsoft.com/en-us/training/modules/manage-sharepoint-online/)
- [Manage Microsoft Teams](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-teams/)
- [Manage Teams collaboration settings](https://learn.microsoft.com/en-us/training/modules/manage-teams-collaboration-settings/)

### Kernbegrippen
| Begriff | Uitleg |
|---------|--------|
| Group site (teamsite) | SharePoint-site gekoppeld aan een Microsoft 365-groep; leden van de groep hebben automatisch toegang |
| Communication site | SharePoint-site voor brede interne communicatie (intranet, nieuws); geen gekoppelde M365-groep |
| Hub site | Overkoepelende site die meerdere SharePoint-sites verbindt voor gedeelde navigatie, zoeken en thema's |
| Externe deling (SharePoint) | Configureerbaar op tenant- en siteniveau: Iedereen (anonymous link), Nieuwe en bestaande gasten, Bestaande gasten, Alleen intern |
| Sensitivity label (sites) | Label dat privacyinstellingen, externe toegang en niet-beheerde apparaten voor een Team of SharePoint-site afdwingt |
| Teams-vergaderbeleid | Beheerdersconfiguratie voor wat deelnemers kunnen doen in vergaderingen: opnemen, transcriptie, lobby-instellingen, externe deelname |
| Privékanaal (Teams) | Kanaal binnen een team dat alleen zichtbaar is voor een geselecteerde subgroep van teamleden; heeft eigen SharePoint-subsite |
| PnP PowerShell | Community-ondersteunde PowerShell-module voor geavanceerd SharePoint Online-beheer (Connect-PnPOnline) |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Maak een SharePoint-sitecollectie aan (Team site) en wijs rechten toe |
| **SSW-MGMT01** | Configureer *external sharing* settings in SharePoint admin center |
| **SSW-W11-01** | Upload documenten naar SharePoint → test deling met TestUser02 |
| **SSW-MGMT01** | Maak een Teams-team aan via Teams admin center → voeg leden toe |
| **SSW-MGMT01** | Configureer *Meetings policies* in Teams: beperk opname voor gasten |
| **SSW-MGMT01** | Bekijk **Teams usage reports** in M365 admin center |

### Kennischeck
1. Wat is het verschil tussen een *Group site*, *Communication site* en *Hub site* in SharePoint?
2. Hoe beheer je externe toegang in Teams op channel-niveau versus team-niveau?
3. Wat zijn *sensitivity labels* en hoe pas je ze toe op Teams en SharePoint?
4. Hoe gebruik je PowerShell (PnP / Teams module) voor bulk-beheer?

<details>
<summary>Antwoorden</summary>

1. **Group site (teamsite):** gekoppeld aan een Microsoft 365-groep; alle leden van de groep hebben automatisch SharePoint-toegang. Bedoeld voor samenwerking binnen een team. **Communication site:** bedoeld voor brede communicatie (intranet, nieuws, aankondigingen) richting veel lezers, weinig schrijvers. Geen gekoppelde M365-groep. **Hub site:** een site die andere SharePoint-sites verbindt; biedt gedeelde navigatiebalk, branding en zoekbereik over alle gekoppelde sites. Ideaal voor een intranetarchitectuur met divisies.

2. **Team-niveau:** in Teams admin center → externe toegang: stel per tenant in of gastgebruikers mogen worden uitgenodigd. Via guestinstellingen in Teams-teams: extern e-mailadres uitnodigen als gast (via Entra ID B2B). **Kanaal-niveau (gedeeld kanaal):** een *shared channel* kan externe Teams-gebruikers (buiten jouw tenant) direct toevoegen zonder gastaccount — via Teams Connect. Privékanalen zijn intern, shared channels zijn cross-tenant maar vereisen dat B2B Direct Connect is ingeschakeld in Cross-Tenant Access Settings.

3. **Sensitivity labels** classificeren en beschermen content. Op **Teams/SharePoint-sites** stelt een label de privacyinstelling in (Publiek/Privé), of externe gebruikers mogen worden toegevoegd, en of onbeheerde apparaten toegang krijgen. Toepassen: beheerder maakt label aan in Purview → configureert *Groups & sites*-scope → publiceert via labelbeleid → teamseigenaar kan het label selecteren bij het aanmaken van een team of site. Automatische toepassing is ook mogelijk via een auto-labelbeleid.

4. **PnP PowerShell** (SharePoint): `Connect-PnPOnline -Url https://tenant.sharepoint.com -Interactive`. Voorbeelden: `Get-PnPList`, `Add-PnPListItem`, bulk-aanmaken van sites via `New-PnPSite`. **MicrosoftTeams-module**: `Connect-MicrosoftTeams`. Voorbeelden: `Get-Team | Export-Csv`, `New-Team`, `Add-TeamUser`. Gebruik voor: bulk-aanmaken/verwijderen van teams, rapporteren van lidmaatschappen, exporteren van configuraties voor audits.

</details>

---

## Week 6 — Microsoft Defender XDR en bedreigingsbeheer
> **Examendomein:** Beveiliging en bedreigingen beheren via Microsoft Defender XDR · **Gewicht:** 30–35%

### Leerdoelen
- [ ] Het Defender XDR-portal navigeren en de relatie tussen MDE, MDO, MDI en MDCA uitleggen
- [ ] Een apparaat onboarden naar Defender for Endpoint via Intune-policy
- [ ] Een incident analyseren via de Attack story-weergave in de Defender portal
- [ ] Automated Investigation and Response (AIR) beschrijven en de resultaten interpreteren
- [ ] Attack Simulation Training uitvoeren en de resultaten analyseren
- [ ] Microsoft Secure Score verbeteren met concrete verbeteracties

### MS Learn modules
- [Explore the Microsoft Defender XDR portal](https://learn.microsoft.com/en-us/training/modules/explore-microsoft-365-defender/)
- [Manage Microsoft Defender for Office 365](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-defender-office-365/)
- [Manage Microsoft Secure Score and Exposure Management](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-secure-score/)

### Kernbegrippen
| Begriff | Uitleg |
|---------|--------|
| Defender XDR | Extended Detection & Response-platform dat MDE, MDO, MDI en MDCA samenvoegt in één portal (security.microsoft.com) |
| Incident | Samenvoeging van meerdere gerelateerde alerts uit verschillende Defender-services tot één aanvalsscenario |
| Attack story | Visuele tijdlijn in de Defender portal die de volledige aanvalsketen toont inclusief betrokken entiteiten |
| Automated Investigation and Response (AIR) | Defender XDR onderzoekt alerts automatisch, verzamelt bewijs en stelt remediatie-acties voor zonder handmatige tussenkomst |
| Attack Simulation Training | Gesimuleerde phishing-aanvallen op eigen medewerkers; koppelt automatisch security awareness-trainingen aan gebruikers die klikken |
| Microsoft Secure Score | Gecombineerde beveiligingsscore over Entra ID, Devices, Apps en Data — verhogen via aanbevolen verbeteracties |
| Exposure Management | Dashboard voor aanvalspositiebeheer; toont aanvalspaden, kritieke assets en verbeteropties naast Secure Score |
| Defender for Endpoint (MDE) | Endpoint-beveiligingsoplossing met EDR, antivirus, ASR-regels, Advanced Hunting en vulnerability management |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Open het **Microsoft Defender XDR-portal** (security.microsoft.com) |
| **SSW-W11-01** | Onboard W11-01 naar Defender for Endpoint via Intune-policy |
| **SSW-W11-01** | Simuleer verdachte activiteit: download het EICAR-testbestand → controleer alert |
| **SSW-MGMT01** | Analyseer het incident in de Defender portal → bekijk de *Attack story*-grafiek |
| **SSW-MGMT01** | Bekijk het **Exposure Management**-dashboard → controleer de Microsoft Secure Score |
| **SSW-MGMT01** | Voer *Attack Simulation Training* uit → phishing-simulatie naar TestUser01 |
| **SSW-MGMT01** | Analyseer *Secure Score* → kies een verbeteractie en implementeer deze |

### Kennischeck
1. Wat is het verschil tussen Defender for Office 365 Plan 1 en Plan 2?
2. Hoe werkt *Automated Investigation and Response* (AIR) in Defender?
3. Wat toont de *Threat Explorer* en wanneer gebruik je het?
4. Hoe verhoog je de Microsoft Secure Score effectief?
5. Wat is *Exposure Management* en hoe verhoudt het zich tot Secure Score?

<details>
<summary>Antwoorden</summary>

1. **Defender for Office 365 Plan 1:** bevat Safe Attachments, Safe Links, anti-phishing met impersonation protection en Spoof Intelligence. Gericht op preventie. **Plan 2:** bevat alles uit Plan 1, plus: Threat Explorer (real-time e-mailonderzoek), Attack Simulation Training, Automated Investigation & Response (AIR) voor e-mail, Campaign Views en geavanceerde hunting. Plan 2 is inbegrepen in Microsoft 365 E5. Plan 1 in Microsoft 365 Business Premium.

2. **AIR (Automated Investigation and Response):** bij een hoog-ernstige alert (bijv. kwaadaardige bijlage geopend door gebruiker) start Defender automatisch een onderzoek. Het analyseert: welke bestanden zijn geraakt, welke gebruikers zijn betrokken, zijn er gerelateerde e-mails, is er laterale beweging? AIR verzamelt bewijsstukken en stelt geautomatiseerde remediatie-acties voor (bijv. quarantaine van e-mails, isolatie van apparaat). Beheerder goedkeurt of weigert via het Action Center. Doel: snellere respons met minder handmatig werk.

3. **Threat Explorer** (security.microsoft.com → Email & collaboration → Explorer) toont real-time een overzicht van e-mailbedreigingen in de tenant: welke berichten zijn als malware/phishing gedetecteerd, afzenderinformatie, bezorgstatus, toegepaste acties. Gebruik het voor: onderzoek van specifieke phishing-campagnes, vinden van berichten die aan meerdere gebruikers zijn verstuurd, handmatig in quarantaine plaatsen van berichten, analyseren van URL-klikken.

4. Microsoft Secure Score verhogen: (1) Ga naar security.microsoft.com → Secure Score → Recommended actions; (2) Filter op "Quick wins" (lage inspanning, hoog effect); (3) Voer verbeteracties uit zoals: MFA inschakelen voor alle gebruikers, legacy-authenticatieprotocollen blokkeren via CA, DKIM en DMARC inschakelen, PIM inschakelen voor beheerdersrollen; (4) Sommige acties hebben een vertraging van 24–48 uur voor scoreverwerking. Prioriteer acties met het hoogste puntenaantal die haalbaar zijn in jouw omgeving.

5. **Microsoft Secure Score** meet de huidige beveiligingshouding op basis van configuratieacties (MFA, CA-policies, enz.) — een percentage van het maximaal haalbare. **Exposure Management** gaat verder: het toont aanvalspaden (hoe een aanvaller van een gewoon account naar een kritiek systeem kan bewegen), kritieke assets (welke systemen het meest waardevol zijn voor een aanvaller) en blootstellingsgraad per categorie. Exposure Management helpt te prioriteren op basis van risico in plaats van configuratiepunten.

</details>

---

## Week 7 — Microsoft Purview Compliance
> **Examendomein:** Compliance beheren via Microsoft Purview · **Gewicht:** 10–15%

### Leerdoelen
- [ ] Sensitivity labels aanmaken, configureren met encryptie en publiceren via een labelbeleid
- [ ] Een DLP-policy maken die BSN-nummers detecteert en verzenden blokkeert
- [ ] Het verschil uitleggen tussen sensitivity labels en retention labels
- [ ] Een eDiscovery Core-zoekopdracht uitvoeren en resultaten exporteren
- [ ] Endpoint DLP beschrijven en onderscheiden van Exchange- en SharePoint-DLP
- [ ] Communication Compliance beschrijven en de toepassingsscenario's benoemen

### MS Learn modules
- [Implement Microsoft Purview Information Protection](https://learn.microsoft.com/en-us/training/modules/implement-information-protection/)
- [Implement data loss prevention](https://learn.microsoft.com/en-us/training/modules/implement-data-loss-prevention/)
- [Manage Microsoft Purview eDiscovery](https://learn.microsoft.com/en-us/training/modules/manage-ediscovery/)

### Kernbegrippen
| Begriff | Uitleg |
|---------|--------|
| Sensitivity label | Classificatietag (bijv. Vertrouwelijk, Strikt Vertrouwelijk) die encryptie, visuele markering en toegangsrechten afdwingt |
| Retention label | Label op item-niveau dat een specifieke bewaar- of verwijdertijdlijn instelt; kan een item als juridisch record declareren |
| Retention policy | Automatisch bewaarbeleid op locatieniveau (bijv. alle Exchange-mailboxen 5 jaar bewaren); overschrijft geen retention labels |
| DLP-policy | Detecteert gevoelige informatie (BSN, creditcard, paspoort) in content en neemt actie: blokkeren, waarschuwen, auditloggen |
| Sensitive Information Type (SIT) | Patroon (regex + bevestiging) dat gevoelige gegevens herkent, bijv. "Dutch Citizen Service Number (BSN)" |
| Endpoint DLP | DLP-policy die ook werkt op Windows-apparaten (geïntegreerd met MDE): blokkeert kopiëren naar USB, uploaden naar niet-zakelijke websites |
| eDiscovery Core | Basiszoekopdrachten en holds op Exchange/SharePoint/Teams; resultaten exporteerbaar voor juridisch onderzoek |
| eDiscovery Premium | Uitgebreide juridische workflow met custodians, review sets, near-duplicate detectie en AI-tagging |
| Communication Compliance | Scant e-mail en Teams-berichten op overtredingen (ongepaste taal, vertrouwelijke data) voor regulatoire compliance |

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Open **Microsoft Purview portal** (compliance.microsoft.com) |
| **SSW-MGMT01** | Maak een *sensitivity label* aan: "Vertrouwelijk - Intern" met encryptie |
| **SSW-W11-01** | Pas het label toe op een Word-document → verifieer encryptie |
| **SSW-MGMT01** | Maak een *DLP-policy* aan: blokkeer verzenden van BSN-nummers via mail |
| **SSW-W11-01** | Test de DLP-policy: stuur mail met fictief BSN → controleer blokkering |
| **SSW-MGMT01** | Voer een *eDiscovery Core* zoekopdracht uit op TestUser01-mailbox |

### Kennischeck
1. Wat is het verschil tussen *sensitivity labels* en *retention labels*?
2. Hoe werkt *DLP endpoint protection* op managed devices?
3. Wat is *Communication Compliance* en wanneer is het verplicht?
4. Wat is het verschil tussen *Core eDiscovery* en *eDiscovery Premium*?

<details>
<summary>Antwoorden</summary>

1. **Sensitivity labels** beschermen content op basis van vertrouwelijkheidsclassificatie: ze voegen encryptie, visuele markeringen (header/footer/watermerk) en toegangsbeperkingen toe aan bestanden en e-mails. Ze zijn gericht op informatiebeveiliging. **Retention labels** sturen de levenscyclus van content: hoe lang moet iets bewaard worden, wanneer mag het worden verwijderd, en moet een menselijke reviewer het verwijderen goedkeuren (disposition review)? Ze zijn gericht op compliance en records management. Een bestand kan zowel een sensitivity label als een retention label hebben.

2. **Endpoint DLP** vereist dat Windows-apparaten zijn geregistreerd in Microsoft Defender for Endpoint (MDE). De DLP-policy detecteert gevoelige informatie bij acties zoals: kopiëren naar een USB-stick, uploaden naar een niet-zakelijke cloudservice, afdrukken, of kopiëren naar het klembord. Acties: blokkeren, blokkeren met override (gebruiker kan reden opgeven), of alleen auditloggen. Geconfigureerd in Purview onder DLP → Endpoint-locatie. Vereist Windows 10/11 met MDE-sensor.

3. **Communication Compliance** scant intern communicatieverkeer (Exchange e-mail, Teams-berichten, Teams-chats) op overtredingen van een geconfigureerd beleid, zoals: ongepaste of beledigende taal, blootstelling van vertrouwelijke of gevoelige informatie, of overtreding van regulatoire vereisten (bijv. financiële sector). Het is **verplicht** voor organisaties die onder financiële regelgeving vallen (bijv. MiFID II, FINRA) die communicatiemonitoring vereist. In andere sectoren is het optioneel maar aanbevolen voor risicobeheersing.

4. **Core eDiscovery:** basisfunctionaliteit voor juridisch onderzoek — zoekopdrachten op Exchange, SharePoint, Teams, OneDrive, resultaten exporteren als PST of bestandsmap, en Holds plaatsen op mailboxen/sites (voorkomt verwijdering tijdens onderzoek). Geschikt voor kleinere onderzoeken. **eDiscovery Premium:** geavanceerde workflow voor grote juridische onderzoeken — beheer van meerdere custodianen (bewaarders), review sets met samenwerking van juridische teams, AI-gestuurde analyse (near-duplicate clustering, e-mail threading, relevantiemodellen), stapsgewijs exporteren en volledige keten-van-bewaring-documentatie. Vereist Microsoft 365 E5 of E5 Compliance add-on.

</details>

---

### Exam Coverage Gaps en Must-Do Labs

Doel: de resterende exam-gaten sluiten met gerichte praktijkopdrachten.

### Nog expliciet af te dekken
1. Service Health, Network connectivity insights en tenant operationele monitoring.
2. Group-based licensing en bulk user management via PowerShell.
3. Defender for Cloud Apps onderdelen, inclusief Cloud Discovery en app connectoren.
4. Purview retentiebeleid en retentielabels naast sensitivity labels.

### Must-do labs voor slaagkans
1. Configureer Service Health notificaties en leg vast welke signalen actie vereisen.
2. Implementeer group-based licensing op een testgroep en valideer automatische toekenning.
3. Koppel Defender for Cloud Apps aan Microsoft 365 en analyseer activity log events.
4. Maak 1 retention policy en 1 retention label policy en vergelijk gedrag met sensitivity labels.
5. Oefen 3 complete incidentflows in Defender XDR: alert, triage, containment, rapportage.

### Exit criteria voordat je examen plant
1. Je kunt per MS-102 domein ten minste 2 concrete beheeracties live demonstreren.
2. Je beheerst tenant, identity, security en compliance zonder script-voorleeswerk.
3. Je hebt practice assessment scores die consistent examgereed zijn.

---

## Week 8 — Examenvoorbereiding

### Activiteiten
- Herhaal zwakke domeinen op basis van het [officiële examenstudiegids](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/ms-102)
- Doe de **Microsoft Learn oefenassessment** MS-102: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Herhaal Azure AD Connect sync, Defender-incidenten en Purview-labels
- Oefen PowerShell: MgGraph module (`Connect-MgGraph`), Exchange Online module
- Plan je examen via Pearson VUE

### Aandachtspunten voor het examen
- Hybride identiteit: ken zowel **Connect Sync** als **Entra Cloud Sync** — verschillen en migratiescenario's
- **Defender XDR (30–35%):** unified portal, AIR, Exposure Management, Attack Simulation, Secure Score
- DLP: verschil tussen policies voor Exchange, SharePoint en Endpoint
- **Purview (10–15%):** retentie vs. sensitivity labels — ken de kernscenario's
- PIM: eligible vs. active vs. permanent rolassignments vallen nu onder MS-102 scope
- Entra Password Protection en Connect Health zijn nu expliciete examendoelstellingen
