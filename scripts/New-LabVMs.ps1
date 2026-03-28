#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | New-LabVMs.ps1
# Interactieve VM-builder met preset-keuze en RAM-preview.
# Dry Run is standaard AAN — zet vinkje uit om echt uit te voeren.
# ============================================================

$modulePath = Join-Path $PSScriptRoot '..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force
$SSWConfig = Import-SSWLabConfig -ConfigPath (Join-Path $PSScriptRoot '..\config.ps1')

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

$profiles = Get-SSWVmProfiles -Config $SSWConfig

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | VM's aanmaken" Height="700" Width="720"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="PresetBtn" TargetType="Button">
      <Setter Property="Background" Value="#313244"/>
      <Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="BorderBrush" Value="#45475A"/>
      <Setter Property="BorderThickness" Value="2"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Width" Value="180"/>
      <Setter Property="Height" Value="110"/>
      <Setter Property="Margin" Value="0,0,12,0"/>
    </Style>
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Background" Value="#89B4FA"/><Setter Property="Foreground" Value="#1E1E2E"/>
      <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="36"/>
    </Style>
  </Window.Resources>
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Margin="0,0,0,16">
      <TextBlock Text="VM's aanmaken" Foreground="#CDD6F4" FontSize="20" FontWeight="SemiBold"/>
      <TextBlock Text="Kies een preset of stel handmatig in" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Orientation="Horizontal" Margin="0,0,0,16">
      <Button x:Name="BtnMinimal" Style="{StaticResource PresetBtn}">
        <StackPanel HorizontalAlignment="Center">
          <TextBlock Text="Minimal" FontSize="15" FontWeight="SemiBold" Foreground="#CDD6F4" HorizontalAlignment="Center"/>
          <TextBlock Text="DC01 + W11-01" FontSize="11" Foreground="#A6ADC8" HorizontalAlignment="Center" Margin="0,4,0,0"/>
          <TextBlock Text="~6 GB RAM" FontSize="11" Foreground="#F9E2AF" HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>
      </Button>
      <Button x:Name="BtnStandard" Style="{StaticResource PresetBtn}">
        <StackPanel HorizontalAlignment="Center">
          <TextBlock Text="Standard" FontSize="15" FontWeight="SemiBold" Foreground="#CDD6F4" HorizontalAlignment="Center"/>
          <TextBlock Text="DC01 + MGMT01 + 2x W11" FontSize="11" Foreground="#A6ADC8" HorizontalAlignment="Center" Margin="0,4,0,0"/>
          <TextBlock Text="~14 GB RAM" FontSize="11" Foreground="#F9E2AF" HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>
      </Button>
      <Button x:Name="BtnFull" Style="{StaticResource PresetBtn}">
        <StackPanel HorizontalAlignment="Center">
          <TextBlock Text="Full" FontSize="15" FontWeight="SemiBold" Foreground="#CDD6F4" HorizontalAlignment="Center"/>
          <TextBlock Text="Standard + Autopilot" FontSize="11" Foreground="#A6ADC8" HorizontalAlignment="Center" Margin="0,4,0,0"/>
          <TextBlock Text="~18 GB RAM" FontSize="11" Foreground="#F9E2AF" HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>
      </Button>
    </StackPanel>

    <Border Grid.Row="2" Background="#313244" CornerRadius="6" Padding="16,12" Margin="0,0,0,12">
      <StackPanel>
        <TextBlock Text="Selecteer VMs" Foreground="#A6ADC8" FontSize="11" Margin="0,0,0,8"/>
        <WrapPanel x:Name="VMPanel"/>
        <TextBlock x:Name="RAMPreview" Text="" Foreground="#F9E2AF" FontSize="12" Margin="0,10,0,0"/>
      </StackPanel>
    </Border>

    <Grid Grid.Row="3" Margin="0,0,0,12">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="8"/><ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock Text="W11 unattended ISO" Foreground="#A6ADC8" FontSize="11" Margin="0,0,0,2"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="8"/><ColumnDefinition Width="70"/></Grid.ColumnDefinitions>
          <TextBox x:Name="TxtW11ISO" Grid.Column="0" Background="#313244" Foreground="#CDD6F4"
                   BorderBrush="#45475A" BorderThickness="1" Padding="6,5" FontSize="11" Height="30"/>
          <Button  x:Name="BtnW11ISO" Grid.Column="2" Content="…" Background="#45475A"
                   Foreground="#CDD6F4" BorderThickness="0" Cursor="Hand" Height="30" FontSize="12"/>
        </Grid>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="WS2025 unattended ISO" Foreground="#A6ADC8" FontSize="11" Margin="0,0,0,2"/>
        <Grid>
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="8"/><ColumnDefinition Width="70"/></Grid.ColumnDefinitions>
          <TextBox x:Name="TxtSrvISO" Grid.Column="0" Background="#313244" Foreground="#CDD6F4"
                   BorderBrush="#45475A" BorderThickness="1" Padding="6,5" FontSize="11" Height="30"/>
          <Button  x:Name="BtnSrvISO" Grid.Column="2" Content="…" Background="#45475A"
                   Foreground="#CDD6F4" BorderThickness="0" Cursor="Hand" Height="30" FontSize="12"/>
        </Grid>
      </StackPanel>
    </Grid>

    <Border Grid.Row="4" Background="#181825" CornerRadius="6" Padding="10">
      <ScrollViewer VerticalScrollBarVisibility="Auto">
        <TextBox x:Name="LogBox" Background="Transparent" Foreground="#A6E3A1"
                 FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" BorderThickness="0"/>
      </ScrollViewer>
    </Border>

    <ProgressBar x:Name="Progress" Grid.Row="5" Height="6" Margin="0,10,0,0"
                 Background="#313244" Foreground="#89B4FA" BorderThickness="0" Minimum="0" Maximum="100" Value="0"/>

    <Border x:Name="DryRunBar" Grid.Row="6" CornerRadius="6" Margin="0,10,0,0" Padding="14,10" BorderThickness="1">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center">
          <TextBlock x:Name="DryRunTitle" FontWeight="SemiBold" FontSize="12"/>
          <TextBlock x:Name="DryRunSub" FontSize="11" Margin="0,2,0,0"/>
        </StackPanel>
        <CheckBox x:Name="ChkDryRun" Grid.Column="1" IsChecked="True"
                  Content="Dry Run" FontWeight="SemiBold" FontSize="12"
                  VerticalContentAlignment="Center" Margin="16,0,0,0"/>
      </Grid>
    </Border>

    <StackPanel Grid.Row="7" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
      <Button x:Name="BtnCreate" Content="VM's aanmaken" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="150"/>
      <Button x:Name="BtnNext"   Content="Doorgaan naar Initialize-DomainController →" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False" Width="220"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader      = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$vmPanel     = $reader.FindName("VMPanel")
