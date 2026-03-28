# Compatibility Wrappers

Dit document legt vast waarom een klein aantal scripts met oude bestandsnamen bewust in de repo blijft staan.

## Doel

De wrappers bestaan om backward compatibility te bewaren terwijl de primaire scriptnamen functioneler en consistenter zijn gemaakt.

Gebruik de nieuwe primaire namen voor:
- documentatie
- wiki en runbooks
- build-output
- nieuwe automatisering

Laat de wrappers staan voor:
- bestaande snelkoppelingen
- oude instructies of notities
- lokale gewoonten
- scripts die nog niet zijn opgeschoond buiten de repo

## Regels

- wrappers blijven op hun oorspronkelijke pad staan
- wrappers verwijzen alleen door naar het nieuwe primaire script
- wrappers worden niet verplaatst naar een aparte map
- wrappers worden niet verwijderd zonder repo-brede compatibiliteitscheck

## Actieve wrappers in SSW-Lab

- `scripts/00-PREFLIGHT.ps1` → `scripts/Initialize-Preflight.ps1`
- `scripts/01-NETWORK.ps1` → `scripts/Configure-HostNetwork.ps1`
- `scripts/02-MAKE-ISOS.ps1` → `scripts/Build-UnattendedIsos.ps1`
- `scripts/03-VMS.ps1` → `scripts/New-LabVMs.ps1`
- `scripts/03A-CLEANUP-VMS.ps1` → `scripts/Remove-OrphanedLabVMArtifacts.ps1`
- `scripts/04-SETUP-DC.ps1` → `scripts/Initialize-DomainController.ps1`
- `scripts/05-JOIN-DOMAIN.ps1` → `scripts/Join-LabComputersToDomain.ps1`
- `scripts/06-SETUP-MGMT.ps1` → `scripts/Initialize-ManagementHost.ps1`
- `scripts/utility/_dhcp-setup.ps1` → `scripts/utility/Initialize-DhcpScope.ps1`
- `scripts/utility/Fix-W11-02-Network.ps1` → `scripts/utility/Repair-W11-02Network.ps1`

## Verwijdercheck

Verwijder een wrapper pas als aan alle punten is voldaan:
- alle repo-docs verwijzen naar de primaire naam
- build-scripts, wiki en runbooks zijn opgeschoond
- er is geen operationele afhankelijkheid meer van het oude pad
- de wijziging is bewust vastgelegd in `decisions.md`
