# Study Guide MD-102 — Endpoint Administrator

> 🌐 **Language:** English | [Nederlands](studieprogramma-MD102.md)

**Duration:** 7 weeks · **Lab preset:** Standard (DC01 · MGMT01 · W11-01 · W11-02) + W11-AUTOPILOT for week 5
**MS Learn path:** [Endpoint Administrator](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/md-102)
**Exam weight:**

| Domain | Weight |
|---|---|
| Prepare infrastructure for devices | 25–30% |
| Manage and maintain devices | 30–35% |
| Manage applications | 15–20% |
| Protect devices | 15–20% |

> **Updated:** Skills measured as of January 23, 2026. The domain structure changed significantly — "Deploy and upgrade" and "Manage identity and compliance" merged into **Prepare infrastructure for devices**. "Manage, maintain, and protect" was split into two separate domains.

> **Prerequisite:** MSDN/Visual Studio subscription with Microsoft 365 E5/E3 developer tenant (for Intune, Entra ID)

## How to use this study guide

- Start each week by reading the learning objectives and MS Learn modules so you know which exam scope you are covering before opening the lab.
- Then perform the lab exercises on the listed VMs and write down what you observe in the portal, PowerShell, and on the client devices.
- Complete the knowledge check only after finishing both the theory and the lab; use the answers to identify weak spots in understanding, not just to verify memorisation.
- If you work with both Dutch-speaking and English-speaking colleagues, deliberately keep both terms in mind, for example *compliance policy / compliancebeleid* and *hybrid join / hybride join*.

## Lab coverage and expectations

- **Strong SSW-Lab coverage:** Windows deployment, Intune enrollment, Autopilot fundamentals, configuration profiles, compliance, update management, app deployment, endpoint security, and LAPS.
- **Partial coverage:** co-management, Windows 365, Endpoint Privilege Management, advanced reporting, and some Intune Suite features require extra tenant capabilities or remain partly conceptual in this lab.
- **Not fully reproducible locally:** fast-moving Microsoft UI changes, licence-dependent features, and features only visible in a fully provisioned Microsoft 365 tenant.
- Use this guide as a complete study path, but be honest about the gaps: if a topic feels only partially covered, revisit the matching MS Learn module directly in the portal.

## How to use the knowledge checks

- Answer every question without looking at the solution first.
- Explain your answer out loud as if you are handing over the topic to a colleague.
- Revisit only the questions you missed or answered with uncertainty.
- Pay special attention to scenario questions: the exam often tests whether you can choose the right approach, not just recognise the term.

---

## Week 1 — Windows client deployment
> **Exam domain:** Prepare infrastructure for devices · **Weight:** 25–30%

> **Real-world scenario:** A consultant at a mid-sized financial services firm is tasked with rolling out Windows 11 to 400 desktops currently running Windows 10 21H2. The IT manager wants to preserve existing applications and user profiles but also needs a clean deployment method for 50 new machines arriving from the OEM. The consultant must choose between in-place upgrade and wipe-and-load, prepare answer files for the new hardware, and validate that all devices meet the Windows 11 hardware requirements before the project starts.

### Learning Objectives
- [ ] Identify the minimum hardware requirements for Windows 11 (TPM 2.0, UEFI + Secure Boot, 64 GB storage, 4 GB RAM)
- [ ] Distinguish between wipe-and-load, in-place upgrade, and fresh-start deployment methods and select the right method for a given scenario
- [ ] Explain the role of `autounattend.xml` and how Windows System Image Manager (SIM) is used to create answer files
- [ ] Describe what DISM does versus what Sysprep does, and when each tool is appropriate
- [ ] Explain the purpose of `oscdimg.exe` in creating bootable ISO images for unattended deployments
- [ ] Identify the minimum Windows 11 build number required for Intune MDM enrollment

### MS Learn modules
- [Deploy Windows 11](https://learn.microsoft.com/en-us/training/modules/deploy-windows-client/)
- [Upgrade Windows client](https://learn.microsoft.com/en-us/training/modules/upgrade-windows-client/)
- [Windows Deployment Services and imaging](https://learn.microsoft.com/en-us/training/modules/configure-windows-deployment-services/)

### Key Concepts
| Term | Description |
|------|-------------|
| Wipe-and-load | Replaces the existing OS entirely with a fresh Windows installation; all user data and applications must be migrated separately |
| In-place upgrade | Upgrades Windows while preserving existing apps, settings, and user data; performed using Windows Setup (`setup.exe`) |
| autounattend.xml | An XML answer file placed on installation media that automates Windows Setup responses (language, product key, disk partitioning, etc.) |
| Windows SIM | Windows System Image Manager — the GUI tool for authoring and validating `autounattend.xml` answer files; included with the Windows ADK |
| DISM | Deployment Image Servicing and Management — a command-line tool for mounting, inspecting, and modifying Windows images (`.wim` files) offline |
| Sysprep | System Preparation Tool — generalizes a Windows installation (removes unique identifiers like the SID) so it can be captured as a master image for deployment |
| oscdimg.exe | An ADK command-line tool that creates ISO images from a directory structure; required when you need to produce a bootable, self-contained deployment ISO |
| WinPE | Windows Preinstallation Environment — a minimal Windows environment used to boot a machine for deployment, recovery, or diagnostics before the full OS is installed |

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-DC01** | Verify domain `ssw.lab` — run `Get-ADDomain` in PowerShell |
| **SSW-MGMT01** | Install Windows ADK + Deployment Tools via `02-MAKE-ISOS.ps1` |
| **SSW-W11-01** | Verify Windows 11 version: `winver` → note the build number |
| **SSW-W11-01** | Run in-place upgrade simulation: analyse `Get-WindowsUpdateLog` |
| **SSW-MGMT01** | Create an answer file using Windows System Image Manager (SIM) |

### Lab commands

```powershell
# Check current Windows build number
(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').CurrentBuild

# Mount a WIM image with DISM for offline servicing
dism /Mount-Image /ImageFile:"C:\Images\install.wim" /Index:1 /MountDir:"C:\Mount"

# Unmount and commit changes
dism /Unmount-Image /MountDir:"C:\Mount" /Commit

# Generalise the reference machine before capture
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown

# Create a bootable ISO from a directory (Windows ADK)
oscdimg.exe -n -m -bC:\WinPE\boot\etfsboot.com C:\WinPE_x64 C:\Output\WinPE.iso
```

### Knowledge check
1. What is the difference between a *wipe-and-load* and an *in-place upgrade*?
2. What is the minimum build Windows 11 requires for Intune enrollment?
3. What does `oscdimg.exe` do and why is it needed for unattended deployments?
4. When do you use DISM versus sysprep?

<details>
<summary>Answers</summary>

1. **Wipe-and-load** completely erases the existing OS and installs a fresh copy of Windows. Applications, settings, and user data must be migrated separately (using USMT or manual backup). This method is best when the existing installation is corrupt, when deploying standardised builds to new hardware, or when you need a clean slate. **In-place upgrade** runs Windows Setup on top of the existing installation and preserves installed applications, personal files, and settings. It is the preferred method for moving a fleet of managed devices to a newer Windows version without requiring full reimaging, and is supported by Windows Autopilot for existing devices scenarios.

2. Windows 11 requires **build 22000** (21H2) or later to enroll in Microsoft Intune. Earlier builds (Windows 10) are supported down to build 1607, but for Windows 11 specifically, version 21H2 is the minimum. In practice, Microsoft recommends keeping devices on a supported servicing channel; any currently supported Windows 11 version will enroll without issue.

3. `oscdimg.exe` is part of the Windows ADK and converts a directory structure into a bootable ISO image file. It is needed for unattended deployments because: (a) the `autounattend.xml` and all installation files must be packaged into a single bootable ISO that can be written to USB media or used by a hypervisor; and (b) it applies the correct El Torito boot record and UDF/ISO 9660 file system layout required to make the image bootable by UEFI firmware.

4. **DISM** operates on Windows image files (`.wim`, `.esd`, `.ffu`) offline — without booting into them. Use DISM to: mount an image, add/remove Windows features, inject drivers, apply updates, capture or apply images, and check image health (`/CheckHealth`, `/RestoreHealth`). **Sysprep** runs on a live, booted Windows installation that has been configured as a reference image. Use Sysprep to generalise the installation before capture — it removes machine-specific identifiers (computer SID, hardware-specific driver entries, activation state) so the image can be deployed to many different machines without identity conflicts. Rule of thumb: DISM manipulates images as files; Sysprep prepares a running system for imaging.

---

**Scenario-based questions:**

5. A company is migrating 300 laptops from Windows 10 to Windows 11. The existing laptops all have their original OEM software, domain-joined profiles, and customised application configurations that took months to set up. The project timeline is tight. Which deployment method is most appropriate?
   - A) Wipe-and-load using a new master image
   - B) In-place upgrade using Windows Setup
   - C) Fresh-start via the Windows Reset option
   - D) Autopilot Reset

<details>
<summary>Answer</summary>

**B) In-place upgrade using Windows Setup.** An in-place upgrade preserves all existing applications, settings, and user data, making it the appropriate choice when re-installation would be disruptive and time-consuming. Wipe-and-load (A) would require migrating applications and data. Fresh-start (C) removes applications. Autopilot Reset (D) requires the device to already be Autopilot-registered and wipes user data.

</details>

