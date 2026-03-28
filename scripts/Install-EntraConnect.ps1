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

# ── Controleer EntraUPN ───────────────────────────────────────────────────────

if ([string]::IsNullOrWhiteSpace($entraUPN)) {
    Write-Host ""
    Write-Host "EntraUPN is niet geconfigureerd." -ForegroundColor Red
    Write-Host "Maak config.local.ps1 aan met:" -ForegroundColor Yellow
    Write-Host '  $SSWConfig.EntraUPN = "lab.jouwdomein.nl"' -ForegroundColor Cyan
    Write-Host ""
    exit 1
}

Write-Host ""
Write-Host "SSW-Lab | Entra Connect installeren op $vmName" -ForegroundColor Cyan
Write-Host "  Domein  : $domain"
Write-Host "  EntraUPN: $entraUPN"
Write-Host ""

# ── Credentials (interactief - nooit hardcoden) ───────────────────────────────

$cred = Get-Credential -Message "Voer credentials in voor $vmName ($($SSWConfig.DomainNetBIOS)\Administrator)"

# ── Controleer VM ─────────────────────────────────────────────────────────────

$vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
if (-not $vm) {
    Write-Host "VM '$vmName' niet gevonden." -ForegroundColor Red
    exit 1
}
if ($vm.State -ne 'Running') {
    Write-Host "VM '$vmName' is niet Running (staat: $($vm.State)). Start de VM eerst." -ForegroundColor Red
    exit 1
}
Write-Host "VM '$vmName' is Running." -ForegroundColor Green

# ── Controleer MSI ────────────────────────────────────────────────────────────

if (-not (Test-Path $msiHost)) {
    Write-Host ""
    Write-Host "MSI niet gevonden op: $msiHost" -ForegroundColor Red
    Write-Host "Download eerst met:" -ForegroundColor Yellow
    Write-Host "  Invoke-WebRequest -Uri 'https://aka.ms/aadconnect' -OutFile '$msiHost'" -ForegroundColor Cyan
    Write-Host ""
    exit 1
}
Write-Host "MSI gevonden: $msiHost" -ForegroundColor Green

# ── TLS 1.2 check en activering ───────────────────────────────────────────────

Write-Host ""
Write-Host "TLS 1.2 controleren en activeren..." -ForegroundColor Cyan

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
            Write-Host "  TLS 1.2 ingeschakeld: $key"
        } else {
            Write-Host "  TLS 1.2 al actief:    $key"
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
    Write-Host "  .NET SchUseStrongCrypto + SystemDefaultTlsVersions ingesteld."
} -ErrorAction Stop

Write-Host "TLS 1.2 klaar." -ForegroundColor Green

# ── Stap 1: UPN-suffix toevoegen aan AD ──────────────────────────────────────

Write-Host ""
Write-Host "Stap 1/3 - UPN-suffix '$entraUPN' toevoegen aan AD..." -ForegroundColor Cyan

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($upn)
    $forest   = Get-ADForest -ErrorAction Stop
    $suffixes = $forest.UPNSuffixes
    if ($suffixes -contains $upn) {
        Write-Host "  UPN-suffix '$upn' bestaat al - overgeslagen."
    } else {
        Set-ADForest -Identity $forest.Name -UPNSuffixes @{Add = $upn} -ErrorAction Stop
        Write-Host "  UPN-suffix '$upn' toegevoegd."
    }
} -ArgumentList $entraUPN -ErrorAction Stop

Write-Host "Stap 1 klaar." -ForegroundColor Green

# ── Stap 2: MSI kopiëren naar VM ─────────────────────────────────────────────

Write-Host ""
Write-Host "Stap 2/3 - MSI kopieren naar $vmName (via PS Direct, chunked base64)..." -ForegroundColor Cyan

# Guest Service Interface is niet vereist - we sturen de MSI via PS Direct in chunks
Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
} -ErrorAction Stop

