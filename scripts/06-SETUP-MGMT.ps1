#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Initialize-ManagementHost.ps1
& (Join-Path $PSScriptRoot 'Initialize-ManagementHost.ps1') @args
