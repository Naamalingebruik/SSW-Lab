#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Initialize-Preflight.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Initialize-Preflight.ps1') @args
