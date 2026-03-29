function ConvertTo-SSWSecureString {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [string]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $secureString = New-Object System.Security.SecureString
    foreach ($character in $Value.ToCharArray()) {
        $secureString.AppendChar($character)
    }

    $secureString.MakeReadOnly()
    return $secureString
}

function ConvertFrom-SSWSecureString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [securestring]$SecureString
    )

    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        if ($ptr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
        }
    }
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
        $plainTextValue = Get-SSWSecretFromEnvironment -EnvironmentVariableName $EnvironmentVariableName
    }

    if (-not $plainTextValue) {
        $plainTextValue = Get-SSWSecretFromCredentialManager -Name $Name
    }

    if (-not $plainTextValue) {
        $plainTextValue = Get-SSWSecretFromSecretManagement -Name $Name
    }

    if (-not $plainTextValue) {
        return $null
    }

    if ($AsPlainText) {
        return $plainTextValue
    }

    return ConvertTo-SSWSecureString -Value $plainTextValue
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
