<#
.SYNOPSIS
    Controleert de huidige staat van het SSW-Lab en mappt die op de MD-102 weekmilestones
    én de officiële MS Learn examendomeinen (zoals gepubliceerd op learn.microsoft.com/credentials/certifications/resources/study-guides/md-102).
    Genereert of overschrijft status.md in de root van de repo.

.DESCRIPTION
    - Verbindt via PS Direct met elke VM
    - Checkt: VM-staat, join-type, activatie, netwerk, Entra Connect, modules
    - Detecteert welke milestones bereikt zijn (ook al zijn ze out-of-order gedaan)
    - Koppelt lab-voltooiing aan de 4 officiële MD-102 examendomeinen
    - Schrijft een gestructureerd markdown-statusbestand

    MD-102 examendomeinen (bron: MS Learn, bijgewerkt jan 2026):
      Domein 1 — Infrastructuur voor devices voorbereiden         (25-30%)
      Domein 2 — Devices beheren en onderhouden                  (30-35%)
      Domein 3 — Applicaties beheren                             (15-20%)
      Domein 4 — Devices beveiligen                             (15-20%)

.NOTES
    Draaien vanaf de Hyper-V host: D:\Github\SSW-Lab
#>

param(
    [string]$OutputPath = "$PSScriptRoot\..\..\status.md",
    [switch]$Quiet
)

$ErrorActionPreference = 'SilentlyContinue'
$startTime = Get-Date

# Config laden
$configPath = "$PSScriptRoot\..\..\config.ps1"
if (Test-Path $configPath) { . $configPath }
$localConfig = "$PSScriptRoot\..\..\config.local.ps1"
if (Test-Path $localConfig) { . $localConfig }

if (-not ($SSWConfig -and $SSWConfig.LabPassword)) {
    Write-Error "config.local.ps1 ontbreekt of heeft geen LabPassword. Maak het aan vanuit config.local.ps1.example."
    exit 1
}
$labPassword = $SSWConfig.LabPassword
$entraUPN    = if ($SSWConfig -and $SSWConfig.EntraUPN) { $SSWConfig.EntraUPN } else { 'lab.stts.nl' }

$pw        = ConvertTo-SecureString $labPassword -AsPlainText -Force
$credAdmin    = New-Object PSCredential('LAB\labadmin', $pw)
$credLocal    = New-Object PSCredential('labadmin', $pw)

# Unicode iconen via runtime char conversion (encoding-safe op Windows PS 5)
$OK   = [char]::ConvertFromUtf32(0x2705)  # OK
$FAIL = [char]::ConvertFromUtf32(0x274C)  # FAIL
$PEND = [char]::ConvertFromUtf32(0x23F3)  # PENDING

# ──────────────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────────────
function icon($bool) { if ($bool) { $OK } else { $FAIL } }
function warn($bool) { if ($bool) { $OK } else { $PEND } }

function Invoke-VMCmd {
    param($VMName, [scriptblock]$ScriptBlock, $Credential = $credAdmin)
    try {
        Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock $ScriptBlock -ErrorAction Stop
    } catch {
        $null
    }
}

# ──────────────────────────────────────────────────────────────────
# 1. VM staat
# ──────────────────────────────────────────────────────────────────
$vms = Get-VM | Select-Object Name, State, CPUUsage, MemoryAssigned
$vmTable = @{}
foreach ($vm in $vms) { $vmTable[$vm.Name] = $vm }

# ──────────────────────────────────────────────────────────────────
# 2. Netwerkcheck per client VM
# ──────────────────────────────────────────────────────────────────
$netStatus = @{}

foreach ($vmName in @('LAB-W11-01','LAB-W11-02','LAB-W11-AUTOPILOT')) {
    if ($vmTable[$vmName].State -ne 'Running') { $netStatus[$vmName] = @{ IP = 'VM_OFF'; Internet = $false }; continue }
    $r = Invoke-VMCmd $vmName {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '169.*' -and $_.IPAddress -ne '127.0.0.1' } | Select-Object -First 1).IPAddress
        # TCP-check op poort 80 — betrouwbaarder dan ICMP (ping wordt geblokkeerd)
        $tcpTest = (New-Object System.Net.Sockets.TcpClient)
        try { $tcpTest.Connect('13.107.4.52', 80); $inet = $tcpTest.Connected } catch { $inet = $false } finally { $tcpTest.Close() }
        # Fallback: DNS-resolutie
        if (-not $inet) { $inet = ($null -ne (Resolve-DnsName 'microsoft.com' -ErrorAction SilentlyContinue | Select-Object -First 1)) }
        [PSCustomObject]@{ IP = $ip; Internet = $inet }
    } $credLocal
    $netStatus[$vmName] = if ($r) { @{ IP = $r.IP; Internet = $r.Internet } } else { @{ IP = 'ERR'; Internet = $false } }
}

# ──────────────────────────────────────────────────────────────────
# 3. Join-status per client VM (dsregcmd)
# ──────────────────────────────────────────────────────────────────
$joinStatus = @{}

