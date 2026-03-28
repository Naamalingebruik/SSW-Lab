#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Join-LabComputersToDomain.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Join-LabComputersToDomain.ps1') @args