6. An endpoint engineer needs to prepare a Windows 11 reference image that will be deployed to 200 new desktops. After fully configuring the reference machine, what must they do before capturing the image with DISM?
   - A) Run `Get-WindowsUpdateLog` to verify patch status
   - B) Run `Sysprep /generalize /oobe /shutdown`
   - C) Run `DISM /CheckHealth` on the live system
   - D) Join the machine to the domain before capture

<details>
<summary>Answer</summary>

**B) Run `Sysprep /generalize /oobe /shutdown`.** Sysprep must be run before capturing a reference image to remove machine-specific identifiers (SID, computer name, hardware-specific drivers). Without generalisation, all deployed machines would share the same SID causing identity conflicts. The machine should NOT be domain-joined before generalisation (D), as Sysprep with generalise will remove the domain join anyway.

</details>

7. A deployment engineer uses `DISM /Mount-Image` to inspect a WIM file and inject updated drivers. After making changes, the engineer runs `DISM /Unmount-Image /Discard` instead of `/Commit`. What is the result?
   - A) All changes including injected drivers are saved to the WIM
   - B) Only the driver injection is saved; other changes are discarded
   - C) All changes are discarded and the WIM reverts to its original state
   - D) The WIM file is deleted from disk

<details>
<summary>Answer</summary>

**C) All changes are discarded and the WIM reverts to its original state.** The `/Discard` flag unmounts the image without committing any staged changes — the WIM is left exactly as it was before mounting. To save changes, `/Commit` must be used instead.

</details>

</details>

---

## Week 2 — Intune enrollment and device management
> **Exam domain:** Prepare infrastructure for devices · **Weight:** 25–30%

> **Real-world scenario:** A Sogeti consultant is onboarding a new client — a 200-person professional services company that has no on-premises domain infrastructure. The client wants all Windows 11 laptops managed via Intune with BitLocker enforced on every device. New employees receive laptops directly from the hardware vendor and should be able to self-provision without calling the helpdesk. The consultant must choose the right enrollment method, configure a BitLocker enforcement profile, and ensure the compliance dashboard is operational before go-live.

### Learning Objectives
- [ ] Explain the difference between MDM enrollment and Hybrid Azure AD Join and identify when each approach is appropriate
- [ ] List and compare the Intune enrollment methods available for Windows devices (manual, Autopilot, bulk/PPKG, GPO auto-enrollment)
- [ ] Create a Configuration Profile in Intune and assign it to a device group
- [ ] Enforce BitLocker via an Intune configuration profile and verify the encryption status using `manage-bde`
- [ ] Create a device compliance policy that checks OS version, and understand how compliance status feeds into Conditional Access
- [ ] Interpret the *Compliant*, *Not compliant*, *In grace period*, and *Not evaluated* device statuses in the Intune portal

### MS Learn modules
- [Enroll devices in Microsoft Intune](https://learn.microsoft.com/en-us/training/modules/enroll-devices/)
- [Manage device profiles with Intune](https://learn.microsoft.com/en-us/training/modules/manage-device-profiles/)
- [Monitor devices with Intune](https://learn.microsoft.com/en-us/training/modules/monitor-devices-microsoft-intune/)

### Key Concepts
| Term | Description |
|------|-------------|
| MDM enrollment | Full device management via Mobile Device Management protocol; Intune receives authority over the device and can push policies, apps, and remote actions |
| Hybrid Azure AD Join | The device is joined to an on-premises Active Directory domain AND registered in Entra ID; enrollment in Intune is typically triggered via Group Policy auto-enrollment |
| Azure AD Join | The device is joined exclusively to Entra ID with no on-premises AD dependency; the primary join type for cloud-first organisations and Autopilot deployments |
| Configuration profile | An Intune policy object that configures a specific set of device settings (Wi-Fi, BitLocker, VPN, restrictions, etc.) and is assigned to users or device groups |
| Compliance policy | A set of rules defining what conditions a device must meet to be considered *compliant* (minimum OS version, BitLocker enabled, Defender running, etc.) |
| Enrollment Status Page (ESP) | A screen displayed during Autopilot provisioning that blocks the user from accessing the desktop until all assigned apps and profiles have been installed |
| manage-bde | Built-in Windows command-line tool for querying and managing BitLocker encryption status on a drive; `manage-bde -status C:` shows encryption state |
| MDM Diagnostic Tool | `MdmDiagnosticsTool.exe -out <path>` collects an enrollment diagnostics bundle from a Windows device, useful for troubleshooting enrollment failures |

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-W11-01** | Enroll device in Intune via **Settings → Accounts → Work or school** |
| **SSW-W11-02** | Enroll second device — observe the difference in the Intune portal |
| **SSW-MGMT01** | Open Intune portal (intune.microsoft.com) → verify both devices under **Devices → All devices** |
| **SSW-MGMT01** | Create a *Configuration profile*: BitLocker enforced on W11-01 |
| **SSW-W11-01** | Verify BitLocker status: `manage-bde -status` |
| **SSW-MGMT01** | Review **Device compliance** — create a compliance policy (minimum OS version) |

### Lab commands

```powershell
# Check BitLocker encryption status on C: drive
manage-bde -status C:

# Force an immediate Intune policy sync from the device
Start-Process "ms-device-enrollment://enroll"
# Alternatively, trigger sync via Scheduled Task:
Start-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\" -TaskName "Schedule to run OMADMClient by client"

# Collect MDM diagnostic bundle for enrollment troubleshooting
MdmDiagnosticsTool.exe -out C:\Temp\MdmDiag

# Check Intune enrollment status in registry
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Enrollments\*" | Select PSChildName, EnrollmentType, UPN
```

### Knowledge check
1. What is the difference between MDM enrollment and Hybrid Azure AD Join?
2. What enrollment methods exist in Intune and when do you use each?
3. What does a *Compliant* versus *Not compliant* status mean in Intune?
4. How does the *Enrollment Status Page* work in Autopilot?

<details>
<summary>Answers</summary>

1. **MDM enrollment** registers a device with Microsoft Intune as its MDM authority. The Intune Management Extension agent is installed, and the device begins receiving policies, compliance checks, and app deployments via the MDM channel. The device can be Azure AD Joined, Hybrid Azure AD Joined, or even just workplace-registered (for BYOD MAM scenarios). **Hybrid Azure AD Join** is a device identity concept, not an enrollment method on its own. A Hybrid AADJ device is simultaneously joined to an on-premises AD domain and registered in Entra ID — enabling SSO to both cloud and on-premises resources. Hybrid AADJ devices are typically enrolled in Intune automatically via a Group Policy Object that triggers MDM auto-enrollment. The key distinction: MDM enrollment = Intune manages the device. Hybrid AADJ = where the device identity lives. They are orthogonal concerns that often coexist.

2. Intune Windows enrollment methods:
   - **Windows Autopilot** — the preferred modern method for new or reset corporate devices; hardware hash is pre-registered, and the device self-configures during OOBE without IT imaging.
   - **Manual enrollment (Settings → Accounts → Work or school)** — used for Azure AD Joined or workplace-registered devices; suitable for smaller environments or individual BYOD scenarios.
   - **GPO auto-enrollment** — for Hybrid AADJ devices already in an AD domain; a Group Policy triggers MDM enrollment silently without user interaction.
   - **Bulk enrollment via Provisioning Package (PPKG)** — created with Windows Configuration Designer; suitable for offline environments or devices without internet connectivity where Autopilot is not possible.
   - **Co-management via Configuration Manager** — for organisations already running ConfigMgr; devices are enrolled in Intune alongside ConfigMgr, and workloads are gradually shifted.

3. **Compliant** means the device satisfies all rules defined in the compliance policy assigned to it (e.g., BitLocker is on, OS version meets the minimum, Defender is running). Compliant devices can pass Conditional Access gates that require compliance. **Not compliant** means one or more compliance rules are not met. Depending on the compliance policy's grace period setting, the device may be in a **grace period** (non-compliant but not yet blocked) or immediately marked non-compliant, triggering CA blocks on cloud app access. **Not evaluated** means no compliance policy has been assigned to the device — Intune treats this as a special state (neither compliant nor non-compliant by default, depending on the Compliance policy setting for "No compliance policy assigned").

4. The Enrollment Status Page is a full-screen progress display that appears on a device during Autopilot provisioning after the user authenticates. It is divided into three phases: (1) **Device preparation** — Autopilot profile is downloaded; (2) **Device setup** — device-targeted apps and configuration profiles are installed; (3) **Account setup** — user-targeted apps and profiles are installed for the signed-in user. The ESP blocks access to the Windows desktop until all tracked apps and profiles finish installing, ensuring the device is fully configured before the user starts working. Administrators configure the ESP in Intune under **Devices → Windows → Enrollment → Enrollment Status Page**, where they can set a timeout, specify which apps must complete before the desktop is released, and control error behaviour.

---

**Scenario-based questions:**

5. A company wants to enroll existing Windows 11 laptops that are currently joined to an on-premises Active Directory domain. The IT team does not want users to take any manual steps. Which enrollment method is most appropriate?
   - A) Manual enrollment via Settings → Accounts → Work or school
   - B) Windows Autopilot User-Driven mode
   - C) GPO-triggered automatic MDM enrollment for Hybrid Azure AD Joined devices
   - D) Bulk enrollment via Provisioning Package (PPKG)

<details>
<summary>Answer</summary>

