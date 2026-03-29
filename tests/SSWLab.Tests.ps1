$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot 'modules\SSWLab\SSWLab.psd1'

Import-Module $modulePath -Force

Describe 'Get-SSWVmSelectionRamTotal' {
    It 'telt RAM van geselecteerde VM profielen op' {
        $profiles = [pscustomobject]@{
            'DC01'    = [pscustomobject]@{ RAM_GB = 4 }
            'W11-01'  = [pscustomobject]@{ RAM_GB = 6 }
            'MGMT01'  = [pscustomobject]@{ RAM_GB = 8 }
        }

        $result = Get-SSWVmSelectionRamTotal -Profiles $profiles -VmKeys @('DC01', 'W11-01')

        $result | Should -Be 10
    }

    It 'negeert onbekende VM sleutels' {
        $profiles = [pscustomobject]@{
            'DC01' = [pscustomobject]@{ RAM_GB = 4 }
        }

        $result = Get-SSWVmSelectionRamTotal -Profiles $profiles -VmKeys @('DC01', 'BESTAAT-NIET')

        $result | Should -Be 4
    }
}

Describe 'Config helpers' {
    It 'leest preset sleutels uit config' {
        $config = @{
            Presets = @{
                Full = @('DC01', 'MGMT01', 'W11-01')
            }
        }

        $result = Get-SSWPresetVmKeys -Config $config -PresetName 'Full'

        $result | Should -Be @('DC01', 'MGMT01', 'W11-01')
    }

    It 'leidt het standaard unattended ISO pad af uit het VM-profiel' {
        $tempRoot = Join-Path $TestDrive 'config-helpers'
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

        $profilesPath = Join-Path $tempRoot 'vm-profiles.json'
        @'
{
  "DC01": { "Name": "DC01", "OS": "Server2025", "RAM_GB": 4, "Disk_GB": 80, "vCPU": 2 },
  "W11-01": { "Name": "W11-01", "OS": "W11", "RAM_GB": 6, "Disk_GB": 80, "vCPU": 2 }
}
'@ | Set-Content -Path $profilesPath -Encoding utf8

        $config = @{
            ProfilePath = $profilesPath
            ISOPath     = 'D:\SSW-Lab\isos'
        }

        (Get-SSWDefaultIsoPath -Config $config -TemplateKey 'W11-01') | Should -Be 'D:\SSW-Lab\isos\SSW-W11-Unattend.iso'
        (Get-SSWDefaultIsoPath -Config $config -TemplateKey 'DC01') | Should -Be 'D:\SSW-Lab\isos\SSW-WS2025-Unattend.iso'
    }

    It 'houdt vm-profiles.json binnen het afgesproken schema' {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $profilesPath = Join-Path $repoRoot 'profiles\vm-profiles.json'
        $schemaPath = Join-Path $repoRoot 'profiles\vm-profiles.schema.json'
        $profiles = Get-Content -LiteralPath $profilesPath -Raw | ConvertFrom-Json
        $schema = Get-Content -LiteralPath $schemaPath -Raw | ConvertFrom-Json

        $schema.properties.Name.type | Should -Be 'string'
        $schema.properties.OS.enum | Should -Contain 'Windows11'
        $schema.properties.OS.enum | Should -Contain 'Server2025'

        foreach ($profileProperty in $profiles.PSObject.Properties) {
            $profile = $profileProperty.Value
            $profile.Name | Should -Not -BeNullOrEmpty
            [int]$profile.vCPU | Should -BeGreaterThan 0
            [int]$profile.RAM_GB | Should -BeGreaterThan 0
            [int]$profile.Disk_GB | Should -BeGreaterThan 19
            $profile.Role | Should -Not -BeNullOrEmpty
            @('Windows11', 'Server2025') | Should -Contain $profile.OS
            $profile.IP | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Test-SSWSecretPolicy' {
    It 'keurt een sterk secret goed' {
        $result = Test-SSWSecretPolicy -Secret 'SterkWachtwoord!123'

        $result.IsValid | Should -Be $true
        $result.Findings.Count | Should -Be 0
    }

    It 'geeft bevindingen terug voor een zwak secret' {
        $result = Test-SSWSecretPolicy -Secret 'kort'

        $result.IsValid | Should -Be $false
        $result.Findings.Count | Should -BeGreaterThan 0
    }
}

Describe 'Get-SSWSecret' {
    It 'leest een secret uit config wanneer aanwezig' {
        $config = @{
            LabPassword = 'ConfigSecret!123'
        }

        $result = Get-SSWSecret -Name 'SSWLab-LabPassword' -Config $config -ConfigValueName 'LabPassword' -AsPlainText

        $result | Should -Be 'ConfigSecret!123'
    }

    It 'geeft null terug wanneer geen bron beschikbaar is' {
        $result = Get-SSWSecret -Name 'SSWLab-Onbekend' -AsPlainText

        $result | Should -Be $null
    }

    It 'leest een secret uit environment variables wanneer config leeg is' {
        $previousValue = [Environment]::GetEnvironmentVariable('SSW_LAB_TEST_SECRET', 'Process')
        try {
            [Environment]::SetEnvironmentVariable('SSW_LAB_TEST_SECRET', 'EnvSecret!123', 'Process')

            $result = Get-SSWSecret -Name 'SSWLab-TestSecret' -EnvironmentVariableName 'SSW_LAB_TEST_SECRET' -AsPlainText

            $result | Should -Be 'EnvSecret!123'
        } finally {
            [Environment]::SetEnvironmentVariable('SSW_LAB_TEST_SECRET', $previousValue, 'Process')
        }
    }
}

Describe 'Test-SSWConfig' {
    It 'keurt een complete config goed' {
        $config = @{
            DomainName    = 'ssw.lab'
            DomainNetBIOS = 'LAB'
            AdminUser     = 'Administrator'
            DomainAdmin   = 'labadmin'
            VMPath        = 'D:\SSW-Lab\VMs'
            ISOPath       = 'D:\SSW-Lab\isos'
            ProfilePath   = 'D:\SSW-Lab\profiles\vm-profiles.json'
            vSwitchName   = 'SSW-Internal'
            NATName       = 'SSW-NAT'
            NATSubnet     = '10.50.10.0/24'
            GatewayIP     = '10.50.10.1'
            DCIP          = '10.50.10.10'
            MGMTIP        = '10.50.10.20'
            Presets       = @{}
        }

        $result = Test-SSWConfig -Config $config

        $result.IsValid | Should -Be $true
    }

    It 'rapporteert ontbrekende verplichte configwaarden' {
        $config = @{
            DomainName = 'ssw.lab'
        }

        $result = Test-SSWConfig -Config $config

        $result.IsValid | Should -Be $false
        $result.Findings.Count | Should -BeGreaterThan 0
    }
}

Describe 'Unattend XML generatie' {
    It 'genereert Windows 11 unattend XML met domain admin en escaped wachtwoord' {
        $config = @{
            DomainAdmin = 'labadmin'
        }

        $xml = New-SSWW11UnattendXml -Config $config -AdminPassword (ConvertTo-SSWSecureString -Value 'Sterk&Geheim<123>')

        $xml | Should -Match '<Name>labadmin</Name>'
        $xml | Should -Match 'Sterk&amp;Geheim&lt;123&gt;'
        $xml | Should -Match '<Value>Windows 11 Enterprise</Value>'
    }

    It 'genereert Server 2025 unattend XML zonder W11 image metadata' {
        $config = @{
            DomainAdmin = 'labadmin'
        }

        $xml = New-SSWServer2025UnattendXml -Config $config -AdminPassword (ConvertTo-SSWSecureString -Value 'Sterk!123')

        $xml | Should -Match '<ComputerName>\*</ComputerName>'
        $xml | Should -Not -Match '/IMAGE/NAME'
    }
}

Describe 'Track-voortgang' {
    It 'laadt leertrajectdefinities uit JSON' {
        $definitions = Import-SSWTrackDefinitions

        @($definitions).Count | Should -BeGreaterThan 0
        (@($definitions | Where-Object id -eq 'MD102')).Count | Should -Be 1
    }

    It 'kiest het actieve traject uit local state wanneer geen track-id is opgegeven' {
        $tempRoot = Join-Path $TestDrive 'track-state'
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

        $definitionsPath = Join-Path $tempRoot 'learning-tracks.json'
        @'
{
  "tracks": [
    {
      "id": "MD102",
      "name": "MD-102",
      "recommendedPreset": "Full",
      "focus": "Endpoint beheer",
      "milestones": [
        { "id": "week1", "title": "Week 1", "summary": "Start", "scriptPath": "scripts/labs/MD102/lab-week1.ps1" }
      ]
    }
  ]
}
'@ | Set-Content -Path $definitionsPath -Encoding utf8

        $currentTrackPath = Join-Path $tempRoot 'current-track.local.json'
        '{ "trackId": "MD102" }' | Set-Content -Path $currentTrackPath -Encoding utf8

        $definitions = Import-SSWTrackDefinitions -Path $definitionsPath
        $track = Get-SSWTrackDefinition -Definitions $definitions -CurrentTrackPath $currentTrackPath

        $track.id | Should -Be 'MD102'
    }

    It 'berekent voortgang en volgende checkpoint op basis van lokale state' {
        $tempRoot = Join-Path $TestDrive 'progress-state'
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

        $definitionsPath = Join-Path $tempRoot 'learning-tracks.json'
        @'
{
  "tracks": [
    {
      "id": "MS102",
      "name": "MS-102",
      "recommendedPreset": "Standard",
      "focus": "M365 beheer",
      "milestones": [
        { "id": "week1", "title": "Week 1", "summary": "Tenant", "scriptPath": "scripts/labs/MS102/lab-week1.ps1" },
        { "id": "week2", "title": "Week 2", "summary": "Gebruikers", "scriptPath": "scripts/labs/MS102/lab-week2.ps1" }
      ]
    }
  ]
}
'@ | Set-Content -Path $definitionsPath -Encoding utf8

        $checkpointStatePath = Join-Path $tempRoot 'track-checkpoints.local.json'
        @'
{
  "completed": {
    "MS102": [ "week1" ]
  },
  "notes": {
    "MS102": {
      "week1": "Afgerond"
    }
  }
}
'@ | Set-Content -Path $checkpointStatePath -Encoding utf8

        $definitions = Import-SSWTrackDefinitions -Path $definitionsPath
        $progress = Get-SSWTrackProgress -TrackId 'MS102' -Definitions $definitions -CheckpointStatePath $checkpointStatePath

        $progress.CompletedCount | Should -Be 1
        $progress.TotalCount | Should -Be 2
        $progress.PercentComplete | Should -Be 50
        $progress.NextMilestone.Id | Should -Be 'week2'
        $progress.Milestones[0].Note | Should -Be 'Afgerond'
    }

    It 'normaliseert hyphenated track ids en schrijft local state weg' {
        $tempRoot = Join-Path $TestDrive 'current-track-state'
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

        $definitionsPath = Join-Path $tempRoot 'learning-tracks.json'
        @'
{
  "tracks": [
    {
      "id": "SC300",
      "name": "SC-300",
      "recommendedPreset": "Minimal",
      "focus": "Identity",
      "milestones": [
        { "id": "week1", "title": "Week 1", "summary": "Start", "scriptPath": "scripts/labs/SC300/lab-week1.ps1" }
      ]
    }
  ]
}
'@ | Set-Content -Path $definitionsPath -Encoding utf8

        $statePath = Join-Path $tempRoot 'current-track.local.json'
        $definitions = Import-SSWTrackDefinitions -Path $definitionsPath

        $result = Set-SSWCurrentTrack -TrackId 'SC-300' -StatePath $statePath -Definitions $definitions
        $saved = Get-Content -Path $statePath -Raw | ConvertFrom-Json

        $result.TrackId | Should -Be 'SC300'
        $saved.trackId | Should -Be 'SC300'
    }
}

Describe 'Lab script parse checks' {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $labDirs  = @(
        (Join-Path $repoRoot 'scripts\labs\MD102'),
        (Join-Path $repoRoot 'scripts\labs\MS102'),
        (Join-Path $repoRoot 'scripts\labs\SC300'),
        (Join-Path $repoRoot 'scripts\labs\AZ104')
    )

    $labScripts = $labDirs |
        Where-Object { Test-Path $_ } |
        ForEach-Object { Get-ChildItem -Path $_ -Filter '*.ps1' } |
        Select-Object -ExpandProperty FullName

    foreach ($script in $labScripts) {
        $relativePath = $script.Replace($repoRoot, '').TrimStart('\')
        It "parses without syntax errors: $relativePath" {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($script, [ref]$null, [ref]$errors)
            $errors | Should -BeNullOrEmpty
        }
    }
}
