# Studieprogramma MD-102 — Endpoint Administrator

> 🌐 **Taal:** Nederlands | [English](study-guide-MD102.md)

**Duur:** 7 weken · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02) + W11-AUTOPILOT voor week 5  
**MS Learn pad:** [Endpoint Administrator](https://learn.microsoft.com/en-us/certifications/exams/md-102/)  
**Examengewicht:**

| Domein | Gewicht |
|---|---|
| Windows client deployen en upgraden | 15–20% |
| Identiteit en compliance beheren | 15–20% |
| Devices beheren, onderhouden en beveiligen | 40–45% |
| Applicaties beheren | 25–30% |

> **Voorwaarde:** MSDN/Visual Studio-subscriptie met Microsoft 365 E5/E3 developer tenant (voor Intune, Entra ID)

---

## Week 1 — Windows client deployment

### MS Learn modules
- [Deploy Windows 11](https://learn.microsoft.com/en-us/training/modules/deploy-windows-client/)
- [Upgrade Windows client](https://learn.microsoft.com/en-us/training/modules/upgrade-windows-client/)
- [Windows Deployment Services en imaging](https://learn.microsoft.com/en-us/training/modules/configure-windows-deployment-services/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-DC01** | Controleer domain `ssw.lab` — voer `Get-ADDomain` uit in PowerShell |
| **SSW-MGMT01** | Installeer Windows ADK + Deployment Tools via `02-MAKE-ISOS.ps1` |
| **SSW-W11-01** | Verifieer Windows 11 versie: `winver` → noteer build nummer |
| **SSW-W11-01** | Voer in-place upgrade-simulatie uit: `Get-WindowsUpdateLog` analyseren |
| **SSW-MGMT01** | Maak een antwoord-bestand aan met Windows System Image Manager (SIM) |

### Kennischeck
1. Wat is het verschil tussen een *wipe-and-load* en een *in-place upgrade*?
2. Welke minimale build heeft Windows 11 nodig voor Intune-enrollment?
3. Wat doet `oscdimg.exe` en waarom is het nodig voor unattended deployments?
4. Wanneer gebruik je DISM versus sysprep?

---

## Week 2 — Intune enrollment en device management

### MS Learn modules
- [Enroll devices in Microsoft Intune](https://learn.microsoft.com/en-us/training/modules/enroll-devices/)
- [Manage device profiles with Intune](https://learn.microsoft.com/en-us/training/modules/manage-device-profiles/)
- [Monitor devices with Intune](https://learn.microsoft.com/en-us/training/modules/monitor-devices-microsoft-intune/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-W11-01** | Enroll device in Intune via **Instellingen → Accounts → Werk of school** |
| **SSW-W11-02** | Enroll second device — observeer verschil in Intune-portal |
| **SSW-MGMT01** | Open Intune-portal (intune.microsoft.com) → controleer beide devices onder **Devices → All devices** |
| **SSW-MGMT01** | Maak een *Configuration profile* aan: BitLocker enforced op W11-01 |
| **SSW-W11-01** | Verifieer BitLocker-status: `manage-bde -status` |
| **SSW-MGMT01** | Bekijk **Device compliance** — maak een compliance policy aan (minimale OS-versie) |

### Kennischeck
1. Wat is het verschil tussen MDM-enrollment en Hybrid Azure AD Join?
2. Welke enrollment-methodes bestaan in Intune en wanneer gebruik je welke?
3. Wat betekent een *Compliant* versus *Not compliant* status in Intune?
4. Hoe werkt de *Enrollment Status Page* bij Autopilot?

---

## Week 3 — Compliance, Conditional Access en identiteit

### MS Learn modules
- [Configure device compliance policies](https://learn.microsoft.com/en-us/training/modules/configure-device-compliance-policies/)
- [Configure Conditional Access](https://learn.microsoft.com/en-us/training/modules/configure-conditional-access/)
- [Manage user and device identities](https://learn.microsoft.com/en-us/training/modules/manage-user-device-identities/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-DC01** | Maak test-gebruikers aan in AD: `New-ADUser -Name "TestUser01" ...` |
| **SSW-DC01** | Sync AD naar Entra ID via Azure AD Connect (installeer op DC01) |
| **SSW-MGMT01** | Configureer een Conditional Access-policy: MFA verplicht buiten het bedrijfsnetwerk |
| **SSW-W11-01** | Test de CA-policy: log in met TestUser01, verifieer MFA-prompt |
| **SSW-MGMT01** | Maak een compliance policy: vereist Defender, BitLocker, en min. W11 22H2 |
| **SSW-W11-02** | Demonstreer niet-compliant device → controleer block in CA-policy |

### Kennischeck
1. Welke signalen gebruikt Conditional Access voor een access-beslissing?
2. Wat is het verschil between *Block* en *Grant with controls* in CA?
3. Hoe verhoudt Azure AD Connect Sync zich tot Cloud Sync?
4. Wat doet de *Named Locations* instelling in CA?

---

## Week 4 — Applicatiebeheer met Intune

### MS Learn modules
- [Deploy and update applications with Intune](https://learn.microsoft.com/en-us/training/modules/deploy-applications/)
- [Manage Win32 apps with Intune](https://learn.microsoft.com/en-us/training/modules/manage-win32-apps/)
- [Configure Microsoft 365 Apps deployment](https://learn.microsoft.com/en-us/training/modules/configure-microsoft-365-apps/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Pak een `.exe` app in als `.intunewin` met de **Intune Win32 Content Prep Tool** |
| **SSW-MGMT01** | Upload de Win32 app naar Intune → assign aan W11-01 (Required) |
| **SSW-W11-01** | Controleer installatie via **Company Portal** of eventlog (`IntuneManagementExtension`) |
| **SSW-MGMT01** | Maak een Microsoft 365 Apps deployment aan via Intune (Office-suite) |
| **SSW-W11-02** | Verifieer Office-installatie na sync (`imdssync` of wacht op Intune check-in) |
| **SSW-MGMT01** | Configureer een *App protection policy* (MAM) voor Microsoft Edge |

### Kennischeck
1. Wat is het verschil tussen een *Required* en *Available* app-assignment?
2. Wanneer gebruik je Win32 app packaging versus Microsoft Store for Business?
3. Wat doet de `IntuneManagementExtension.log` en waar staat die?
4. Wat zijn de voordelen van MAM zonder MDM-enrollment?

---

## Week 5 — Windows Autopilot

### MS Learn modules
- [Configure Windows Autopilot](https://learn.microsoft.com/en-us/training/modules/configure-windows-autopilot/)
- [Autopilot deployment scenarios](https://learn.microsoft.com/en-us/training/modules/windows-autopilot-deployment-scenarios/)
- [Troubleshoot Windows Autopilot](https://learn.microsoft.com/en-us/training/modules/troubleshoot-windows-autopilot/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-W11-AUTOPILOT** | Haal hardware hash op: `Get-WindowsAutoPilotInfo -OutputFile hash.csv` |
| **SSW-MGMT01** | Upload hash naar Intune: **Devices → Windows → Enrollment → Windows Autopilot devices** |
| **SSW-MGMT01** | Maak een Autopilot deployment profile aan: *User-driven, Azure AD join* |
| **SSW-W11-AUTOPILOT** | Reset de VM (Instellingen → Systeem → Herstel → Reset deze pc) |
| **SSW-W11-AUTOPILOT** | Doorloop de Out-of-Box Experience (OOBE) → verifieer automatische enrollment |
| **SSW-MGMT01** | Analyseer de Autopilot-events in **Event Viewer → Applications and Services → Microsoft → Windows → Autopilot** |

### Kennischeck
1. Wat is het verschil tussen *User-driven* en *Self-deploying* Autopilot mode?
2. Waarvoor dient de *Enrollment Status Page* en hoe configureer je 'm?
3. Hoe reset je een Autopilot-profiel toewijzing als een device al geregistreerd is?
4. Wat is *Windows Autopilot Reset* en wanneer gebruik je het?

---

## Week 6 — Security, updates en monitoring

### MS Learn modules
- [Manage endpoint security with Intune](https://learn.microsoft.com/en-us/training/modules/manage-endpoint-security/)
- [Manage Windows updates with Intune](https://learn.microsoft.com/en-us/training/modules/manage-windows-updates-intune/)
- [Monitor and troubleshoot devices](https://learn.microsoft.com/en-us/training/modules/monitor-troubleshoot-devices/)

### Lab oefeningen (SSW-Lab)
| VM | Taak |
|---|---|
| **SSW-MGMT01** | Configureer een *Update ring* in Intune: Semi-Annual Channel, 7 dagen defer |
| **SSW-W11-01** | Controleer Windows Update-status: `Get-WindowsUpdateLog` |
| **SSW-MGMT01** | Activeer Microsoft Defender for Endpoint via Intune *Endpoint security → Antivirus* |
| **SSW-W11-01** | Voer een Defender Quick Scan uit: `Start-MpScan -ScanType QuickScan` |
| **SSW-W11-02** | Simuleer een detectie met EICAR testbestand → analyseer alert in Defender portal |
| **SSW-MGMT01** | Bekijk **Device diagnostics** in Intune-portal → download diagnostics van W11-01 |

### Kennischeck
1. Wat is het verschil tussen een *Update ring* en een *Feature update policy*?
2. Hoe werkt *Co-management* tussen Intune en Configuration Manager?
3. Wat toont het **Endpoint analytics** dashboard in Intune?
4. Hoe gebruik je *Remote actions* (wipe, retire, sync) in Intune?

---

## Week 7 — Examenvoorbereiding

### Activiteiten
- Herhaal zwakke domeinen op basis van het [officiële examenprofiel](https://learn.microsoft.com/en-us/certifications/exams/md-102/)
- Doe de **Microsoft Learn oefenassessment** MD-102: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Herhaal lab-taken die je minder zeker voelde (week 2 Intune enrollment, week 5 Autopilot)
- Maak een samenvatting van alle PowerShell-commando's uit de lab-oefeningen
- Plan je examen via Pearson VUE of Certiport

### Aandachtspunten voor het examen
- Intune enrollment-methoden en wanneer je welke kiest
- Conditional Access: scenario-vragen zijn het meest voorkomend
- Autopilot: ken alle deployment modes en reset procedures
- App beheer: verschil tussen Win32, LOB, Store en M365 Apps
