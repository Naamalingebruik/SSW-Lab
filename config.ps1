# ============================================================
# SSW-Lab | config.ps1
# Centrale configuratie — aanpassen voor jouw omgeving.
# Dot-sourcen in elk script: . "$PSScriptRoot\..\config.ps1"
# ============================================================

$SSWConfig = @{

    # ── Domein ──────────────────────────────────────────────
    DomainName    = "ssw.lab"
    DomainNetBIOS = "LAB"
    AdminUser     = "Administrator"
    DomainAdmin   = "labadmin"
    # AdminPassword wordt interactief gevraagd — nooit hardcoden

    # ── Paden ───────────────────────────────────────────────
    VMPath        = "D:\SSW-Lab\VMs"
    ISOPath       = "$PSScriptRoot\isos"   # map staat in repo, inhoud genegeerd via .gitignore
    # ── Netwerk ─────────────────────────────────────────────
    vSwitchName   = "SSW-Internal"
    NATName       = "SSW-NAT"
    NATSubnet     = "10.50.10.0/24"
    GatewayIP     = "10.50.10.1"

    # ── VM IP-adressen ──────────────────────────────────────
    DCIP          = "10.50.10.10"
    MGMTIP        = "10.50.10.20"

    # ── VM Profielen (uit vm-profiles.json geladen in scripts)
    ProfilePath   = "$PSScriptRoot\profiles\vm-profiles.json"

    # ── Entra Connect (optioneel) ────────────────────────────
    # Vul EntraUPN in als je een geverifieerd custom domein hebt in je dev-tenant.
    # Laat leeg als je geen Entra Connect wilt gebruiken.
    # Gebruik config.local.ps1 (gitignored) voor jouw persoonlijke waarde.
    EntraUPN      = ""   # bijv. "lab.contoso.com"

    # ── Wachtwoorden ─────────────────────────────────────────
    # LabPassword: wachtwoord voor labadmin (DC, MGMT, W11-01, W11-02) — stel in via config.local.ps1
    LabPassword       = ""
    # AutopilotPassword: wachtwoord voor lokale 'autopilot'-account op W11-AUTOPILOT
    # Dit account is anders omdat Autopilot OOBE een eigen lokaal account aanmaakt.
    # Stel in via config.local.ps1 als het afwijkt van LabPassword.
    AutopilotPassword = ""

    # ── Presets ─────────────────────────────────────────────
    Presets = @{
        Minimal  = @("DC01", "W11-01")
        Standard = @("DC01", "MGMT01", "W11-01", "W11-02")
        Full     = @("DC01", "MGMT01", "W11-01", "W11-02", "W11-AUTOPILOT")
    }
}

# ── Lokale override (gitignored) ─────────────────────────────
# Maak config.local.ps1 aan om persoonlijke waarden te overschrijven.
# Voorbeeld inhoud:  $SSWConfig.EntraUPN = "lab.jouwdomein.nl"
if (Test-Path "$PSScriptRoot\config.local.ps1") {
    . "$PSScriptRoot\config.local.ps1"
}
