# ============================================================
# SSW-Lab | config.ps1
# Centrale configuratie — aanpassen voor jouw omgeving.
# Dot-sourcen in elk script: . "$PSScriptRoot\..\config.ps1"
# ============================================================

$SSWConfig = @{

    # ── Domein ──────────────────────────────────────────────
    DomainName    = "ssw.lab"
    DomainNetBIOS = "SSW"
    AdminUser     = "Administrator"
    DomainAdmin   = "labadmin"
    # AdminPassword wordt interactief gevraagd — nooit hardcoden

    # ── Paden ───────────────────────────────────────────────
    VMPath        = "D:\SSW-Lab\VMs"
    ISOPath       = "D:\SSW-Lab\ISOs"
    UnattendPath  = "D:\SSW-Lab\Unattend"
    LogPath       = "D:\SSW-Lab\Logs"

    # ── Netwerk ─────────────────────────────────────────────
    vSwitchName   = "SSW-Internal"
    NATName       = "SSW-NAT"
    NATSubnet     = "10.50.10.0/24"
    GatewayIP     = "10.50.10.1"

    # ── VM IP-adressen ──────────────────────────────────────
    DCIP          = "10.50.10.10"
    MGMTIP        = "10.50.10.20"
    ClientBaseIP  = "10.50.10.30"   # .30, .31, .32 voor clients

    # ── VM Profielen (uit vm-profiles.json geladen in scripts)
    ProfilePath   = "$PSScriptRoot\profiles\vm-profiles.json"

    # ── Presets ─────────────────────────────────────────────
    Presets = @{
        Minimal  = @("DC01", "W11-01")
        Standard = @("DC01", "MGMT01", "W11-01", "W11-02")
        Full     = @("DC01", "MGMT01", "W11-01", "W11-02", "W11-AUTOPILOT")
    }
}
