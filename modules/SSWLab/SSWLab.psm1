Set-StrictMode -Version Latest

function ConvertTo-SSWXmlSafeValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value
    )

    return [System.Security.SecurityElement]::Escape($Value)
}

function Import-SSWLabConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        throw "Configbestand niet gevonden: $ConfigPath"
    }

    $script:SSWConfig = $null
    . $ConfigPath

    if (-not $script:SSWConfig) {
        throw "Configbestand heeft geen `$SSWConfig opgeleverd: $ConfigPath"
    }

    return $script:SSWConfig
}

function Get-SSWVmProfiles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    if (-not $Config.ProfilePath) {
        throw "ProfilePath ontbreekt in configuratie."
    }

    if (-not (Test-Path -LiteralPath $Config.ProfilePath)) {
        throw "VM-profielenbestand niet gevonden: $($Config.ProfilePath)"
    }

    return Get-Content -LiteralPath $Config.ProfilePath -Raw | ConvertFrom-Json
}

function Get-SSWVmProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Profiles,

        [Parameter(Mandatory)]
        [string]$Name
    )

    $vmProfileProperty = $Profiles.PSObject.Properties[$Name]
    if (-not $vmProfileProperty) {
        throw "VM-profiel '$Name' bestaat niet."
    }

    return $vmProfileProperty.Value
}

function Get-SSWVmSelectionRamTotal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$Profiles,

        [string[]]$VmKeys = @()
    )

    $total = 0
    foreach ($key in $VmKeys) {
        $property = $Profiles.PSObject.Properties[$key]
        if ($property) {
            $ramGb = [int]$property.Value.RAM_GB
            $total += $ramGb
        }
    }

    return $total
}

function Get-SSWSecret {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [hashtable]$Config,

        [string]$ConfigValueName,

        [string]$EnvironmentVariableName,

        [switch]$AsPlainText
    )

    $plainTextValue = $null

    if ($Config -and $ConfigValueName -and $Config.ContainsKey($ConfigValueName)) {
        $candidate = [string]$Config[$ConfigValueName]
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $plainTextValue = $candidate
        }
    }

    if (-not $plainTextValue -and $EnvironmentVariableName) {
        $candidate = [Environment]::GetEnvironmentVariable($EnvironmentVariableName, 'Process')
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            $candidate = [Environment]::GetEnvironmentVariable($EnvironmentVariableName, 'User')
        }
        if ([string]::IsNullOrWhiteSpace($candidate)) {
            $candidate = [Environment]::GetEnvironmentVariable($EnvironmentVariableName, 'Machine')
        }
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            $plainTextValue = $candidate
        }
    }

    if (-not $plainTextValue) {
        $secretCommand = Get-Command -Name Get-Secret -ErrorAction SilentlyContinue
        if ($secretCommand) {
            try {
                $secret = Get-Secret -Name $Name -ErrorAction Stop
                if ($secret -is [securestring]) {
                    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret)
                    try {
                        $plainTextValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
                    } finally {
                        if ($ptr -ne [IntPtr]::Zero) {
                            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
                        }
                    }
                } elseif ($secret) {
                    $plainTextValue = [string]$secret
                }
            } catch {
            }
        }
    }

    if (-not $plainTextValue) {
        return $null
    }

    if ($AsPlainText) {
        return $plainTextValue
    }

    return ConvertTo-SecureString -String $plainTextValue -AsPlainText -Force
}

function New-SSWCredential {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,

        [securestring]$Password,

        [string]$SecretName,

        [hashtable]$Config,

        [string]$ConfigValueName,

        [string]$EnvironmentVariableName
    )

    if (-not $Password) {
        $Password = Get-SSWSecret -Name $SecretName -Config $Config -ConfigValueName $ConfigValueName -EnvironmentVariableName $EnvironmentVariableName
    }

    if (-not $Password) {
        throw "Geen wachtwoord beschikbaar voor referentie '$UserName'."
    }

    return [PSCredential]::new($UserName, $Password)
}

