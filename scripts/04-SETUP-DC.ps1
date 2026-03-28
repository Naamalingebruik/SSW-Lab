#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Initialize-DomainController.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Initialize-DomainController.ps1') @args
