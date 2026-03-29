#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Start-LabVMs.ps1
# Headless startup: netwerk herstellen + VMs in de juiste volgorde starten.
#
# Volgorde:
#   1. Netwerk (vSwitch + NAT + gateway-IP op host) - niet persistent na reboot
#   2. DC01  - moet als eerste draaien (AD, DNS, DHCP)
#   3. MGMT01, W11-01, W11-02, W11-AUTOPILOT
#
# Autopilot-IP:
#   Na een Autopilot-reset wordt het OS opnieuw geïnstalleerd en
#   raakt een handmatig ingesteld statisch IP kwijt. Dit script
#   configureert eenmalig een DHCP-scope op DC01 + een vaste
#   reservering voor de Autopilot-VM op basis van het Hyper-V
#   MAC-adres. Zo krijgt de VM altijd hetzelfde IP - ook na reset.
#   Gereserveerd IP: zie $AutopilotReservedIP hieronder.
#
# Draait via Windows Scheduled Task bij systeemstart (als SYSTEM).
# Log → Start-LabVMs.log (in repo-root, staat in .gitignore)
# ============================================================

$ErrorActionPreference = 'Continue'

# ── Configuratie ─────────────────────────────────────────────
$AutopilotReservedIP = '10.50.10.30'   # vaste DHCP-reservering voor LAB-W11-AUTOPILOT
$DhcpScopeStart      = '10.50.10.100'
$DhcpScopeEnd        = '10.50.10.200'
$DcWaitMinutes       = 3               # max. wachttijd tot DC online is
$VmStartDelay        = 5               # seconden pauze tussen VM-starts

# ── Config laden ─────────────────────────────────────────────
$repoRoot   = Join-Path $PSScriptRoot '..\..'
$configPath = Join-Path $repoRoot 'config.ps1'
if (-not (Test-Path $configPath)) { Write-Error "config.ps1 niet gevonden: $configPath"; exit 1 }
$modulePath = Join-Path $repoRoot 'modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force
$SSWConfig = Import-SSWLabConfig -ConfigPath $configPath
$localConfig = Join-Path $repoRoot 'config.local.ps1'
if (Test-Path $localConfig) { . $localConfig }

# ── Logging ──────────────────────────────────────────────────
$logFile = Join-Path $repoRoot 'Start-LabVMs.log'
function Write-Log([string]$msg) {
    $line = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $msg"
    Write-Host $line
    try {
        Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
    } catch {
        Write-Verbose "Schrijven naar logbestand mislukte: $($_.Exception.Message)"
    }
}

# ── Hulpfunctie: lab-credential ──────────────────────────────
function Get-LabCred([string]$user) {
    if (-not $SSWConfig.LabPassword) {
        Write-Log "  LET OP: LabPassword niet ingesteld in config.local.ps1 - PS Direct-stappen overgeslagen."
        return $null
    }
    New-SSWCredential -UserName $user -SecretName 'SSWLab-LabPassword' -Config $SSWConfig -ConfigValueName 'LabPassword' -EnvironmentVariableName 'SSW_LAB_PASSWORD'
}

# Autopilot VM heeft een eigen lokaal account met apart wachtwoord
function Get-AutopilotCred {
    $apPw = if ($SSWConfig.AutopilotPassword) { $SSWConfig.AutopilotPassword } else { $SSWConfig.LabPassword }
    if (-not $apPw) { return $null }
    New-SSWCredential -UserName 'autopilot' -Password (ConvertTo-SSWSecureString -Value $apPw)
}

Write-Log "======================================================"
Write-Log "  SSW-Lab Startup"
Write-Log "======================================================"

# ══════════════════════════════════════════════════════════════
# STAP 1 — Netwerk herstellen
# (vSwitch, gateway-IP en NAT verdwijnen na host-reboot)
# ══════════════════════════════════════════════════════════════
Write-Log "[1/3] Netwerk controleren/herstellen..."

$switchName   = $SSWConfig.vSwitchName    # SSW-Internal
$natName      = $SSWConfig.NATName        # SSW-NAT
$natSubnet    = $SSWConfig.NATSubnet      # 10.50.10.0/24
$gatewayIP    = $SSWConfig.GatewayIP      # 10.50.10.1
$adapterAlias = "vEthernet ($switchName)"