function Test-SSWSecretPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Secret,

        [int]$MinimumLength = 12
    )

    $findings = [System.Collections.Generic.List[string]]::new()

    if ($Secret.Length -lt $MinimumLength) {
        $findings.Add("Secret is korter dan $MinimumLength tekens.")
    }
    if ($Secret -notmatch '[A-Z]') {
        $findings.Add("Secret mist een hoofdletter.")
    }
    if ($Secret -notmatch '[a-z]') {
        $findings.Add("Secret mist een kleine letter.")
    }
    if ($Secret -notmatch '\d') {
        $findings.Add("Secret mist een cijfer.")
    }
    if ($Secret -notmatch '[^a-zA-Z0-9]') {
        $findings.Add("Secret mist een speciaal teken.")
    }

    [pscustomobject]@{
        IsValid  = ($findings.Count -eq 0)
        Findings = [string[]]$findings
    }
}

function Test-SSWConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $requiredKeys = @(
        'DomainName',
        'DomainNetBIOS',
        'AdminUser',
        'DomainAdmin',
        'VMPath',
        'ISOPath',
        'ProfilePath',
        'vSwitchName',
        'NATName',
        'NATSubnet',
        'GatewayIP',
        'DCIP',
        'MGMTIP',
        'Presets'
    )

    $findings = [System.Collections.Generic.List[string]]::new()

    foreach ($key in $requiredKeys) {
        if (-not $Config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace([string]$Config[$key])) {
            $findings.Add("Config mist verplichte waarde '$key'.")
        }
    }

    if ($Config.ContainsKey('Presets') -and $Config.Presets -isnot [hashtable]) {
        $findings.Add("Configwaarde 'Presets' moet een hashtable zijn.")
    }

    [pscustomobject]@{
        IsValid  = ($findings.Count -eq 0)
        Findings = [string[]]$findings
    }
}

function New-SSWW11UnattendXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$AdminPassword
    )

    $adminPassXml = ConvertTo-SSWXmlSafeValue -Value $AdminPassword
    $domainAdminXml = ConvertTo-SSWXmlSafeValue -Value $Config.DomainAdmin

    return @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"
          xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>nl-NL</UILanguage></SetupUILanguage>
      <InputLocale>nl-NL</InputLocale>
      <UILanguage>nl-NL</UILanguage>
      <SystemLocale>nl-NL</SystemLocale>
      <UserLocale>nl-NL</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>300</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>2</PartitionID></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>3</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label></ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallFrom>
            <MetaData wcm:action="add">
              <Key>/IMAGE/NAME</Key>
              <Value>Windows 11 Enterprise</Value>
            </MetaData>
            <MetaData wcm:action="add">
              <Key>/IMAGE/EDITIONID</Key>
              <Value>Enterprise</Value>
            </MetaData>
          </InstallFrom>
          <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
          <WillShowUI>Never</WillShowUI>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>SSW Lab</FullName>
        <Organization>Sogeti SSW</Organization>
        <ProductKey>
          <Key>NPPR9-FWDCX-D2C8J-H872K-2YT43</Key>
          <WillShowUI>Never</WillShowUI>
        </ProductKey>
      </UserData>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <ComputerName>*</ComputerName>
      <RegisteredOrganization>Sogeti SSW</RegisteredOrganization>
      <TimeZone>W. Europe Standard Time</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-International-Core"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <InputLocale>nl-NL</InputLocale>
      <UILanguage>nl-NL</UILanguage>
      <UILanguageFallback>en-US</UILanguageFallback>
      <SystemLocale>nl-NL</SystemLocale>
      <UserLocale>nl-NL</UserLocale>
    </component>
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>3</ProtectYourPC>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$adminPassXml</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password><Value>$adminPassXml</Value><PlainText>true</PlainText></Password>
            <DisplayName>$domainAdminXml</DisplayName>
            <Group>Administrators</Group>
            <Name>$domainAdminXml</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
    </component>
  </settings>
