#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar New-LabVMs.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'New-LabVMs.ps1') @args