# vSwitch
if (-not (Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue)) {
    try {
        New-VMSwitch -Name $switchName -SwitchType Internal -ErrorAction Stop | Out-Null
        Write-Log "  vSwitch '$switchName' aangemaakt."
    } catch { Write-Log "  FOUT vSwitch: $_" }
} else {
    Write-Log "  vSwitch '$switchName' bestaat al."
}

# Gateway-IP op host-adapter
$existIP = Get-NetIPAddress -InterfaceAlias $adapterAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
           Where-Object { $_.IPAddress -eq $gatewayIP }
if (-not $existIP) {
    try {
        New-NetIPAddress -IPAddress $gatewayIP -PrefixLength 24 -InterfaceAlias $adapterAlias -ErrorAction Stop | Out-Null
        Write-Log "  Gateway-IP $gatewayIP ingesteld op $adapterAlias."
    } catch { Write-Log "  FOUT gateway-IP: $_" }
} else {
    Write-Log "  Gateway-IP $gatewayIP al aanwezig."
}

# NAT
if (-not (Get-NetNat -Name $natName -ErrorAction SilentlyContinue)) {
    try {
        New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix $natSubnet -ErrorAction Stop | Out-Null
        Write-Log "  NAT '$natName' aangemaakt."
    } catch { Write-Log "  FOUT NAT: $_" }
} else {
    Write-Log "  NAT '$natName' bestaat al."
}

Write-Log "[1/3] Netwerk gereed."

# ══════════════════════════════════════════════════════════════
# STAP 2 — DC01 starten + wachten op AD
# ══════════════════════════════════════════════════════════════
Write-Log "[2/3] DC01 starten en wachten op AD..."

$profiles = Get-SSWVmProfiles -Config $SSWConfig
$dcVMName = (Get-SSWVmProfile -Profiles $profiles -Name 'DC01').Name

$dcVM = Get-VM -Name $dcVMName -ErrorAction SilentlyContinue
if (-not $dcVM) {
    Write-Log "  VM '$dcVMName' niet gevonden in Hyper-V - VMs nog niet aangemaakt? Startup gestopt."
    exit 0
}

if ($dcVM.State -ne 'Running') {
    Start-VM -Name $dcVMName
    Write-Log "  '$dcVMName' gestart."
} else {
    Write-Log "  '$dcVMName' draait al."
}

# Wachten tot NTDS-service actief is (= AD beschikbaar)
$domCred = Get-LabCred "$($SSWConfig.DomainName)\$($SSWConfig.DomainAdmin)"
$dcOnline = $false
if ($domCred) {
    Write-Log "  Wachten op AD (max $DcWaitMinutes min)..."
    $deadline = (Get-Date).AddMinutes($DcWaitMinutes)
    while (-not $dcOnline -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 15
        try {
            $svc = Invoke-Command -VMName $dcVMName -Credential $domCred -ErrorAction Stop -ScriptBlock {
                (Get-Service 'NTDS' -ErrorAction SilentlyContinue).Status
            }
            if ($svc -eq 'Running') { $dcOnline = $true }
        } catch {
            Write-Verbose "DC nog niet klaar voor NTDS-check: $($_.Exception.Message)"
        }
    }
    if ($dcOnline) { Write-Log "  DC online - AD actief." }
    else           { Write-Log "  WAARSCHUWING: DC niet bereikbaar binnen $DcWaitMinutes min - doorgaan zonder AD-check." }
}