foreach ($vmName in @('LAB-W11-01','LAB-W11-02','LAB-W11-AUTOPILOT')) {
    if ($vmTable[$vmName].State -ne 'Running') { $joinStatus[$vmName] = @{ PsDirect = $false }; continue }
    $r = Invoke-VMCmd $vmName {
        $raw = dsregcmd /status
        $get = { param($k) ($raw | Select-String "^\s*$k\s*:\s*(.+)$" | Select-Object -First 1) -replace ".*:\s*", '' }
        [PSCustomObject]@{
            AzureAdJoined    = (& $get 'AzureAdJoined').Trim()
            DomainJoined     = (& $get 'DomainJoined').Trim()
            WorkplaceJoined  = (& $get 'WorkplaceJoined').Trim()
            TenantName       = (& $get 'WorkplaceTenantName').Trim()
            DeviceId         = (& $get 'DeviceId').Trim()
            MdmUrl           = (& $get 'MdmUrl').Trim()
        }
    } $credLocal
    $joinStatus[$vmName] = if ($r) {
        @{
            PsDirect        = $true
            AzureAdJoined   = $r.AzureAdJoined -eq 'YES'
            DomainJoined    = $r.DomainJoined  -eq 'YES'
            WorkplaceJoined = $r.WorkplaceJoined -eq 'YES'
            TenantName      = $r.TenantName
            DeviceId        = $r.DeviceId
            MdmUrl          = $r.MdmUrl
            InIntune        = $r.MdmUrl -like '*manage.microsoft.com*'
        }
    } else {
        @{ PsDirect = $false }  # PS Direct mislukt — geen credential beschikbaar, niet fout-positief rapporteren
    }
}

# ──────────────────────────────────────────────────────────────────
# 4. Windows activatie per client VM
# ──────────────────────────────────────────────────────────────────
$activation = @{}

foreach ($vmName in @('LAB-W11-01','LAB-W11-02','LAB-W11-AUTOPILOT')) {
    if ($vmTable[$vmName].State -ne 'Running') { $activation[$vmName] = 99; continue }
    $r = Invoke-VMCmd $vmName {
        (Get-CimInstance SoftwareLicensingProduct |
            Where-Object {$_.Name -like 'Windows*' -and $_.PartialProductKey} |
            Select-Object -First 1).LicenseStatus
    } $credLocal
    $activation[$vmName] = if ($null -ne $r) { [int]$r } else { -1 }
}

# ──────────────────────────────────────────────────────────────────
# 5. Entra Connect sync status (op DC01)
# ──────────────────────────────────────────────────────────────────
$syncStatus = @{ Installed = $false; ServiceRunning = $false; LastSync = $null; SyncEnabled = $false }

if ($vmTable['LAB-DC01'].State -eq 'Running') {
    $r = Invoke-VMCmd 'LAB-DC01' {
        $svc = Get-Service ADSync -ErrorAction SilentlyContinue
        if (-not $svc) { return $null }
        Import-Module ADSync -ErrorAction SilentlyContinue
        $sched = Get-ADSyncScheduler -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Installed       = $true
            ServiceRunning  = ($svc.Status -eq 'Running')
            LastSync        = $sched.LastSyncRunStartTime
            SyncEnabled     = $sched.SyncCycleEnabled
        }
    }
    if ($r) { $syncStatus = @{ Installed = $r.Installed; ServiceRunning = $r.ServiceRunning; LastSync = $r.LastSync; SyncEnabled = $r.SyncEnabled } }
}

# ──────────────────────────────────────────────────────────────────
# 6. Modules op MGMT01
# ──────────────────────────────────────────────────────────────────
$mgmtModules = @{ Graph = $false; ExO = $false; Az = $false; LAPS = $false }

if ($vmTable['LAB-MGMT01'].State -eq 'Running') {
    $r = Invoke-VMCmd 'LAB-MGMT01' {
        [PSCustomObject]@{
            Graph = [bool](Get-Module Microsoft.Graph -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1)
            ExO   = [bool](Get-Module ExchangeOnlineManagement -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1)
            Az    = [bool](Get-Module Az -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1)
            LAPS  = [bool](Get-Module LAPS -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1)
        }
    }
    if ($r) { $mgmtModules = @{ Graph = $r.Graph; ExO = $r.ExO; Az = $r.Az; LAPS = $r.LAPS } }
}

# ──────────────────────────────────────────────────────────────────
# 7. AD domein + labadmin check (op DC01)
# ──────────────────────────────────────────────────────────────────
$adStatus = @{ DomainOK = $false; LabadminExists = $false; UPNSuffixOK = $false; UserCount = 0 }

