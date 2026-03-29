@{
    RootModule        = 'SSWLab.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = 'f5b6cbf3-0ef9-4472-8fb1-9cb55683fca2'
    Author            = 'OpenAI Codex'
    CompanyName       = 'SSW-Lab'
    Copyright         = '(c) SSW-Lab'
    Description       = 'Herbruikbare logica voor SSW-Lab scripts.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
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
}
