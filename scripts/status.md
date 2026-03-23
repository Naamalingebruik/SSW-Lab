# SSW-Lab â€” Voortgangsstatus MD-102

_Gegenereerd: 2026-03-22 18:51 (host: LNL-5CG5252876)_
_Examendomeinen gebaseerd op: [MS Learn MD-102 study guide](https://learn.microsoft.com/credentials/certifications/resources/study-guides/md-102) (bijgewerkt jan 2026)_

---

## VM-overzicht

| VM | State | IP | Join-type | Activatie |
|----|-------|----|-----------|-----------|
| LAB-DC01 | Running | 10.50.10.10 | Domain Controller | â€” |
| LAB-MGMT01 | Running | 10.50.10.20 | Domain Joined | â€” |
| LAB-W11-01 | Running | 10.50.10.30 | Onbekend | Geactiveerd |
| LAB-W11-02 | Running | 10.50.10.31 | Onbekend | Geactiveerd |
| LAB-W11-AUTOPILOT | Running | 10.50.10.32 | Onbekend | Geactiveerd |

---

## Entra Connect (LAB-DC01)

| Check | Status |
|-------|--------|
| GeÃ¯nstalleerd | ✅ |
| ADSync service Running | ✅ |
| UPN-suffix lab.stts.nl in AD | ✅ |
| LastSyncRunStartTime | âš ï¸ nog niet gerund |

---

## Modules op MGMT01

| Module | Beschikbaar |
|--------|------------|
| Microsoft.Graph | ❌ |
| ExchangeOnlineManagement | ❌ |
| Az | ❌ |
| LAPS | ✅ |

---

## MD-102 Voortgang per MS Learn Examendomain

> Bron: [MD-102 Study Guide â€” Microsoft Learn](https://learn.microsoft.com/credentials/certifications/resources/study-guides/md-102)

### Domein 1 â€” Infrastructuur voor devices voorbereiden (25â€“30%)
_Deployment, provisioning, Intune enrollment, Hybrid Join, Autopilot, update management_

| Lab milestone | Bereikt | MS Learn skill |
|---------------|---------|---------------|
| Alle core VMs Running | ✅ | Windows 11 deployment environment |
| Domein ssw.lab actief + labadmin | ✅ | On-premises AD als basis voor Hybrid ID |
| W11-01 Windows geactiveerd | ✅ | Windows client deployment verifiÃ«ren |
| Entra Connect geÃ¯nstalleerd + sync | ✅ | Microsoft Entra Connect configureren |
| UPN-suffix lab.stts.nl in AD | ✅ | UPN-suffix voor Hybrid Join |
| W11-01 Hybrid Entra Joined | ❌ | Hybrid Microsoft Entra Join implementeren |
| W11-02 enrolled (Entra ID device) | ❌ | Entra ID Join / MDM enrollment |
| W11-AUTOPILOT VM klaar + geactiveerd | ✅ | Windows Autopilot deployment voorbereiden |
| Autopilot hash geÃ¼pload | âŒ | Autopilot device registreren |
| Sync daadwerkelijk gerund | ❌ | Sync-cyclus en monitoring |

**Domein 1 voortgang: 6/10 items**

---

### Domein 2 â€” Devices beheren en onderhouden (30â€“35%)
_Compliance policies, Conditional Access, Configuration profiles, remote actions, LAPS_

| Lab milestone | Bereikt | MS Learn skill |
|---------------|---------|---------------|
| W11-01 enrolled in Intune | ❌ | Device enrollment en beheer in Intune |
| W11-02 enrolled in Intune | ❌ | Enrollment methoden (MDM, MAM) |
| Compliance policy aangemaakt | âŒ | Compliance policies configureren |
| Conditional Access policy | âŒ | Conditional Access implementeren |
| Configuration profile (BitLocker) | âŒ | Device configuration profiles |
| LAPS geconfigureerd | ✅ | Windows LAPS via Intune |
| Remote actions (wipe/sync/restart) | âŒ | Device remote actions uitvoeren |
| Devices zichtbaar in Intune-portal | ❌ | Intune device monitoring |

**Domein 2 voortgang: 1/8 items**

---

### Domein 3 â€” Applicaties beheren (15â€“20%)
_Win32 apps, Microsoft Store, M365 Apps, app protection policies_

| Lab milestone | Bereikt | MS Learn skill |
|---------------|---------|---------------|
| Microsoft.Graph module op MGMT01 | ❌ | PowerShell beheer via Graph API |
| ExchangeOnlineManagement module | ❌ | Exchange Online beheer |
| Win32 app verpakt + geÃ¼pload | âŒ | Win32 app packaging (.intunewin) |
| App assignment (Required) | âŒ | App deployment methoden |
| M365 Apps deployment | âŒ | Microsoft 365 Apps via Intune |
| App protection policy (MAM) | âŒ | MAM zonder MDM enrollment |

**Domein 3 voortgang: 0/6 items**

---

### Domein 4 â€” Devices beveiligen (15â€“20%)
_Defender for Endpoint, security baselines, disk encryption, Windows Firewall_

| Lab milestone | Bereikt | MS Learn skill |
|---------------|---------|---------------|
| Security baseline policy | âŒ | Security baselines in Intune |
| BitLocker compliance policy | âŒ | Disk encryption afdwingen |
| Defender for Endpoint onboarding | âŒ | MDE onboarden via Intune |
| Windows Firewall via Intune | âŒ | Endpoint security policies |
| Attack surface reduction rules | âŒ | ASR-regels configureren |

**Domein 4 voortgang: 0/5 items**

---

## Totaaloverzicht examenvoortgang

| Domein | Gewicht | Lab-items klaar | Schatting |
|--------|---------|-----------------|-----------|
| D1 Infrastructuur devices voorbereiden | 25-30% | 6/10 | ~16% van examen |
| D2 Devices beheren en onderhouden | 30-35% | 1/8 | ~4% van examen |
| D3 Applicaties beheren | 15-20% | 0/6 | ~0% van examen |
| D4 Devices beveiligen | 15-20% | 0/5 | ~0% van examen |

> âš ï¸ Dit is een lab-completeness schatting, geen directe examenscore. Kennischeck en conceptueel begrip tellen mee.

---

## Aanbevolen volgende stappen

[ACTIE] W11-02: Nog niet gejoined. Settings -> Accounts -> Access work or school -> Join to Microsoft Entra ID -> lab.stts.nl

[WARN] Entra Connect: sync nog niet uitgevoerd. Forceer: Start-ADSyncSyncCycle -PolicyType Delta

[INFO] W11-01: Hybrid gejoined maar nog niet MDM-enrolled. Wacht op auto-enrollment of configureer via Intune-portal.

[ACTIE] MGMT01: Microsoft.Graph ontbreekt. Install-Module Microsoft.Graph -Scope AllUsers

[ACTIE] MGMT01: ExchangeOnlineManagement ontbreekt. Nodig voor week 4+ labs.

[VOLGENDE] W11-AUTOPILOT: Geactiveerd. Volgende stap: Autopilot hash uploaden voor Autopilot-flow.

---

_Script: `scripts/utility/Get-LabProgress.ps1` | Herchecken: voer script opnieuw uit_