**C) GPO-triggered automatic MDM enrollment for Hybrid Azure AD Joined devices.** The devices are already domain-joined, so if they are also Hybrid Azure AD Joined (synced via Azure AD Connect), a Group Policy targeting the MDM enrollment URL will silently enroll them in Intune without any user interaction. Manual enrollment (A) requires user action. Autopilot (B) is designed for new or reset devices going through OOBE. PPKG (D) is intended for offline scenarios or devices without Intune licensing.

</details>

6. An Intune compliance policy requires BitLocker to be enabled and OS version to be at least Windows 11 22H2. A device is running Windows 11 21H2 with BitLocker enabled. A grace period of 3 days is configured. The device checked in 1 day ago. What is the current compliance status?
   - A) Compliant
   - B) Not compliant
   - C) In grace period
   - D) Not evaluated

<details>
<summary>Answer</summary>

**C) In grace period.** The device fails the OS version requirement (21H2 is below the required 22H2), so it is technically non-compliant. However, because the 3-day grace period has not yet elapsed (only 1 day has passed), the device is shown as "In grace period" rather than "Not compliant." After 3 days without remediation, the status changes to "Not compliant" and Conditional Access blocks can take effect.

</details>

7. After creating a new configuration profile in Intune and assigning it to a device group, how long does it typically take for the policy to apply on an enrolled Windows device, and how can an engineer force immediate delivery?
   - A) Up to 24 hours; no way to force delivery
   - B) Up to 8 hours; trigger a Sync remote action from the Intune portal or from the device's Company Portal app
   - C) Immediately; Intune always pushes policies in real time
   - D) Up to 72 hours; the device must be restarted

<details>
<summary>Answer</summary>

**B) Up to 8 hours; trigger a Sync remote action from the Intune portal or from the device's Company Portal app.** Intune devices check in approximately every 8 hours by default. To force an immediate policy sync, an administrator can use the **Sync** remote action in the Intune portal (Devices → select device → Sync), or the user can open Company Portal and select **Sync** from the device details page. The default check-in interval is 8 hours for enrolled Windows devices (not 24h, not immediate, not 72h).

</details>

</details>

---

## Week 3 — Compliance, Conditional Access and identity
> **Exam domain:** Prepare infrastructure for devices · **Weight:** 25–30%

> **Real-world scenario:** A Sogeti consultant is engaged by a manufacturing company after a targeted phishing attack compromised several employee accounts. The CISO mandates that all cloud application access must require MFA when users are off-site, and that only Intune-enrolled, compliant devices can access Microsoft 365 services. The consultant must configure Conditional Access policies, set up Named Locations for the corporate network, deploy Windows LAPS to prevent lateral movement via shared local admin passwords, and ensure the hybrid identity sync is working correctly via Azure AD Connect.

### Learning Objectives
- [ ] Describe the three categories of signals that Conditional Access evaluates (user/group, device condition, location/risk) and explain how they combine into an access decision
- [ ] Distinguish between *Block access* and *Grant access with controls* in a Conditional Access policy, and when to use each
- [ ] Compare Azure AD Connect Sync and Microsoft Entra Cloud Sync, including their supported topologies and limitations
- [ ] Configure Windows LAPS via Intune (backup destination, password age, rotation) and retrieve a managed local admin password
- [ ] Explain the difference between Windows LAPS (modern, cloud-integrated) and legacy Microsoft LAPS (AD-only, requires separate agent)
- [ ] Use Named Locations in Conditional Access to define trusted IP ranges and enforce location-based access controls

