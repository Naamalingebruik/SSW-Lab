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

function Get-SSWPresetVmKeys {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$PresetName
    )

    if (-not $Config.ContainsKey('Presets') -or $Config.Presets -isnot [hashtable]) {
        throw "Config bevat geen geldige 'Presets' hashtable."
    }

    if (-not $Config.Presets.ContainsKey($PresetName)) {
        throw "Preset '$PresetName' bestaat niet."
    }

    return @($Config.Presets[$PresetName])
}

function Get-SSWDefaultIsoPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$TemplateKey
    )

    $profiles = Get-SSWVmProfiles -Config $Config
    $profile = Get-SSWVmProfile -Profiles $profiles -Name $TemplateKey

    $fileName = if ($profile.OS -eq 'Server2025') {
        'SSW-WS2025-Unattend.iso'
    } else {
        'SSW-W11-Unattend.iso'
    }

    return Join-Path $Config.ISOPath $fileName
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
