#Requires -RunAsAdministrator
# Compat wrapper: old step name forwards to New-LabVMs.ps1
& (Join-Path $PSScriptRoot 'New-LabVMs.ps1') @args