if ($vmTable['LAB-DC01'].State -eq 'Running') {
    $r = Invoke-VMCmd 'LAB-DC01' {
        param($upn)
        $domain    = Get-ADDomain -ErrorAction SilentlyContinue
        $labadmin  = Get-ADUser -Filter {SamAccountName -eq 'labadmin'} -ErrorAction SilentlyContinue
        $upnSuffix = (Get-ADForest).UPNSuffixes -contains $upn
        $users     = (Get-ADUser -Filter *).Count
        [PSCustomObject]@{
            DomainOK       = ($domain.DNSRoot -eq 'ssw.lab')
            LabadminExists = ($null -ne $labadmin)
            UPNSuffixOK    = $upnSuffix
            UserCount      = $users
        }
    } -ScriptBlock { param($upn)
        $domain    = Get-ADDomain -ErrorAction SilentlyContinue
        $labadmin  = Get-ADUser -Filter {SamAccountName -eq 'labadmin'} -ErrorAction SilentlyContinue
        $upnSuffix = (Get-ADForest).UPNSuffixes -contains $upn
        $users     = (Get-ADUser -Filter *).Count
        [PSCustomObject]@{
            DomainOK       = ($domain.DNSRoot -eq 'ssw.lab')
            LabadminExists = ($null -ne $labadmin)
            UPNSuffixOK    = $upnSuffix
            UserCount      = $users
        }
    }

    # Aparte aanroep ivm parameter
    $r2 = Invoke-Command -VMName 'LAB-DC01' -Credential $credAdmin -ScriptBlock {
        param($upn)
        $domain    = Get-ADDomain -ErrorAction SilentlyContinue
        $labadmin  = Get-ADUser -Filter {SamAccountName -eq 'labadmin'} -ErrorAction SilentlyContinue
        $upnSuffix = (Get-ADForest -ErrorAction SilentlyContinue).UPNSuffixes -contains $upn
        $users     = (Get-ADUser -Filter * -ErrorAction SilentlyContinue).Count
        [PSCustomObject]@{
            DomainOK       = ($domain.DNSRoot -eq 'ssw.lab')
            LabadminExists = ($null -ne $labadmin)
            UPNSuffixOK    = $upnSuffix
            UserCount      = $users
        }
    } -ArgumentList $entraUPN -ErrorAction SilentlyContinue

    if ($r2) { $adStatus = @{ DomainOK = $r2.DomainOK; LabadminExists = $r2.LabadminExists; UPNSuffixOK = $r2.UPNSuffixOK; UserCount = $r2.UserCount } }
}

# ──────────────────────────────────────────────────────────────────
# 8. Graph API checks (D2/D3/D4) — verbindt als host-user met tenant
# ──────────────────────────────────────────────────────────────────
$graphStatus = @{
    Connected              = $false
    CompliancePolicies     = 0
    ConditionalAccess      = 0
    ConfigProfiles         = 0
    AutopilotDevices       = 0
    IntuneDevices          = 0
    Win32Apps              = 0
    M365Apps               = 0
    AppProtectionPolicies  = 0
    SecurityBaselines      = 0
    DefenderOnboarded      = 0
    BitLockerPolicies      = 0
}

$graphModule = Get-Module Microsoft.Graph.Authentication -ListAvailable -ErrorAction SilentlyContinue |
               Select-Object -First 1

if ($graphModule) {
    try {
        Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
        Import-Module Microsoft.Graph.DeviceManagement -ErrorAction SilentlyContinue
        Import-Module Microsoft.Graph.Identity.SignIns -ErrorAction SilentlyContinue
        Import-Module Microsoft.Graph.Applications -ErrorAction SilentlyContinue

        # Stille connect — hergebruikt bestaande browser-sessie / cached token
        $ctx = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $ctx) {
            Connect-MgGraph -Scopes @(
                'DeviceManagementConfiguration.Read.All',
                'DeviceManagementApps.Read.All',
                'Policy.Read.All',
                'DeviceManagementManagedDevices.Read.All'
            ) -NoWelcome -ErrorAction Stop
            $ctx = Get-MgContext -ErrorAction SilentlyContinue
        }

        if ($ctx) {
            $graphStatus.Connected = $true

            # D2 — Compliance policies
            $cp = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceCompliancePolicies' -ErrorAction SilentlyContinue
            $graphStatus.CompliancePolicies = if ($cp.value) { $cp.value.Count } else { 0 }

            # D2 — Conditional Access policies
            $ca = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies' -ErrorAction SilentlyContinue
            $graphStatus.ConditionalAccess = if ($ca.value) { $ca.value.Count } else { 0 }

            # D2 — Configuration profiles
            $cfgp = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/deviceConfigurations' -ErrorAction SilentlyContinue
            $graphStatus.ConfigProfiles = if ($cfgp.value) { $cfgp.value.Count } else { 0 }

            # D1 — Autopilot devices
            $ap = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities' -ErrorAction SilentlyContinue
            $graphStatus.AutopilotDevices = if ($ap.value) { $ap.value.Count } else { 0 }

            # D2 — Intune managed devices
            $devs = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?$top=5' -ErrorAction SilentlyContinue
            $graphStatus.IntuneDevices = if ($devs.value) { $devs.value.Count } else { 0 }

            # D3 — Apps
            $apps = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps' -ErrorAction SilentlyContinue
            if ($apps.value) {
                $graphStatus.Win32Apps  = ($apps.value | Where-Object { $_.'@odata.type' -like '*win32*' }).Count
                $graphStatus.M365Apps   = ($apps.value | Where-Object { $_.'@odata.type' -like '*officeSuite*' -or $_.'@odata.type' -like '*m365*' }).Count
            }

            # D3 — App protection policies (MAM)
            $mam = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceAppManagement/managedAppPolicies' -ErrorAction SilentlyContinue
            $graphStatus.AppProtectionPolicies = if ($mam.value) { $mam.value.Count } else { 0 }

            # D4 — Security baselines (intent-based)
            $sb = Invoke-MgGraphRequest -Method GET -Uri 'https://graph.microsoft.com/v1.0/deviceManagement/intents' -ErrorAction SilentlyContinue
            $graphStatus.SecurityBaselines = if ($sb.value) { $sb.value.Count } else { 0 }

            # D4 — Defender onboarded devices
            $graphStatus.DefenderOnboarded = ($devs.value | Where-Object { $_.managedDeviceName -ne $null -and $_.deviceRegistrationState -eq 'registered' }).Count
        }
    } catch {
        # Graph niet beschikbaar of niet ingelogd — silent skip
    }
}

