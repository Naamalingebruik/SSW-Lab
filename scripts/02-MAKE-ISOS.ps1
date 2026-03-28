#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Build-UnattendedIsos.ps1
& (Join-Path $PSScriptRoot 'Build-UnattendedIsos.ps1') @args
