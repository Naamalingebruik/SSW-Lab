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

# ── Config laden ──────────────────────────────────────────────
$repoRoot   = Join-Path $PSScriptRoot '..\..'
$configPath = Join-Path $repoRoot 'config.ps1'
if (-not (Test-Path $configPath)) { Write-Error "config.ps1 niet gevonden: $configPath"; exit 1 }
. $configPath
$localConfig = Join-Path $repoRoot 'config.local.ps1'
if (Test-Path $localConfig) { . $localConfig }

# ── Logging ───────────────────────────────────────────────────
$logFile = Join-Path $repoRoot 'Stop-LabVMs.log'
function Write-Log([string]$msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    try { Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue } catch {}
}

# ── VM graceful afsluiten ─────────────────────────────────────
function Stop-LabVM([string]$vmName) {
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm) {
        Write-Log "  '$vmName' niet gevonden in Hyper-V — overgeslagen."
        return
    }
    if ($vm.State -eq 'Off') {
        Write-Log "  '$vmName' staat al uit."
        return
    }

    if ($Force) {
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
        Write-Log "  '$vmName' geforceerd uitgezet."
        return
    }

    # Graceful: stuur shutdown-signaal via integration services
    try {
        Stop-VM -Name $vmName -ErrorAction Stop
        Write-Log "  '$vmName' shutdown-signaal gestuurd, wachten (max ${Timeout}s)…"
    } catch {
        Write-Log "  '$vmName' graceful shutdown mislukt ($_) — forceer uitzetten."
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
        return
    }

    $deadline = (Get-Date).AddSeconds($Timeout)
    while ((Get-VM -Name $vmName -ErrorAction SilentlyContinue).State -ne 'Off' -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
    }

    if ((Get-VM -Name $vmName -ErrorAction SilentlyContinue).State -ne 'Off') {
        Write-Log "  '$vmName' na ${Timeout}s nog niet uit — forceer uitzetten."
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
    } else {
        Write-Log "  '$vmName' is afgesloten."
    }
}

# ── Hoofdprogramma ────────────────────────────────────────────
Write-Log "======================================================"
Write-Log "  SSW-Lab Stop$(if ($Force) { ' (geforceerd)' })"
Write-Log "======================================================"

$profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json

$stopOrder = @('W11-AUTOPILOT', 'W11-02', 'W11-01', 'MGMT01', 'DC01')
foreach ($key in $stopOrder) {
    $vmProfile = $profiles.$key
    if (-not $vmProfile) { Write-Log "  Profiel '$key' niet gevonden — overgeslagen."; continue }
    Stop-LabVM -vmName $vmProfile.Name
}

Write-Log "======================================================"
Write-Log "  SSW-Lab Stop voltooid."
Write-Log "======================================================"