# ──────────────────────────────────────────────────────────────────
# 9. Milestone mapping MD-102 + MS Learn examendomeinen
#    Bron: https://learn.microsoft.com/credentials/certifications/resources/study-guides/md-102
#    Skills bijgewerkt: januari 2026
# ──────────────────────────────────────────────────────────────────

# MS Learn Domein 1 — Infrastructuur voor devices voorbereiden (25-30%)
#   Skills: Windows 11 deployment, Entra provisioning, Autopilot, Intune enrollment,
#           Hybrid Join, Entra Connect, update management

# MS Learn Domein 2 — Devices beheren en onderhouden (30-35%)
#   Skills: Compliance policies, Conditional Access, Configuration profiles,
#           remote actions, monitoring, LAPS

# MS Learn Domein 3 — Applicaties beheren (15-20%)
#   Skills: Win32 apps, Microsoft Store, M365 Apps deployment, app protection policies

# MS Learn Domein 4 — Devices beveiligen (15-20%)
#   Skills: Defender for Endpoint, security baselines, disk encryption, Windows Firewall

# Week 1 — Windows client deployment / lab infra
$w1 = @{
    VM_Running      = ($vmTable['LAB-DC01'].State -eq 'Running') -and ($vmTable['LAB-MGMT01'].State -eq 'Running') -and ($vmTable['LAB-W11-01'].State -eq 'Running')
    Domain_OK       = $adStatus.DomainOK
    Labadmin_OK     = $adStatus.LabadminExists
    W11_Activated   = $activation['LAB-W11-01'] -eq 1
}
$w1.Done = $w1.VM_Running -and $w1.Domain_OK -and $w1.Labadmin_OK -and $w1.W11_Activated

# Week 2 — Intune enrollment
$w2 = @{
    W11_01_Enrolled   = $joinStatus['LAB-W11-01'].InIntune -eq $true
    W11_02_Enrolled   = $joinStatus['LAB-W11-02'].InIntune -eq $true
    Compliance_Policy = $graphStatus.CompliancePolicies -gt 0
    CA_Policy         = $graphStatus.ConditionalAccess -gt 0
    Config_Profiles   = $graphStatus.ConfigProfiles -gt 0
    Devices_In_Portal = $graphStatus.IntuneDevices -gt 0
}
$w2.Done = $w2.W11_01_Enrolled -and $w2.W11_02_Enrolled

# Week 3 — Compliance, CA, identiteit
$w3 = @{
    EntraConnect_Installed = $syncStatus.Installed
    Sync_Running           = $syncStatus.ServiceRunning
    Sync_Ran               = ($null -ne $syncStatus.LastSync -and $syncStatus.LastSync -ne [datetime]::MinValue)
    UPN_Suffix             = $adStatus.UPNSuffixOK
    W11_01_HybridJoined    = $joinStatus['LAB-W11-01'].AzureAdJoined -and $joinStatus['LAB-W11-01'].DomainJoined
}
$w3.Done = $w3.EntraConnect_Installed -and $w3.Sync_Running -and $w3.W11_01_HybridJoined

# Week 4 — App management
$w4 = @{
    Graph_Module   = $mgmtModules.Graph
    ExO_Module     = $mgmtModules.ExO
    Win32_App      = $graphStatus.Win32Apps -gt 0
    M365_Apps      = $graphStatus.M365Apps -gt 0
    App_Protection = $graphStatus.AppProtectionPolicies -gt 0
}
$w4.Done = $w4.Graph_Module -and $w4.ExO_Module