### MS Learn modules
- [Configure device compliance policies](https://learn.microsoft.com/en-us/training/modules/configure-device-compliance-policies/)
- [Configure Conditional Access](https://learn.microsoft.com/en-us/training/modules/configure-conditional-access/)
- [Manage user and device identities](https://learn.microsoft.com/en-us/training/modules/manage-user-device-identities/)

### Key Concepts
| Term | Description |
|------|-------------|
| Conditional Access | An Entra ID policy engine that evaluates signals (user identity, device compliance, location, sign-in risk) and grants, blocks, or grants with controls (e.g., MFA required) |
| Named Locations | Defined IP address ranges or countries in Entra ID that CA policies can use as a condition — e.g., "require MFA when signing in from outside the corporate IP range" |
| Azure AD Connect Sync | On-premises sync agent that synchronises users, groups, and devices from AD DS to Entra ID; supports complex, multi-forest topologies; requires Windows Server on-premises |
| Entra Cloud Sync | Lightweight cloud-based sync agent that supports simpler hybrid identity scenarios; managed entirely from the cloud with no on-premises infrastructure beyond the lightweight agent |
| Windows LAPS | Local Administrator Password Solution built into Windows 11 22H2+ and Windows Server 2022; automatically rotates the local admin password and backs it up to Entra ID or AD DS |
| Legacy LAPS | The original Microsoft LAPS solution (client-side extension); backs up passwords only to on-premises AD, requires a separate MSI agent install, and is configured via Group Policy |
| Primary Refresh Token (PRT) | A long-lived SSO token issued to Entra ID-joined or registered devices after user authentication; used to silently acquire access tokens for cloud resources without re-prompting for credentials |
| Report-only mode | A CA policy state where the policy evaluates sign-ins and logs what it would have done, without actually enforcing a block or grant — safe way to test CA policy impact before enabling it |

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

### Lab commands

```powershell
# Create a test user in Active Directory
New-ADUser -Name "TestUser01" -SamAccountName "testuser01" -UserPrincipalName "testuser01@ssw.lab" `
  -AccountPassword (ConvertTo-SecureString "P@ssw0rd!" -AsPlainText -Force) -Enabled $true

# Force an Azure AD Connect delta sync
Start-ADSyncSyncCycle -PolicyType Delta

# Retrieve the LAPS-managed local admin password via Microsoft Graph (requires Az or Graph module)
Get-MgDeviceLocalCredentials -DeviceId "<device-object-id>" -IncludeSecrets

# Check Windows LAPS status on the local device
Get-LapsAADPassword -DeviceId (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon").DefaultDomainName
```

### Knowledge check
1. What signals does Conditional Access use to make an access decision?
2. What is the difference between *Block* and *Grant with controls* in CA?
3. How does Azure AD Connect Sync compare to Cloud Sync?
4. What does the *Named Locations* setting do in CA?
5. What is *Windows LAPS* and how does it differ from the legacy LAPS solution?

<details>
<summary>Answers</summary>

1. Conditional Access evaluates three broad categories of signals to determine whether to allow or deny access:
   - **Identity signals** — who is signing in: the user account, group membership, assigned directory roles (e.g., Global Admin), and workload identity (service principal).
   - **Device signals** — the state of the device: whether it is Azure AD Joined or Hybrid AADJ, its Intune compliance status (*compliant* or *not compliant*), and the platform (Windows, iOS, Android, macOS).
   - **Context signals** — the circumstances of the sign-in: Named Location (IP range or country), client application type (browser, modern auth client, legacy auth), sign-in risk level and user risk level (from Entra ID Identity Protection), and the target cloud application being accessed.
   CA combines these signals using an if-then logic: "IF user is in Group A AND device is not compliant AND location is not trusted, THEN block access."

2. **Block access** unconditionally denies the authentication request for any user or device that matches the policy conditions. There is no way for the user to satisfy additional requirements and gain access — the block is absolute. Use Block for: preventing legacy authentication protocols, blocking access from high-risk locations for sensitive apps, or enforcing zero access for specific user groups. **Grant access with controls** allows access but requires the user or device to satisfy one or more conditions first: require MFA, require a compliant device, require a Hybrid Azure AD Joined device, require an approved app, or require an app protection policy. The user can satisfy these controls and proceed. Use Grant with controls for: requiring MFA for all users accessing Microsoft 365, requiring device compliance before accessing SharePoint, or requiring MAM policies for mobile access to Exchange.

3. **Azure AD Connect Sync** (now Entra Connect Sync) is a full-featured synchronisation engine installed on a Windows Server on-premises. It supports: multi-forest AD topologies, granular attribute filtering, complex OU filtering, password hash sync, pass-through authentication, federation with AD FS, device writeback, and group writeback. It requires an on-premises server and ongoing maintenance. **Entra Cloud Sync** uses a lightweight agent installed on-premises (no full server required beyond the agent host) but all configuration and orchestration happen in the cloud. It supports: simpler single- or multi-forest scenarios (with some topology limitations), password hash sync, group writeback (preview). It does not support pass-through authentication, federation, or device writeback. Cloud Sync is the preferred choice for new deployments without complex legacy requirements; Connect Sync remains necessary for complex topologies or features Cloud Sync does not yet support.

4. Named Locations allow administrators to define trusted or untrusted network locations based on **IP address ranges** (IPv4/IPv6 CIDR notation) or **countries/regions**. In Conditional Access, Named Locations are used as a *Locations* condition: you can require MFA only when signing in from outside a trusted Named Location (e.g., the corporate office IP range), or block access entirely from specific countries. IP-based Named Locations can be marked as **trusted**, which also affects Identity Protection risk calculations (sign-ins from trusted locations receive a lower risk score). Country-based locations use Entra ID's IP-to-country mapping and are less precise than IP ranges.

5. **Windows LAPS** (introduced in Windows 11 22H2 / Windows Server 2022) is built directly into the Windows operating system — no separate agent or MSI installation is required. It can back up the local administrator password to **Entra ID** (for Azure AD Joined or Hybrid AADJ devices) or to **on-premises Active Directory**. It is configured via Intune (Endpoint security → Account protection) or Group Policy, and passwords are retrievable via the Intune portal or Microsoft Graph API. Passwords can be automatically rotated on a schedule or on demand, and post-authentication actions (e.g., reset password and log off after use) are configurable. **Legacy Microsoft LAPS** (the original solution) requires installing a client-side extension (MSI) on each managed device and backs up passwords **only to on-premises Active Directory**. It is configured exclusively via Group Policy and does not support Entra ID backup. Microsoft recommends migrating to Windows LAPS for all new deployments; legacy LAPS remains supported but not enhanced.

---

**Scenario-based questions:**

6. A company wants to ensure that employees can only access Microsoft 365 applications (Exchange Online, SharePoint) when they are using a device that is enrolled in Intune and marked compliant. Employees signing in from personal, unmanaged devices should be blocked entirely. Which Conditional Access configuration achieves this?
   - A) Grant access with controls: require MFA
   - B) Grant access with controls: require compliant device
   - C) Block access for all locations except Named Locations
   - D) Grant access with controls: require Hybrid Azure AD Joined device

<details>
<summary>Answer</summary>

**B) Grant access with controls: require compliant device.** Requiring a compliant device means only Intune-enrolled devices that satisfy the compliance policy can access the applications — unmanaged personal devices are blocked because they are not enrolled and therefore have no compliance status. Option A (MFA only) does not block unmanaged devices. Option C would only restrict by location, not by device management state. Option D (Hybrid AADJ) would block cloud-only Entra ID joined devices and is not the right choice for a cloud-first environment.

</details>

7. An organisation recently completed a migration to a cloud-only Entra ID environment with no remaining on-premises Active Directory infrastructure. They need to rotate local administrator passwords on all Windows 11 22H2 devices and store them securely. Which solution should the consultant recommend?
   - A) Legacy Microsoft LAPS with passwords stored in on-premises AD
   - B) Windows LAPS configured to back up to Entra ID via Intune policy
   - C) A PowerShell script that generates and emails passwords to the IT team
   - D) Disable the local administrator account on all devices

<details>
<summary>Answer</summary>

**B) Windows LAPS configured to back up to Entra ID via Intune policy.** Windows LAPS (built into Windows 11 22H2+) supports Entra ID as a backup destination, which is exactly what a cloud-only environment requires. Legacy LAPS (A) requires on-premises Active Directory and cannot store passwords in Entra ID. A script (C) is not a managed, auditable solution. Disabling the local administrator account (D) removes the break-glass recovery option and is not recommended.

</details>

8. A Conditional Access policy is being created to enforce MFA for all users accessing SharePoint Online. The security team wants to test the impact before enabling enforcement, to avoid unintentionally locking out employees. What CA setting should be used during the testing phase?
   - A) Set the policy to **Disabled**
   - B) Set the policy to **Report-only** mode
   - C) Set the policy to **Block access** for a pilot group only
   - D) Enable the policy with a Named Location exclusion for the corporate network

<details>
<summary>Answer</summary>

**B) Set the policy to Report-only mode.** Report-only mode evaluates every sign-in against the policy conditions and logs what the policy would have done (grant, block, or require MFA), but does not enforce any action. This allows the security team to analyse the sign-in logs in Entra ID and identify affected users before enabling the policy. Setting it to Disabled (A) provides no testing data. Option C (Block for pilot group) is enforcement, not testing. Option D changes the policy scope rather than testing it safely.

</details>

</details>

---

## Week 4 — Application management with Intune
> **Exam domain:** Manage applications · **Weight:** 15–20%

> **Real-world scenario:** A Sogeti consultant is supporting a retail chain that manages 600 Windows 11 endpoints entirely via Intune. The IT team needs to deploy a legacy ERP application (complex EXE installer with custom switches) silently to all corporate devices, make the Adobe Acrobat Reader available optionally in the Company Portal, and ensure that employees using personal iPhones for work email cannot copy corporate data to their personal apps. The consultant must package the Win32 app, configure app assignment intents, and set up App Protection Policies for mobile BYOD.

### Learning Objectives
- [ ] Package a Win32 application using the Intune Win32 Content Prep Tool (`IntuneWinAppUtil.exe`) and upload it to Intune with a correct detection rule
- [ ] Distinguish between *Required*, *Available*, and *Uninstall* app assignment intents and explain when each is appropriate
- [ ] Describe the role and location of `IntuneManagementExtension.log` and use it to diagnose Win32 app deployment failures
- [ ] Deploy Microsoft 365 Apps via the built-in Intune app type and understand the relationship between Intune, ODT, and OCT
- [ ] Configure an App Protection Policy (MAM) and explain how MAM-without-enrollment protects data on unmanaged BYOD devices
- [ ] Explain when to use Win32 app packaging versus the Microsoft Store (new) or the Enterprise App Catalog

### MS Learn modules
- [Deploy and update applications with Intune](https://learn.microsoft.com/en-us/training/modules/deploy-applications/)
- [Manage Win32 apps with Intune](https://learn.microsoft.com/en-us/training/modules/manage-win32-apps/)
- [Configure Microsoft 365 Apps deployment](https://learn.microsoft.com/en-us/training/modules/configure-microsoft-365-apps/)

### Key Concepts
| Term | Description |
|------|-------------|
| IntuneWinAppUtil.exe | Free Microsoft command-line tool that wraps an application installer and its dependencies into a `.intunewin` package for upload to Intune |
| Win32 app | The most flexible Intune app type — supports any installer format (EXE, MSI, MSIX) packaged as `.intunewin`; supports custom install/uninstall commands and detection rules |
| Detection rule | Logic that Intune uses to determine if a Win32 app is already installed; can be based on file path existence, a registry key/value, or MSI product code |
| Required assignment | The app is forcibly installed (or uninstalled) on all devices/users in the assigned group without user interaction |
| Available assignment | The app appears in Company Portal and the user can choose to install it themselves; not pushed automatically |
| IntuneManagementExtension.log | The primary log file for Win32 app deployments on Windows devices; located at `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\`; contains install command output, detection results, and error codes |
| App Protection Policy (MAM) | A set of rules that protect corporate data within managed apps (e.g., Outlook, Teams, Edge) — encrypts app data, restricts copy/paste to unmanaged apps, and can wipe corporate data selectively; works with or without MDM enrollment |
| MAM-WE | Mobile Application Management Without Enrollment — applies App Protection Policies to corporate apps on BYOD devices that are NOT enrolled in Intune; only the app-level data is managed, not the device |
| ODT / OCT | Office Deployment Tool (command-line installer for Microsoft 365 Apps) and Office Customization Tool (web GUI at config.office.com for generating the XML configuration); used together for advanced M365 Apps deployments |

### Lab exercises (SSW-Lab)
| VM | Task |
|---|---|
| **SSW-MGMT01** | Package a `.exe` app as `.intunewin` using the **Intune Win32 Content Prep Tool** |
| **SSW-MGMT01** | Upload the Win32 app to Intune → assign to W11-01 (Required) |
| **SSW-W11-01** | Verify installation via **Company Portal** or event log (`IntuneManagementExtension`) |
| **SSW-MGMT01** | Create a Microsoft 365 Apps deployment in Intune (Office suite) |
| **SSW-W11-02** | Verify Office installation after sync (`imdssync` or wait for Intune check-in) |
| **SSW-MGMT01** | Configure an *App protection policy* (MAM) for Microsoft Edge |

### Lab commands

```powershell
# Package a Win32 app installer into .intunewin format
.\IntuneWinAppUtil.exe -c "C:\AppSource\MyApp" -s "setup.exe" -o "C:\IntunePackages"

# Tail the IntuneManagementExtension log in real time for troubleshooting
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" -Wait -Tail 50

# Check if a specific app is detected (simulate detection rule - file path)
Test-Path "C:\Program Files\MyApp\myapp.exe"

# Trigger IME app re-evaluation (restart the service)
Restart-Service -Name IntuneManagementExtension
```

### Knowledge check
1. What is the difference between a *Required* and *Available* app assignment?
2. When do you use Win32 app packaging versus Microsoft Store for Business?
3. What does `IntuneManagementExtension.log` contain and where is it located?
4. What are the benefits of MAM without MDM enrollment?

<details>
<summary>Answers</summary>

1. A **Required** assignment causes Intune to automatically install (or uninstall, if the intent is "Uninstall") the app on all devices or users in the assigned group without any user action or approval. The user cannot decline it and will not see a prompt — it is silently enforced by the Intune Management Extension. Use Required for mandatory corporate software (Defender, VPN clients, line-of-business apps). An **Available** assignment adds the app to the Company Portal catalogue, where the user can browse to it and choose to install it at a time of their convenience. The app is never automatically pushed. Use Available for optional productivity tools, utilities, or apps that only some users need. Note: a single app can have both assignments simultaneously — Required for a group of power users and Available for everyone else.

2. Use **Win32 app packaging** (`.intunewin`) when: the app uses a traditional installer (EXE, MSI, MSIX); you need custom install/uninstall command-line switches; you need a specific detection rule (registry, file path, or MSI product code); or the app is not available in any store. Win32 is the most flexible option and supports virtually any Windows application. Use the **Microsoft Store (new)** — the updated WinGet-based store integration in Intune — when the app is available in the public Microsoft Store, you want automatic updates managed by the store, and the app supports WinGet packaging. It requires no manual packaging. The **Enterprise App Catalog** (part of Intune Suite) is similar but provides pre-packaged Win32 apps with automatic update management for popular applications like Google Chrome, 7-Zip, and Zoom — reducing the packaging burden while keeping the Win32 app type's flexibility. Legacy "Microsoft Store for Business" was retired in March 2023.

3. `IntuneManagementExtension.log` is the primary diagnostic log for the Intune Management Extension (IME), which handles Win32 app deployments, PowerShell scripts, and proactive remediations on Windows devices. It is located at `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\`. The log contains: app download progress and CDN URLs, install command execution output (stdout/stderr from the installer), detection rule evaluation results (detected or not detected), assignment targeting resolution, retry logic, and error codes returned by the installer. When an app fails to install, this log is always the first place to look — it shows the exact exit code returned by the installer, which you can cross-reference with the installer's own documentation to determine the root cause.

4. MAM without MDM enrollment (MAM-WE) enables organisations to protect corporate data within specific managed apps on personal, unmanaged BYOD devices — without requiring the user to enrol their personal device into full MDM management. Benefits include: (a) **Privacy** — the organisation has no visibility into the personal device, its apps, or its location; only the specific managed apps are in scope; (b) **Data separation** — corporate data within apps like Outlook and Teams is encrypted, and copy/paste to unmanaged apps (personal email, social media) is blocked; (c) **Selective wipe** — only the corporate data within managed apps can be remotely wiped; the personal data and the device itself are never touched; (d) **No enrollment barrier** — employees do not need to accept full MDM management of their personal phone to access corporate email, making adoption easier; (e) **Supported on unmanaged devices** — works on iOS, Android, and Windows without any agent or MDM enrollment.

---

**Scenario-based questions:**

5. A company deploys a Win32 app to a device group in Intune with a Required assignment. The app does not install on one device, and there is no error visible in the Intune portal. Where should the engineer look first to diagnose the issue?
   - A) Windows Event Viewer → Application log
   - B) `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`
   - C) The Microsoft Endpoint Manager admin centre → Troubleshooting + support
   - D) The Windows Update log (`Get-WindowsUpdateLog`)

<details>
<summary>Answer</summary>

**B) `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.** This is always the first file to check for Win32 app deployment failures. It contains the full execution output of the installer, the detection rule evaluation result, the exit code returned by the installer, and any retry attempts. The Intune portal often shows a generic error code; the IME log reveals the specific root cause. The Windows Event Viewer (A) and Windows Update log (D) do not contain Win32 app deployment details.

</details>

6. A company wants to protect Microsoft Outlook data on employee-owned iPhones without requiring the devices to be enrolled in Intune. Employees must be able to use their personal iPhones for corporate email, but copying corporate emails to personal notes or third-party apps must be blocked. Which Intune feature should the consultant configure?
   - A) Device compliance policy for iOS
   - B) Device configuration profile: Email settings for iOS
   - C) App Protection Policy (MAM without enrollment) for Outlook on iOS
   - D) Conditional Access policy requiring a compliant device

