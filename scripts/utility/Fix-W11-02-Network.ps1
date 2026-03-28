#Requires -RunAsAdministrator
# Compat wrapper: oude utilitynaam verwijst door naar Repair-W11-02Network.ps1
& (Join-Path $PSScriptRoot 'Repair-W11-02Network.ps1') @args