</unattend>
"@
}

function New-SSWServer2025UnattendXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$AdminPassword
    )

    $adminPassXml = ConvertTo-SSWXmlSafeValue -Value $AdminPassword
    $domainAdminXml = ConvertTo-SSWXmlSafeValue -Value $Config.DomainAdmin

    return @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"
          xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
      <InputLocale>nl-NL</InputLocale><UILanguage>en-US</UILanguage>
      <SystemLocale>nl-NL</SystemLocale><UserLocale>nl-NL</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>300</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>2</PartitionID></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>3</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label></ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
          <WillShowUI>OnError</WillShowUI>
          <InstallToAvailablePartition>false</InstallToAvailablePartition>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>SSW Lab</FullName>
        <Organization>Sogeti SSW</Organization>
      </UserData>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <ComputerName>*</ComputerName>
      <TimeZone>W. Europe Standard Time</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <NetworkLocation>Work</NetworkLocation>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$adminPassXml</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password><Value>$adminPassXml</Value><PlainText>true</PlainText></Password>
            <DisplayName>$domainAdminXml</DisplayName>
            <Group>Administrators</Group>
            <Name>$domainAdminXml</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
    </component>
  </settings>
</unattend>
"@
}

function Import-SSWTrackDefinitions {
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path $PSScriptRoot '..\..\profiles\learning-tracks.json')
    )

    if (-not (Test-Path $Path)) {
        throw "Trackdefinities niet gevonden: $Path"
    }

    $raw = Get-Content -Path $Path -Raw | ConvertFrom-Json
    if (-not $raw.tracks) {
        throw "Trackdefinities in $Path bevatten geen tracks."
    }

    return @($raw.tracks)
}

function Resolve-SSWTrackId {
    [CmdletBinding()]
    param(
        [string]$TrackId
    )

    if ([string]::IsNullOrWhiteSpace($TrackId)) {
        return $null
    }

    $normalized = ($TrackId -replace '[^A-Za-z0-9]', '').ToUpperInvariant()
    switch ($normalized) {
        'MD102' { return 'MD102' }
        'MS102' { return 'MS102' }
        'SC300' { return 'SC300' }
        'AZ104' { return 'AZ104' }
        default { return $normalized }
    }
}

function Get-SSWTrackDefinition {
    [CmdletBinding()]
    param(
        [string]$TrackId,
        [object[]]$Definitions,
        [string]$CurrentTrackPath = (Join-Path $PSScriptRoot '..\..\profiles\current-track.local.json')
    )

    if (-not $Definitions) {
        $Definitions = Import-SSWTrackDefinitions
    }

    if ([string]::IsNullOrWhiteSpace($TrackId)) {
        if (Test-Path $CurrentTrackPath) {
            $currentState = Get-Content -Path $CurrentTrackPath -Raw | ConvertFrom-Json
            $TrackId = $currentState.trackId
        }
    }

    if ([string]::IsNullOrWhiteSpace($TrackId)) {
        return $null
    }

    $resolvedTrackId = Resolve-SSWTrackId -TrackId $TrackId
    return @($Definitions | Where-Object { $_.id -eq $resolvedTrackId }) | Select-Object -First 1
}

function Set-SSWCurrentTrack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TrackId,

        [string]$StatePath = (Join-Path $PSScriptRoot '..\..\profiles\current-track.local.json'),
        [object[]]$Definitions
    )

    if (-not $Definitions) {
        $Definitions = Import-SSWTrackDefinitions
    }

    $resolvedTrackId = Resolve-SSWTrackId -TrackId $TrackId
    $definition = Get-SSWTrackDefinition -TrackId $resolvedTrackId -Definitions $Definitions
    if (-not $definition) {
        throw "Onbekend track-id '$TrackId'."
    }

    $payload = [ordered]@{
        trackId = $definition.id
    }

    $payload | ConvertTo-Json | Set-Content -Path $StatePath -Encoding utf8

    return [pscustomobject]@{
        TrackId   = $definition.id
        TrackName = $definition.name
        StatePath = $StatePath
    }
}