<details>
<summary>Answer</summary>

**C) App Protection Policy (MAM without enrollment) for Outlook on iOS.** MAM-WE applies App Protection Policies to managed apps (Outlook) on unmanaged personal devices without requiring MDM enrollment. It can restrict copy/paste to unmanaged apps, require a PIN to open Outlook, encrypt app data, and enable selective corporate data wipe — all without touching personal data or requiring the user to enrol their iPhone. A device compliance policy (A) requires enrollment. A configuration profile (B) also requires enrollment. A CA policy requiring a compliant device (D) would block access entirely from unmanaged devices.

</details>

7. An engineer is uploading a Win32 app to Intune and must configure a detection rule. The installer creates a registry key `HKLM:\SOFTWARE\MyCompany\MyApp` with a value `Version = 2.1` after successful installation. Which detection rule type should be used?
   - A) MSI product code detection
   - B) File path detection
   - C) Registry key detection
   - D) PowerShell script detection

<details>
<summary>Answer</summary>

**C) Registry key detection.** Since the successful installation creates a specific registry key and value, a registry detection rule is the most direct and reliable approach. Configure it to check for the existence of `HKLM:\SOFTWARE\MyCompany\MyApp` with value `Version = 2.1`. MSI product code detection (A) is only applicable for MSI-based installers. File path detection (B) would work if the installation creates a known file, but the scenario specifies a registry key. PowerShell detection (D) is the most flexible but also the most complex — unnecessary when a built-in rule type directly matches the evidence.

</details>

</details>

---

## Week 5 — Windows Autopilot
> **Exam domain:** Prepare infrastructure for devices · **Weight:** 25–30%

> **Real-world scenario:** A Sogeti consultant is setting up a zero-touch deployment process for a logistics company that receives 50 new laptops per month from a hardware reseller. The company wants new employees to unbox their laptop, connect to the internet, and have a fully configured, corporate-ready Windows 11 device within 30 minutes — without any IT involvement. Additionally, the company has shared kiosk terminals in warehouses that must auto-configure without any user sign-in. The consultant must configure Autopilot for both User-Driven and Self-Deploying scenarios, set up the Enrollment Status Page, and register the hardware hashes via the reseller portal.

### Learning Objectives
- [ ] Collect a device hardware hash using `Get-WindowsAutoPilotInfo` and import it into the Intune portal
- [ ] Configure an Autopilot deployment profile for User-Driven mode with Entra ID join and walk through the OOBE end-to-end
- [ ] Differentiate between User-Driven, Self-Deploying, Pre-Provisioning (White Glove), and Autopilot for Existing Devices scenarios
- [ ] Configure the Enrollment Status Page and explain how it controls app installation sequencing during provisioning
- [ ] Perform an Autopilot Reset on a registered device and explain when it is used versus a full wipe
- [ ] Explain the positioning of Windows 365 versus Azure Virtual Desktop and identify the correct scenario for each
- [ ] Run a basic KQL device query in Intune using the Device query feature and interpret the results

