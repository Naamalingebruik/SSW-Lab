#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Grondige cleanup van SSW-Lab VM-residu.

.DESCRIPTION
  Ruimt de VMs uit vm-profiles.json op, inclusief:
  - Stoppen van draaiende VMs
  - Verwijderen van snapshots/checkpoints
  - Verwijderen van de VM registratie
  - Verwijderen van gekoppelde VHDX/AVHDX bestanden
  - Opruimen van orphan VHDX in VMPath met bekende VM-namen

  Standaard draait dit script in PREVIEW modus.
  Gebruik -Live om echt te verwijderen.

.PARAMETER Live
  Voert echte wijzigingen uit. Zonder -Live is het een preview.

.PARAMETER IncludeLabPrefixOrphans
  Verwijder ook orphan disks met naam LAB-*.vhdx / LAB-*.avhdx en oude SSW-*.vhdx / SSW-*.avhdx in VMPath.

.EXAMPLE
  .\Remove-OrphanedLabVMArtifacts.ps1

.EXAMPLE
  .\Remove-OrphanedLabVMArtifacts.ps1 -Live

.EXAMPLE
  .\Remove-OrphanedLabVMArtifacts.ps1 -Live -IncludeLabPrefixOrphans
#>
param(
    [switch]$Live,
    [switch]$IncludeLabPrefixOrphans
)

. "$PSScriptRoot\..\config.ps1"

$profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
$targetVmNames = @(
    $profiles.PSObject.Properties.Value | ForEach-Object { $_.Name }
) | Sort-Object -Unique

$mode = if ($Live) { "LIVE" } else { "PREVIEW" }
Write-Host "=== SSW-Lab VM cleanup ($mode) ===" -ForegroundColor Cyan
Write-Host "VMPath: $($SSWConfig.VMPath)"
Write-Host "Target VMs: $($targetVmNames -join ', ')"
Write-Host ""

$stats = [ordered]@{
    VmRemoved            = 0
    VmSkipped            = 0
    SnapshotRemoved      = 0
    DiskRemoved          = 0
    OrphanRemoved        = 0
    Errors               = 0
}

function Invoke-Action {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    if (-not $Live) {
        Write-Host "[PREVIEW] $Label" -ForegroundColor Yellow
        return $true
    }

    try {
        & $Action
        Write-Host "[OK] $Label" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[ERROR] $Label -> $($_.Exception.Message)" -ForegroundColor Red
        $script:stats.Errors++
        return $false
    }
}

foreach ($vmName in $targetVmNames) {
    Write-Host "--- $vmName ---" -ForegroundColor Magenta

    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm) {
        Write-Host "Niet gevonden als Hyper-V VM (kan wel orphan disk hebben)." -ForegroundColor DarkGray
        $stats.VmSkipped++
    } else {
        $diskPaths = @(Get-VMHardDiskDrive -VMName $vmName -ErrorAction SilentlyContinue | ForEach-Object { $_.Path }) |
            Where-Object { $_ } |
            Sort-Object -Unique

        if ($vm.State -ne 'Off') {
            Invoke-Action "Stop-VM $vmName" { Stop-VM -Name $vmName -TurnOff -Force -ErrorAction Stop } | Out-Null
        }

        $snaps = @(Get-VMSnapshot -VMName $vmName -ErrorAction SilentlyContinue)
        if ($snaps.Count -gt 0) {
            Invoke-Action "Remove-VMSnapshot $vmName ($($snaps.Count) checkpoints)" {
                Remove-VMSnapshot -VMName $vmName -IncludeAllChildSnapshots -ErrorAction Stop
            } | Out-Null
            if ($Live) { $stats.SnapshotRemoved += $snaps.Count }
        }

        $removedVm = Invoke-Action "Remove-VM $vmName" {
            Remove-VM -Name $vmName -Force -ErrorAction Stop
        }

        if ($removedVm) {
            if ($Live) { $stats.VmRemoved++ }

            foreach ($path in $diskPaths) {
                if (Test-Path $path) {
                    $removedDisk = Invoke-Action "Remove disk $path" {
                        Remove-Item -Path $path -Force -ErrorAction Stop
                    }
                    if ($removedDisk -and $Live) { $stats.DiskRemoved++ }
                }
            }
        }
    }

    # Orphan disks in VMPath for this VM name (covers old failed/partial attempts)
    $namePattern = "$vmName*.vhdx"
    $orphans = @(Get-ChildItem -Path $SSWConfig.VMPath -Filter $namePattern -File -ErrorAction SilentlyContinue)
    foreach ($orphan in $orphans) {
        $removedOrphan = Invoke-Action "Remove orphan $($orphan.FullName)" {
            Remove-Item -Path $orphan.FullName -Force -ErrorAction Stop
        }
        if ($removedOrphan -and $Live) { $stats.OrphanRemoved++ }
    }

    $avhdPattern = "$vmName*.avhdx"
    $orphansAvhd = @(Get-ChildItem -Path $SSWConfig.VMPath -Filter $avhdPattern -File -ErrorAction SilentlyContinue)
    foreach ($orphan in $orphansAvhd) {
        $removedOrphan = Invoke-Action "Remove orphan $($orphan.FullName)" {
            Remove-Item -Path $orphan.FullName -Force -ErrorAction Stop
        }
        if ($removedOrphan -and $Live) { $stats.OrphanRemoved++ }
    }

    Write-Host ""
}

if ($IncludeLabPrefixOrphans) {
    Write-Host "--- Extra orphan cleanup: LAB-* + oud SSW-* ---" -ForegroundColor Magenta
    $prefixOrphans = @(
        Get-ChildItem -Path $SSWConfig.VMPath -Filter "LAB-*.vhdx" -File -ErrorAction SilentlyContinue
        Get-ChildItem -Path $SSWConfig.VMPath -Filter "LAB-*.avhdx" -File -ErrorAction SilentlyContinue
        Get-ChildItem -Path $SSWConfig.VMPath -Filter "SSW-*.vhdx" -File -ErrorAction SilentlyContinue
        Get-ChildItem -Path $SSWConfig.VMPath -Filter "SSW-*.avhdx" -File -ErrorAction SilentlyContinue
    ) | Sort-Object FullName -Unique

    foreach ($orphan in $prefixOrphans) {
        $removed = Invoke-Action "Remove prefix orphan $($orphan.FullName)" {
            Remove-Item -Path $orphan.FullName -Force -ErrorAction Stop
        }
        if ($removed -and $Live) { $stats.OrphanRemoved++ }
    }
    Write-Host ""
}

Write-Host "=== Samenvatting ($mode) ===" -ForegroundColor Cyan
Write-Host "VM verwijderd      : $($stats.VmRemoved)"
Write-Host "VM overgeslagen    : $($stats.VmSkipped)"
Write-Host "Snapshots verwijderd: $($stats.SnapshotRemoved)"
Write-Host "Disks verwijderd   : $($stats.DiskRemoved)"
Write-Host "Orphans verwijderd : $($stats.OrphanRemoved)"
Write-Host "Fouten             : $($stats.Errors)"

if (-not $Live) {
    Write-Host ""
    Write-Host "Preview klaar. Run met -Live om echt op te ruimen." -ForegroundColor Yellow
}

