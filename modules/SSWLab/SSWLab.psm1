Set-StrictMode -Version Latest

$privatePath = Join-Path $PSScriptRoot 'Private'
if (Test-Path -LiteralPath $privatePath) {
    foreach ($file in Get-ChildItem -LiteralPath $privatePath -Filter '*.ps1' | Sort-Object Name) {
        . $file.FullName
    }
}

$publicPath = Join-Path $PSScriptRoot 'Public'
if (Test-Path -LiteralPath $publicPath) {
    foreach ($file in Get-ChildItem -LiteralPath $publicPath -Filter '*.ps1' | Sort-Object Name) {
        . $file.FullName
    }
}

Export-ModuleMember -Function @(
    'ConvertTo-SSWSecureString',
    'ConvertFrom-SSWSecureString',
    'Import-SSWLabConfig',
    'Get-SSWVmProfiles',
    'Get-SSWVmProfile',
    'Get-SSWVmSelectionRamTotal',
    'Get-SSWPresetVmKeys',
    'Get-SSWDefaultIsoPath',
    'Get-SSWSecret',
    'New-SSWCredential',
    'Test-SSWSecretPolicy',
    'Test-SSWConfig',
    'New-SSWUnattendIso',
    'New-SSWW11UnattendXml',
    'New-SSWServer2025UnattendXml',
    'Set-SSWVMDvdIsoWithRetry',
    'New-SSWLabVm',
    'Import-SSWTrackDefinitions',
    'Get-SSWTrackDefinition',
    'Set-SSWCurrentTrack',
    'Get-SSWTrackProgress'
)