### MS Learn modules
- [Configure Windows Autopilot](https://learn.microsoft.com/en-us/training/modules/configure-windows-autopilot/)
- [Autopilot deployment scenarios](https://learn.microsoft.com/en-us/training/modules/windows-autopilot-deployment-scenarios/)
- [Troubleshoot Windows Autopilot](https://learn.microsoft.com/en-us/training/modules/troubleshoot-windows-autopilot/)

### Key Concepts
| Term | Description |
|------|-------------|
| Hardware hash | A cryptographic fingerprint of the device's hardware components (motherboard, NIC, etc.) used to uniquely identify the device for Autopilot registration; collected via `Get-WindowsAutoPilotInfo` |
| User-Driven mode | Autopilot scenario where a user authenticates with their Entra ID account during OOBE, and the device is provisioned with their profile and assigned apps; most common enterprise deployment mode |
| Self-Deploying mode | Autopilot scenario with no user interaction during OOBE; the device authenticates using TPM 2.0 device attestation; designed for kiosks, shared devices, or digital signage |
| Pre-Provisioning (White Glove) | A two-phase Autopilot mode where IT or a reseller completes the device-targeted provisioning phase (apps, profiles) in advance, then the user completes the user-targeted phase when they first sign in |
| Group Tag | A string label attached to an Autopilot device that can be used in dynamic Entra ID group membership rules (`(device.devicePhysicalIds -any _ -eq "[OrderID]:TAGVALUE")`) to automatically assign profiles |
| Autopilot Reset | A Windows action that reinstalls Windows while keeping the device registered in Autopilot and Entra ID; preserves corporate settings but wipes user data; useful for reassigning a device to a new user |
| Windows 365 Cloud PC | Desktop-as-a-Service offering from Microsoft; each user gets a persistent, personal virtual desktop with a fixed monthly per-user price; managed via Intune like a physical device |
| Azure Virtual Desktop (AVD) | Microsoft's Azure-based VDI platform; supports multi-session Windows (multiple users on a single VM host), pay-per-use pricing, and pooled/non-persistent desktops; more complex and flexible than Windows 365 |
| KQL Device Query | Kusto Query Language queries run per-device in real-time via Intune Advanced Analytics; retrieves current hardware, software, user, and disk information directly from the device without waiting for inventory sync |

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

### Lab commands

```powershell
# Collect hardware hash and export to CSV (requires WindowsAutoPilotIntune module)
Install-Script -Name Get-WindowsAutoPilotInfo
Get-WindowsAutoPilotInfo -OutputFile C:\Temp\AutopilotHash.csv

# Upload hardware hash to Intune directly (requires MS Graph / WindowsAutoPilotIntune module)
Install-Module -Name WindowsAutoPilotIntune
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
Import-AutoPilotCSV -csvFile C:\Temp\AutopilotHash.csv

# KQL device query examples in Intune Device Query
# Run these in: Intune → Devices → [select device] → Device query
# InstalledApplications | project ApplicationName, ApplicationVersion | order by ApplicationName asc
# SystemInfo | project DeviceName, Manufacturer, Model, OSVersion, TotalMemory
```

### Knowledge check
1. What is the difference between *User-driven* and *Self-deploying* Autopilot mode?
2. What is the *Enrollment Status Page* used for and how do you configure it?
3. How do you reset an Autopilot profile assignment if a device is already registered?
4. What is *Windows Autopilot Reset* and when do you use it?
5. What is *Windows 365* and how does it differ from Azure Virtual Desktop?
6. How do you run a KQL device query in Intune and what data can you retrieve?

<details>
<summary>Answers</summary>

1. **User-Driven mode** requires a user to sign in with their Entra ID (Microsoft 365) account during OOBE. After authentication, Autopilot downloads the deployment profile, applies device configuration, installs required apps, and then presents the user with their personalised desktop. This is the standard enterprise scenario for distributing corporate laptops to employees. **Self-Deploying mode** performs the entire provisioning process with zero user interaction. The device authenticates to Entra ID using its **TPM 2.0 hardware attestation** (no username or password is entered). It is designed for devices that will not have a dedicated user — kiosks, lobby displays, shared workstations, or conference room systems. Because no user authenticates, User Affinity is set to None. Self-Deploying mode requires TPM 2.0 and a network connection; it will fail on hardware without TPM or on virtual machines without virtual TPM enabled.

2. The Enrollment Status Page (ESP) tracks and displays the progress of app and profile installation during Autopilot provisioning. It holds the device at a "Setting up your device" or "Setting up for work" screen until all tracked items are complete, preventing users from accessing the desktop on a partially configured device. To configure the ESP: navigate to **Intune → Devices → Windows → Enrollment → Enrollment Status Page → Create**. Key settings include: **Show app and profile installation progress** (enable to show the ESP), **Show error when installation takes longer than specified minutes** (timeout, e.g., 60 minutes), **Allow users to reset device if installation error occurs**, **Block device use until all apps and profiles are installed**, and **Block device use until these required apps are installed** (specify a subset of apps that must complete before the desktop is released). The ESP is assigned to device groups and can be configured differently for different user populations (e.g., longer timeout for IT staff doing pre-provisioning).

3. If a device already has an Autopilot profile assigned but you need to change or reassign it: (a) in Intune, go to **Devices → Windows → Enrollment → Windows Autopilot Devices**, find the device, and select it; (b) choose **Assign user** if the profile assignment is user-based, or review the **Group Tag** and update the dynamic group membership rules that target the profile; (c) to force a profile re-download on the device, trigger an Autopilot Reset or use the **Sync** remote action to force the device to re-check Intune; (d) alternatively, delete and re-import the hardware hash with a different Group Tag to route the device into a different dynamic device group and thus a different deployment profile. Note that the Autopilot profile itself cannot be "un-assigned" without either removing the device from the targeted group or deleting the profile.

4. **Windows Autopilot Reset** re-provisions a device that is already registered in Autopilot and enrolled in Intune. It: removes all user accounts, personal data, and user-installed apps; resets Windows to a clean state as if it were freshly installed; retains the device's Autopilot registration, Entra ID device object, and Intune enrollment; and then re-applies the assigned Autopilot profile, compliance policies, configuration profiles, and required apps. Use Autopilot Reset when: reassigning a device from one employee to another; recovering a device that has drifted from its desired configuration; or refreshing a device after an employee departs. It is faster than a full wipe-and-reload because it does not require reimaging. Autopilot Reset can be triggered locally (Windows key + Ctrl + R at the lock screen, for IT technicians) or remotely via the **Autopilot Reset** remote action in the Intune portal.

5. **Windows 365** is a Desktop-as-a-Service product that delivers a full, personal, persistent Windows virtual desktop hosted in Microsoft's cloud. Each user gets their own dedicated Cloud PC that is always available and retains their apps, files, and settings between sessions. Pricing is a fixed monthly fee per user per Cloud PC tier. Cloud PCs are Entra ID-joined and managed in Intune exactly like physical devices — compliance policies, configuration profiles, and app deployments all apply. **Azure Virtual Desktop (AVD)** is a flexible Azure-based VDI platform. Key differences: AVD supports **multi-session** (multiple concurrent users on a single Windows host VM, reducing cost at scale), uses **pay-per-use Azure consumption pricing** (cheaper when desktops are idle), supports both persistent and **pooled/non-persistent** desktop configurations, and requires Azure infrastructure management. Windows 365 is simpler to manage (no Azure expertise required) and suitable for knowledge workers needing a personal, always-on desktop. AVD is better suited for large-scale VDI deployments, seasonal workers, or scenarios requiring cost optimisation through multi-session hosting.

6. To run a KQL device query in Intune: navigate to **Intune → Devices → All devices**, select a specific device, then click the **Device query** tab (requires Intune Advanced Analytics, which is part of Intune Suite or Intune Plan 2). Type a KQL query in the editor and click **Run**. The query executes in real-time on the device and returns current data within seconds. Available tables and example queries:
   - `InstalledApplications | project ApplicationName, ApplicationVersion` — lists all installed software
   - `SystemInfo | project DeviceName, Manufacturer, Model, TotalMemory, OSVersion` — hardware summary
   - `LocalUsers | project Name, SID, PrincipalSource` — local user accounts
   - `LogicalDrive | project DriveName, TotalSpace, FreeSpace` — disk space per drive
   The key differentiator from standard Intune inventory: device queries return **real-time, live data** from the device at the moment the query runs, whereas the standard hardware and discovered apps inventory is refreshed periodically (cached) based on the Intune sync schedule.

---

**Scenario-based questions:**

7. A company deploys warehouse kiosk terminals running Windows 11. The terminals should configure themselves automatically when connected to the network — no user should ever need to sign in during provisioning, and no user account should be associated with the device in Entra ID. Which Autopilot mode should be used?
   - A) User-Driven mode with Entra ID join
   - B) Pre-Provisioning (White Glove) with technician flow
   - C) Self-Deploying mode
   - D) Autopilot for Existing Devices

<details>
<summary>Answer</summary>

**C) Self-Deploying mode.** Self-Deploying mode provisions the device with zero user interaction — the device authenticates using TPM 2.0 hardware attestation, no user account is required, and User Affinity is set to None. This is the correct mode for kiosks, shared devices, and digital signage. User-Driven mode (A) requires a user to authenticate. White Glove (B) is a two-phase mode for pre-staging devices before user delivery. Autopilot for Existing Devices (D) is for migrating existing domain-joined machines to Autopilot, not for kiosk deployment.

</details>

8. A device was recently used by an employee who has left the company. The IT team wants to reassign it to a new employee. The device is currently enrolled in Intune and registered in Autopilot. The IT team wants to preserve the Intune enrollment and Autopilot registration, remove all previous user data, and have the new employee go through the standard OOBE provisioning. What is the correct action?
   - A) Perform a Wipe (factory reset) from the Intune portal
   - B) Perform an Autopilot Reset from the Intune portal
   - C) Delete the device from Intune and re-import the hardware hash
   - D) Retire the device from Intune and re-enroll manually

<details>
<summary>Answer</summary>

**B) Perform an Autopilot Reset from the Intune portal.** Autopilot Reset removes all user data and applications, returns Windows to a clean OOBE-ready state, but keeps the device registered in Autopilot and its Entra ID object intact. The new employee can then sign in during OOBE and the device re-provisions automatically with all assigned profiles and apps. A full Wipe (A) also resets the device but removes the Entra ID device object and Intune enrollment — the device would need to re-register. Deleting from Intune (C) or Retiring (D) introduces unnecessary complexity.

</details>

9. An Intune administrator runs the following KQL query on a device via the Device Query feature: `InstalledApplications | where ApplicationName contains "Chrome"`. The query returns no results, but the administrator can see Chrome installed in the standard Intune hardware inventory. What is the most likely explanation?
   - A) KQL device queries only work on devices running Windows 11 23H2 or later
   - B) The standard Intune inventory is real-time; KQL queries use cached data
   - C) The KQL query ran successfully but Chrome was uninstalled between the inventory sync and the query
   - D) KQL Device Query requires Intune Advanced Analytics; the device may not have the feature licensed

<details>
<summary>Answer</summary>

**D) KQL Device Query requires Intune Advanced Analytics; the device may not have the feature licensed.** Device Query is part of Intune Advanced Analytics, which requires Intune Suite or Intune Plan 2 licensing. Without this license, the Device Query tab may appear but return no results or show an error. The scenario description of results returning empty while inventory shows the app is the classic symptom of a licensing or feature enablement gap. Note also that KQL queries are *real-time* (not cached) — the opposite of option B — so the inventory/query discrepancy described in option B is reversed in reality.

</details>

</details>

---

## Week 6 — Security, updates, Intune Suite and monitoring
> **Exam domain:** Protect devices · **Weight:** 15–20%

> **Real-world scenario:** A Sogeti consultant is engaged by a healthcare organisation following a ransomware incident that encrypted several file servers. The CISO requires immediate action: enforce Windows Update patching within 7 days of release, onboard all endpoints to Microsoft Defender for Endpoint, remove local administrator rights from all standard users while still allowing certain maintenance tools to run with elevation, and implement a proactive monitoring strategy that alerts IT before devices become a problem. The consultant must configure update rings, Defender onboarding, Endpoint Privilege Management, and Endpoint Analytics.

