#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Install-EntraConnect.ps1
# Installeert Entra Connect op LAB-DC01 en voegt de UPN-suffix
# toe aan Active Directory.
#
# Vereisten:
#   - config.local.ps1 met: $SSWConfig.EntraUPN = "lab.jouwdomein.nl"
#   - LAB-DC01 is Running en domain is ingericht (na Initialize-DomainController.ps1)
#   - MSI gedownload via: Invoke-WebRequest -Uri 'https://aka.ms/aadconnect' -OutFile 'D:\SSW-Lab\AzureADConnect.msi'
# ============================================================

. "$PSScriptRoot\..\config.ps1"

$vmName   = "LAB-DC01"
$msiHost  = "D:\SSW-Lab\AzureADConnect.msi"
$msiDest  = "C:\Temp\AzureADConnect.msi"
$domain   = $SSWConfig.DomainName
$entraUPN = $SSWConfig.EntraUPN

function Write-InstallMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [ValidateSet('Default', 'Warning', 'Error')]
        [string]$Level = 'Default'
    )

    switch ($Level) {
        'Warning' { Write-Warning $Message }
        'Error' { Write-Error $Message -ErrorAction Continue }
        default { Write-Output $Message }
    }
}

# ── Controleer EntraUPN ───────────────────────────────────────────────────────

if ([string]::IsNullOrWhiteSpace($entraUPN)) {
    Write-InstallMessage ""
    Write-InstallMessage "EntraUPN is niet geconfigureerd." -Level Error
    Write-InstallMessage "Maak config.local.ps1 aan met:" -Level Warning
    Write-InstallMessage '  $SSWConfig.EntraUPN = "lab.jouwdomein.nl"'
    Write-InstallMessage ""
    exit 1
}

Write-InstallMessage ""
Write-InstallMessage "SSW-Lab | Entra Connect installeren op $vmName"
Write-InstallMessage "  Domein  : $domain"
Write-InstallMessage "  EntraUPN: $entraUPN"
Write-InstallMessage ""

# ── Credentials (interactief - nooit hardcoden) ───────────────────────────────

$cred = Get-Credential -Message "Voer credentials in voor $vmName ($($SSWConfig.DomainNetBIOS)\Administrator)"

# ── Controleer VM ─────────────────────────────────────────────────────────────

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if (-not $vm) {
    Write-InstallMessage "VM '$vmName' not found." -Level Error
    exit 1
}
if ($vm.State -ne 'Running') {
    Write-InstallMessage "VM '$vmName' is niet Running (staat: $($vm.State)). Start de VM eerst." -Level Error
    exit 1
}
Write-InstallMessage "VM '$vmName' is Running."

# ── Controleer MSI ────────────────────────────────────────────────────────────

if (-not (Test-Path $msiHost)) {
    Write-InstallMessage ""
    Write-InstallMessage "MSI niet gevonden op: $msiHost" -Level Error
    Write-InstallMessage "Download eerst met:" -Level Warning
    Write-InstallMessage "  Invoke-WebRequest -Uri 'https://aka.ms/aadconnect' -OutFile '$msiHost'"
    Write-InstallMessage ""
    exit 1
}
Write-InstallMessage "MSI gevonden: $msiHost"

# ── TLS 1.2 check en activering ───────────────────────────────────────────────

Write-InstallMessage ""
Write-InstallMessage "TLS 1.2 controleren en activeren..."

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    $tlsBase  = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2'
    $srvKey   = "$tlsBase\Server"
    $cliKey   = "$tlsBase\Client"

    foreach ($key in @($srvKey, $cliKey)) {
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        $enabled  = (Get-ItemProperty -Path $key -Name Enabled       -ErrorAction SilentlyContinue).Enabled
        $disabled = (Get-ItemProperty -Path $key -Name DisabledByDefault -ErrorAction SilentlyContinue).DisabledByDefault
        if ($enabled -ne 1 -or $disabled -ne 0) {
            Set-ItemProperty -Path $key -Name Enabled            -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $key -Name DisabledByDefault  -Value 0 -Type DWord -Force
            Write-Output "  TLS 1.2 ingeschakeld: $key"
        } else {
            Write-Output "  TLS 1.2 al actief:    $key"
        }
    }

    # .NET moet TLS 1.2 ook gebruiken (vereist door Entra Connect)
    $netKeys = @(
        'HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319'
    )
    foreach ($key in $netKeys) {
        if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
        Set-ItemProperty -Path $key -Name SchUseStrongCrypto -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $key -Name SystemDefaultTlsVersions -Value 1 -Type DWord -Force
    }
    Write-Output "  .NET SchUseStrongCrypto + SystemDefaultTlsVersions ingesteld."
} -ErrorAction Stop

Write-InstallMessage "TLS 1.2 klaar."

# ── Stap 1: UPN-suffix toevoegen aan AD ──────────────────────────────────────

Write-InstallMessage ""
Write-InstallMessage "Stap 1/3 - UPN-suffix '$entraUPN' toevoegen aan AD..."

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($upn)
    $forest   = Get-ADForest -ErrorAction Stop
    $suffixes = $forest.UPNSuffixes
    if ($suffixes -contains $upn) {
        Write-Output "  UPN-suffix '$upn' bestaat al - overgeslagen."
    } else {
        Set-ADForest -Identity $forest.Name -UPNSuffixes @{Add = $upn} -ErrorAction Stop
        Write-Output "  UPN-suffix '$upn' toegevoegd."
    }
} -ArgumentList $entraUPN -ErrorAction Stop

