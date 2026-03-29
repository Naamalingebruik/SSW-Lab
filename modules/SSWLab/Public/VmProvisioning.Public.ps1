function Set-SSWVMDvdIsoWithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [Microsoft.HyperV.PowerShell.VirtualMachine]$VM,

        [Parameter(Mandatory)]
        [string]$IsoPath,

        [int]$MaxAttempts = 4,
        [int]$DelaySeconds = 2,
        [scriptblock]$Log
    )

    if (-not (Test-Path $IsoPath)) {
        throw "ISO pad bestaat niet: $IsoPath"
    }

    $dvd = Get-VMDvdDrive -VM $VM -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $dvd) {
        Add-VMDvdDrive -VM $VM -ErrorAction Stop | Out-Null
        $dvd = Get-VMDvdDrive -VM $VM -ErrorAction Stop | Select-Object -First 1
    }

    $lastError = $null
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            Set-VMDvdDrive -VMName $VM.Name -ControllerNumber $dvd.ControllerNumber -ControllerLocation $dvd.ControllerLocation -Path $null -ErrorAction SilentlyContinue
            Start-Sleep -Milliseconds 250
            Set-VMDvdDrive -VMName $VM.Name -ControllerNumber $dvd.ControllerNumber -ControllerLocation $dvd.ControllerLocation -Path $IsoPath -ErrorAction Stop
            return (Get-VMDvdDrive -VMName $VM.Name | Where-Object { $_.ControllerNumber -eq $dvd.ControllerNumber -and $_.ControllerLocation -eq $dvd.ControllerLocation } | Select-Object -First 1)
        } catch {
            $lastError = $_
            if ($attempt -lt $MaxAttempts) {
                if ($Log) {
                    & $Log "Waarschuwing: ISO-koppeling mislukt voor $($VM.Name) (poging $attempt/$MaxAttempts). Nieuwe poging over $DelaySeconds s."
                }
                Start-Sleep -Seconds $DelaySeconds
            }
        }
    }

    throw "ISO koppelen aan $($VM.Name) is mislukt na $MaxAttempts pogingen. Laatste fout: $($lastError.Exception.Message)"
}

function New-SSWLabVm {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [psobject]$VmProfile,

        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$IsoPath,

        [scriptblock]$Log
    )

    $vmName = [string]$VmProfile.Name
    $existing = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if ($existing) {
        if ($Log) {
            & $Log "$vmName bestaat al - overgeslagen."
        }

        return [pscustomobject]@{
            Name   = $vmName
            Status = 'SkippedExisting'
            VM     = $existing
        }
    }

    if (-not $IsoPath -or -not (Test-Path $IsoPath)) {
        throw "ISO niet gevonden voor ${vmName}: $IsoPath"
    }

    $vmPath = $Config.VMPath
    if (-not (Test-Path $vmPath)) {
        New-Item -ItemType Directory -Path $vmPath -Force | Out-Null
    }

    $switch = Get-VMSwitch -Name $Config.vSwitchName -ErrorAction SilentlyContinue
    if (-not $switch) {
        throw "vSwitch '$($Config.vSwitchName)' niet gevonden. Run eerst Configure-HostNetwork.ps1 in LIVE modus."
    }

    $diskPath = Join-Path $vmPath "$vmName.vhdx"
    if (Test-Path $diskPath) {
        throw "Schijfbestand bestaat al op $diskPath. Verwijder of hernoem dit VHDX-bestand en probeer opnieuw."
    }

    New-VHD -Path $diskPath -SizeBytes ([int]$VmProfile.Disk_GB * 1GB) -Dynamic -ErrorAction Stop | Out-Null
    $vm = New-VM -Name $vmName -MemoryStartupBytes ([int]$VmProfile.RAM_GB * 1GB) -VHDPath $diskPath `
        -SwitchName $Config.vSwitchName -Generation 2 -Path $vmPath -ErrorAction Stop
    Set-VM -VM $vm -ProcessorCount ([int]$VmProfile.vCPU) -DynamicMemory:$false -AutomaticCheckpointsEnabled:$false
    Set-VMFirmware -VM $vm -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows -ErrorAction Stop
    Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector -ErrorAction Stop | Out-Null
    Enable-VMTPM -VMName $vmName -ErrorAction Stop | Out-Null
    $dvd = Set-SSWVMDvdIsoWithRetry -VM $vm -IsoPath $IsoPath -Log $Log
    Set-VMFirmware -VM $vm -FirstBootDevice $dvd

    if ($Log) {
        & $Log "$vmName aangemaakt (Secure Boot + vTPM actief)."
    }

    return [pscustomobject]@{
        Name   = $vmName
        Status = 'Created'
        VM     = $vm
    }
}