### Learning Objectives
- [ ] Configure a Windows Update for Business update ring in Intune and differentiate between quality update and feature update deferral periods
- [ ] Distinguish between an *Update ring* (WUfB) and a *Feature update policy* and explain when to use each
- [ ] Enable Microsoft Defender for Endpoint onboarding via Intune and verify sensor status using the Defender portal and the `sc query sense` command
- [ ] Explain how co-management works between Intune and Configuration Manager and identify which workloads to shift first
- [ ] Describe the Intune Suite add-on capabilities (EPM, Remote Help, Advanced Analytics, Enterprise App Catalog, Cloud PKI, Tunnel for MAM) and the problem each solves
- [ ] Use Intune remote actions (wipe, retire, sync, rotate LAPS password) and explain the difference between *Wipe* and *Retire*

### MS Learn modules
- [Manage endpoint security with Intune](https://learn.microsoft.com/en-us/training/modules/manage-endpoint-security/)
- [Manage Windows updates with Intune](https://learn.microsoft.com/en-us/training/modules/manage-windows-updates-intune/)
- [Monitor and troubleshoot devices](https://learn.microsoft.com/en-us/training/modules/monitor-troubleshoot-devices/)
- [Intune Suite add-on capabilities](https://learn.microsoft.com/en-us/mem/intune/fundamentals/intune-add-ons)

### Key Concepts
| Term | Description |
|------|-------------|
| Update ring | A Windows Update for Business policy in Intune that defines deferral periods for quality updates and feature updates, active hours, restart behaviour, and deadline grace periods |
| Quality update | Monthly cumulative security and bug-fix updates released on Patch Tuesday; deferral is configurable up to 30 days |
| Feature update | Biannual Windows version upgrades (e.g., 22H2 → 23H2); deferral configurable up to 365 days; requires a separate *Feature update policy* in Intune for controlled targeting |
| Deferral period | Number of days after Microsoft releases an update before it is offered to devices in the ring; used to give time for testing before broad deployment |
| Endpoint analytics | Intune dashboard showing device health scores, startup performance, app reliability, and proactive remediations results across the fleet |
| Co-management | A configuration where a Windows device is simultaneously managed by Configuration Manager (SCCM) and Microsoft Intune; workloads (Compliance, Endpoint Protection, etc.) can be individually shifted from ConfigMgr to Intune |
| Wipe | A remote action that factory-resets a device by removing all data and reinstalling Windows; the device is removed from Entra ID and Intune; use when a device is lost or being decommissioned |
| Retire | A remote action that removes corporate data and configuration from the device while leaving personal data intact; the device is unenrolled from Intune; appropriate for BYOD or when an employee leaves |
| Endpoint Privilege Management (EPM) | An Intune Suite add-on that allows standard (non-admin) users to run specific, IT-approved processes with elevated privileges without making them local administrators |
| Microsoft Tunnel for MAM | An Intune Suite add-on VPN tunnel for MAM-managed apps on non-enrolled iOS/Android devices; only managed app traffic routes through the tunnel — the device itself does not need to be enrolled |

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

### Lab commands

```powershell
# Check Windows Defender service (SENSE = MDE sensor) status
sc query sense

# Trigger a Defender Quick Scan
Start-MpScan -ScanType QuickScan

# Check current Windows Update deferral settings in registry
Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" | Select DeferQualityUpdates, DeferQualityUpdatesPeriodInDays

# Check Defender threat definitions version
Get-MpComputerStatus | Select AntivirusSignatureVersion, AntispywareSignatureLastUpdated, RealTimeProtectionEnabled

# Initiate a Defender signature update
Update-MpSignature
```

### Knowledge check
1. What is the difference between an *Update ring* and a *Feature update policy*?
2. How does *Co-management* work between Intune and Configuration Manager?
3. What does the **Endpoint analytics** dashboard show in Intune?
4. How do you use *Remote actions* (wipe, retire, sync) in Intune?
5. What Intune Suite add-ons exist and what problem does each solve?
6. What is *Endpoint Privilege Management* and when do you use elevation policies?

<details>
<summary>Answers</summary>

1. An **Update ring** (Windows Update for Business policy) controls the *timing* of update delivery for both quality and feature updates. It sets deferral periods (days before an update is offered), active hours (when restarts are blocked), restart grace periods, and deadline enforcement. Update rings apply to all future updates that flow through Windows Update channels — they are ongoing, continuous policies. A **Feature update policy** is a more targeted Intune policy that lets you pin devices to a specific Windows feature version (e.g., "hold devices at Windows 11 22H2 regardless of the update ring's feature deferral"). It is used for controlled OS version migrations: you can deploy Windows 11 23H2 to a pilot group while keeping production devices on 22H2. When you are ready, you update the feature update policy to allow the production ring to advance. Use both together: update rings for timing and restart management; feature update policies for OS version lifecycle control.

2. Co-management requires: (a) a Microsoft Endpoint Configuration Manager (MECM/SCCM) Current Branch installation (version 1709 or later), (b) the ConfigMgr client installed on Windows devices, and (c) the devices to be Azure AD Joined or Hybrid Azure AD Joined and enrolled in Intune. Once co-management is enabled, you configure a **workload slider** for each of these workloads: Compliance policies, Device configuration, Endpoint Protection, Resource Access policies (Wi-Fi, VPN, certificate profiles), Office Click-to-Run apps, and Windows Update policies. Each workload can independently be set to ConfigMgr, Pilot Intune (a specified collection gets Intune authority as a pilot), or Intune. The recommended starting workload to shift is **Compliance policies** — it is low risk, gives immediate value (devices report compliance to Intune), and is easy to test. Devices continue to receive ConfigMgr for workloads that have not been shifted.

3. The Endpoint analytics dashboard in Intune provides fleet-wide device health and performance insights: **Startup score** — measures how long devices take to boot and sign in, flagging devices with slow startup performance due to hardware age, driver issues, or excessive startup processes; **App reliability score** — tracks application crash rates and hang frequency across the fleet; **Work from anywhere score** — evaluates the percentage of devices that are cloud-managed, cloud-identity-joined, and capable of working without VPN; **Recommended software** — identifies devices running older Windows versions or without the Intune Management Extension; **Proactive remediations status** — shows results of detection and remediation scripts; **Anomaly detection** (Intune Suite / Advanced Analytics) — identifies devices deviating from baseline behaviour patterns, indicating potential issues before they generate helpdesk tickets.

4. Remote actions are available from the device's detail page in Intune (**Devices → All devices → [select device]**). The most common actions: **Sync** — forces the device to immediately check in with Intune and download any pending policy or app changes (useful after creating a new assignment and wanting to test it without waiting for the default check-in interval); **Wipe** — factory resets the device, removes all data and reinstalls Windows, and unenrolls it from Intune; use for lost/stolen devices or decommissioning; **Retire** — removes corporate data, policies, and apps while preserving personal data and files; the device is unenrolled from Intune but not wiped; appropriate for BYOD offboarding; **Restart** — remotely reboots the device; **BitLocker key rotation** — rotates the BitLocker recovery key and updates the new key in Entra ID; **Rotate local admin password** — triggers an immediate LAPS password rotation. All remote actions are logged in the Intune audit log.

5. The six Intune Suite add-on capabilities (all require Intune Suite or Intune Plan 2 licensing):
   - **Endpoint Privilege Management (EPM)** — solves the least-privilege problem: allows standard users to run specific, IT-approved files or processes with elevated rights without granting them permanent local admin membership.
   - **Microsoft Intune Remote Help** — replaces ad-hoc tools like TeamViewer or Quick Assist with a fully Intune-integrated remote support solution that includes RBAC-based helper roles, compliance checks before connecting, and full audit logging of sessions.
   - **Advanced Analytics** — extends Endpoint analytics with anomaly detection, custom device queries (KQL), and enhanced reporting; solves the problem of reactive IT (knowing about device issues only after a helpdesk call).
   - **Enterprise App Catalog** — solves Win32 app packaging maintenance: provides a library of 300+ popular third-party apps (Chrome, 7-Zip, Zoom) pre-packaged with install commands, detection rules, and automatic version updates maintained by Microsoft.
   - **Microsoft Cloud PKI** — eliminates the need for on-premises ADCS, NDES, and the Intune Certificate Connector by hosting the entire PKI infrastructure in Microsoft's cloud; simplifies certificate deployment for Wi-Fi and VPN authentication.
   - **Microsoft Tunnel for MAM** — solves secure access for unmanaged BYOD mobile devices: provides a per-app VPN tunnel for MAM-managed apps on non-enrolled iOS/Android devices so they can securely reach on-premises resources without enrolling the device into MDM.

6. Endpoint Privilege Management addresses the tension between security (users should not be local administrators) and productivity (some IT tasks or legitimate business applications require elevated rights). EPM works by deploying an Intune policy to devices that installs the EPM client. When a user right-clicks an approved file in Windows Explorer, they see a **"Run with elevated access"** option. Depending on the elevation rule type: **Managed elevation** — the file is silently elevated without any user confirmation (the IT-approved app simply runs as admin); **User-confirmed elevation** — the user sees a confirmation dialog and must acknowledge the elevation (creates an audit trail); **Support-approved elevation** — the user must request approval from the help desk before the elevation is granted. Use EPM elevation policies for: applications that legitimately require admin rights but should not require making users permanent admins (e.g., legacy installers, some diagnostic tools); and for phased least-privilege rollouts where you are removing admin rights from a user population and need a safety net for the remaining edge cases.

---

**Scenario-based questions:**

7. A company's security team requires that all Windows quality updates (security patches) must be installed within 10 days of Microsoft's release date, with forced restart enforcement after the deadline. Feature updates should be held at the current Windows 11 version until explicitly approved. Which combination of Intune policies achieves this?
   - A) One Update ring with quality deferral of 10 days and forced restart deadline; no Feature update policy needed
   - B) One Update ring with quality deferral of 0 days; a Feature update policy pinning the current Windows 11 version
   - C) One Update ring with quality deferral of 10 days and restart enforcement; plus a Feature update policy pinning the current Windows 11 version
   - D) Two Update rings — one for quality, one for feature — with different deferral settings

