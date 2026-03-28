#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Initialize-Preflight.ps1
& (Join-Path $PSScriptRoot 'Initialize-Preflight.ps1') @args
