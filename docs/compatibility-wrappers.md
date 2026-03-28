# Compatibility Wrappers

De tijdelijke wrapperlaag in `SSW-Lab` is verwijderd.

## Huidige situatie

Gebruik alleen nog de primaire scriptnamen:
- `scripts/Initialize-Preflight.ps1`
- `scripts/Configure-HostNetwork.ps1`
- `scripts/Build-UnattendedIsos.ps1`
- `scripts/New-LabVMs.ps1`
- `scripts/Remove-OrphanedLabVMArtifacts.ps1`
- `scripts/Initialize-DomainController.ps1`
- `scripts/Join-LabComputersToDomain.ps1`
- `scripts/Initialize-ManagementHost.ps1`
- `scripts/utility/Initialize-DhcpScope.ps1`
- `scripts/utility/Repair-W11-02Network.ps1`

## Historische noot

De oude genummerde en alternatieve namen zijn bewust verwijderd nadat docs, runbooks, wiki en build-output op de primaire namen waren gestandaardiseerd.
