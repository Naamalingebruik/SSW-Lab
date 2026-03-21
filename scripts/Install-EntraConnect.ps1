#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Install-EntraConnect.ps1
# Installeert Entra Connect op LAB-DC01 en voegt de UPN-suffix
# toe aan Active Directory.
#
# Vereisten:
#   - config.local.ps1 met: $SSWConfig.EntraUPN = "lab.jouwdomein.nl"
#   - LAB-DC01 is Running en domain is ingericht (na 04-SETUP-DC.ps1)
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

# ── Credentials (interactief — nooit hardcoden) ───────────────────────────────

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

# ── Stap 1: UPN-suffix toevoegen aan AD ──────────────────────────────────────

Write-Host ""
Write-Host "Stap 1/3 — UPN-suffix '$entraUPN' toevoegen aan AD..." -ForegroundColor Cyan

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    param($upn)
    $forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
    if ($forest.UPNSuffixes -contains $upn) {
        Write-Host "  UPN-suffix '$upn' bestaat al — overgeslagen."
    } else {
        $forest.UPNSuffixes.Add($upn)
        Write-Host "  UPN-suffix '$upn' toegevoegd."
    }
} -ArgumentList $entraUPN -ErrorAction Stop

Write-Host "Stap 1 klaar." -ForegroundColor Green

# ── Stap 2: MSI kopiëren naar VM ─────────────────────────────────────────────

Write-Host ""
Write-Host "Stap 2/3 — MSI kopiëren naar $vmName..." -ForegroundColor Cyan

Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
    New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
} -ErrorAction Stop

Copy-VMFile -Name $vmName -SourcePath $msiHost -DestinationPath $msiDest `
    -CreateFullPath -FileSource Host -Force -ErrorAction Stop

Write-Host "MSI gekopieerd naar $msiDest." -ForegroundColor Green

# ── Stap 3: Installeren ───────────────────────────────────────────────────────

Write-Host ""
Write-Host "Stap 3/3 — Entra Connect installeren (dit duurt ~2 minuten)..." -ForegroundColor Cyan

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
    3010 { Write-Host "Installatie geslaagd — herstart vereist." -ForegroundColor Yellow
           Write-Host "  Restart-VM -Name '$vmName' -Force" }
    default { Write-Host "Installatie mislukt — ExitCode: $exitCode" -ForegroundColor Red
              Write-Host "  Controleer C:\Windows\Temp\MSI*.log op $vmName voor details."
              exit 1 }
}

Write-Host ""
Write-Host "Volgende stappen:" -ForegroundColor Yellow
Write-Host "  1. Open Hyper-V console naar $vmName"
Write-Host "  2. Start 'Microsoft Entra Connect' via het Startmenu"
Write-Host "  3. Kies 'Express Settings' (of Custom voor meer controle)"
Write-Host "  4. Log in met je Global Admin van de dev-tenant"
Write-Host "  5. AD-credentials: $($env:USERDOMAIN)\Administrator"
Write-Host "  6. Verifieer sync: Start-ADSyncSyncCycle -PolicyType Initial"
Write-Host ""