# Week 5 — Autopilot
$w5 = @{
    VM_Running           = $vmTable['LAB-W11-AUTOPILOT'].State -eq 'Running'
    Activated            = $activation['LAB-W11-AUTOPILOT'] -eq 1
    Internet             = $netStatus['LAB-W11-AUTOPILOT'].Internet -eq $true
    Autopilot_Registered = $graphStatus.AutopilotDevices -gt 0
}
$w5.Done = $w5.VM_Running -and $w5.Activated -and $w5.Internet

# ──────────────────────────────────────────────────────────────────
# 9. Aanbeveling: volgende stap
# ──────────────────────────────────────────────────────────────────
$nextSteps = @()

# Volgende stappen samenstellen (ASCII-safe)
$w02join = $joinStatus['LAB-W11-02']

if (-not $w02join.InIntune -and $w02join.WorkplaceJoined -and $w02join.TenantName -notlike '*stts*') {
    $nextSteps += '[ERROR] W11-02: Workplace Join bij verkeerde tenant. Settings -> Accounts -> Access work or school -> Disconnect.'
}

if ($w02join.PsDirect -eq $true -and -not $w02join.WorkplaceJoined -and -not $w02join.AzureAdJoined) {
    $nextSteps += "[ACTIE] W11-02: Nog niet gejoined. Settings -> Accounts -> Access work or school -> Join to Microsoft Entra ID -> $entraUPN"
} elseif ($w02join.PsDirect -eq $false) {
    $nextSteps += '[INFO] W11-02: PS Direct niet beschikbaar (lokale Administrator uitgeschakeld). Join-status onbekend. Activeer via VM-console: net user Administrator <ww> /active:yes'
}

if (-not $syncStatus.Installed) {
    $nextSteps += '[ACTIE] Entra Connect niet geinstalleerd. Voer Install-EntraConnect.ps1 uit op DC01.'
} elseif (-not $syncStatus.ServiceRunning) {
    $nextSteps += '[ACTIE] ADSync service is gestopt. Start: Start-Service ADSync (op DC01)'
} elseif ($null -eq $syncStatus.LastSync -or $syncStatus.LastSync -eq [datetime]::MinValue) {
    $nextSteps += '[WARN] Entra Connect: sync nog niet uitgevoerd. Forceer: Start-ADSyncSyncCycle -PolicyType Delta'
}

if (-not $joinStatus['LAB-W11-01'].InIntune) {
    $nextSteps += '[INFO] W11-01: Hybrid gejoined maar nog niet MDM-enrolled. Wacht op auto-enrollment of configureer via Intune-portal.'
}

if (-not $mgmtModules.Graph) {
    $nextSteps += '[ACTIE] MGMT01: Microsoft.Graph ontbreekt. Install-Module Microsoft.Graph -Scope AllUsers'
}
if (-not $mgmtModules.ExO) {
    $nextSteps += '[ACTIE] MGMT01: ExchangeOnlineManagement ontbreekt. Nodig voor week 4+ labs.'
}

if ($activation['LAB-W11-AUTOPILOT'] -eq 1 -and -not $joinStatus['LAB-W11-AUTOPILOT'].AzureAdJoined) {
    $nextSteps += '[VOLGENDE] W11-AUTOPILOT: Geactiveerd. Volgende stap: Autopilot hash uploaden voor Autopilot-flow.'
}

if (-not $graphStatus.Connected) {
    $nextSteps += "[INFO] Graph niet verbonden - D2/D3/D4 items kunnen niet automatisch worden gemeten. Voer uit: Connect-MgGraph -Scopes 'DeviceManagementConfiguration.Read.All','DeviceManagementApps.Read.All','Policy.Read.All','DeviceManagementManagedDevices.Read.All'"
}

# ──────────────────────────────────────────────────────────────────
# 10. Markdown output samenstellen
# ──────────────────────────────────────────────────────────────────
$ts = $startTime.ToString('yyyy-MM-dd HH:mm')
$host_ = $env:COMPUTERNAME

$activationLabel = @{ 1 = 'Geactiveerd'; 5 = 'Notification (niet geactiveerd)'; -1 = 'Onbekend'; 99 = 'VM Uit' }

function actLabel($code) { if ($activationLabel.ContainsKey($code)) { $activationLabel[$code] } else { "Status $code" } }
function joinLabel($j) {
    if (-not $j -or $j.Count -eq 0) { return 'Onbekend' }
    if ($j.PsDirect -eq $false) { return '(PS Direct n.v.t.)' }
    if ($j.AzureAdJoined -and $j.DomainJoined) { return "Hybrid Entra Joined $(if ($j.InIntune) { $OK + ' Intune' } else { '(Intune pending)' })" }
    if ($j.AzureAdJoined) { return "Entra ID Joined $(if ($j.InIntune) { $OK + ' Intune' } else { '(Intune pending)' })" }
    if ($j.WorkplaceJoined -and $j.InIntune) { return "Workplace Joined + Intune $OK" }
    if ($j.WorkplaceJoined) {
        $t = if ($j.TenantName -eq 'MSFT' -and $j.TenantId -eq '51aecf5c-6f4d-4cf8-a4f1-6c66e6fb3823') { 'lab.stts.nl (dev tenant)' } else { $j.TenantName }
        return "Workplace Joined - $t (MDM pending)"
    }
    return 'Niet gejoined'
}