function Get-SSWTrackProgress {
    [CmdletBinding()]
    param(
        [string]$TrackId,
        [object[]]$Definitions,
        [string]$CurrentTrackPath = (Join-Path $PSScriptRoot '..\..\profiles\current-track.local.json'),
        [string]$CheckpointStatePath = (Join-Path $PSScriptRoot '..\..\profiles\track-checkpoints.local.json')
    )

    if (-not $Definitions) {
        $Definitions = Import-SSWTrackDefinitions
    }

    $track = Get-SSWTrackDefinition -TrackId $TrackId -Definitions $Definitions -CurrentTrackPath $CurrentTrackPath
    if (-not $track) {
        throw 'Geen actief traject gevonden. Gebruik Set-CurrentTrack.ps1 of geef -TrackId op.'
    }

    $completedMap = @{}
    $noteMap = @{}

    if (Test-Path $CheckpointStatePath) {
        $checkpointState = Get-Content -Path $CheckpointStatePath -Raw | ConvertFrom-Json

        if ($checkpointState.completed) {
            foreach ($property in $checkpointState.completed.PSObject.Properties) {
                $completedMap[$property.Name] = @($property.Value)
            }
        }

        if ($checkpointState.notes) {
            foreach ($property in $checkpointState.notes.PSObject.Properties) {
                $trackNotes = @{}
                foreach ($noteProperty in $property.Value.PSObject.Properties) {
                    $trackNotes[$noteProperty.Name] = [string]$noteProperty.Value
                }
                $noteMap[$property.Name] = $trackNotes
            }
        }
    }

    $completedIds = @()
    if ($completedMap.ContainsKey($track.id)) {
        $completedIds = @($completedMap[$track.id])
    }

    $trackNotes = @{}
    if ($noteMap.ContainsKey($track.id)) {
        $trackNotes = $noteMap[$track.id]
    }

    $milestones = foreach ($milestone in $track.milestones) {
        [pscustomobject]@{
            Id          = $milestone.id
            Title       = $milestone.title
            Summary     = $milestone.summary
            ScriptPath  = $milestone.scriptPath
            IsCompleted = ($completedIds -contains $milestone.id)
            Note        = if ($trackNotes.ContainsKey($milestone.id)) { $trackNotes[$milestone.id] } else { $null }
        }
    }

    $completedCount = @($milestones | Where-Object IsCompleted).Count
    $totalCount = @($milestones).Count
    $nextMilestone = @($milestones | Where-Object { -not $_.IsCompleted }) | Select-Object -First 1

    [pscustomobject]@{
        TrackId           = $track.id
        TrackName         = $track.name
        Focus             = $track.focus
        RecommendedPreset = $track.recommendedPreset
        CompletedCount    = $completedCount
        TotalCount        = $totalCount
        PercentComplete   = if ($totalCount -gt 0) { [math]::Round(($completedCount / $totalCount) * 100, 0) } else { 0 }
        IsComplete        = ($totalCount -gt 0 -and $completedCount -eq $totalCount)
        NextMilestone     = $nextMilestone
        Milestones        = @($milestones)
    }
}

Export-ModuleMember -Function @(
    'ConvertTo-SSWXmlSafeValue',
    'Import-SSWLabConfig',
    'Get-SSWVmProfiles',
    'Get-SSWVmProfile',
    'Get-SSWVmSelectionRamTotal',
    'Get-SSWSecret',
    'New-SSWCredential',
    'Test-SSWSecretPolicy',
    'Test-SSWConfig',
    'New-SSWW11UnattendXml',
    'New-SSWServer2025UnattendXml',
    'Import-SSWTrackDefinitions',
    'Get-SSWTrackDefinition',
    'Set-SSWCurrentTrack',
    'Get-SSWTrackProgress'
)
