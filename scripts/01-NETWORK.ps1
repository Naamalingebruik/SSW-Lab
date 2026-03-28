#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Configure-HostNetwork.ps1
& (Join-Path $PSScriptRoot 'Configure-HostNetwork.ps1') @args
