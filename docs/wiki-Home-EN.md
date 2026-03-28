# SSW-Lab — Current Wiki Home

> 🌐 **Language:** English | [Nederlands](wiki-Home.md)
>
> **Effective version since:** `2026-03-28 23:14 +01:00`
>
> **Important:** this is now the authoritative wiki version for `SSW-Lab`. Older text, screenshots, wrapper names, and references to the retired fixed MD-102 progress flow are no longer authoritative.

`SSW-Lab` is a Hyper-V lab for Microsoft certification tracks on a laptop or workstation, with focus on:
- `MD-102`
- `MS-102`
- `SC-300`
- `AZ-104`

The repository now uses:
- primary script names only, without the wrapper layer
- shared logic through `modules/SSWLab`
- track-driven progress instead of a fixed MD-102 status flow

---

## What is the current operating model?

The current operational flow in `SSW-Lab` is:
1. start with [Initialize-Preflight.ps1](D:\GitHub\SSW-Lab\scripts\Initialize-Preflight.ps1)
2. configure networking with [Configure-HostNetwork.ps1](D:\GitHub\SSW-Lab\scripts\Configure-HostNetwork.ps1)
3. build unattended ISOs with [Build-UnattendedIsos.ps1](D:\GitHub\SSW-Lab\scripts\Build-UnattendedIsos.ps1)
4. create VMs with [New-LabVMs.ps1](D:\GitHub\SSW-Lab\scripts\New-LabVMs.ps1)
5. configure the domain controller with [Initialize-DomainController.ps1](D:\GitHub\SSW-Lab\scripts\Initialize-DomainController.ps1)
6. join clients with [Join-LabComputersToDomain.ps1](D:\GitHub\SSW-Lab\scripts\Join-LabComputersToDomain.ps1)
7. continue with the labs under `scripts/labs/<TRACK>/`

Use these primary script names from now on. The old numbered wrappers have been removed.

---

## Track selection and progress

This wiki now assumes `SSW-Lab` is operated in a track-driven way.

Supported tracks:
- `MD102`
- `MS102`
- `SC300`
- `AZ104`

The active progress flow is now:
- [Set-CurrentTrack.ps1](D:\GitHub\SSW-Lab\scripts\utility\Set-CurrentTrack.ps1)
- [Set-TrackCheckpoint.ps1](D:\GitHub\SSW-Lab\scripts\utility\Set-TrackCheckpoint.ps1)
- [Get-TrackProgress.ps1](D:\GitHub\SSW-Lab\scripts\utility\Get-TrackProgress.ps1)
- [Register-TrackProgressTask.ps1](D:\GitHub\SSW-Lab\scripts\utility\Register-TrackProgressTask.ps1)

The track choice made in [Initialize-Preflight.ps1](D:\GitHub\SSW-Lab\scripts\Initialize-Preflight.ps1) and [Initialize-ManagementHost.ps1](D:\GitHub\SSW-Lab\scripts\Initialize-ManagementHost.ps1) now feeds this state automatically. Manual use of `Set-CurrentTrack.ps1` is only needed when you intentionally want to override the current track later.

This flow writes local state to:
- `profiles/current-track.local.json`
- `profiles/track-checkpoints.local.json`
- `status.md`
- `next-steps.md`

These files are intentionally ignored by git. Progress is personal and local by design.

**No longer valid:**
- the old fixed MD-102 progress flow
- `Get-LabProgress.ps1`
- `Register-LabProgressTask.ps1`
- references to `sog-status.md` as the primary status output

---

## Current quick start

```powershell
.\scripts\Initialize-Preflight.ps1
.\scripts\Configure-HostNetwork.ps1
.\scripts\Build-UnattendedIsos.ps1
.\scripts\New-LabVMs.ps1
.\scripts\Initialize-DomainController.ps1
.\scripts\Join-LabComputersToDomain.ps1
```

Then follow your track:

```powershell
.\scripts\utility\Set-CurrentTrack.ps1 -TrackId MS102
.\scripts\utility\Get-TrackProgress.ps1
```

Mark a checkpoint as completed:

```powershell
.\scripts\utility\Set-TrackCheckpoint.ps1 -CheckpointId week1 -Note "Tenant baseline ready"
```

---

## Tracks and recommended presets

| Track | Recommended preset | Main purpose |
|---|---|---|
| `MD102` | `Full` | Endpoint deployment, Intune, Autopilot, compliance, security |
| `MS102` | `Standard` | Microsoft 365 administration, hybrid identity, Exchange, Teams, SharePoint, Defender |
| `SC300` | `Minimal` or `Standard` | Identity, Conditional Access, app registrations, governance |
| `AZ104` | `Minimal` | Hybrid identity plus network and management scenarios alongside Azure exercises |

The actual track definitions and checkpoints live in [learning-tracks.json](D:\GitHub\SSW-Lab\profiles\learning-tracks.json).

---

## Important technical principles

- `SSW-Lab` uses `ssw.lab` as its internal domain.
- More shared logic now lives in [SSWLab.psm1](D:\GitHub\SSW-Lab\modules\SSWLab\SSWLab.psm1).
- Secrets should not live in repo files; environment variables or SecretManagement are preferred.
- `Pester` and `PSScriptAnalyzer` are part of the quality flow through [Invoke-QualityChecks.ps1](D:\GitHub\SSW-Lab\build\Invoke-QualityChecks.ps1).

---

## What is explicitly retired?

From this wiki version onward, the following assumptions are no longer valid:
- “Numbered script names remain as wrappers”
- “Progress is determined by one central MD-102 status script”
- “Status belongs in a historical dump under `scripts/`”

The current decisions and rationale are recorded in [decisions.md](D:\GitHub\SSW-Lab\decisions.md).
