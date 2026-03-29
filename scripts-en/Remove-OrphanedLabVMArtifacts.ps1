#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Deep cleanup of SSW-Lab VM leftovers.

.DESCRIPTION
  Cleans VMs from vm-profiles.json, including:
  - Stop running VMs
  - Remove snapshots/checkpoints
  - Remove VM registration
  - Remove attached VHDX/AVHDX files
  - Remove orphan VHDX files in VMPath for known VM names

  By default, this script runs in PREVIEW mode.
  Use -Live to actually delete resources.

.PARAMETER Live
  Executes real changes. Without -Live, only preview output is shown.

.PARAMETER IncludeLabPrefixOrphans
  Also removes orphan disks matching SSW-*.vhdx / SSW-*.avhdx in VMPath.

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
        Write-Host "Not found as a Hyper-V VM (orphan disks may still exist)." -ForegroundColor DarkGray
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
    Write-Host "--- Extra orphan cleanup: SSW-* ---" -ForegroundColor Magenta
    $prefixOrphans = @(
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

Write-Host "=== Summary ($mode) ===" -ForegroundColor Cyan
Write-Host "VMs removed        : $($stats.VmRemoved)"
Write-Host "VMs skipped        : $($stats.VmSkipped)"
Write-Host "Snapshots removed  : $($stats.SnapshotRemoved)"
Write-Host "Disks removed      : $($stats.DiskRemoved)"
Write-Host "Orphans removed    : $($stats.OrphanRemoved)"
Write-Host "Errors             : $($stats.Errors)"

if (-not $Live) {
    Write-Host ""
    Write-Host "Preview complete. Run with -Live to perform cleanup." -ForegroundColor Yellow
}


