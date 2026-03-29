#Requires -RunAsAdministrator
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$TemplateKey,

    [Parameter(Mandatory)]
    [string]$VmName,

    [string]$IsoPath,

    [int]$MemoryGB,

    [int]$DiskGB,

    [int]$CpuCount,

    [string]$VmRoot,

    [switch]$StartAfter
)

$modulePath = Join-Path $PSScriptRoot '..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force
$SSWConfig = $null
. (Join-Path $PSScriptRoot '..\config.ps1')
if (-not $SSWConfig) {
    throw "Configbestand heeft geen `$SSWConfig opgeleverd: $(Join-Path $PSScriptRoot '..\config.ps1')"
}
$profiles = Get-SSWVmProfiles -Config $SSWConfig

function Write-ExtraVmLog {
    param([string]$Message)
    Write-Output ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Message)
}

function Initialize-LabDirectory {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Set-LabVMDvdIso {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]$VM,
        [Parameter(Mandatory)][string]$IsoPath,
        [int]$MaxAttempts = 4,
        [int]$DelaySeconds = 2
    )

    if (-not (Test-Path -LiteralPath $IsoPath)) {
        throw "ISO pad bestaat niet: $IsoPath"
    }

    $dvd = Get-VMDvdDrive -VM $VM -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $dvd) {
        if (-not $PSCmdlet.ShouldProcess($VM.Name, "DVD drive toevoegen")) {
            return $null
        }
        Add-VMDvdDrive -VM $VM -ErrorAction Stop | Out-Null
        $dvd = Get-VMDvdDrive -VM $VM -ErrorAction Stop | Select-Object -First 1
    }

    $lastError = $null
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            if (-not $PSCmdlet.ShouldProcess($VM.Name, "ISO koppelen: $IsoPath")) {
                return $dvd
            }
            Set-VMDvdDrive -VMName $VM.Name -ControllerNumber $dvd.ControllerNumber -ControllerLocation $dvd.ControllerLocation -Path $null -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 250
            Set-VMDvdDrive -VMName $VM.Name -ControllerNumber $dvd.ControllerNumber -ControllerLocation $dvd.ControllerLocation -Path $IsoPath -ErrorAction Stop
            return (Get-VMDvdDrive -VMName $VM.Name | Where-Object {
                $_.ControllerNumber -eq $dvd.ControllerNumber -and $_.ControllerLocation -eq $dvd.ControllerLocation
            } | Select-Object -First 1)
        } catch {
            $lastError = $_
            if ($attempt -lt $MaxAttempts) {
                Write-ExtraVmLog "Waarschuwing: ISO-koppeling mislukt voor $($VM.Name) (poging $attempt/$MaxAttempts). Nieuwe poging over $DelaySeconds s."
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }

    throw "ISO koppelen aan $($VM.Name) is mislukt na $MaxAttempts pogingen. Laatste fout: $($lastError.Exception.Message)"
}

$template = Get-SSWVmProfile -Profiles $profiles -Name $TemplateKey
$resolvedVmRoot = if ($VmRoot) { $VmRoot } else { $SSWConfig.VMPath }

if (-not $IsoPath) {
    $isoFile = if ($template.OS -eq 'Server2025') { 'SSW-WS2025-Unattend.iso' } else { 'SSW-W11-Unattend.iso' }
    $IsoPath = Join-Path $SSWConfig.ISOPath $isoFile
}

$resolvedMemoryGB = if ($PSBoundParameters.ContainsKey('MemoryGB')) { $MemoryGB } else { [int]$template.RAM_GB }
$resolvedDiskGB = if ($PSBoundParameters.ContainsKey('DiskGB')) { $DiskGB } else { [int]$template.Disk_GB }
$resolvedCpuCount = if ($PSBoundParameters.ContainsKey('CpuCount')) { $CpuCount } else { [int]$template.vCPU }
$vmStorePath = Join-Path $resolvedVmRoot $VmName
$diskPath = Join-Path $resolvedVmRoot "$VmName.vhdx"

