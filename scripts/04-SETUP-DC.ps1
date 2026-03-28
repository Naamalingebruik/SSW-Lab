#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Initialize-DomainController.ps1
& (Join-Path $PSScriptRoot 'Initialize-DomainController.ps1') @args
