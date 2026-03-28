#Requires -RunAsAdministrator
# Compat wrapper: oude utilitynaam verwijst door naar Initialize-DhcpScope.ps1
& (Join-Path $PSScriptRoot 'Initialize-DhcpScope.ps1') @args
