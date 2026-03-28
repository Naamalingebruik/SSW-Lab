#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Build-UnattendedIsos.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Build-UnattendedIsos.ps1') @args