Write-InstallMessage "Stap 1 klaar."

# ── Stap 2: MSI kopiëren naar VM ─────────────────────────────────────────────

Write-InstallMessage ""
Write-InstallMessage "Stap 2/3 - MSI kopieren naar $vmName (via PS Direct, chunked base64)..."

# Guest Service Interface is niet vereist - we sturen de MSI via PS Direct in chunks
Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
} -ErrorAction Stop

# MSI in stukken van 3 MB versturen als base64
$chunkSize   = 3 * 1024 * 1024   # 3 MB per chunk
$msiBytes    = [System.IO.File]::ReadAllBytes($msiHost)
$totalChunks = [math]::Ceiling($msiBytes.Length / $chunkSize)

Write-InstallMessage "  Bestandsgrootte: $([math]::Round($msiBytes.Length/1MB,1)) MB - $totalChunks chunk(s)"

# Zorg dat doelbestand leeg begint
Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($dest)
    Remove-Item $dest -Force -ErrorAction SilentlyContinue
    $null = New-Item -ItemType File -Path $dest -Force
} -ArgumentList $msiDest -ErrorAction Stop

for ($i = 0; $i -lt $totalChunks; $i++) {
    $offset = $i * $chunkSize
    $length = [math]::Min($chunkSize, $msiBytes.Length - $offset)
    $chunk  = $msiBytes[$offset..($offset + $length - 1)]
    $b64    = [Convert]::ToBase64String($chunk)
    Write-InstallMessage "  Chunk $($i+1)/$totalChunks..."
    Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
        param($dest, $data)
        $bytes = [Convert]::FromBase64String($data)
        $fs    = [System.IO.File]::Open($dest, [System.IO.FileMode]::Append)
        $fs.Write($bytes, 0, $bytes.Length)
        $fs.Close()
    } -ArgumentList $msiDest, $b64 -ErrorAction Stop
    Write-InstallMessage "  Chunk $($i+1)/$totalChunks klaar"
}

Write-InstallMessage "MSI gekopieerd naar $msiDest."

# ── Stap 3: Installeren ───────────────────────────────────────────────────────

Write-InstallMessage ""
Write-InstallMessage "Stap 3/3 - Entra Connect installeren (dit duurt ~2 minuten)..."

$exitCode = Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($dest)
    # Verwijder eventuele bestaande installatie
    $existing = Get-Package -Name "Microsoft Entra Connect*","Microsoft Azure AD Connect*" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Output "  Bestaande installatie verwijderen..."
        $existing | Uninstall-Package -Force -ErrorAction SilentlyContinue
    }
    $proc = Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i `"$dest`" /quiet /norestart ALLUSERS=1" `
        -Wait -PassThru -ErrorAction Stop
    return $proc.ExitCode
} -ArgumentList $msiDest -ErrorAction Stop

# ── Resultaat ─────────────────────────────────────────────────────────────────

Write-InstallMessage ""
switch ($exitCode) {
    0    { Write-InstallMessage "Installatie geslaagd." }
    3010 { Write-InstallMessage "Installatie geslaagd - herstart vereist." -Level Warning
           Write-InstallMessage "  Restart-VM -Name '$vmName' -Force" }
     default { Write-InstallMessage "Installatie mislukt - ExitCode: $exitCode" -Level Error
              Write-InstallMessage "  Controleer C:\Windows\Temp\MSI*.log op $vmName voor details."
              exit 1 }
}

# ── Stap 4: AD Recycle Bin inschakelen ───────────────────────────────────────

Write-InstallMessage ""
Write-InstallMessage "Stap 4/4 - AD Recycle Bin inschakelen voor '$domain'..."

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($domain)
    $feature = Get-ADOptionalFeature -Filter { Name -eq "Recycle Bin Feature" } -ErrorAction Stop
    if ($feature.EnabledScopes.Count -gt 0) {
        Write-Output "  AD Recycle Bin is al ingeschakeld - overgeslagen."
    } else {
        Enable-ADOptionalFeature -Identity "Recycle Bin Feature" `
            -Scope ForestOrConfigurationSet -Target $domain -Confirm:$false -ErrorAction Stop
        Write-Output "  AD Recycle Bin ingeschakeld voor '$domain'."
    }
} -ArgumentList $domain -ErrorAction Stop

Write-InstallMessage "Stap 4 klaar."

Write-InstallMessage ""
Write-InstallMessage "Next steppen:" -Level Warning
Write-InstallMessage "  1. Open Hyper-V console naar $vmName"
Write-InstallMessage "  2. Start 'Microsoft Entra Connect' via het Startmenu"
Write-InstallMessage "  3. Kies 'Express Settings' (of Custom voor meer controle)"
Write-InstallMessage "  4. Log in met je Global Admin van de dev-tenant"
Write-InstallMessage "  5. AD-credentials: $($env:USERDOMAIN)\Administrator"
Write-InstallMessage "  6. Verifieer sync: Start-ADSyncSyncCycle -PolicyType Initial"
Write-InstallMessage ""


