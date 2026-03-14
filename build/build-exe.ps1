#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | build\build-exe.ps1
# Converteert alle lab-scripts naar zelfstandige .exe's.
# Vereist: ps2exe (wordt automatisch geïnstalleerd via PSGallery)
# Gebruik : .\build\build-exe.ps1
#           .\build\build-exe.ps1 -Version "1.2.0"
# ============================================================
param(
    [string]$Version = "1.0.0"
)

$ErrorActionPreference = "Stop"

# ── ps2exe installeren indien nog niet aanwezig ──────────────
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "ps2exe niet gevonden — installeren via PSGallery…" -ForegroundColor Cyan
    Install-Module -Name ps2exe -Scope CurrentUser -Force -Repository PSGallery
}
Import-Module ps2exe -Force

# ── Paden ────────────────────────────────────────────────────
$root     = Split-Path $PSScriptRoot -Parent
$scripts  = Join-Path $root "scripts"
$output   = Join-Path $root "executables"

if (-not (Test-Path $output)) { New-Item -ItemType Directory -Path $output -Force | Out-Null }

# ── Script-definitie ─────────────────────────────────────────
$targets = @(
    @{ Script = "00-PREFLIGHT.ps1";   Exe = "Stap1 - Preflight (systeemcheck).exe";          Description = "SSW-Lab Stap 1 — Preflight systeemcheck" }
    @{ Script = "01-NETWORK.ps1";     Exe = "Stap2 - Netwerk (vSwitch en NAT).exe";           Description = "SSW-Lab Stap 2 — Netwerk inrichten" }
    @{ Script = "02-MAKE-ISOS.ps1";   Exe = "Stap3 - ISO voorbereiding (unattended).exe";    Description = "SSW-Lab Stap 3 — Unattended ISO's bouwen" }
    @{ Script = "03-VMS.ps1";         Exe = "Stap4 - VMs aanmaken.exe";                      Description = "SSW-Lab Stap 4 — VMs aanmaken" }
    @{ Script = "04-SETUP-DC.ps1";    Exe = "Stap5 - Domain Controller inrichten.exe";       Description = "SSW-Lab Stap 5 — DC inrichten" }
    @{ Script = "05-JOIN-DOMAIN.ps1"; Exe = "Stap6 - Domain Join (clients).exe";             Description = "SSW-Lab Stap 6 — Domain Join" }
)

# ── Bouwen ───────────────────────────────────────────────────
$ok = 0; $fail = 0

foreach ($t in $targets) {
    $src = Join-Path $scripts $t.Script
    $dst = Join-Path $output  $t.Exe

    if (-not (Test-Path $src)) {
        Write-Warning "Niet gevonden: $src — overgeslagen."
        $fail++
        continue
    }

    Write-Host "Bouwen: $($t.Script) → $($t.Exe) …" -ForegroundColor Cyan
    try {
        Invoke-ps2exe `
            -InputFile  $src `
            -OutputFile $dst `
            -requireAdmin `
            -noConsole `
            -title       $t.Description `
            -description $t.Description `
            -company     "Sogeti SSW" `
            -product     "SSW-Lab" `
            -version     $Version `
            -copyright   "Sogeti SSW $(Get-Date -Format yyyy)"

        $size = [math]::Round((Get-Item $dst).Length / 1KB)
        Write-Host "  ✔ $($t.Exe) ($size KB)" -ForegroundColor Green
        $ok++
    } catch {
        Write-Warning "  ✘ FOUT bij $($t.Script): $_"
        $fail++
    }
}

Write-Host ""
Write-Host "Klaar: $ok geslaagd, $fail mislukt." -ForegroundColor $(if ($fail -gt 0) { "Yellow" } else { "Green" })
Write-Host "EXE's staan in: $output" -ForegroundColor Cyan

# ── Optioneel: zip maken klaar voor GitHub Release ───────────
$zipPath = Join-Path $root "build\SSW-Lab-$Version.zip"
if (Get-Command Compress-Archive -ErrorAction SilentlyContinue) {
    Compress-Archive -Path "$output\*.exe" -DestinationPath $zipPath -Force
    Write-Host "Release-zip: $zipPath" -ForegroundColor Cyan
}
