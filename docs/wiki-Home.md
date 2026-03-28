# SSW-Lab — Geldende Wiki Home

> 🌐 **Taal:** Nederlands | [English](wiki-Home-EN.md)
>
> **Geldende versie vanaf:** `2026-03-28 23:14 +01:00`
>
> **Belangrijk:** dit is vanaf heden de leidende wiki-versie voor `SSW-Lab`. Oudere teksten, screenshots, wrappernamen en verwijzingen naar de oude vaste MD-102 progress-flow zijn niet meer leidend.

`SSW-Lab` is een Hyper-V lab voor Microsoft-certificeringstrajecten op een laptop of werkstation, met focus op:
- `MD-102`
- `MS-102`
- `SC-300`
- `AZ-104`

De repo gebruikt nu:
- primaire scriptnamen zonder wrapperlaag
- gedeelde logica via `modules/SSWLab`
- trajectgestuurde voortgang in plaats van een vaste MD-102-statusflow

---

## Wat is nu de geldende werkwijze?

De geldende operationele flow in `SSW-Lab` is:
1. start met [Initialize-Preflight.ps1](D:\GitHub\SSW-Lab\scripts\Initialize-Preflight.ps1)
2. richt netwerk in met [Configure-HostNetwork.ps1](D:\GitHub\SSW-Lab\scripts\Configure-HostNetwork.ps1)
3. bouw unattended ISO’s met [Build-UnattendedIsos.ps1](D:\GitHub\SSW-Lab\scripts\Build-UnattendedIsos.ps1)
4. maak VM’s aan met [New-LabVMs.ps1](D:\GitHub\SSW-Lab\scripts\New-LabVMs.ps1)
5. richt de domain controller in met [Initialize-DomainController.ps1](D:\GitHub\SSW-Lab\scripts\Initialize-DomainController.ps1)
6. join clients met [Join-LabComputersToDomain.ps1](D:\GitHub\SSW-Lab\scripts\Join-LabComputersToDomain.ps1)
7. werk daarna verder in de labs onder `scripts/labs/<TRACK>/`

Gebruik vanaf nu alleen deze primaire scriptnamen. De oude genummerde wrappers zijn verwijderd.

---

## Trajectkeuze en voortgang

De wiki gaat er vanaf nu vanuit dat werken in `SSW-Lab` trajectgestuurd gebeurt.

Ondersteunde trajecten:
- `MD102`
- `MS102`
- `SC300`
- `AZ104`

De voortgangsflow is nu:
- [Set-CurrentTrack.ps1](D:\GitHub\SSW-Lab\scripts\utility\Set-CurrentTrack.ps1)
- [Set-TrackCheckpoint.ps1](D:\GitHub\SSW-Lab\scripts\utility\Set-TrackCheckpoint.ps1)
- [Get-TrackProgress.ps1](D:\GitHub\SSW-Lab\scripts\utility\Get-TrackProgress.ps1)
- [Register-TrackProgressTask.ps1](D:\GitHub\SSW-Lab\scripts\utility\Register-TrackProgressTask.ps1)

De trajectkeuze uit [Initialize-Preflight.ps1](D:\GitHub\SSW-Lab\scripts\Initialize-Preflight.ps1) en [Initialize-ManagementHost.ps1](D:\GitHub\SSW-Lab\scripts\Initialize-ManagementHost.ps1) voedt deze state nu automatisch. Handmatig zetten via `Set-CurrentTrack.ps1` blijft alleen nodig als je het traject later bewust wilt overschrijven.

Deze flow schrijft lokaal naar:
- `profiles/current-track.local.json`
- `profiles/track-checkpoints.local.json`
- `status.md`
- `next-steps.md`

Deze bestanden staan bewust in `.gitignore`. Voortgang is dus persoonlijk en blijft buiten git.

**Niet meer geldig:**
- de oude vaste MD-102 voortgangsflow
- `Get-LabProgress.ps1`
- `Register-LabProgressTask.ps1`
- verwijzingen naar `sog-status.md` als primaire statusuitvoer

---

## Huidige snelle start

```powershell
.\scripts\Initialize-Preflight.ps1
.\scripts\Configure-HostNetwork.ps1
.\scripts\Build-UnattendedIsos.ps1
.\scripts\New-LabVMs.ps1
.\scripts\Initialize-DomainController.ps1
.\scripts\Join-LabComputersToDomain.ps1
```

Daarna volg je je traject:

```powershell
.\scripts\utility\Set-CurrentTrack.ps1 -TrackId MS102
.\scripts\utility\Get-TrackProgress.ps1
```

Checkpoint afronden:

```powershell
.\scripts\utility\Set-TrackCheckpoint.ps1 -CheckpointId week1 -Note "Tenantbasis staat"
```

---

## Trajecten en aanbevolen presets

| Traject | Aanbevolen preset | Doel |
|---|---|---|
| `MD102` | `Full` | Endpoint deployment, Intune, Autopilot, compliance, security |
| `MS102` | `Standard` | Microsoft 365 beheer, hybrid identity, Exchange, Teams, SharePoint, Defender |
| `SC300` | `Minimal` of `Standard` | Identity, Conditional Access, app registrations, governance |
| `AZ104` | `Minimal` | Hybride identiteit, netwerk- en beheerscenario’s naast Azure-oefeningen |

De feitelijke trajectdefinities en checkpoints staan in [learning-tracks.json](D:\GitHub\SSW-Lab\profiles\learning-tracks.json).

---

## Belangrijke technische uitgangspunten

- `SSW-Lab` gebruikt `ssw.lab` als intern domein.
- De hoofdlogica zit steeds meer in [SSWLab.psm1](D:\GitHub\SSW-Lab\modules\SSWLab\SSWLab.psm1).
- Secrets horen niet in repo-bestanden thuis; environment variables of SecretManagement hebben de voorkeur.
- `Pester` en `PSScriptAnalyzer` zijn onderdeel van de kwaliteitsflow via [Invoke-QualityChecks.ps1](D:\GitHub\SSW-Lab\build\Invoke-QualityChecks.ps1).

---

## Wat is expliciet vervallen?

Vanaf deze wiki-versie zijn de volgende aannames niet meer geldig:
- “Genummerde scriptnamen blijven bestaan als wrappers”
- “Voortgang wordt centraal door één MD-102 script bepaald”
- “Status hoort thuis in een historische dump onder `scripts/`”

De actuele keuzes en onderbouwing staan in [decisions.md](D:\GitHub\SSW-Lab\decisions.md).
