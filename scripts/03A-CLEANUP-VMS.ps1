#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Remove-OrphanedLabVMArtifacts.ps1
& (Join-Path $PSScriptRoot 'Remove-OrphanedLabVMArtifacts.ps1') @args
