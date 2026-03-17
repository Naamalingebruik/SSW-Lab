# SSW-Lab End-to-End Smoke Test

Doel: in 15-30 minuten valideren dat de complete basisflow werkt van hostcheck tot domain join.

Doelgroep: beheerders en collega-gebruikers die snel willen bevestigen dat het lab operationeel is.

## Voorwaarden

- Start PowerShell als Administrator.
- Gebruik een testhost met Hyper-V.
- Gebruik MSDN-bron-ISO's.
- In elke GUI staat Dry Run standaard aan.
- Voor echte uitvoering moet Dry Run uit staan.

## Workflow in 6 stappen

1. Preflight uitvoeren
2. Netwerk bouwen
3. Unattended ISO's bouwen
4. VM's aanmaken
5. Domain Controller inrichten
6. Clients joinen aan het domein

## Stap 1 - Preflight

Uitvoeren:

```powershell
.\scripts\00-PREFLIGHT.ps1
```

Acties:

- Klik Opnieuw controleren.
- Los alle rode blokkades op.

Pass criteria:

- Hyper-V is OK.
- BIOS-virtualisatie is OK.
- Geen blokkerende foutstatus.

## Stap 2 - Netwerk

Uitvoeren:

```powershell
.\scripts\01-NETWORK.ps1
```

Acties:

- Zet Dry Run uit.
- Klik LIVE uitvoeren.

Pass criteria:

- vSwitch SSW-Internal bestaat.
- NAT SSW-NAT bestaat.
- Host-gateway staat op 10.50.10.1.

Snelle validatie:

```powershell
Get-VMSwitch -Name SSW-Internal
Get-NetNat -Name SSW-NAT
Get-NetIPAddress -InterfaceAlias "vEthernet (SSW-Internal)" -AddressFamily IPv4
```

## Stap 3 - ISO build

Uitvoeren:

```powershell
.\scripts\02-MAKE-ISOS.ps1
```

Acties:

- Selecteer Windows 11 en/of Server 2025 bron-ISO.
- Vul het admin wachtwoord in.
- Zet Dry Run uit.
- Klik LIVE ISO('s) bouwen.

Pass criteria:

- SSW-W11-Unattend.iso en/of SSW-WS2025-Unattend.iso is aangemaakt.

Snelle validatie:

```powershell
Get-ChildItem D:\SSW-Lab\ISOs\SSW-*-Unattend.iso
```

## Stap 4 - VM creatie

Uitvoeren:

```powershell
.\scripts\03-VMS.ps1
```

Acties:

- Kies preset Minimal voor een snelle smoke test.
- Controleer de ISO-paden.
- Zet Dry Run uit.
- Klik LIVE VM's aanmaken.

Pass criteria:

- Minimaal SSW-DC01 en SSW-W11-01 bestaan.

Snelle validatie:

```powershell
Get-VM | Where-Object Name -like "SSW-*" | Select-Object Name, State
```

## Stap 5 - DC setup

Uitvoeren:

```powershell
.\scripts\04-SETUP-DC.ps1
```

Acties:

- Start SSW-DC01 als die nog uit staat.
- Vul lokaal admin wachtwoord en DSRM wachtwoord in.
- Zet Dry Run uit.
- Klik LIVE DC inrichten.

Pass criteria:

- AD DS installatie succesvol.
- Forest ssw.lab bestaat.
- DC herstart correct.

## Stap 6 - Domain join

Uitvoeren:

```powershell
.\scripts\05-JOIN-DOMAIN.ps1
```

Acties:

- Start de client-VM('s) die je wilt joinen.
- Vul domain admin en lokaal admin credentials in.
- Zet Dry Run uit.
- Klik LIVE Domain Join uitvoeren.

Pass criteria:

- Geselecteerde clients joinen ssw.lab.
- Clients rebooten na join.

## Eindcontrole checklist

- VM's bestaan en zijn opgestart.
- vSwitch en NAT bestaan.
- DC is bereikbaar en AD DS draait.
- Client-objecten zijn zichtbaar in Active Directory Users and Computers.

Snelle commando-check:

```powershell
Get-VM | Where-Object Name -like "SSW-*" | Select-Object Name, State
Get-VMSwitch -Name SSW-Internal
Get-NetNat -Name SSW-NAT
```

## Veelvoorkomende fouten en fixes

Netwerkstap faalt met switch of NAT errors

- Oorzaak: script nog in Dry Run of geen admin rechten.
- Fix: Dry Run uitzetten en PowerShell als Administrator starten.

ISO-build faalt met oscdimg.exe niet gevonden

- Oorzaak: ADK Deployment Tools ontbreken.
- Fix: installeer Windows ADK met Deployment Tools.

VM-creatie faalt met switch niet gevonden

- Oorzaak: netwerkstap niet live uitgevoerd.
- Fix: voer eerst 01-NETWORK.ps1 live uit.

DC setup faalt met PowerShell Direct login

- Oorzaak: wachtwoord mismatch of VM nog niet klaar met OOBE.
- Fix: wacht tot login werkt en controleer credentials.

Domain join faalt op credentials

- Oorzaak: domain admin account of wachtwoord mismatch.
- Fix: verifieer account op DC en probeer opnieuw.