# ── 2b. DHCP op DC01: scope + vaste reservering voor Autopilot-VM ────────
if ($dcOnline -and $domCred) {
    Write-Log "  DHCP op DC01 controleren..."

    # MAC-adres van de Autopilot-VM ophalen via Hyper-V (host-kant, VM hoeft niet te draaien)
    $apVMName  = $profiles.'W11-AUTOPILOT'.Name
    $apAdapter = Get-VMNetworkAdapter -VMName $apVMName -ErrorAction SilentlyContinue | Select-Object -First 1
    $apMAC = if ($apAdapter -and $apAdapter.MacAddress) {
        # Hyper-V levert '001234ABCDEF' -> DHCP verwacht '00-12-34-AB-CD-EF'
        ($apAdapter.MacAddress -replace '[:\-]', '') -replace '(..)(..)(..)(..)(..)(..)', '$1-$2-$3-$4-$5-$6'
    } else {
        Write-Log "  WAARSCHUWING: MAC-adres van '$apVMName' niet gevonden - DHCP-reservering overgeslagen."
        $null
    }

    $scopeID     = '10.50.10.0'
    $dhcpGateway = $gatewayIP
    $dhcpDNS     = $SSWConfig.DCIP   # 10.50.10.10

    try {
        $dhcpLog = Invoke-Command -VMName $dcVMName -Credential $domCred -ErrorAction Stop -ScriptBlock {
            param($scopeID, $scopeStart, $scopeEnd, $apIP, $apMAC, $gateway, $dns)
            $out = [System.Collections.Generic.List[string]]::new()

            # DHCP-server installeren indien nog niet aanwezig
            $fqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN"
            $feat = Get-WindowsFeature DHCP -ErrorAction SilentlyContinue
            if ($feat -and -not $feat.Installed) {
                $out.Add("DHCP-server installeren...")
                Install-WindowsFeature DHCP -IncludeManagementTools | Out-Null
                # Post-install configuratie-melding onderdrukken
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' `
                    -Name 'ConfigurationState' -Value 2 -ErrorAction SilentlyContinue
                $out.Add("DHCP-server geïnstalleerd.")
            }
            # Autorisatie altijd controleren (los van installatie) - vereist FQDN, niet NetBIOS naam
            $authorized = Get-DhcpServerInDC -ErrorAction SilentlyContinue | Where-Object { $_.DnsName -ieq $fqdn }
            if (-not $authorized) {
                try {
                    Add-DhcpServerInDC -DnsName $fqdn -ErrorAction Stop
                    Restart-Service DHCPServer -ErrorAction SilentlyContinue
                    $out.Add("DHCP-server geautoriseerd in AD ($fqdn) en service herstart.")
                } catch {
                    $out.Add("WAARSCHUWING: DHCP-autorisatie mislukt: $_")
                }
            } else {
                $out.Add("DHCP-server was al geautoriseerd in AD.")
            }

            # DHCP-scope aanmaken als die er nog niet is
            if (-not (Get-DhcpServerv4Scope -ScopeId $scopeID -ErrorAction SilentlyContinue)) {
                Add-DhcpServerv4Scope -Name 'SSW-Lab' `
                    -StartRange $scopeStart -EndRange $scopeEnd `
                    -SubnetMask '255.255.255.0' -State Active | Out-Null
                Set-DhcpServerv4OptionValue -ScopeId $scopeID `
                    -Router $gateway -DnsServer $dns -ErrorAction SilentlyContinue | Out-Null
                $out.Add("DHCP-scope $scopeID aangemaakt ($scopeStart - $scopeEnd).")
            } else {
                $out.Add("DHCP-scope $scopeID bestaat al.")
            }

            # Exclusion range: .1-.99 zijn infrastructuur-IPs (gateway, DC, MGMT, Autopilot).
            # DHCP mag nooit een IP in dit bereik uitdelen aan een willekeurige client.
            $excl = Get-DhcpServerv4ExclusionRange -ScopeId $scopeID -ErrorAction SilentlyContinue |
                    Where-Object { $_.StartRange -eq '10.50.10.1' }
            if (-not $excl) {
                Add-DhcpServerv4ExclusionRange -ScopeId $scopeID -StartRange '10.50.10.1' -EndRange '10.50.10.99' -ErrorAction SilentlyContinue
                $out.Add("DHCP-exclusie 10.50.10.1-99 aangemaakt (infrastructuur-IPs beschermd).")
            } else {
                $out.Add("DHCP-exclusie 10.50.10.1-99 bestond al.")
            }

            # DHCP-reservering voor Autopilot-VM
            if ($apMAC) {
                $existing = Get-DhcpServerv4Reservation -ScopeId $scopeID -ErrorAction SilentlyContinue |
                            Where-Object { $_.ClientId -ieq $apMAC }
                if (-not $existing) {
                    Add-DhcpServerv4Reservation -ScopeId $scopeID -IPAddress $apIP `
                        -ClientId $apMAC -Description 'LAB-W11-AUTOPILOT - vaste DHCP-reservering' | Out-Null
                    $out.Add("DHCP-reservering $apIP aangemaakt voor MAC $apMAC.")
                } else {
                    $out.Add("DHCP-reservering voor Autopilot-VM al aanwezig ($apIP).")
                }
            }

            return $out
        } -ArgumentList $scopeID, $DhcpScopeStart, $DhcpScopeEnd, $AutopilotReservedIP, $apMAC, $dhcpGateway, $dhcpDNS

        foreach ($line in $dhcpLog) { Write-Log "  $line" }
    } catch {
        Write-Log "  WAARSCHUWING DHCP-setup: $_"
    }
}

