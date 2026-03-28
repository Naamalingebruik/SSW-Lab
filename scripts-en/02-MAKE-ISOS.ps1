#Requires -RunAsAdministrator
# Compat wrapper: old step name forwards to Build-UnattendedIsos.ps1
& (Join-Path $PSScriptRoot 'Build-UnattendedIsos.ps1') @args