$ramPreview  = $reader.FindName("RAMPreview")
$logBox      = $reader.FindName("LogBox")
$progress    = $reader.FindName("Progress")
$btnCreate   = $reader.FindName("BtnCreate")
$btnNext     = $reader.FindName("BtnNext")
$txtW11ISO   = $reader.FindName("TxtW11ISO")
$txtSrvISO   = $reader.FindName("TxtSrvISO")
$chkDryRun   = $reader.FindName("ChkDryRun")
$dryRunBar   = $reader.FindName("DryRunBar")
$dryRunTitle = $reader.FindName("DryRunTitle")
$dryRunSub   = $reader.FindName("DryRunSub")
$conv        = [System.Windows.Media.BrushConverter]::new()

$vmKeys     = @("DC01","MGMT01","W11-01","W11-02","W11-AUTOPILOT")
$checkBoxes = @{}

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "[DRY RUN] Geen VM's worden aangemaakt"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk uit te voeren"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
        $btnCreate.Content      = "Simuleren (Dry Run)"
        $btnCreate.Background   = $conv.ConvertFrom("#89B4FA")
        $btnCreate.Foreground   = $conv.ConvertFrom("#1E1E2E")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "[LIVE] VM's worden aangemaakt op dit systeem"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
        $btnCreate.Content      = "LIVE VM's aanmaken"
        $btnCreate.Background   = $conv.ConvertFrom("#F38BA8")
        $btnCreate.Foreground   = $conv.ConvertFrom("#1E1E2E")
    }
}

