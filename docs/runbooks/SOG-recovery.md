# SSW-Lab — Recovery runbook (Sogeti laptop)

Machine: Sogeti High Flex laptop (Hyper-V host)  
Scope: herstel van SSW-Lab na host-reboot, herinstallatie, of mislukte lab-setup.  
Vereiste: scripts uitvoeren als Administrator via *Uitvoeren als andere gebruiker* met je High Flex-beheerder (`admin-xxx@sogeti.com`).

---

## Wanneer dit runbook gebruiken

| Symptoom | Scenario |
|----------|----------|
| VMs starten niet / Hyper-V manager leeg | [Scenario A](#scenario-a--vms-verdwenen-na-host-reboot) |
| VMs draaien, maar geen netwerk in VMs | [Scenario B](#scenario-b--netwerk-weg-na-host-reboot) |
| DC start niet / AD antwoordt niet | [Scenario C](#scenario-c--dc-niet-bereikbaar) |
| Client-VM doet niet mee aan domein | [Scenario D](#scenario-d--client-vm-niet-gejoined) |
| Hele lab opnieuw opbouwen (vers) | [Scenario E](#scenario-e--volledige-herinstallatie) |
| Autopilot-VM heeft verkeerd / geen IP na reset | [Scenario F](#scenario-f--autopilot-vm-kwijt-ip-na-reset) |
| W11-01/W11-02 heeft geen internet of veroorzaakt IP-conflict | [Scenario G](#scenario-g--ip-conflict-door-statisch-ip-na-lab-oefening) |

---

## Kernprincipes

1. **Netwerk is niet persistent.** Het gateway-IP `10.50.10.1` op `vEthernet (SSW-Internal)` verdwijnt bij host-reboot. Altijd `01-NETWORK.ps1` draaien na reboot.
2. **Volgorde is verplicht.** DC vóór clients. Netwerk vóór VMs. Zie [Scenario E](#scenario-e--volledige-herinstallatie).
3. **PS Direct via VMBus werkt altijd** (ook zonder netwerk), zolang de VM Running is en credentials kloppen:
   - DC01 / MGMT01: `LAB\labadmin`
   - W11-xx: `labadmin` (geen domein prefix)
4. **Scripts zijn idempotent.** Alle opbouwscripts zijn veilig om opnieuw uit te voeren.
5. **Startup-taak automatiseert stappen 1–2.** Na het registreren van `Register-LabStartupTask.ps1` wordt bij elke host-reboot automatisch het netwerk hersteld en worden VMs in de juiste volgorde gestart. Zie [Scenario E](#scenario-e--volledige-herinstallatie).
6. **Autopilot-VM krijgt altijd hetzelfde IP.** Via DHCP-reservering op DC01 op basis van het Hyper-V MAC-adres. Dit MAC verandert nooit — ook niet na Autopilot-reset of OS-herinstallatie. Zie [Scenario F](#scenario-f--autopilot-vm-kwijt-ip-na-reset).
7. **IP-adresverdeling is strikt gescheiden:**
   - `.1–.9` — host-infrastructuur (gateway = `.1`)
   - `.10–.99` — vaste VM-IPs (DC01 = `.10`, MGMT01 = `.20`, Autopilot-VM = `.30`)
   - `.100–.200` — DHCP-pool voor W11-01, W11-02 en andere clients
   - DHCP heeft een exclusion range op `.1–.99` zodat het nooit infrastructuur-IPs uitdeelt.
   - **Lab-oefeningen die een statisch IP instellen op W11-01/W11-02 mogen nooit een adres < .100 gebruiken.** De startup-taak reset clients automatisch naar DHCP als er een statisch IP in het infrastructuurbereik wordt gedetecteerd.

---

## Scenario A — VMs verdwenen na host-reboot

**Symptoom:** Hyper-V Manager toont geen VMs, of `Get-VM` geeft lege lijst.

**Oorzaak:** VM-bestanden staan nog op schijf maar zijn niet geregistreerd in Hyper-V.

```powershell
# Controleer of VM-bestanden nog bestaan
$vmPath = (. D:\Github\SSW-Lab\config.ps1; $SSWConfig.VMPath)
Get-ChildItem $vmPath -Filter '*.vmcx' -Recurse | Select-Object FullName

# Importeer VMs opnieuw (uit bestaande config-bestanden)
Get-ChildItem $vmPath -Filter '*.vmcx' -Recurse | ForEach-Object {
    Import-VM -Path $_.FullName
}

# Verificeer
Get-VM | Select-Object Name, State
```

Als VM-bestanden weg zijn → zie [Scenario E](#scenario-e--volledige-herinstallatie).

---

## Scenario B — Netwerk weg na host-reboot

**Symptoom:** VMs draaien, maar kunnen internet of DC niet bereiken. `ping 10.50.10.1` faalt vanuit VM.

**Oorzaak:** `vEthernet (SSW-Internal)` adapter heeft IP-adres verloren na reboot.

```powershell
# Herstel netwerk (vSwitch, NAT, gateway-IP, IP-forwarding)
Set-Location D:\Github\SSW-Lab
.\scripts\01-NETWORK.ps1
```

**Verificeer vanuit DC01:**
```powershell
$pw   = ConvertTo-SecureString 'jouw-labwachtwoord' -AsPlainText -Force
$cred = New-Object PSCredential('LAB\labadmin', $pw)

Invoke-Command -VMName 'LAB-DC01' -Credential $cred -ScriptBlock {
    Test-NetConnection 8.8.8.8 -InformationLevel Quiet
}
```

Verwacht: `True`

---

## Scenario C — DC niet bereikbaar

**Symptoom:** Clients kunnen niet inloggen, `Add-Computer` faalt, AD-opdrachten geven timeouts.

### Stap 1 — Controleer of DC Running is

```powershell
Get-VM -Name 'LAB-DC01' | Select-Object Name, State
```

Als `State = Off` → `Start-VM -Name 'LAB-DC01'` en wacht 60 seconden.

### Stap 2 — Valideer AD-services (niet alleen DNS)

```powershell
$pw   = ConvertTo-SecureString 'jouw-labwachtwoord' -AsPlainText -Force
$cred = New-Object PSCredential('LAB\labadmin', $pw)

Invoke-Command -VMName 'LAB-DC01' -Credential $cred -ScriptBlock {
    @('NTDS','ADWS','DNS','Netlogon') | ForEach-Object {
        "$_ = $((Get-Service $_).Status)"
    }
    try { (Get-ADDomain).DNSRoot } catch { "AD NIET BESCHIKBAAR: $_" }
}
```

Verwacht: alle services `Running`, DNSRoot = `ssw.lab`.

### Stap 3 — Als AD niet reageert: DC opnieuw promoveren

Alleen uitvoeren als `Get-ADDomain` faalt én NTDS/ADWS stoppen steeds.

```powershell
# DC-setup opnieuw draaien (idempotent — promoot alleen als domein nog niet bestaat)
Set-Location D:\Github\SSW-Lab
.\scripts\04-SETUP-DC.ps1
```

### Stap 4 — Entra Connect herstarten als sync stopt

```powershell
Invoke-Command -VMName 'LAB-DC01' -Credential $cred -ScriptBlock {
    Restart-Service ADSync -Force
    Start-Sleep 15
    Start-ADSyncSyncCycle -PolicyType Delta
    (Get-ADSyncScheduler).LastSyncRunStartTime
}
```

---

## Scenario D — Client-VM niet gejoined

**Symptoom:** W11-01 of W11-02 toont domain-join fout, of `dsregcmd /status` geeft geen `DomainJoined: YES`.

### Stap 1 — Controleer netwerk en DC bereikbaarheid vanuit client

```powershell
$pw    = ConvertTo-SecureString 'jouw-labwachtwoord' -AsPlainText -Force
$cred  = New-Object PSCredential('labadmin', $pw)   # geen domein prefix voor clients

Invoke-Command -VMName 'LAB-W11-01' -Credential $cred -ScriptBlock {
    Test-NetConnection 10.50.10.10 -Port 389 -InformationLevel Quiet  # LDAP naar DC
}
```

Als dit faalt → voer eerst [Scenario B](#scenario-b--netwerk-weg-na-host-reboot) uit.

### Stap 2 — Herverbind client aan domein

```powershell
# Domain-join script opnieuw draaien
Set-Location D:\Github\SSW-Lab
.\scripts\05-JOIN-DOMAIN.ps1
```

### Stap 3 — Entra Connect sync forceren na re-join

```powershell
$credAdmin = New-Object PSCredential('LAB\labadmin', $pw)
Invoke-Command -VMName 'LAB-DC01' -Credential $credAdmin -ScriptBlock {
    Import-Module ADSync
    Start-ADSyncSyncCycle -PolicyType Delta
}
```

---

## Scenario E — Volledige herinstallatie

Gebruik dit als de laptop opnieuw geïnstalleerd is, of als je lab volledig corrupt is.

**Vereisten voor je begint:**
- [ ] Hyper-V enabled (via Windows Features)
- [ ] MSDN ISO's beschikbaar (Windows Server 2022 + Windows 11)
- [ ] `config.local.ps1` hersteld vanuit je eigen backup (bevat labwachtwoord)
- [ ] PowerShell uitvoeren als administrator

**Opbouw-volgorde (strikt volhouden):**

```powershell
Set-Location D:\Github\SSW-Lab

# 1. Systeemcheck
.\scripts\00-PREFLIGHT.ps1

# 2. Netwerk aanmaken (vSwitch, NAT, gateway)
.\scripts\01-NETWORK.ps1

# 3. Unattended ISO's voorbereiden (MSDN ISO's vereist)
.\scripts\02-MAKE-ISOS.ps1

# 4. VMs aanmaken en starten
.\scripts\03-VMS.ps1

# 5. DC inrichten (AD, DNS, labadmin, UPN-suffix)
#    LET OP: installeert ook automatisch DHCP + vaste IP-reservering voor Autopilot-VM
.\scripts\04-SETUP-DC.ps1

# 6. Entra Connect installeren op DC01 (voor Hybrid Join)
.\scripts\Install-EntraConnect.ps1

# 7. Clients joinen aan domein
.\scripts\05-JOIN-DOMAIN.ps1

# 8. MGMT01 inrichten (modules, Entra Connect)
.\scripts\06-SETUP-MGMT.ps1

# 9. Startup-taak registreren (eenmalig — start lab automatisch bij elke host-reboot)
.\scripts\utility\Register-LabStartupTask.ps1
```

**Verwachte tijdsduur:** 45–90 minuten (afhankelijk van schijfsnelheid en ISO-locatie).

---

## Snelle healthcheck na recovery

```powershell
# Draai het voortgangsscript — geeft volledige status van alle VMs en AD
Set-Location D:\Github\SSW-Lab
.\scripts\utility\Get-LabProgress.ps1
```

Output geeft: VM-status, join-type per client, Entra Connect sync, module-aanwezigheid, en MD-102 milestone-voortgang.

---

## Scenario F — Autopilot-VM kwijt IP na reset

**Symptoom:** `LAB-W11-AUTOPILOT` heeft na een Autopilot-reset geen netwerk, of krijgt een willekeurig DHCP-adres in plaats van `10.50.10.30`.

**Oorzaak:** Bij een Autopilot-reset wordt Windows opnieuw geïnstalleerd. Een eerder handmatig ingesteld statisch IP is dan weg. De structurele oplossing is een DHCP-reservering op DC01, gekoppeld aan het Hyper-V MAC-adres van de VM. Dit MAC-adres verandert nooit.

**Is DHCP al ingesteld? (was je lab gebouwd vóór maart 2026)**

Als je het lab vóór de update hebt opgebouwd, is DHCP mogelijk nog niet aanwezig op DC01. Controleer:

```powershell
$pw   = ConvertTo-SecureString 'jouw-labwachtwoord' -AsPlainText -Force
$cred = New-Object PSCredential('LAB\labadmin', $pw)

Invoke-Command -VMName 'LAB-DC01' -Credential $cred -ScriptBlock {
    (Get-WindowsFeature DHCP).Installed
}
```

**Als `False`** → draai de startup utility (idempotent, veilig om opnieuw te draaien):

```powershell
Set-Location D:\Github\SSW-Lab
.\scripts\utility\Start-LabVMs.ps1
```

Dit script installeert DHCP op DC01, maakt de scope aan en voegt de reservering toe.

**Als de Autopilot-VM al draait maar verkeerd IP heeft:**

```powershell
# Herstart de VM — DHCP-reservering zorgt voor correct IP bij volgende boot
Restart-VM -Name 'LAB-W11-AUTOPILOT' -Force
```

**Verifieer de reservering:**

```powershell
$pw   = ConvertTo-SecureString 'jouw-labwachtwoord' -AsPlainText -Force
$cred = New-Object PSCredential('LAB\labadmin', $pw)

Invoke-Command -VMName 'LAB-DC01' -Credential $cred -ScriptBlock {
    Get-DhcpServerv4Reservation -ScopeId '10.50.10.0' | Where-Object { $_.Description -like '*AUTOPILOT*' }
}
```

Verwacht output: reservering met IP `10.50.10.30` en MAC-adres van de Autopilot-VM.

---

## Scenario G — IP-conflict door statisch IP na lab-oefening

**Symptoom:** Een VM (bijv. Autopilot-VM of een andere client) heeft geen internet terwijl DC01 wel internet heeft. Gateway is bereikbaar maar extern TCP faalt. `arp -a` toont een IP-adres bij twee verschillende MAC-adressen.

**Oorzaak:** Een MD-102 lab-oefening (bijv. netwerk- of Autopilot-configuratie) heeft een statisch IP ingesteld op W11-01 of W11-02 in het infrastructuurbereik (`.1–.99`). Dat IP botst met een gereserveerd adres.

**Diagnose:**

```powershell
# Check ARP tabel op de host voor het SSW-Internal subnet
arp -a | Select-String '10.50.10'
```

Als één IP onder twee verschillende MAC-adressen verschijnt → IP-conflict.

**Oplossing — betrokken VM terug naar DHCP:**

```powershell
# Vervang 'LAB-W11-01' met de naam van de conflicterende VM
$pw   = ConvertTo-SecureString 'jouw-labwachtwoord' -AsPlainText -Force
$cred = New-Object PSCredential('labadmin', $pw)

Invoke-Command -VMName 'LAB-W11-01' -Credential $cred -ScriptBlock {
    $n = (Get-NetAdapter | Where-Object Status -eq 'Up').Name
    netsh interface ip set address name="$n" source=dhcp
    netsh interface ip set dns    name="$n" source=dhcp
}
```

Daarna: lease vernieuwen en conflict-VM opnieuw testen:

```powershell
Invoke-Command -VMName 'LAB-W11-01' -Credential $cred -ScriptBlock {
    ipconfig /release; ipconfig /renew
    (Get-NetIPAddress -AddressFamily IPv4 | Where-Object PrefixOrigin -eq 'Dhcp').IPAddress
}
```

**Structureel geborgd (geen actie vereist):**
- De DHCP-scope heeft een exclusion range op `10.50.10.1–99`. DHCP kan nooit zelf een infrastructuur-IP uitdelen.
- `Start-LabVMs.ps1` (en de startup-taak) detecteert bij elke start automatisch statische IPs < `.100` op W11-01/W11-02 en zet ze terug naar DHCP.
- Lab-oefeningen die een statisch IP vereisen: gebruik altijd een adres uit de range `.100–.200`, nooit lager.

> **Structurele fix:** `04-SETUP-DC.ps1` installeert DHCP en de reservering nu automatisch als onderdeel van de DC-setup. Nieuwe installaties lopen dit probleem niet meer tegen.

---

## config.local.ps1 backup

`config.local.ps1` bevat je labwachtwoord en staat buiten git (`.gitignore`). Bewaar dit bestand:

- Op een USB-stick of persoonlijke OneDrive (niet Sogeti OneDrive)
- Of onthoud het wachtwoord (het staat ook in je MSDN lab-setup notities)

Minimale inhoud om te bewaren:
```powershell
$SSWConfig.LabPassword = 'jouw-labwachtwoord'
```
