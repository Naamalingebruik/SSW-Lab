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

---

## Week 1 — Microsoft 365 tenant inrichten

### MS Learn modules
- [Explore your Microsoft 365 cloud environment](https://learn.microsoft.com/en-us/training/modules/explore-microsoft-365-cloud-environment/)
- [Configure your Microsoft 365 experience](https://learn.microsoft.com/en-us/training/modules/configure-microsoft-365-experience/)
- [Manage Microsoft 365 tenants](https://learn.microsoft.com/en-us/training/modules/manage-your-microsoft-365-tenant/)

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

---

## Week 2 — Gebruikers- en groepsbeheer

### MS Learn modules
- [Manage users and groups in Microsoft 365](https://learn.microsoft.com/en-us/training/modules/manage-users-and-groups-in-microsoft-365/)
- [Manage admin roles in Microsoft 365](https://learn.microsoft.com/en-us/training/modules/manage-admin-roles/)
- [Manage password policies](https://learn.microsoft.com/en-us/training/modules/manage-password-policies/)

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

---

## Week 3 — Entra ID en hybride identiteit

### MS Learn modules
- [Manage identity synchronization with Azure AD Connect and Entra Cloud Sync](https://learn.microsoft.com/en-us/training/modules/manage-azure-active-directory-connect/)
- [Implement multifactor authentication](https://learn.microsoft.com/en-us/training/modules/implement-multifactor-authentication/)
- [Manage external identities](https://learn.microsoft.com/en-us/training/modules/manage-external-identities/)

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

---

## Week 4 — Exchange Online beheer

### MS Learn modules
- [Manage Exchange Online recipients and permissions](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-recipients/)
- [Manage Exchange Online mail flow](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-mail-flow/)
- [Manage Exchange Online protection](https://learn.microsoft.com/en-us/training/modules/manage-exchange-online-protection/)

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

---

## Week 5 — SharePoint Online en Microsoft Teams

### MS Learn modules
- [Manage SharePoint Online](https://learn.microsoft.com/en-us/training/modules/manage-sharepoint-online/)
- [Manage Microsoft Teams](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-teams/)
- [Manage Teams collaboration settings](https://learn.microsoft.com/en-us/training/modules/manage-teams-collaboration-settings/)

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

---

## Week 6 — Microsoft Defender XDR en bedreigingsbeheer

### MS Learn modules
- [Explore the Microsoft Defender XDR portal](https://learn.microsoft.com/en-us/training/modules/explore-microsoft-365-defender/)
- [Manage Microsoft Defender for Office 365](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-defender-office-365/)
- [Manage Microsoft Secure Score and Exposure Management](https://learn.microsoft.com/en-us/training/modules/manage-microsoft-secure-score/)

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

---

## Week 7 — Microsoft Purview Compliance

### MS Learn modules
- [Implement Microsoft Purview Information Protection](https://learn.microsoft.com/en-us/training/modules/implement-information-protection/)
- [Implement data loss prevention](https://learn.microsoft.com/en-us/training/modules/implement-data-loss-prevention/)
- [Manage Microsoft Purview eDiscovery](https://learn.microsoft.com/en-us/training/modules/manage-ediscovery/)

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
