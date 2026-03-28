#Requires -RunAsAdministrator
# Compat wrapper: oude utilitynaam verwijst door naar Repair-W11-02Network.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Repair-W11-02Network.ps1') @args