# MSI in stukken van 3 MB versturen als base64
$chunkSize   = 3 * 1024 * 1024   # 3 MB per chunk
$msiBytes    = [System.IO.File]::ReadAllBytes($msiHost)
$totalChunks = [math]::Ceiling($msiBytes.Length / $chunkSize)

Write-Host "  Bestandsgrootte: $([math]::Round($msiBytes.Length/1MB,1)) MB - $totalChunks chunk(s)" -ForegroundColor Gray

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
    Write-Host "  Chunk $($i+1)/$totalChunks..." -ForegroundColor Gray -NoNewline
    Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
        param($dest, $data)
        $bytes = [Convert]::FromBase64String($data)
        $fs    = [System.IO.File]::Open($dest, [System.IO.FileMode]::Append)
        $fs.Write($bytes, 0, $bytes.Length)
        $fs.Close()
    } -ArgumentList $msiDest, $b64 -ErrorAction Stop
    Write-Host " klaar" -ForegroundColor Gray
}

Write-Host "MSI gekopieerd naar $msiDest." -ForegroundColor Green

# ── Stap 3: Installeren ───────────────────────────────────────────────────────

Write-Host ""
Write-Host "Stap 3/3 - Entra Connect installeren (dit duurt ~2 minuten)..." -ForegroundColor Cyan

$exitCode = Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($dest)
    # Verwijder eventuele bestaande installatie
    $existing = Get-Package -Name "Microsoft Entra Connect*","Microsoft Azure AD Connect*" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "  Bestaande installatie verwijderen..."
        $existing | Uninstall-Package -Force -ErrorAction SilentlyContinue
    }
    $proc = Start-Process -FilePath "msiexec.exe" `
        -ArgumentList "/i `"$dest`" /quiet /norestart ALLUSERS=1" `
        -Wait -PassThru -ErrorAction Stop
    return $proc.ExitCode
} -ArgumentList $msiDest -ErrorAction Stop

# ── Resultaat ─────────────────────────────────────────────────────────────────

Write-Host ""
switch ($exitCode) {
    0    { Write-Host "Installatie geslaagd." -ForegroundColor Green }
    3010 { Write-Host "Installatie geslaagd - herstart vereist." -ForegroundColor Yellow
           Write-Host "  Restart-VM -Name '$vmName' -Force" }
     default { Write-Host "Installatie mislukt - ExitCode: $exitCode" -ForegroundColor Red
              Write-Host "  Controleer C:\Windows\Temp\MSI*.log op $vmName voor details."
              exit 1 }
}

# ── Stap 4: AD Recycle Bin inschakelen ───────────────────────────────────────

Write-Host ""
Write-Host "Stap 4/4 - AD Recycle Bin inschakelen voor '$domain'..." -ForegroundColor Cyan

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($domain)
    $feature = Get-ADOptionalFeature -Filter { Name -eq "Recycle Bin Feature" } -ErrorAction Stop
    if ($feature.EnabledScopes.Count -gt 0) {
        Write-Host "  AD Recycle Bin is al ingeschakeld - overgeslagen."
    } else {
        Enable-ADOptionalFeature -Identity "Recycle Bin Feature" `
            -Scope ForestOrConfigurationSet -Target $domain -Confirm:$false -ErrorAction Stop
        Write-Host "  AD Recycle Bin ingeschakeld voor '$domain'." -ForegroundColor Green
    }
} -ArgumentList $domain -ErrorAction Stop

Write-Host "Stap 4 klaar." -ForegroundColor Green

Write-Host ""
Write-Host "Volgende stappen:" -ForegroundColor Yellow
Write-Host "  1. Open Hyper-V console naar $vmName"
Write-Host "  2. Start 'Microsoft Entra Connect' via het Startmenu"
Write-Host "  3. Kies 'Express Settings' (of Custom voor meer controle)"
Write-Host "  4. Log in met je Global Admin van de dev-tenant"
Write-Host "  5. AD-credentials: $($env:USERDOMAIN)\Administrator"
Write-Host "  6. Verifieer sync: Start-ADSyncSyncCycle -PolicyType Initial"
Write-Host ""