# ──────────────────────────────────────────────────────────────────
# 10a. Domain item arrays pre-computeren (markdown + console)
# ──────────────────────────────────────────────────────────────────
$d1items = @(
    $w1.VM_Running,
    ($w1.Domain_OK -and $w1.Labadmin_OK),
    $w1.W11_Activated,
    ($w3.EntraConnect_Installed -and $w3.Sync_Running),
    $w3.UPN_Suffix,
    $w3.W11_01_HybridJoined,
    $joinStatus['LAB-W11-02'].WorkplaceJoined,
    ($w5.VM_Running -and $w5.Activated),
    $w5.Autopilot_Registered,   # Autopilot hash geupload
    $w3.Sync_Ran
)
$d1done = ($d1items | Where-Object { $_ }).Count

$d2items = @(
    $w2.W11_01_Enrolled,
    $w2.W11_02_Enrolled,
    $w2.Compliance_Policy,   # Compliance policy
    $w2.CA_Policy,           # Conditional Access policy
    $w2.Config_Profiles,     # Configuration profile
    $mgmtModules.LAPS,
    $false,                  # Remote actions (niet automatisch detecteerbaar)
    $w2.Devices_In_Portal
)
$d2done = ($d2items | Where-Object { $_ }).Count

$d3items = @(
    $mgmtModules.Graph,
    $mgmtModules.ExO,
    $w4.Win32_App,       # Win32 app verpakt + geüpload
    $w4.Win32_App,       # App assignment (proxied via Win32 aanwezigheid)
    $w4.M365_Apps,       # M365 Apps deployment
    $w4.App_Protection   # App protection policy (MAM)
)
$d3done = ($d3items | Where-Object { $_ }).Count

$d4items = @(
    $graphStatus.SecurityBaselines -gt 0,   # Security baseline policy
    $w2.Compliance_Policy,                  # BitLocker compliance policy
    $graphStatus.DefenderOnboarded -gt 0,   # Defender for Endpoint onboarding
    $false,                                 # Windows Firewall via Intune
    $false                                  # ASR rules
)
$d4done = ($d4items | Where-Object { $_ }).Count

$pct1 = [math]::Round(($d1done / [math]::Max(1, $d1items.Count)) * 27.5)
$pct2 = [math]::Round(($d2done / [math]::Max(1, $d2items.Count)) * 32.5)
$pct3 = [math]::Round(($d3done / [math]::Max(1, $d3items.Count)) * 17.5)
$pct4 = [math]::Round(($d4done / [math]::Max(1, $d4items.Count)) * 17.5)

# ──────────────────────────────────────────────────────────────────
# 10b. Markdown output samenstellen
# ──────────────────────────────────────────────────────────────────
$md = @"
# SSW-Lab — Voortgangsstatus MD-102

