#Requires -RunAsAdministrator
# Compat wrapper: oude utilitynaam verwijst door naar Initialize-DhcpScope.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Initialize-DhcpScope.ps1') @args