if ($resolvedMemoryGB -le 0 -or $resolvedDiskGB -le 0 -or $resolvedCpuCount -le 0) {
    throw "CPU, RAM en disk moeten groter dan 0 zijn."
}

if (Get-VM -Name $VmName -ErrorAction SilentlyContinue) {
    throw "VM '$VmName' bestaat al."
}

if (Test-Path -LiteralPath $vmStorePath) {
    throw "VM-map bestaat al: $vmStorePath"
}

if (Test-Path -LiteralPath $diskPath) {
    throw "Schijfbestand bestaat al: $diskPath"
}

if (-not (Test-Path -LiteralPath $IsoPath)) {
    if ($WhatIfPreference) {
        Write-ExtraVmLog "Waarschuwing: ISO niet gevonden voor preview: $IsoPath"
    } else {
        throw "ISO niet gevonden: $IsoPath"
    }
}

$switch = Get-VMSwitch -Name $SSWConfig.vSwitchName -ErrorAction SilentlyContinue
if (-not $switch) {
    if ($WhatIfPreference) {
        Write-ExtraVmLog "Waarschuwing: vSwitch '$($SSWConfig.vSwitchName)' niet gevonden voor preview."
    } else {
        throw "vSwitch '$($SSWConfig.vSwitchName)' niet gevonden. Run eerst Configure-HostNetwork.ps1."
    }
}

Write-ExtraVmLog "Template: $TemplateKey ($($template.Name))"
Write-ExtraVmLog "Nieuwe VM : $VmName"
Write-ExtraVmLog "Pad       : $resolvedVmRoot"
Write-ExtraVmLog "Switch    : $($SSWConfig.vSwitchName)"
Write-ExtraVmLog "CPU/RAM   : $resolvedCpuCount vCPU / $resolvedMemoryGB GB"
Write-ExtraVmLog "Disk      : $resolvedDiskGB GB"
Write-ExtraVmLog "ISO       : $IsoPath"

if (-not $PSCmdlet.ShouldProcess($VmName, "Extra SSW-lab VM aanmaken")) {
    return
}

if (-not (Test-Path -LiteralPath $IsoPath)) {
    throw "ISO niet gevonden: $IsoPath"
}

if (-not $switch) {
    throw "vSwitch '$($SSWConfig.vSwitchName)' niet gevonden. Run eerst Configure-HostNetwork.ps1."
}

Initialize-LabDirectory -Path $resolvedVmRoot

New-VHD -Path $diskPath -SizeBytes ([int64]$resolvedDiskGB * 1GB) -Dynamic -ErrorAction Stop | Out-Null
$vm = New-VM -Name $VmName -MemoryStartupBytes ([int64]$resolvedMemoryGB * 1GB) -VHDPath $diskPath `
    -SwitchName $SSWConfig.vSwitchName -Generation 2 -Path $resolvedVmRoot -ErrorAction Stop

Set-VM -VM $vm -ProcessorCount $resolvedCpuCount -DynamicMemory:$false -AutomaticCheckpointsEnabled:$false | Out-Null
Set-VMFirmware -VM $vm -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows -ErrorAction Stop
Set-VMKeyProtector -VMName $VmName -NewLocalKeyProtector -ErrorAction Stop | Out-Null
Enable-VMTPM -VMName $VmName -ErrorAction Stop | Out-Null
$dvd = Set-LabVMDvdIso -VM $vm -IsoPath $IsoPath
if ($dvd) {
    Set-VMFirmware -VM $vm -FirstBootDevice $dvd | Out-Null
}

if ($StartAfter) {
    Start-VM -Name $VmName -ErrorAction Stop | Out-Null
    Write-ExtraVmLog "VM '$VmName' gestart."
}

Write-ExtraVmLog "VM '$VmName' succesvol aangemaakt."
