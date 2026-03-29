#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Stop-LabVMs.ps1
# Sluit alle lab-VMs graceful af in omgekeerde volgorde.
#
# Volgorde (omgekeerd t.o.v. opstarten):
#   1. W11-AUTOPILOT
#   2. W11-02
#   3. W11-01
#   4. MGMT01
#   5. DC01  — laatste, zodat AD/DNS tot het einde beschikbaar blijft
#
# Gebruik:
#   .\Stop-LabVMs.ps1                  # graceful, 60s timeout per VM
#   .\Stop-LabVMs.ps1 -Force           # direct uitzetten (TurnOff)
#   .\Stop-LabVMs.ps1 -Timeout 120     # langere wachttijd
#
# Log → Stop-LabVMs.log (in repo-root, staat in .gitignore)
# ============================================================

[CmdletBinding()]
param(
    [switch]$Force,
    [int]$Timeout = 60    # seconden per VM voor graceful shutdown
)

$ErrorActionPreference = 'Continue'
$script:ShutdownTimeout = $Timeout

# ── Config laden ──────────────────────────────────────────────
$repoRoot   = Join-Path $PSScriptRoot '..\..'
$configPath = Join-Path $repoRoot 'config.ps1'
if (-not (Test-Path $configPath)) { Write-Error "config.ps1 niet gevonden: $configPath"; exit 1 }
. $configPath
$localConfig = Join-Path $repoRoot 'config.local.ps1'
if (Test-Path $localConfig) { . $localConfig }

# ── Logging ───────────────────────────────────────────────────
$logFile = Join-Path $repoRoot 'Stop-LabVMs.log'
function Add-StopLog([string]$msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Output $line
    try {
        Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
    } catch {
        Write-Verbose "Logregel kon niet worden weggeschreven naar $logFile."
    }
}

# ── VM graceful afsluiten ─────────────────────────────────────
function Stop-LabVM([string]$vmName) {
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm) {
        Add-StopLog "  '$vmName' niet gevonden in Hyper-V — overgeslagen."
        return
    }
    if ($vm.State -eq 'Off') {
        Add-StopLog "  '$vmName' staat al uit."
        return
    }

    if ($Force) {
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
        Add-StopLog "  '$vmName' geforceerd uitgezet."
        return
    }

    # Graceful: stuur shutdown-signaal via integration services
    try {
        Stop-VM -Name $vmName -ErrorAction Stop
        Add-StopLog "  '$vmName' shutdown-signaal gestuurd, wachten (max $($script:ShutdownTimeout)s)…"
    } catch {
        Add-StopLog "  '$vmName' graceful shutdown mislukt ($_) — forceer uitzetten."
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
        return
    }

    $deadline = (Get-Date).AddSeconds($script:ShutdownTimeout)
    while ((Get-VM -Name $vmName -ErrorAction SilentlyContinue).State -ne 'Off' -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
    }

    if ((Get-VM -Name $vmName -ErrorAction SilentlyContinue).State -ne 'Off') {
        Add-StopLog "  '$vmName' na $($script:ShutdownTimeout)s nog niet uit — forceer uitzetten."
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
    } else {
        Add-StopLog "  '$vmName' is afgesloten."
    }
}

# ── Hoofdprogramma ────────────────────────────────────────────
Add-StopLog "======================================================"
Add-StopLog "  SSW-Lab Stop$(if ($Force) { ' (geforceerd)' })"
Add-StopLog "======================================================"

$profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json

$stopOrder = @('W11-AUTOPILOT', 'W11-02', 'W11-01', 'MGMT01', 'DC01')
foreach ($key in $stopOrder) {
    $vmProfile = $profiles.$key
    if (-not $vmProfile) { Add-StopLog "  Profiel '$key' niet gevonden — overgeslagen."; continue }
    Stop-LabVM -vmName $vmProfile.Name
}

Add-StopLog "======================================================"
Add-StopLog "  SSW-Lab Stop voltooid."
Add-StopLog "======================================================"