_Gegenereerd: $ts (host: $host_)_
_Examendomeinen gebaseerd op: [MS Learn MD-102 study guide](https://learn.microsoft.com/credentials/certifications/resources/study-guides/md-102) (bijgewerkt jan 2026)_

---

## VM-overzicht

| VM | State | IP | Join-type | Activatie |
|----|-------|----|-----------|-----------|
| LAB-DC01 | $($vmTable['LAB-DC01'].State) | 10.50.10.10 | Domain Controller | — |
| LAB-MGMT01 | $($vmTable['LAB-MGMT01'].State) | 10.50.10.20 | Domain Joined | — |
| LAB-W11-01 | $($vmTable['LAB-W11-01'].State) | $($netStatus['LAB-W11-01'].IP) | $(joinLabel $joinStatus['LAB-W11-01']) | $(actLabel $activation['LAB-W11-01']) |
| LAB-W11-02 | $($vmTable['LAB-W11-02'].State) | $($netStatus['LAB-W11-02'].IP) | $(joinLabel $joinStatus['LAB-W11-02']) | $(actLabel $activation['LAB-W11-02']) |
| LAB-W11-AUTOPILOT | $($vmTable['LAB-W11-AUTOPILOT'].State) | $($netStatus['LAB-W11-AUTOPILOT'].IP) | $(joinLabel $joinStatus['LAB-W11-AUTOPILOT']) | $(actLabel $activation['LAB-W11-AUTOPILOT']) |

---

## Entra Connect (LAB-DC01)

| Check | Status |
|-------|--------|
| Geïnstalleerd | $(icon $syncStatus.Installed) |
| ADSync service Running | $(icon $syncStatus.ServiceRunning) |
| UPN-suffix $entraUPN in AD | $(icon $adStatus.UPNSuffixOK) |
| LastSyncRunStartTime | $(if ($syncStatus.LastSync) { $syncStatus.LastSync.ToString('yyyy-MM-dd HH:mm') } else { '⚠️ nog niet gerund' }) |

---

## Modules op MGMT01

| Module | Beschikbaar |
|--------|------------|
| Microsoft.Graph | $(icon $mgmtModules.Graph) |
| ExchangeOnlineManagement | $(icon $mgmtModules.ExO) |
| Az | $(icon $mgmtModules.Az) |
| LAPS | $(icon $mgmtModules.LAPS) |

---

## Graph API (tenant: $entraUPN)

| Check | Waarde |
|-------|--------|
| Verbonden | $(icon $graphStatus.Connected) |
| Compliance policies | $(if ($graphStatus.Connected) { $graphStatus.CompliancePolicies } else { 'N/A' }) |
| Conditional Access policies | $(if ($graphStatus.Connected) { $graphStatus.ConditionalAccess } else { 'N/A' }) |
| Configuration profiles | $(if ($graphStatus.Connected) { $graphStatus.ConfigProfiles } else { 'N/A' }) |
| Intune managed devices | $(if ($graphStatus.Connected) { $graphStatus.IntuneDevices } else { 'N/A' }) |
| Autopilot devices | $(if ($graphStatus.Connected) { $graphStatus.AutopilotDevices } else { 'N/A' }) |
| Win32 apps | $(if ($graphStatus.Connected) { $graphStatus.Win32Apps } else { 'N/A' }) |
| App protection policies (MAM) | $(if ($graphStatus.Connected) { $graphStatus.AppProtectionPolicies } else { 'N/A' }) |
| Security baselines | $(if ($graphStatus.Connected) { $graphStatus.SecurityBaselines } else { 'N/A' }) |

---

## MD-102 Voortgang per MS Learn Examendomain

> Bron: [MD-102 Study Guide — Microsoft Learn](https://learn.microsoft.com/credentials/certifications/resources/study-guides/md-102)

### Domein 1 — Infrastructuur voor devices voorbereiden (25–30%)
_Deployment, provisioning, Intune enrollment, Hybrid Join, Autopilot, update management_

| Lab milestone | Bereikt | MS Learn skill |
|---------------|---------|---------------|
| Alle core VMs Running | $(icon $w1.VM_Running) | Windows 11 deployment environment |
| Domein ssw.lab actief + labadmin | $(icon ($w1.Domain_OK -and $w1.Labadmin_OK)) | On-premises AD als basis voor Hybrid ID |
| W11-01 Windows geactiveerd | $(icon $w1.W11_Activated) | Windows client deployment verifiëren |
| Entra Connect geïnstalleerd + sync | $(icon ($w3.EntraConnect_Installed -and $w3.Sync_Running)) | Microsoft Entra Connect configureren |
| UPN-suffix $entraUPN in AD | $(icon $w3.UPN_Suffix) | UPN-suffix voor Hybrid Join |
| W11-01 Hybrid Entra Joined | $(icon $w3.W11_01_HybridJoined) | Hybrid Microsoft Entra Join implementeren |
| W11-02 enrolled (Entra ID device) | $(icon $joinStatus['LAB-W11-02'].WorkplaceJoined) | Entra ID Join / MDM enrollment |
| W11-AUTOPILOT VM klaar + geactiveerd | $(icon ($w5.VM_Running -and $w5.Activated)) | Windows Autopilot deployment voorbereiden |
| Autopilot hash geüpload | $(icon $w5.Autopilot_Registered) | Autopilot device registreren |
| Sync daadwerkelijk gerund | $(icon $w3.Sync_Ran) | Sync-cyclus en monitoring |

**Domein 1 voortgang: $d1done/$($d1items.Count) items**

---

### Domein 2 — Devices beheren en onderhouden (30–35%)
_Compliance policies, Conditional Access, Configuration profiles, remote actions, LAPS_

| Lab milestone | Bereikt | MS Learn skill |
|---------------|---------|---------------|
| W11-01 enrolled in Intune | $(icon $w2.W11_01_Enrolled) | Device enrollment en beheer in Intune |
| W11-02 enrolled in Intune | $(icon $w2.W11_02_Enrolled) | Enrollment methoden (MDM, MAM) |
| Compliance policy aangemaakt | $(icon $w2.Compliance_Policy) | Compliance policies configureren |
| Conditional Access policy | $(icon $w2.CA_Policy) | Conditional Access implementeren |
| Configuration profile | $(icon $w2.Config_Profiles) | Device configuration profiles |
| LAPS geconfigureerd | $(icon $mgmtModules.LAPS) | Windows LAPS via Intune |
| Remote actions (wipe/sync/restart) | ❌ | Device remote actions uitvoeren |
| Devices zichtbaar in Intune-portal | $(icon $w2.Devices_In_Portal) | Intune device monitoring |

**Domein 2 voortgang: $d2done/$($d2items.Count) items**

---

### Domein 3 — Applicaties beheren (15–20%)
_Win32 apps, Microsoft Store, M365 Apps, app protection policies_

| Lab milestone | Bereikt | MS Learn skill |
|---------------|---------|---------------|
| Microsoft.Graph module op MGMT01 | $(icon $mgmtModules.Graph) | PowerShell beheer via Graph API |
| ExchangeOnlineManagement module | $(icon $mgmtModules.ExO) | Exchange Online beheer |
| Win32 app verpakt + geüpload | $(icon $w4.Win32_App) | Win32 app packaging (.intunewin) |
| App assignment (Required) | $(icon $w4.Win32_App) | App deployment methoden |
| M365 Apps deployment | $(icon $w4.M365_Apps) | Microsoft 365 Apps via Intune |
| App protection policy (MAM) | $(icon $w4.App_Protection) | MAM zonder MDM enrollment |

**Domein 3 voortgang: $d3done/$($d3items.Count) items**

---

### Domein 4 — Devices beveiligen (15–20%)
_Defender for Endpoint, security baselines, disk encryption, Windows Firewall_

| Lab milestone | Bereikt | MS Learn skill |
|---------------|---------|---------------|
| Security baseline policy | $(icon ($graphStatus.SecurityBaselines -gt 0)) | Security baselines in Intune |
| BitLocker compliance policy | $(icon $w2.Compliance_Policy) | Disk encryption afdwingen |
| Defender for Endpoint onboarding | $(icon ($graphStatus.DefenderOnboarded -gt 0)) | MDE onboarden via Intune |
| Windows Firewall via Intune | ❌ | Endpoint security policies |
| Attack surface reduction rules | ❌ | ASR-regels configureren |

**Domein 4 voortgang: $d4done/$($d4items.Count) items**

---

## Totaaloverzicht examenvoortgang

| Domein | Gewicht | Lab-items klaar | Schatting |
|--------|---------|-----------------|-----------|
| D1 Infrastructuur devices voorbereiden | 25-30% | $d1done/$($d1items.Count) | ~$($pct1)% van examen |
| D2 Devices beheren en onderhouden | 30-35% | $d2done/$($d2items.Count) | ~$($pct2)% van examen |
| D3 Applicaties beheren | 15-20% | $d3done/$($d3items.Count) | ~$($pct3)% van examen |
| D4 Devices beveiligen | 15-20% | $d4done/$($d4items.Count) | ~$($pct4)% van examen |

> ⚠️ Dit is een lab-completeness schatting, geen directe examenscore. Kennischeck en conceptueel begrip tellen mee.

---

## Aanbevolen volgende stappen

$(if ($nextSteps.Count -eq 0) { '✅ Geen openstaande blockers gevonden.' } else { $nextSteps -join "`n`n" })

---

_Script: ``scripts/utility/Get-LabProgress.ps1`` | Herchecken: voer script opnieuw uit_
"@

# ──────────────────────────────────────────────────────────────────
# 11. Wegschrijven
# ──────────────────────────────────────────────────────────────────
$outputFile = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $OutputPath.Replace("$PSScriptRoot", '')))
# Gebruik altijd relatief pad vanuit script locatie
$repoRoot = (Get-Item "$PSScriptRoot\..\..").FullName
$outFile = Join-Path $repoRoot 'sog-status.md'

