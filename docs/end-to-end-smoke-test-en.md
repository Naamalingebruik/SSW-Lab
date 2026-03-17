# SSW-Lab End-to-End Smoke Test (EN)

Goal: validate the complete baseline flow from host checks to domain join in 15-30 minutes.

Audience: admins and colleagues who need a fast go/no-go validation of lab readiness.

## Preconditions

- Start PowerShell as Administrator.
- Use a test host with Hyper-V.
- Use MSDN source ISOs.
- Dry Run is enabled by default in each GUI.
- Turn Dry Run off for real execution.

## Workflow in 6 Steps

1. Run preflight
2. Build network
3. Build unattended ISOs
4. Create VMs
5. Configure Domain Controller
6. Join clients to the domain

## Step 1 - Preflight

Run:

```powershell
.\scripts\00-PREFLIGHT.ps1
```

Actions:

- Click Check again.
- Resolve all blocking (red) findings.

Pass criteria:

- Hyper-V is OK.
- BIOS virtualization is OK.
- No blocking failures remain.

## Step 2 - Network

Run:

```powershell
.\scripts\01-NETWORK.ps1
```

Actions:

- Turn Dry Run off.
- Click Run LIVE.

Pass criteria:

- vSwitch SSW-Internal exists.
- NAT SSW-NAT exists.
- Host gateway is 10.50.10.1.

Quick validation:

```powershell
Get-VMSwitch -Name SSW-Internal
Get-NetNat -Name SSW-NAT
Get-NetIPAddress -InterfaceAlias "vEthernet (SSW-Internal)" -AddressFamily IPv4
```

## Step 3 - ISO Build

Run:

```powershell
.\scripts\02-MAKE-ISOS.ps1
```

Actions:

- Select Windows 11 and/or Server 2025 source ISOs.
- Enter the admin password.
- Turn Dry Run off.
- Click Build LIVE ISO(s).

Pass criteria:

- SSW-W11-Unattend.iso and/or SSW-WS2025-Unattend.iso is created.

Quick validation:

```powershell
Get-ChildItem D:\SSW-Lab\ISOs\SSW-*-Unattend.iso
```

## Step 4 - VM Creation

Run:

```powershell
.\scripts\03-VMS.ps1
```

Actions:

- Choose Minimal preset for a quick smoke test.
- Verify ISO paths.
- Turn Dry Run off.
- Click Create LIVE VMs.

Pass criteria:

- At least SSW-DC01 and SSW-W11-01 exist.

Quick validation:

```powershell
Get-VM | Where-Object Name -like "SSW-*" | Select-Object Name, State
```

## Step 5 - DC Setup

Run:

```powershell
.\scripts\04-SETUP-DC.ps1
```

Actions:

- Start SSW-DC01 if needed.
- Enter local admin password and DSRM password.
- Turn Dry Run off.
- Click Configure LIVE DC.

Pass criteria:

- AD DS installation succeeds.
- Forest ssw.lab exists.
- DC reboots successfully.

## Step 6 - Domain Join

Run:

```powershell
.\scripts\05-JOIN-DOMAIN.ps1
```

Actions:

- Start the client VM(s) to join.
- Enter domain admin and local admin credentials.
- Turn Dry Run off.
- Click Run LIVE Domain Join.

Pass criteria:

- Selected clients join ssw.lab.
- Clients reboot after join.

## Final Checklist

- VMs exist and are running.
- vSwitch and NAT exist.
- DC is reachable and AD DS is healthy.
- Client computer objects are visible in Active Directory Users and Computers.

Quick command check:

```powershell
Get-VM | Where-Object Name -like "SSW-*" | Select-Object Name, State
Get-VMSwitch -Name SSW-Internal
Get-NetNat -Name SSW-NAT
```

## Common Issues and Fixes

Network step fails with switch or NAT errors

- Cause: still in Dry Run or not running as admin.
- Fix: disable Dry Run and run PowerShell as Administrator.

ISO build fails with oscdimg.exe not found

- Cause: ADK Deployment Tools missing.
- Fix: install Windows ADK with Deployment Tools.

VM creation fails with switch not found

- Cause: network step was not run in LIVE mode.
- Fix: run 01-NETWORK.ps1 in LIVE mode first.

DC setup fails to connect through PowerShell Direct

- Cause: password mismatch or VM still in OOBE.
- Fix: wait for VM readiness and verify credentials.

Domain join fails on credentials

- Cause: domain admin account or password mismatch.
- Fix: verify the account on DC and retry.
