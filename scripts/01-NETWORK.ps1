#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Configure-HostNetwork.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Configure-HostNetwork.ps1') @args