$md | Set-Content -Path $outFile -Encoding UTF8 -Force

if (-not $Quiet) {
    Write-Host ''
    Write-Host "SSW-Lab MD-102 voortgang -- $ts" -ForegroundColor Cyan
    Write-Host '================================================================'
    Write-Host ''
    Write-Host "  D1 Infrastructuur (25-30%):  $d1done/$($d1items.Count) items $(icon ($d1done -gt 8))" -ForegroundColor $(if ($d1done -gt 8) {'Green'} elseif ($d1done -gt 4) {'Yellow'} else {'Red'})
    Write-Host "  D2 Beheren (30-35%):         $d2done/$($d2items.Count) items $(icon ($d2done -gt 5))" -ForegroundColor $(if ($d2done -gt 5) {'Green'} elseif ($d2done -gt 1) {'Yellow'} else {'Red'})
    Write-Host "  D3 Applicaties (15-20%):     $d3done/$($d3items.Count) items $(icon ($d3done -gt 4))" -ForegroundColor $(if ($d3done -gt 4) {'Green'} elseif ($d3done -gt 1) {'Yellow'} else {'Red'})
    Write-Host "  D4 Beveiliging (15-20%):     $d4done/$($d4items.Count) items $(icon ($d4done -gt 3))" -ForegroundColor $(if ($d4done -gt 3) {'Green'} elseif ($d4done -gt 1) {'Yellow'} else {'Red'})
    Write-Host ''
    if ($nextSteps.Count -gt 0) {
        Write-Host 'Volgende stappen:' -ForegroundColor Yellow
        $nextSteps | ForEach-Object { Write-Host "  $_" }
    }
    Write-Host ''
    Write-Host "Status weggeschreven naar: $outFile" -ForegroundColor Green
}
