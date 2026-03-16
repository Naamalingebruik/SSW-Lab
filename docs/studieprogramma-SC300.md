# Studieprogramma SC-300 — Identity and Access Administrator

> 🌐 **Taal:** Nederlands | [English](study-guide-SC300.md)

**Duur:** 7 weken · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02)  
**MS Learn pad:** [Identity and Access Administrator](https://learn.microsoft.com/en-us/credentials/certifications/exams/sc-300/)  
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

> **Nieuw per november 2025:** *Implement Global Secure Access* is toegevoegd aan het examen (vervangt deels de Azure RBAC voor resources scope). SSW-Lab-scripts dekken dit onderdeel nog niet — raadpleeg de [MS Learn module](https://learn.microsoft.com/en-us/training/modules/deploy-configure-microsoft-entra-global-secure-access/) als zelfstandige voorbereiding.

---

## Week 1 — Entra ID fundamenten en hybride identiteit

### MS Learn modules
- [Implement initial configuration of Microsoft Entra ID](https://learn.microsoft.com/en-us/training/modules/implement-initial-configuration-azure-active-directory/)
- [Create, configure, and manage identities](https://learn.microsoft.com/en-us/training/modules/create-configure-manage-identities/)
- [Implement and manage hybrid identity](https://learn.microsoft.com/en-us/training/modules/implement-manage-hybrid-identity/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-DC01** | Verifieer AD-structuur: `Get-ADForest`, `Get-ADDomain`, `Get-ADUser -Filter *` |
| **SSW-DC01** | Installeer Azure AD Connect Sync → configureer *Password Hash Sync* |
| **SSW-DC01** | Controleer sync: `Start-ADSyncSyncCycle -PolicyType Delta` |
| **SSW-MGMT01** | Open **Entra admin center** (entra.microsoft.com) → verifieer sync-status |
| **SSW-MGMT01** | Configureer *Custom Security Attributes* voor gebruikersclassificatie |
| **SSW-MGMT01** | Bekijk *Audit logs* in Entra ID → filter op gebruikers-aanmaak events |

### Kennischeck
1. Wat zijn de drie authenticatiemethoden bij hybride identiteit en wanneer gebruik je welke?
2. Hoe werkt *Seamless SSO* en welke Kerberos-component is betrokken?
3. Wat is het verschil tussen *soft delete* en *hard delete* van een Entra ID-gebruiker?
4. Hoe configureer je *password writeback* en waarom is het nodig voor SSPR?

---

## Week 2 — Externe identiteiten en Entra B2B

### MS Learn modules
- [Implement and manage external identities](https://learn.microsoft.com/en-us/training/modules/implement-manage-external-identities/)
- [Implement and manage Microsoft Entra ID Protection](https://learn.microsoft.com/en-us/training/modules/implement-manage-azure-ad-identity-protection/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Nodig een externe B2B-gebruiker uit (gebruik een persoonlijk of second tenant-account) |
| **SSW-MGMT01** | Configureer *Cross-tenant access settings*: blokkeer inbound access voor specifieke tenants |
| **SSW-MGMT01** | Schakel *Entra ID Protection* in → bekijk *Risk detections* dashboard |
| **SSW-MGMT01** | Configureer *User risk policy*: hoog risico → wachtwoordwijziging verplicht |
| **SSW-MGMT01** | Configureer *Sign-in risk policy*: medium risico → MFA verplicht |
| **SSW-W11-01** | Simuleer risky sign-in: log in met TestUser01 vanuit anonieme browser-sessie |

### Kennischeck
1. Wat is het verschil tussen *B2B direct connect* en *B2B collaboration*?
2. Hoe werkt *Identity Protection* — welke signalen gebruikt het voor risicoscores?
3. Wat is een *risky user* versus een *risky sign-in*? Hoe remedieer je elk?
4. Wat doet een *Conditional Access policy op basis van user risk*?

---

## Week 3 — Authenticatiemethoden en MFA

### MS Learn modules
- [Plan and implement multifactor authentication](https://learn.microsoft.com/en-us/training/modules/plan-implement-administer-multi-factor-authentication/)
- [Implement passwordless authentication](https://learn.microsoft.com/en-us/training/modules/implement-authentication-by-using-microsoft-entra-id/)
- [Manage user authentication](https://learn.microsoft.com/en-us/training/modules/manage-user-authentication/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Open **Entra → Security → Authentication methods** → activeer FIDO2 en Authenticator |
| **SSW-W11-01** | Registreer *Microsoft Authenticator* als MFA-methode voor TestUser01 |
| **SSW-W11-01** | Registreer *Windows Hello for Business* op W11-01 |
| **SSW-MGMT01** | Configureer *Authentication strength* in Conditional Access: Phishing-resistant MFA |
| **SSW-MGMT01** | Bekijk *Authentication methods activity* report → analyseer methode-gebruik |
| **SSW-MGMT01** | Schakel *legacy per-user MFA* uit → migreer naar Conditional Access-based MFA |

### Kennischeck
1. Wat is *phishing-resistant MFA* en welke methoden vallen hieronder?
2. Hoe werkt *Windows Hello for Business* in hybride omgeving?
3. Wat is het verschil tussen *Authentication methods policy* en *legacy MFA-instellingen*?
4. Wanneer gebruik je *Temporary Access Pass (TAP)*?

---

## Week 4 — Conditional Access en Global Secure Access

### MS Learn modules
- [Plan, implement, and administer Conditional Access](https://learn.microsoft.com/en-us/training/modules/plan-implement-administer-conditional-access/)
- [Implement Conditional Access for cloud app access](https://learn.microsoft.com/en-us/training/modules/implement-conditional-access-cloud-app-protection/)
- [Implement Global Secure Access](https://learn.microsoft.com/en-us/training/modules/implement-global-secure-access/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Maak CA-policy: blokkeer toegang tot alle apps van buiten compliance-devices |
| **SSW-MGMT01** | Maak CA-policy: MFA verplicht voor beheerderrollen bij elke sign-in |
| **SSW-MGMT01** | Gebruik *What If* tool in CA om access-beslissingen te simuleren |
| **SSW-W11-01** | Test CA-policy als TestUser01 → verifieer welke controls worden afgedwongen |
| **SSW-W11-02** | Test met niet-enrolled device → verifieer blokkering |
| **SSW-MGMT01** | Schakel *Sign-in frequency* in voor gevoelige applicaties (elke 4 uur re-auth) |
| **SSW-MGMT01** | Bekijk **CA insights and reporting** workbook in Entra ID |
| **SSW-MGMT01** | Open **Global Secure Access** in het Entra admin center → verken Private Access en Internet Access-instellingen |
| **SSW-MGMT01** | Schakel *Internet Access voor Microsoft 365* in via Global Secure Access → bekijk verkeerslogboeken |

### Kennischeck
1. Wat is het verschil tussen *Block* en *Grant with MFA* in Conditional Access?
2. Hoe werkt *Named Locations* en wanneer gebruik je *compliant network*?
3. Wat zijn *Authentication contexts* en wanneer gebruik je ze?
4. Hoe voorkom je *lock-out* bij CA-migratie in productie?
5. Wat is *Global Secure Access* en wat zijn de drie verkeersprofielen (Private, Internet, M365)?
6. Wat is het verschil tussen *Private Access* en een traditionele VPN?

---

## Week 5 — Applicatietoegang en app registraties

### MS Learn modules
- [Manage and implement application access in Azure AD](https://learn.microsoft.com/en-us/training/modules/manage-implement-application-access/)
- [Implement app registrations](https://learn.microsoft.com/en-us/training/modules/implement-app-registrations/)
- [Integrate single sign-on in Microsoft Entra ID](https://learn.microsoft.com/en-us/training/modules/authenticate-external-apps/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Registreer een test-app in **Entra → App registrations** |
| **SSW-MGMT01** | Voeg *API permissions* toe: `User.Read` en `Mail.Read` → admin consent verlenen |
| **SSW-MGMT01** | Maak een *client secret* aan → noteer de waarde |
| **SSW-MGMT01** | Configureer SSO voor een gallery-app (bijv. GitHub) via *Enterprise applications* |
| **SSW-MGMT01** | Configureer *App proxy* voor een on-premises app (gebruik MGMT01 als testserver) |
| **SSW-MGMT01** | Wijs de app toe aan een groep → bekijk toegang in *My Apps* portal |

### Kennischeck
1. Wat is het verschil tussen een *App registration* en een *Enterprise application*?
2. Hoe werkt OAuth 2.0 *authorization code flow* in het kort?
3. Wat is een *managed identity* en wanneer gebruik je system-assigned versus user-assigned?
4. Wat doet *application proxy* en welke ports heeft het nodig?

---

## Week 6 — Identity governance: Entitlement en Access Reviews

### MS Learn modules
- [Plan and implement entitlement management](https://learn.microsoft.com/en-us/training/modules/plan-implement-entitlement-management/)
- [Plan, implement, and manage access reviews](https://learn.microsoft.com/en-us/training/modules/plan-implement-manage-access-review/)
- [Implement Privileged Identity Management](https://learn.microsoft.com/en-us/training/modules/implement-privileged-identity-management/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Maak een *Access package* aan via **Entra → Identity Governance → Entitlement management** |
| **SSW-MGMT01** | Configureer *policy*: gebruikers kunnen zelf toegang aanvragen, manager moet goedkeuren |
| **SSW-W11-01** | Vraag het Access package aan als TestUser01 via *My Access* portal (`myaccess.microsoft.com`) |
| **SSW-MGMT01** | Keur de aanvraag goed → verifieer toewijzing |
| **SSW-MGMT01** | Maak een *Access review* aan voor een groep → wijs reviewer aan |
| **SSW-MGMT01** | Activeer **Privileged Identity Management (PIM)** voor de rol *Global Administrator* |
| **SSW-MGMT01** | Activeer de GA-rol *Just-in-time* via PIM → verifieer audit trail |

### Kennischeck
1. Wat is het verschil tussen *entitlement management* en *access reviews*?
2. Hoe werkt PIM *Just-in-Time access* en waarom is het beter dan permanente roltowijzing?
3. Wat zijn *lifecycle workflows* in Identity Governance?
4. Hoe configureer je *separation of duties* via incompatible access packages?

---

## Week 7 — Examenvoorbereiding

### Activiteiten
- Herhaal zwakke domeinen op basis van het [officiële examenprofiel](https://learn.microsoft.com/en-us/certifications/exams/sc-300/)
- Doe de **Microsoft Learn oefenassessment** SC-300: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Herhaal PIM-configuratie, CA What-If scenario's en entitlement management
- Maak een overzicht van alle Identity Protection risicotypes en remediation-stappen
- Plan je examen via Pearson VUE

### Aandachtspunten voor het examen
- **Domeingewichten gewijzigd:** gebruikersidentiteiten 20–25%, workload-identiteiten 20–25%, governance 20–25%
- **Global Secure Access** is een nieuw examenonderwerp — ken Private Access, Internet Access en M365-profielen
- Azure RBAC voor resources („Implement access management for Azure resources”) is **verwijderd** uit SC-300
- Conditional Access: *What If* scenario’s, authentication strength, continuous access evaluation en protected actions
- PIM: weet het verschil tussen eligible, active en permanent assignments
- Identity governance: entitlement management vs. access reviews vs. lifecycle workflows
- B2B: cross-tenant access settings, cross-tenant synchronization en external collaboration instellingen
- App registrations: ken het verschil delegated vs. application API permissions; managed identities (system vs. user-assigned)
- Identity monitoring: KQL-query’s in Log Analytics, Identity Secure Score