<details>
<summary>Answer</summary>

**C) One Update ring with quality deferral of 10 days and restart enforcement; plus a Feature update policy pinning the current Windows 11 version.** The Update ring handles quality update timing and restart behaviour. The Feature update policy separately controls which Windows version devices stay on, allowing the security team to approve feature updates independently of quality patches. Option A leaves feature updates uncontrolled (they would be governed by the update ring's feature deferral, which may not pin to a specific version). Option B sets quality deferral to 0 (immediate), which does not allow the 10-day window. Option D is not how Intune Update rings work — a single ring manages both update types.

</details>

8. An employee has left a company and returned their personal iPhone that was used for corporate email via an MAM App Protection Policy (no MDM enrollment). IT wants to remove all corporate data from the device while leaving the employee's personal photos and apps intact. Which Intune action should be performed?
   - A) Wipe the device remotely from Intune
   - B) Retire the device from Intune
   - C) Delete the device from Intune
   - D) Perform a selective app wipe via App Protection

<details>
<summary>Answer</summary>

**D) Perform a selective app wipe via App Protection.** Since the device is not MDM-enrolled, the Retire and Wipe remote actions are not applicable (they require MDM enrollment). A selective app wipe (available for MAM-protected apps) removes only the corporate data within the managed apps (e.g., wipes the Outlook and OneDrive corporate account) while leaving personal data, photos, and apps completely untouched. Deleting the device from Intune (C) removes the device record but does not wipe corporate app data.

</details>

9. A company has 500 Windows devices currently managed by Configuration Manager (SCCM). The organisation wants to start moving to Intune-based management gradually. They want to keep ConfigMgr managing software deployments and Windows Updates, but immediately gain Intune compliance reporting. Which co-management workload should be shifted to Intune first?
   - A) Windows Update policies
   - B) Office Click-to-Run apps
   - C) Compliance policies
   - D) Endpoint Protection

<details>
<summary>Answer</summary>

**C) Compliance policies.** Shifting the Compliance policies workload to Intune is the recommended first step in a co-management migration. It is low-risk (compliance reporting does not disrupt device behaviour), immediately valuable (devices start reporting compliance status to Intune, enabling Conditional Access), and allows the team to validate Intune integration before touching workloads that directly affect software delivery or security. Windows Update policies (A), Office apps (B), and Endpoint Protection (D) have larger operational impact if misconfigured during the transition.

</details>

</details>

---

## Week 7 — Exam preparation

### Activities
- Review weak domains based on the [official exam study guide](https://learn.microsoft.com/en-us/credentials/certifications/resources/study-guides/md-102)
- Complete the **Microsoft Learn practice assessment** for MD-102: [Practice assessment](https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications)
- Revisit lab tasks you felt less confident about (week 2 Intune enrollment, week 5 Autopilot)
- Create a summary of all PowerShell commands used in the lab exercises
- Schedule your exam via Pearson VUE or Certiport

### Exam focus areas
- **Prepare infrastructure (25–30%):** Entra join types, enrollment methods, compliance policies, Conditional Access, Windows LAPS
- **Manage & maintain devices (30–35%):** Autopilot deployment modes, configuration profiles, Windows 365 vs AVD, KQL device queries, Intune Suite add-ons (EPM, Remote Help, Tunnel for MAM)
- **Manage applications (15–20%):** Win32/LOB/Store/M365 Apps, app protection policies, ODT/OCT, Enterprise App Catalog
- **Protect devices (15–20%):** Security baselines, Defender for Endpoint onboarding, update rings vs feature update policies

### Common exam traps — know these cold

| Trap | The correct answer |
|------|--------------------|
| Self-Deploying Autopilot requires a user to sign in | **No** — zero user interaction; device authenticates via TPM 2.0 attestation |
| MAM requires device enrollment | **No** — MAM-WE (without enrollment) applies App Protection Policies to apps on unmanaged BYOD devices |
| A non-compliant device is immediately blocked | **No** — a configurable grace period applies before the block takes effect |
| Security Baseline always overrides Configuration Profiles | **No** — conflicts between policies are reported as Errors; no automatic winner |
| BitLocker always prompts the user during encryption | **No** — Intune supports silent BitLocker encryption via TPM with no user interaction |
| Tenant Attach equals Co-management | **No** — Tenant Attach gives visibility of ConfigMgr devices in the Intune portal; co-management means shared workload authority |
| Autopilot Reset requires reimaging | **No** — Autopilot Reset re-provisions Windows while keeping the device's Autopilot registration and Entra ID object intact |
| The Enterprise App Catalog requires manual packaging | **No** — apps in the catalog are pre-packaged by Microsoft with detection rules and auto-updates included |

---

## Exam Coverage Gaps and Must-Do Labs

This section identifies topics that are tested on the MD-102 exam but are not fully covered by the 7-week SSW-Lab schedule. Complete these before scheduling your exam.

### Topics not fully covered by the weekly labs

1. **Cross-platform enrollment and profiles** — The lab schedule focuses on Windows. The exam tests knowledge of Android Enterprise enrollment modes (Fully Managed, Dedicated, Corporate-Owned Work Profile, Personally-Owned Work Profile), iOS/iPadOS ADE (Automated Device Enrollment via Apple Business Manager), and macOS configuration profiles. Study these conceptually via MS Learn even if you cannot test them in the SSW-Lab environment.

2. **Bulk enrollment via Provisioning Package (PPKG)** — Creating a PPKG with Windows Configuration Designer and applying it during OOBE (via USB) or post-setup (`Add-ProvisioningPackage`). Know when PPKG is the right tool: offline deployments, no Intune license, devices without TPM 2.0.

3. **Delivery Optimization** — Intune policy for peer-to-peer Windows Update content sharing within a subnet, reducing internet bandwidth usage. Know the Download mode options (HTTP only, LAN peering, Internet peering, Simple, Bypass) and when to configure each.

4. **Security Baselines** — Deploying the Windows Security Baseline, Microsoft Defender for Endpoint Baseline, and Microsoft Edge Baseline in Intune (Endpoint security → Security baselines). Understand that baselines are opinionated bundles of recommended settings, not individual profiles, and that conflicting settings between a baseline and a configuration profile are reported as errors without a defined winner.

5. **Attack Surface Reduction (ASR) rules** — Common rules tested on the exam: "Block Office apps from creating executable content", "Block credential stealing from LSASS", "Block JavaScript/VBScript from launching downloaded executables". Know the three modes: Audit (log only), Block (enforce), and Warn (block with user override).

6. **Intune Suite components not tested in the lab** — Remote Help (setup, RBAC roles, session audit logs), Cloud PKI (replaces ADCS + NDES + Intune Certificate Connector), and Microsoft Tunnel for MAM (per-app VPN for non-enrolled mobile devices). Understand the architectural difference between each add-on and the problem it solves.

7. **Co-management workload migration** — Know the co-management slider, the supported workloads, the concept of the Pilot collection, and the recommended sequence for shifting workloads from ConfigMgr to Intune.

### Must-do labs before sitting the exam

1. Create at least one **Android Enterprise enrollment profile** (Fully Managed) in your Intune tenant. Document which settings are exam-relevant (token expiry, QR code provisioning, zero-touch enrollment requirement).

2. Create at least one **iOS/iPadOS configuration profile** with Device restrictions applied via a filter. Note which settings are available that differ from Windows profiles.

3. Configure an **Update ring** (quality deferral 7 days, feature deferral 30 days) and a **Feature update policy** (pin to a specific Windows 11 version) side by side in your Intune tenant. Document the difference in what each controls.

4. Run at least five KQL **device queries** in Intune using the `InstalledApplications`, `SystemInfo`, `LocalUsers`, and `LogicalDrive` tables. Include the query output in your study notes.

5. Perform five complete end-to-end scenarios and document the steps: (a) Enroll a device, (b) create and assign a compliance policy, (c) configure a Conditional Access policy that blocks non-compliant devices, (d) deploy a Required Win32 app, (e) trigger a remote action (Sync, then Retire).

6. Create and test a **Proactive Remediation** (detection script + remediation script pair). Verify that Intune reports the detection and remediation status correctly in the portal.

### Exit criteria — do not schedule the exam until you can answer all of these

1. You can explain all four exam domains with concrete examples drawn from your own lab work (not just from reading).
2. You have performed at least two hands-on labs per exam domain.
3. You score consistently above 75% on the Microsoft Learn practice assessment and can explain — not just identify — why each incorrect answer is wrong.
4. You can draw the Autopilot provisioning flow (OOBE → ESP phases → desktop) from memory.
5. You can explain the difference between these six pairs without hesitation: (Wipe vs Retire) · (Update ring vs Feature update policy) · (Windows LAPS vs Legacy LAPS) · (Co-management vs Tenant Attach) · (Windows 365 vs AVD) · (MAM-WE vs MDM enrollment).