$reader.Add_Loaded({
    foreach ($key in $vmKeys) {
        $p = $profiles.$key
        $cb = [System.Windows.Controls.CheckBox]::new()
        $cb.Content = "$key ($($p.RAM_GB) GB)"
        $cb.Foreground = $conv.ConvertFrom("#CDD6F4")
        $cb.FontSize = 12
        $cb.Margin = [System.Windows.Thickness]::new(0,0,16,4)
        $cb.VerticalContentAlignment = "Center"
        $cb.Tag = $key
        $cb.Add_Checked({   Update-RAMPreview })
        $cb.Add_Unchecked({ Update-RAMPreview })
        $vmPanel.Children.Add($cb)
        $checkBoxes[$key] = $cb
    }
    $w11Path = Join-Path $SSWConfig.ISOPath "SSW-W11-Unattend.iso"
    $srvPath = Join-Path $SSWConfig.ISOPath "SSW-WS2025-Unattend.iso"
    if (Test-Path $w11Path) { $txtW11ISO.Text = $w11Path }
    if (Test-Path $srvPath) { $txtSrvISO.Text = $srvPath }
    Set-Preset "Minimal"
    Update-DryRunBar
})

$chkDryRun.Add_Checked({   Update-DryRunBar })
$chkDryRun.Add_Unchecked({ Update-DryRunBar })

function Update-RAMPreview {
    $sel = $checkBoxes.GetEnumerator() | Where-Object { $_.Value.IsChecked } | ForEach-Object { $_.Key }
    $total = Get-SSWVmSelectionRamTotal -Profiles $profiles -VmKeys $sel
    $ramPreview.Text = "Totaal geselecteerd: $total GB RAM"
}

function Set-Preset($name) {
    $keys = $SSWConfig.Presets[$name]
    foreach ($k in $checkBoxes.Keys) { $checkBoxes[$k].IsChecked = ($keys -contains $k) }
    Update-RAMPreview
}

$reader.FindName("BtnMinimal").Add_Click({ Set-Preset "Minimal" })
$reader.FindName("BtnStandard").Add_Click({ Set-Preset "Standard" })
$reader.FindName("BtnFull").Add_Click({ Set-Preset "Full" })

foreach ($pair in @(@("BtnW11ISO",$txtW11ISO), @("BtnSrvISO",$txtSrvISO))) {
    $btn = $reader.FindName($pair[0]); $box = $pair[1]
    $btn.Add_Click({
        $dlg = [System.Windows.Forms.OpenFileDialog]::new()
        $dlg.Filter = "ISO bestanden (*.iso)|*.iso"
        if ($dlg.ShowDialog() -eq "OK") { $box.Text = $dlg.FileName }
    }.GetNewClosure())
}

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logBox.ScrollToEnd()
}

function Set-VMIsoWithRetry {
  param(
    $VM,
    [string]$IsoPath,
    [int]$MaxAttempts = 4,
    [int]$DelaySeconds = 2
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
        Write-Log "Waarschuwing: ISO-koppeling mislukt voor $($VM.Name) (poging $attempt/$MaxAttempts). Nieuwe poging over $DelaySeconds s."
        Start-Sleep -Seconds $DelaySeconds
      }
    }
  }

  throw "ISO koppelen aan $($VM.Name) is mislukt na $MaxAttempts pogingen. Laatste fout: $($lastError.Exception.Message)"
}

