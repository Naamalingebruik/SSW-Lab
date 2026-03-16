# Study Guide MD-102 — Endpoint Administrator

> 🌐 **Language:** English | [Nederlands](studieprogramma-MD102.md)

**Duration:** 7 weeks · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02) + W11-AUTOPILOT for week 5  
**MS Learn path:** [Endpoint Administrator](https://learn.microsoft.com/en-us/certifications/exams/md-102/)  
**Exam weight:**

| Domain | Weight |
|---|---|
| Prepare infrastructure for devices | 25–30% |
| Manage and maintain devices | 30–35% |
| Manage applications | 15–20% |
| Protect devices | 15–20% |

> **Updated:** Skills measured as of January 23, 2026. The domain structure changed significantly — "Deploy and upgrade" and "Manage identity and compliance" merged into **Prepare infrastructure for devices**. "Manage, maintain, and protect" was split into two separate domains.

> **Prerequisite:** MSDN/Visual Studio subscription with Microsoft 365 E5/E3 developer tenant (for Intune, Entra ID)

---

## Week 1 — Windows client deployment

### MS Learn modules
- [Deploy Windows 11](https://learn.microsoft.com/en-us/training/modules/deploy-windows-client/)
- [Upgrade Windows client](https://learn.microsoft.com/en-us/training/modules/upgrade-windows-client/)
- [Windows Deployment Services and imaging](https://learn.microsoft.com/en-us/training/modules/configure-windows-deployment-services/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-DC01** | Verify domain `ssw.lab` — run `Get-ADDomain` in PowerShell |
| **SSW-MGMT01** | Install Windows ADK + Deployment Tools via `02-MAKE-ISOS.ps1` |
| **SSW-W11-01** | Verify Windows 11 version: `winver` → note the build number |
| **SSW-W11-01** | Run in-place upgrade simulation: analyse `Get-WindowsUpdateLog` |
| **SSW-MGMT01** | Create an answer file using Windows System Image Manager (SIM) |

### Knowledge check
1. What is the difference between a *wipe-and-load* and an *in-place upgrade*?
2. What is the minimum build Windows 11 requires for Intune enrollment?
3. What does `oscdimg.exe` do and why is it needed for unattended deployments?
4. When do you use DISM versus sysprep?

---

## Week 2 — Intune enrollment and device management

### MS Learn modules
- [Enroll devices in Microsoft Intune](https://learn.microsoft.com/en-us/training/modules/enroll-devices/)
- [Manage device profiles with Intune](https://learn.microsoft.com/en-us/training/modules/manage-device-profiles/)
- [Monitor devices with Intune](https://learn.microsoft.com/en-us/training/modules/monitor-devices-microsoft-intune/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-W11-01** | Enroll device in Intune via **Settings → Accounts → Work or school** |
| **SSW-W11-02** | Enroll second device — observe the difference in the Intune portal |
| **SSW-MGMT01** | Open Intune portal (intune.microsoft.com) → verify both devices under **Devices → All devices** |
| **SSW-MGMT01** | Create a *Configuration profile*: BitLocker enforced on W11-01 |
| **SSW-W11-01** | Verify BitLocker status: `manage-bde -status` |
| **SSW-MGMT01** | Review **Device compliance** — create a compliance policy (minimum OS version) |

### Knowledge check
1. What is the difference between MDM enrollment and Hybrid Azure AD Join?
2. What enrollment methods exist in Intune and when do you use each?
3. What does a *Compliant* versus *Not compliant* status mean in Intune?
4. How does the *Enrollment Status Page* work in Autopilot?

---

## Week 3 — Compliance, Conditional Access and identity

### MS Learn modules
- [Configure device compliance policies](https://learn.microsoft.com/en-us/training/modules/configure-device-compliance-policies/)
- [Configure Conditional Access](https://learn.microsoft.com/en-us/training/modules/configure-conditional-access/)
- [Manage user and device identities](https://learn.microsoft.com/en-us/training/modules/manage-user-device-identities/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-DC01** | Create test users in AD: `New-ADUser -Name "TestUser01" ...` |
| **SSW-DC01** | Sync AD to Entra ID via Azure AD Connect (install on DC01) |
| **SSW-MGMT01** | Configure a Conditional Access policy: MFA required outside corporate network |
| **SSW-W11-01** | Test the CA policy: sign in as TestUser01, verify MFA prompt |
| **SSW-MGMT01** | Create a compliance policy: requires Defender, BitLocker, and min. W11 22H2 |
| **SSW-W11-02** | Demonstrate non-compliant device → verify block in CA policy |
| **SSW-MGMT01** | Enable **Windows LAPS** in Intune: Endpoint security → Account protection → LAPS policy |
| **SSW-W11-01** | Verify LAPS: retrieve the rotated local admin password via Intune portal |

### Knowledge check
1. What signals does Conditional Access use to make an access decision?
2. What is the difference between *Block* and *Grant with controls* in CA?
3. How does Azure AD Connect Sync compare to Cloud Sync?
4. What does the *Named Locations* setting do in CA?
5. What is *Windows LAPS* and how does it differ from the legacy LAPS solution?

---

## Week 4 — Application management with Intune

### MS Learn modules
- [Deploy and update applications with Intune](https://learn.microsoft.com/en-us/training/modules/deploy-applications/)
- [Manage Win32 apps with Intune](https://learn.microsoft.com/en-us/training/modules/manage-win32-apps/)
- [Configure Microsoft 365 Apps deployment](https://learn.microsoft.com/en-us/training/modules/configure-microsoft-365-apps/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Package a `.exe` app as `.intunewin` using the **Intune Win32 Content Prep Tool** |
| **SSW-MGMT01** | Upload the Win32 app to Intune → assign to W11-01 (Required) |
| **SSW-W11-01** | Verify installation via **Company Portal** or event log (`IntuneManagementExtension`) |
| **SSW-MGMT01** | Create a Microsoft 365 Apps deployment in Intune (Office suite) |
| **SSW-W11-02** | Verify Office installation after sync (`imdssync` or wait for Intune check-in) |
| **SSW-MGMT01** | Configure an *App protection policy* (MAM) for Microsoft Edge |

### Knowledge check
1. What is the difference between a *Required* and *Available* app assignment?
2. When do you use Win32 app packaging versus Microsoft Store for Business?
3. What does `IntuneManagementExtension.log` contain and where is it located?
4. What are the benefits of MAM without MDM enrollment?

---

## Week 5 — Windows Autopilot

### MS Learn modules
- [Configure Windows Autopilot](https://learn.microsoft.com/en-us/training/modules/configure-windows-autopilot/)
- [Autopilot deployment scenarios](https://learn.microsoft.com/en-us/training/modules/windows-autopilot-deployment-scenarios/)
- [Troubleshoot Windows Autopilot](https://learn.microsoft.com/en-us/training/modules/troubleshoot-windows-autopilot/)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-W11-AUTOPILOT** | Gather hardware hash: `Get-WindowsAutoPilotInfo -OutputFile hash.csv` |
| **SSW-MGMT01** | Upload hash to Intune: **Devices → Windows → Enrollment → Windows Autopilot devices** |
| **SSW-MGMT01** | Create an Autopilot deployment profile: *User-driven, Microsoft Entra join* |
| **SSW-W11-AUTOPILOT** | Reset the VM (Settings → System → Recovery → Reset this PC) |
| **SSW-W11-AUTOPILOT** | Walk through the Out-of-Box Experience (OOBE) → verify automatic enrollment |
| **SSW-MGMT01** | Analyse Autopilot events in **Event Viewer → Applications and Services → Microsoft → Windows → Autopilot** |
| **SSW-MGMT01** | Explore *Windows 365* in Intune: review Cloud PC provisioning policies |
| **SSW-MGMT01** | Run a *device query* using KQL: **Devices → select device → Device query** |

### Knowledge check
1. What is the difference between *User-driven* and *Self-deploying* Autopilot mode?
2. What is the *Enrollment Status Page* used for and how do you configure it?
3. How do you reset an Autopilot profile assignment if a device is already registered?
4. What is *Windows Autopilot Reset* and when do you use it?
5. What is *Windows 365* and how does it differ from Azure Virtual Desktop?
6. How do you run a KQL device query in Intune and what data can you retrieve?

---

## Week 6 — Security, updates, Intune Suite and monitoring

### MS Learn modules
- [Manage endpoint security with Intune](https://learn.microsoft.com/en-us/training/modules/manage-endpoint-security/)
- [Manage Windows updates with Intune](https://learn.microsoft.com/en-us/training/modules/manage-windows-updates-intune/)
- [Monitor and troubleshoot devices](https://learn.microsoft.com/en-us/training/modules/monitor-troubleshoot-devices/)
- [Intune Suite add-on capabilities](https://learn.microsoft.com/en-us/mem/intune/fundamentals/intune-add-ons)

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Configure an *Update ring* in Intune: Semi-Annual Channel, 7-day deferral |
| **SSW-W11-01** | Check Windows Update status: `Get-WindowsUpdateLog` |
| **SSW-MGMT01** | Enable Microsoft Defender for Endpoint via Intune *Endpoint security → Antivirus* |
| **SSW-W11-01** | Run a Defender Quick Scan: `Start-MpScan -ScanType QuickScan` |
| **SSW-W11-02** | Simulate a detection with EICAR test file → analyse alert in Defender portal |
| **SSW-MGMT01** | View **Device diagnostics** in Intune portal → download diagnostics from W11-01 |
| **SSW-MGMT01** | Explore *Endpoint Privilege Management* (EPM) in Intune Suite: create an elevation policy |
| **SSW-MGMT01** | Review *Advanced Analytics* in Intune: check anomaly detection dashboard |
| **SSW-MGMT01** | Explore **Enterprise App Catalog**: find a managed app and review its metadata |

### Knowledge check
1. What is the difference between an *Update ring* and a *Feature update policy*?
2. How does *Co-management* work between Intune and Configuration Manager?
3. What does the **Endpoint analytics** dashboard show in Intune?
4. How do you use *Remote actions* (wipe, retire, sync) in Intune?
5. What Intune Suite add-ons exist and what problem does each solve?
6. What is *Endpoint Privilege Management* and when do you use elevation policies?

---

## Week 7 — Exam preparation

### Activities
- Review weak domains based on the [official exam profile](https://learn.microsoft.com/en-us/certifications/exams/md-102/)
- Complete the **Microsoft Learn practice assessment** for MD-102: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Revisit lab tasks you felt less confident about (week 2 Intune enrollment, week 5 Autopilot)
- Create a summary of all PowerShell commands used in the lab exercises
- Schedule your exam via Pearson VUE or Certiport

### Exam focus areas
- **Prepare infrastructure (25–30%):** Entra join types, enrollment methods, compliance policies, Conditional Access, Windows LAPS
- **Manage & maintain devices (30–35%):** Autopilot deployment modes, configuration profiles, Windows 365 vs AVD, KQL device queries, Intune Suite add-ons (EPM, Remote Help, Tunnel for MAM)
- **Manage applications (15–20%):** Win32/LOB/Store/M365 Apps, app protection policies, ODT/OCT, Enterprise App Catalog
- **Protect devices (15–20%):** Security baselines, Defender for Endpoint onboarding, update rings vs feature update policies
