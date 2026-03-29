function Get-SSWSecretFromEnvironment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$EnvironmentVariableName
    )

    foreach ($scope in 'Process', 'User', 'Machine') {
        $candidate = [Environment]::GetEnvironmentVariable($EnvironmentVariableName, $scope)
        if (-not [string]::IsNullOrWhiteSpace($candidate)) {
            return $candidate
        }
    }

    return $null
}

function Get-SSWSecretFromCredentialManager {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $cmdKey = Get-Command -Name cmdkey.exe -ErrorAction SilentlyContinue
    if (-not $cmdKey) {
        return $null
    }

    try {
        $output = & $cmdKey.Source "/list:$Name" 2>$null
        if (-not $output) {
            return $null
        }

        foreach ($line in $output) {
            if ($line -match '^\s*Password:\s*(.+?)\s*$') {
                $password = $matches[1].Trim()
                if (-not [string]::IsNullOrWhiteSpace($password)) {
                    return $password
                }
            }
        }
    } catch {
        Write-Verbose "Credential Manager lookup voor '$Name' mislukte: $($_.Exception.Message)"
    }

    return $null
}

function Get-SSWSecretFromSecretManagement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    $secretCommand = Get-Command -Name Get-Secret -ErrorAction SilentlyContinue
    if (-not $secretCommand) {
        return $null
    }

    try {
        $secret = Get-Secret -Name $Name -ErrorAction Stop
        if ($secret -is [securestring]) {
            return ConvertFrom-SSWSecureString -SecureString $secret
        }

        if ($secret) {
            return [string]$secret
        }
    } catch {
        Write-Verbose "Get-Secret voor '$Name' gaf geen bruikbaar resultaat: $($_.Exception.Message)"
    }

    return $null
}
