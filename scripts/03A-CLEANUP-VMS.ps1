#Requires -RunAsAdministrator
# Compat wrapper: oude stapnaam verwijst door naar Remove-OrphanedLabVMArtifacts.ps1
# Niet verwijderen zonder repo-brede compatibiliteitscheck.
& (Join-Path $PSScriptRoot 'Remove-OrphanedLabVMArtifacts.ps1') @args