# ── 2c. Zorg dat W11-01 en W11-02 DHCP gebruiken ──────────────────────────
# Lab-oefeningen (bijv. MD-102 netwerkconfiguratie) kunnen statische IPs
# achterlaten in het infrastructuurbereik (.1-.99). Dat veroorzaakt IP-conflicten
# met de Autopilot-VM en andere vaste IPs. Bij elke startup worden de client-VMs
# automatisch teruggezet naar DHCP als ze een statisch IP in .1-.99 hebben.
$clientW11 = @('W11-01', 'W11-02')
foreach ($key in $clientW11) {
    $vmProfile = $profiles.$key
    if (-not $vmProfile) { continue }
    $vmName = $vmProfile.Name
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm -or $vm.State -ne 'Running') { continue }

    $labCred = Get-LabCred "labadmin"
    if (-not $labCred) { break }  # LabPassword niet ingesteld, overslaan

    try {
        $resetResult = Invoke-Command -VMName $vmName -Credential $labCred -ErrorAction Stop -ScriptBlock {
            $a   = Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1
            $idx = $a.InterfaceIndex
            $staticIPs = Get-NetIPAddress -InterfaceIndex $idx -AddressFamily IPv4 |
                         Where-Object { $_.PrefixOrigin -eq 'Manual' -and $_.IPAddress -match '^10\.50\.10\.[1-9][0-9]?$' -and [int]($_.IPAddress.Split('.')[-1]) -lt 100 }
            if ($staticIPs) {
                netsh interface ip set address name="$($a.Name)" source=dhcp 2>$null
                netsh interface ip set dns    name="$($a.Name)" source=dhcp 2>$null
                "DHCP ingesteld (had statisch: $($staticIPs.IPAddress -join ', '))"
            } else {
                "OK (geen statisch IP in infrastructuurbereik)"
            }
        }
        Write-Log "  $vmName - $resetResult"
    } catch {
        Write-Log "  $vmName - kan DHCP-check niet uitvoeren: $_"
    }
}

# ══════════════════════════════════════════════════════════════
# STAP 3 — Overige VMs starten in volgorde
# (MGMT01 → W11-01 → W11-02 → W11-AUTOPILOT)
# VMs die niet bestaan worden overgeslagen (geen fout).
# ══════════════════════════════════════════════════════════════
Write-Log "[3/3] Overige VMs starten..."

$startOrder = @('MGMT01', 'W11-01', 'W11-02', 'W11-AUTOPILOT')
foreach ($key in $startOrder) {
    $vmProfile = $profiles.$key
    if (-not $vmProfile) { Write-Log "  Profiel '$key' niet gevonden - overgeslagen."; continue }

    $vmName = $vmProfile.Name
    $vm     = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm)                  { Write-Log "  '$vmName' niet gevonden in Hyper-V - overgeslagen."; continue }
    if ($vm.State -eq 'Running')   { Write-Log "  '$vmName' draait al."; continue }

    try {
        Start-VM -Name $vmName
        Write-Log "  '$vmName' gestart."
        Start-Sleep -Seconds $VmStartDelay
    } catch {
        Write-Log "  FOUT bij starten '$vmName': $_"
    }
}

Write-Log "[3/3] Alle aanwezige VMs gestart."
Write-Log "======================================================"
Write-Log "  SSW-Lab Startup voltooid."
Write-Log "======================================================"
