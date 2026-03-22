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

---

## Kernprincipes

1. **Netwerk is niet persistent.** Het gateway-IP `10.50.10.1` op `vEthernet (SSW-Internal)` verdwijnt bij host-reboot. Altijd `01-NETWORK.ps1` draaien na reboot.
2. **Volgorde is verplicht.** DC vóór clients. Netwerk vóór VMs. Zie [Scenario E](#scenario-e--volledige-herinstallatie).
3. **PS Direct via VMBus werkt altijd** (ook zonder netwerk), zolang de VM Running is en credentials kloppen:
   - DC01 / MGMT01: `LAB\labadmin`
   - W11-xx: `labadmin` (geen domein prefix)
4. **Scripts zijn idempotent.** Alle opbouwscripts zijn veilig om opnieuw uit te voeren.

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
.\scripts\04-SETUP-DC.ps1

# 6. Entra Connect installeren op DC01 (voor Hybrid Join)
.\scripts\Install-EntraConnect.ps1

# 7. Clients joinen aan domein
.\scripts\05-JOIN-DOMAIN.ps1

# 8. MGMT01 inrichten (modules, Entra Connect)
.\scripts\06-SETUP-MGMT.ps1
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

## config.local.ps1 backup

`config.local.ps1` bevat je labwachtwoord en staat buiten git (`.gitignore`). Bewaar dit bestand:

- Op een USB-stick of persoonlijke OneDrive (niet Sogeti OneDrive)
- Of onthoud het wachtwoord (het staat ook in je MSDN lab-setup notities)

Minimale inhoud om te bewaren:
```powershell
$SSWConfig.LabPassword = 'jouw-labwachtwoord'
```