$btnCreate.Add_Click({
    $btnCreate.IsEnabled = $false
    $logBox.Text = ""
    $progress.Value = 0
    $isDry = $chkDryRun.IsChecked
    $pre   = if ($isDry) { "[DRY RUN] " } else { "" }
    $sel   = $checkBoxes.GetEnumerator() | Where-Object { $_.Value.IsChecked } | ForEach-Object { $_.Key }

    if ($sel.Count -eq 0) { Write-Log "Geen VMs geselecteerd."; $btnCreate.IsEnabled = $true; return }

    $vmPath = $SSWConfig.VMPath
    if (-not $isDry -and -not (Test-Path $vmPath)) { New-Item -ItemType Directory -Path $vmPath -Force | Out-Null }

    if (-not $isDry) {
      $switch = Get-VMSwitch -Name $SSWConfig.vSwitchName -ErrorAction SilentlyContinue
      if (-not $switch) {
        Write-Log "vSwitch '$($SSWConfig.vSwitchName)' niet gevonden. Run eerst Configure-HostNetwork.ps1 in LIVE modus."
        $btnCreate.IsEnabled = $true
        return
      }
    }

    $step = [math]::Floor(100 / $sel.Count); $done = 0
    $createdCount = 0
    $skippedCount = 0
    $failedCount = 0

    foreach ($key in $sel) {
        $p = $profiles.$key
        $vmName = $p.Name
        $existing = Get-VM -Name $vmName -ErrorAction SilentlyContinue

        if ($existing) {
            Write-Log "${pre}$vmName bestaat al - overgeslagen."
          $skippedCount++
        } else {
            $isoPath = if ($p.OS -eq "Server2025") { $txtSrvISO.Text } else { $txtW11ISO.Text }
            Write-Log "${pre}New-VM '$vmName' ($($p.RAM_GB) GB RAM, $($p.Disk_GB) GB disk, ISO: $(Split-Path $isoPath -Leaf))"
            if (-not $isDry) {
                try {
              if (-not $isoPath -or -not (Test-Path $isoPath)) { Write-Log "ISO niet gevonden voor $vmName."; $failedCount++; continue }
                    $diskPath = Join-Path $vmPath "$vmName.vhdx"
              if (Test-Path $diskPath) {
                Write-Log "FOUT $vmName`: Schijfbestand bestaat al op $diskPath. Verwijder of hernoem dit VHDX-bestand en probeer opnieuw."
                $failedCount++
                continue
              }
                    New-VHD -Path $diskPath -SizeBytes ($p.Disk_GB * 1GB) -Dynamic -ErrorAction Stop | Out-Null
                    $vm = New-VM -Name $vmName -MemoryStartupBytes ($p.RAM_GB * 1GB) -VHDPath $diskPath `
                                 -SwitchName $SSWConfig.vSwitchName -Generation 2 -Path $vmPath -ErrorAction Stop
                    Set-VM -VM $vm -ProcessorCount $p.vCPU -DynamicMemory:$false -AutomaticCheckpointsEnabled:$false
                    # Windows 11/Server 2025 lab-VMs moeten Secure Boot + vTPM hebben.
                    Set-VMFirmware -VM $vm -EnableSecureBoot On -SecureBootTemplate MicrosoftWindows -ErrorAction Stop
                    Set-VMKeyProtector -VMName $vmName -NewLocalKeyProtector -ErrorAction Stop | Out-Null
                    Enable-VMTPM -VMName $vmName -ErrorAction Stop | Out-Null
                    $dvd = Set-VMIsoWithRetry -VM $vm -IsoPath $isoPath
                    Set-VMFirmware -VM $vm -FirstBootDevice $dvd
                    Write-Log "✔ $vmName aangemaakt (Secure Boot + vTPM actief)."
                    $createdCount++
                  } catch {
                    Write-Log "FOUT $vmName`: $_"
                    $failedCount++
                  }
                } else {
                  $createdCount++
            }
        }
        $done += $step
        $progress.Value = [math]::Min($done, 100)
    }

    $progress.Value = 100
    if ($isDry) {
      Write-Log "Dry Run klaar - niets aangemaakt. Geselecteerd: $($sel.Count), bestaand/overgeslagen: $skippedCount."
      $btnNext.IsEnabled = $true
    } elseif ($failedCount -gt 0) {
      Write-Log "Voltooid met fouten. Aangemaakt: $createdCount, overgeslagen: $skippedCount, fouten: $failedCount."
      Write-Log "Los de fouten op en run deze stap opnieuw voordat je doorgaat."
      $btnNext.IsEnabled = $false
    } else {
      Write-Log "Klaar. Aangemaakt: $createdCount, overgeslagen: $skippedCount, fouten: 0. Start de VMs om de installatie te voltooien."
      $btnNext.IsEnabled = $true
    }
    $btnCreate.IsEnabled = $true
})

$btnNext.Add_Click({
    $reader.Close()
    $next = Join-Path $PSScriptRoot "Initialize-DomainController.ps1"
    if (Test-Path $next) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" -Verb RunAs }
})

$reader.ShowDialog() | Out-Null



