#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Registreert Start-LabVMs.ps1 als Windows Scheduled Task.
.DESCRIPTION
    Maakt taak 'SSW-Lab-Startup' aan in Task Scheduler.
    Trigger  : bij systeemstart (before user logon)
    Account  : SYSTEM (zodat netwerk + Hyper-V altijd beschikbaar zijn)
    Effect   : na elke host-reboot wordt automatisch:
               - het interne netwerk (vSwitch / NAT / gateway-IP) hersteld
               - DC01 gestart en gewacht totdat AD beschikbaar is
               - DHCP op DC01 gecontroleerd (scope + Autopilot-reservering)
               - overige VMs gestart in volgorde: MGMT01 → W11-01 → W11-02 → W11-AUTOPILOT
    Log      : Start-LabVMs.log in de repo-root (staat in .gitignore)
#>

$scriptPath = Join-Path $PSScriptRoot 'Start-LabVMs.ps1'
$taskName   = 'SSW-Lab-Startup'
$taskDesc   = 'SSW-Lab: netwerk herstellen en VMs starten bij systeemstart (Configure-HostNetwork + volgorde DC→clients)'

if (-not (Test-Path $scriptPath)) {
    Write-Error "Script not found: $scriptPath"
    exit 1
}

# Bestaande taak verwijderen
$existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existing) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Host "Bestaande taak '$taskName' verwijderd." -ForegroundColor Yellow
}

# PowerShell executable: PS7 bij voorkeur, anders Windows PS
$pwshPath = 'C:\Program Files\PowerShell\7\pwsh.exe'
if (-not (Test-Path $pwshPath)) {
    $pwshPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
}

# Actie
$argStr  = "-NoProfile -ExecutionPolicy Bypass -NonInteractive -File `"$scriptPath`""
$action  = New-ScheduledTaskAction -Execute $pwshPath -Argument $argStr

# Trigger: bij systeemstart — 30 sec vertraging zodat Hyper-V-services tijd hebben om te laden
$trigger = New-ScheduledTaskTrigger -AtStartup
$trigger.Delay = 'PT30S'   # ISO 8601 — 30 seconden

# Instellingen
$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit   (New-TimeSpan -Minutes 15) `
    -StartWhenAvailable `
    -MultipleInstances    IgnoreNew `
    -RunOnlyIfIdle:$false

# Principal: SYSTEM — draait voor userslogin, heeft altijd access tot Hyper-V
$principal = New-ScheduledTaskPrincipal `
    -UserId    'SYSTEM' `
    -LogonType ServiceAccount `
    -RunLevel  Highest

$task = Register-ScheduledTask `
    -TaskName    $taskName `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -Principal   $principal `
    -Description $taskDesc `
    -Force

if ($task) {
    Write-Host ''
    Write-Host "Taak '$taskName' geregistreerd." -ForegroundColor Green
    Write-Host "  Script  : $scriptPath" -ForegroundColor Cyan
    Write-Host "  Trigger : bij systeemstart (30 sec vertraging)"
    Write-Host "  Account : SYSTEM (before user logon)"
    Write-Host "  Log     : $(Resolve-Path (Join-Path $PSScriptRoot '..\..\Start-LabVMs.log') -ErrorAction SilentlyContinue)"
    Write-Host ''

    $ans = Read-Host "Wil je de taak nu direct testen? (Y/N)"
    if ($ans -match '^[Yy]') {
        Write-Host "Taak starten…" -ForegroundColor Cyan
        Start-ScheduledTask -TaskName $taskName
        Start-Sleep -Seconds 8
        $state = (Get-ScheduledTask -TaskName $taskName).State
        $logPath = Join-Path $PSScriptRoot '..\..\Start-LabVMs.log'
        Write-Host "Taakstatus : $state"
        if (Test-Path $logPath) {
            Write-Host ''
            Write-Host "Laatste logregels:" -ForegroundColor Yellow
            Get-Content $logPath -Tail 20
        }
    }
} else {
    Write-Error 'Registratie mislukt.'
}



