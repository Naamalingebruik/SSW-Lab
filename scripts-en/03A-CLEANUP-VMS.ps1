#Requires -RunAsAdministrator
# Compat wrapper: old step name forwards to Remove-OrphanedLabVMArtifacts.ps1
& (Join-Path $PSScriptRoot 'Remove-OrphanedLabVMArtifacts.ps1') @args
