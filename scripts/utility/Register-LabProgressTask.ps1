#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Registreert een Windows Scheduled Task die Get-LabProgress.ps1 elk uur draait.
.DESCRIPTION
    Maakt taak 'SSW-Lab-Progress' aan in Task Scheduler. Draait elke 2 uur als
    de huidige gebruiker. Output gaat naar sog-status.md in de repo-root.
#>

$scriptPath = Join-Path $PSScriptRoot 'Get-LabProgress.ps1'
$taskName   = 'SSW-Lab-Progress'
$taskDesc   = 'MD-102 lab voortgang bijhouden (genereert sog-status.md)'

if (-not (Test-Path $scriptPath)) {
    Write-Error "Script niet gevonden: $scriptPath"
    exit 1
}

# Verwijder bestaande taak als die er al is
$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Bestaande taak '$taskName' verwijderd." -ForegroundColor Yellow
}

# Action: pwsh (PS7) voor graph module support, anders Windows PowerShell
$pwshPath = 'C:\Program Files\PowerShell\7\pwsh.exe'
if (-not (Test-Path $pwshPath)) { $pwshPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" }

$argStr = '-NoProfile -ExecutionPolicy Bypass -File "' + $scriptPath + '" -Quiet'
$action = New-ScheduledTaskAction -Execute $pwshPath -Argument $argStr

# Trigger: elke 2 uur
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Hours 2) -Once -At (Get-Date)

# Settings
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
    -RunOnlyIfNetworkAvailable `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew

# Principal: huidige gebruiker
$principal = New-ScheduledTaskPrincipal `
    -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) `
    -LogonType Interactive `
    -RunLevel Highest

$task = Register-ScheduledTask `
    -TaskName  $taskName `
    -Action    $action `
    -Trigger   $trigger `
    -Settings  $settings `
    -Principal $principal `
    -Description $taskDesc `
    -Force

if ($task) {
    Write-Host ''
    Write-Host "Taak '$taskName' geregistreerd." -ForegroundColor Green
    Write-Host "Script: $scriptPath"
    Write-Host "Interval: elke 2 uur (start bij inloggen)"
    Write-Host ''
    Write-Host 'Nu direct uitvoeren...' -ForegroundColor Cyan
    Start-ScheduledTask -TaskName $taskName
    Start-Sleep -Seconds 3
    $state = (Get-ScheduledTask -TaskName $taskName).State
    Write-Host "Taakstatus: $state"
} else {
    Write-Error 'Registratie mislukt.'
}
