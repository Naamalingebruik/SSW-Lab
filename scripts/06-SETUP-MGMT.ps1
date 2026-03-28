#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Initialize-ManagementHost.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Initialize-ManagementHost.ps1') @args
