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
$SSWConfig = Import-SSWLabConfig -ConfigPath (Join-Path $PSScriptRoot '..\config.ps1')
$profiles = Get-SSWVmProfiles -Config $SSWConfig

function Write-ExtraVmLog {
    param([string]$Message)
    Write-Output ("[{0}] {1}" -f (Get-Date -Format 'HH:mm:ss'), $Message)
}

$template = Get-SSWVmProfile -Profiles $profiles -Name $TemplateKey
$resolvedVmRoot = if ($VmRoot) { $VmRoot } else { $SSWConfig.VMPath }

if (-not $IsoPath) {
    $IsoPath = Get-SSWDefaultIsoPath -Config $SSWConfig -TemplateKey $TemplateKey
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

$vmProfile = [pscustomobject]@{
    Name    = $VmName
    RAM_GB  = $resolvedMemoryGB
    Disk_GB = $resolvedDiskGB
    vCPU    = $resolvedCpuCount
    OS      = $template.OS
}

$vmConfig = @{}
foreach ($key in $SSWConfig.Keys) {
    $vmConfig[$key] = $SSWConfig[$key]
}
$vmConfig.VMPath = $resolvedVmRoot

$null = New-SSWLabVm -VmProfile $vmProfile -Config $vmConfig -IsoPath $IsoPath -Log { param($Message) Write-ExtraVmLog $Message }

if ($StartAfter) {
    Start-VM -Name $VmName -ErrorAction Stop | Out-Null
    Write-ExtraVmLog "VM '$VmName' gestart."
}

Write-ExtraVmLog "VM '$VmName' succesvol aangemaakt."
