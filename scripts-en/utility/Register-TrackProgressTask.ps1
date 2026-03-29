#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$scriptPath = Join-Path $PSScriptRoot 'Get-TrackProgress.ps1'
$taskName   = 'SSW-Lab-TrackProgress'
$taskDesc   = 'Actief certificeringstraject van SSW-Lab bijhouden (genereert status.md en next-steps.md)'

if (-not (Test-Path $scriptPath)) {
    throw "Script niet gevonden: $scriptPath"
}

$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

$pwshPath = 'C:\Program Files\PowerShell\7\pwsh.exe'
if (-not (Test-Path $pwshPath)) {
    $pwshPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
}

$argStr = '-NoProfile -ExecutionPolicy Bypass -File "' + $scriptPath + '"'
$action = New-ScheduledTaskAction -Execute $pwshPath -Argument $argStr
$trigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Hours 2) -Once -At (Get-Date)
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 5) `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal `
    -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) `
    -LogonType Interactive `
    -RunLevel Highest

$task = Register-ScheduledTask `
    -TaskName $taskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description $taskDesc `
    -Force

if (-not $task) {
    throw 'Registratie mislukt.'
}

Write-Host "Taak '$taskName' geregistreerd." -ForegroundColor Green
Write-Host "Script: $scriptPath"
Write-Host "Output: status.md en next-steps.md in de repo-root"

