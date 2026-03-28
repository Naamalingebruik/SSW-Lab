#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Join-LabComputersToDomain.ps1
& (Join-Path $PSScriptRoot 'Join-LabComputersToDomain.ps1') @args
