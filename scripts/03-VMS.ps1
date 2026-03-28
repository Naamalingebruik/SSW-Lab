#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar New-LabVMs.ps1
& (Join-Path $PSScriptRoot 'New-LabVMs.ps1') @args
