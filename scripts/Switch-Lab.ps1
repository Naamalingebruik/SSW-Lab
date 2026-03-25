#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Switch-Lab.ps1
# Schakel met één druk op de knop tussen SSW-Lab en M365-Lab.
# Sluit alle VMs van het actieve lab graceful af en start
# daarna de VMs van het doellab op.
# ============================================================

# WPF vereist STA-threading. PowerShell 7 gebruikt MTA standaard.
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $script = $MyInvocation.MyCommand.Path
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-STA -ExecutionPolicy Bypass -File `"$script`"" `
        -Verb RunAs
    exit
}

. "$PSScriptRoot\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ── VM-lijsten ────────────────────────────────────────────────
$SSWVMs = @(
    @{ Key='DC01';          Name=$null }   # naam uit vm-profiles.json
    @{ Key='MGMT01';        Name=$null }
    @{ Key='W11-01';        Name=$null }
    @{ Key='W11-02';        Name=$null }
    @{ Key='W11-AUTOPILOT'; Name=$null }
)

# Vul echte VM-namen in vanuit vm-profiles.json
try {
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    foreach ($entry in $SSWVMs) {
        $p = $profiles.($entry.Key)
        if ($p) { $entry.Name = $p.Name }
    }
} catch {}

$M365VMs = @(
    'M365-DFT-DC01'
    'M365-STTS-DC01'
    'M365-DFT-MGMT01'
    'M365-STTS-MGMT01'
    'M365-DFT-ENTRA'
    'M365-DFT-HYBRID'
    'M365-DFT-AUTOPILOT'
)

# Shutdown-/startup-volgorde
$SSWStopOrder  = @('W11-AUTOPILOT','W11-02','W11-01','MGMT01','DC01')
$SSWStartOrder = @('DC01','MGMT01','W11-01','W11-02','W11-AUTOPILOT')
$M365StopOrder  = @(
    'M365-DFT-AUTOPILOT','M365-DFT-HYBRID','M365-DFT-ENTRA',
    'M365-DFT-MGMT01','M365-STTS-MGMT01',
    'M365-DFT-DC01','M365-STTS-DC01'
)
$M365StartOrder = @(
    'M365-DFT-DC01','M365-STTS-DC01',
    'M365-DFT-MGMT01','M365-STTS-MGMT01',
    'M365-DFT-ENTRA','M365-DFT-HYBRID','M365-DFT-AUTOPILOT'
)

# ── Helpers ───────────────────────────────────────────────────
function Get-VMState([string]$name) {
    if (-not $name) { return 'Unknown' }
    $vm = Get-VM -Name $name -ErrorAction SilentlyContinue
    if (-not $vm) { return 'Absent' }
    return $vm.State
}

function Get-SSWVMName([string]$key) {
    $entry = $SSWVMs | Where-Object { $_.Key -eq $key }
    if ($entry -and $entry.Name) { return $entry.Name }
    return $null
}

# ── XAML ─────────────────────────────────────────────────────
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Lab Switcher" Height="720" Width="740"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Header" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="FontSize" Value="20"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style x:Key="Sub" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#A6ADC8"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="0,2,0,0"/>
    </Style>
    <Style x:Key="CardTitle" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="FontSize" Value="14"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="0,0,0,10"/>
    </Style>
    <Style x:Key="VMRow" TargetType="TextBlock">
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="FontFamily" Value="Consolas"/>
      <Setter Property="Margin" Value="0,2,0,0"/>
    </Style>
    <Style x:Key="BtnPrimary" TargetType="Button">
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="38"/>
      <Setter Property="Padding" Value="0,0"/>
    </Style>
    <Style x:Key="BtnSecondary" TargetType="Button">
      <Setter Property="Background" Value="#45475A"/>
      <Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="34"/>
      <Setter Property="Padding" Value="16,0"/>
    </Style>
  </Window.Resources>

  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Header -->
    <StackPanel Grid.Row="0" Margin="0,0,0,20">
      <TextBlock Text="Lab Switcher" Style="{StaticResource Header}"/>
      <TextBlock Text="Schakel tussen SSW-Lab en M365-Lab op deze NUC" Style="{StaticResource Sub}"/>
    </StackPanel>

    <!-- Status kaarten -->
    <Grid Grid.Row="1" Margin="0,0,0,16">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="16"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <!-- SSW-Lab kaart -->
      <Border Grid.Column="0" x:Name="CardSSW" Background="#2A2A3E" CornerRadius="8" Padding="16">
        <StackPanel>
          <TextBlock Text="SSW-Lab" Style="{StaticResource CardTitle}"/>
          <StackPanel x:Name="PanelSSWVMs"/>
          <Button x:Name="BtnSSW" Content="Schakel naar SSW-Lab"
                  Style="{StaticResource BtnPrimary}"
                  Background="#89B4FA" Foreground="#1E1E2E"
                  Margin="0,14,0,0"/>
        </StackPanel>
      </Border>

      <!-- M365-Lab kaart -->
      <Border Grid.Column="2" x:Name="CardM365" Background="#2A2A3E" CornerRadius="8" Padding="16">
        <StackPanel>
          <TextBlock Text="M365-Lab" Style="{StaticResource CardTitle}"/>
          <StackPanel x:Name="PanelM365VMs"/>
          <Button x:Name="BtnM365" Content="Schakel naar M365-Lab"
                  Style="{StaticResource BtnPrimary}"
                  Background="#CBA6F7" Foreground="#1E1E2E"
                  Margin="0,14,0,0"/>
        </StackPanel>
      </Border>
    </Grid>

    <!-- Dry Run balk -->
    <Border x:Name="ForceBar" Grid.Row="2" CornerRadius="6" Margin="0,0,0,10"
            Padding="14,10" BorderThickness="1"
            Background="#1A2E24" BorderBrush="#A6E3A1">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center">
          <TextBlock x:Name="ForceTitle" FontWeight="SemiBold" FontSize="12"
                     Text="🔒  Graceful shutdown — VMs krijgen tijd om netjes af te sluiten (60s per VM)"
                     Foreground="#A6E3A1"/>
          <TextBlock x:Name="ForceSub" FontSize="11" Margin="0,2,0,0"
                     Text="Vink aan voor direct uitzetten als een VM niet reageert"
                     Foreground="#5A8A6A"/>
        </StackPanel>
        <CheckBox x:Name="ChkForce" Grid.Column="1"
                  Content="Forceer uitzetten" FontWeight="SemiBold" FontSize="12"
                  Foreground="#A6E3A1" VerticalContentAlignment="Center" Margin="16,0,0,0"/>
      </Grid>
    </Border>

    <!-- Log -->
    <Border Grid.Row="3" Background="#181825" CornerRadius="6" Padding="12">
      <ScrollViewer x:Name="LogScroll" VerticalScrollBarVisibility="Auto">
        <TextBox x:Name="LogBox" Background="Transparent" Foreground="#A6E3A1"
                 FontFamily="Consolas" FontSize="11" IsReadOnly="True"
                 TextWrapping="Wrap" BorderThickness="0"/>
      </ScrollViewer>
    </Border>

    <!-- Progress -->
    <ProgressBar x:Name="Progress" Grid.Row="4" Height="6" Margin="0,10,0,0"
                 Background="#313244" Foreground="#89B4FA" BorderThickness="0"
                 Minimum="0" Maximum="100" Value="0"/>

    <!-- Knoppen onderaan -->
    <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
      <Button x:Name="BtnRefresh" Content="Vernieuwen" Style="{StaticResource BtnSecondary}" Margin="0,0,10,0"/>
      <Button x:Name="BtnClose"   Content="Sluiten"    Style="{StaticResource BtnSecondary}"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader      = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$conv        = [System.Windows.Media.BrushConverter]::new()

$cardSSW     = $reader.FindName("CardSSW")
$cardM365    = $reader.FindName("CardM365")
$panelSSW    = $reader.FindName("PanelSSWVMs")
$panelM365   = $reader.FindName("PanelM365VMs")
$btnSSW      = $reader.FindName("BtnSSW")
$btnM365     = $reader.FindName("BtnM365")
$forceBar    = $reader.FindName("ForceBar")
$forceTitle  = $reader.FindName("ForceTitle")
$forceSub    = $reader.FindName("ForceSub")
$chkForce    = $reader.FindName("ChkForce")
$logBox      = $reader.FindName("LogBox")
$logScroll   = $reader.FindName("LogScroll")
$progress    = $reader.FindName("Progress")
$btnRefresh  = $reader.FindName("BtnRefresh")
$btnClose    = $reader.FindName("BtnClose")

# ── UI helpers ────────────────────────────────────────────────
function Write-Log([string]$msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logScroll.ScrollToBottom()
}

function Set-Busy([bool]$busy) {
    $btnSSW.IsEnabled     = -not $busy
    $btnM365.IsEnabled    = -not $busy
    $btnRefresh.IsEnabled = -not $busy
    $chkForce.IsEnabled   = -not $busy
    $progress.Value = if ($busy) { $progress.Value } else { 0 }
}

function Get-StateColor([string]$state) {
    switch ($state) {
        'Running' { return '#A6E3A1' }   # groen
        'Off'     { return '#585B70' }   # grijs
        'Absent'  { return '#45475A' }   # donkergrijs
        default   { return '#F9E2AF' }   # geel (Paused, Saved, enz.)
    }
}

function Get-StateIcon([string]$state) {
    switch ($state) {
        'Running' { return '●' }
        'Off'     { return '○' }
        'Absent'  { return '—' }
        default   { return '◐' }
    }
}

function Refresh-VMPanel([System.Windows.Controls.StackPanel]$panel, [string[]]$names) {
    $panel.Children.Clear()
    foreach ($name in $names) {
        $state = Get-VMState $name
        $color = Get-StateColor $state
        $icon  = Get-StateIcon $state

        $tb = [System.Windows.Controls.TextBlock]::new()
        $tb.Style = $reader.Resources["VMRow"]
        $tb.Text  = "$icon  $name"
        $tb.Foreground = $conv.ConvertFrom($color)
        $panel.Children.Add($tb) | Out-Null
    }
}

function Refresh-Status {
    # SSW-Lab
    $sswNames = $SSWVMs | Where-Object { $_.Name } | ForEach-Object { $_.Name }
    Refresh-VMPanel -panel $panelSSW -names $sswNames

    # M365-Lab
    Refresh-VMPanel -panel $panelM365 -names $M365VMs

    # Kaartkleur: groen randje als er VMs draaien
    $sswRunning  = ($sswNames  | Where-Object { (Get-VMState $_) -eq 'Running' }).Count
    $m365Running = ($M365VMs   | Where-Object { (Get-VMState $_) -eq 'Running' }).Count

    $cardSSW.BorderThickness  = [System.Windows.Thickness]::new(2)
    $cardM365.BorderThickness = [System.Windows.Thickness]::new(2)
    $cardSSW.BorderBrush  = $conv.ConvertFrom(if ($sswRunning  -gt 0) { '#89B4FA' } else { '#313244' })
    $cardM365.BorderBrush = $conv.ConvertFrom(if ($m365Running -gt 0) { '#CBA6F7' } else { '#313244' })
}

# ── Force-checkbox stijl ──────────────────────────────────────
function Update-ForceBar {
    if ($chkForce.IsChecked) {
        $forceBar.Background  = $conv.ConvertFrom("#2E1A1A")
        $forceBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $forceTitle.Text      = "⚠  Geforceerd uitzetten — VMs worden direct uitgezet zonder afsluiten"
        $forceTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $forceSub.Text        = "Haal het vinkje weg voor graceful shutdown"
        $forceSub.Foreground  = $conv.ConvertFrom("#8A5A5A")
        $chkForce.Foreground  = $conv.ConvertFrom("#F38BA8")
    } else {
        $forceBar.Background  = $conv.ConvertFrom("#1A2E24")
        $forceBar.BorderBrush = $conv.ConvertFrom("#A6E3A1")
        $forceTitle.Text      = "🔒  Graceful shutdown — VMs krijgen tijd om netjes af te sluiten (60s per VM)"
        $forceTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $forceSub.Text        = "Vink aan voor direct uitzetten als een VM niet reageert"
        $forceSub.Foreground  = $conv.ConvertFrom("#5A8A6A")
        $chkForce.Foreground  = $conv.ConvertFrom("#A6E3A1")
    }
}

$chkForce.Add_Checked({   Update-ForceBar })
$chkForce.Add_Unchecked({ Update-ForceBar })

# ── VM stop/start logica (draait op UI-thread, progress via dispatcher) ──
function Stop-VMGraceful([string]$vmName, [bool]$force, [int]$timeout = 60) {
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm)                  { Write-Log "  skip  $vmName — niet gevonden"; return }
    if ($vm.State -eq 'Off')       { Write-Log "  uit   $vmName — staat al uit"; return }

    if ($force) {
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
        Write-Log "  force $vmName — uitgezet"
        return
    }

    try {
        Stop-VM -Name $vmName -ErrorAction Stop
        Write-Log "  stop  $vmName — shutdown gestuurd, wachten…"
    } catch {
        Write-Log "  force $vmName — graceful mislukt, forceer"
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
        return
    }

    $deadline = (Get-Date).AddSeconds($timeout)
    while ((Get-VM -Name $vmName -ErrorAction SilentlyContinue).State -ne 'Off' -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 3
        $reader.Dispatcher.Invoke([action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }

    if ((Get-VM -Name $vmName -ErrorAction SilentlyContinue).State -ne 'Off') {
        Write-Log "  force $vmName — timeout, geforceerd uitgezet"
        Stop-VM -Name $vmName -Force -TurnOff -ErrorAction SilentlyContinue
    } else {
        Write-Log "  ok    $vmName — afgesloten"
    }
}

function Start-VMIfAbsent([string]$vmName, [int]$delay = 4) {
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm)                    { Write-Log "  skip  $vmName — niet gevonden in Hyper-V"; return }
    if ($vm.State -eq 'Running')     { Write-Log "  ok    $vmName — draait al"; return }
    try {
        Start-VM -Name $vmName -ErrorAction Stop
        Write-Log "  start $vmName — gestart"
        if ($delay -gt 0) { Start-Sleep -Seconds $delay }
    } catch {
        Write-Log "  fout  $vmName — $($_.Exception.Message)"
    }
}

# ── Switch-actie ──────────────────────────────────────────────
function Invoke-Switch([string]$targetLab) {
    $force = [bool]$chkForce.IsChecked

    Set-Busy $true
    $logBox.Text = ""
    $progress.Value = 5

    $sourceLab = if ($targetLab -eq 'SSW') { 'M365' } else { 'SSW' }

    Write-Log "======================================"
    Write-Log "  Schakel: $sourceLab → $targetLab"
    Write-Log "======================================"

    # ── STAP 1: Source lab stoppen ──
    Write-Log ""
    Write-Log "[1/2] $sourceLab-Lab afsluiten…"
    $progress.Value = 10

    if ($sourceLab -eq 'SSW') {
        $total = $SSWStopOrder.Count
        $i = 0
        foreach ($key in $SSWStopOrder) {
            $name = Get-SSWVMName $key
            if ($name) { Stop-VMGraceful -vmName $name -force $force }
            $i++
            $progress.Value = 10 + [int](($i / $total) * 35)
            Refresh-Status
        }
    } else {
        $total = $M365StopOrder.Count
        $i = 0
        foreach ($name in $M365StopOrder) {
            Stop-VMGraceful -vmName $name -force $force
            $i++
            $progress.Value = 10 + [int](($i / $total) * 35)
            Refresh-Status
        }
    }

    Write-Log ""
    Write-Log "[1/2] $sourceLab-Lab afgesloten."
    $progress.Value = 50

    # ── STAP 2: Target lab starten ──
    Write-Log ""
    Write-Log "[2/2] $targetLab-Lab starten…"

    if ($targetLab -eq 'SSW') {
        # Eerst het netwerk herstellen via Start-LabVMs.ps1 als dat bestaat,
        # anders VMs direct starten (netwerk is al opgezet)
        $startScript = Join-Path $PSScriptRoot 'utility\Start-LabVMs.ps1'
        if (Test-Path $startScript) {
            Write-Log "  Start-LabVMs.ps1 uitvoeren (incl. netwerkherstel)…"
            $progress.Value = 60
            try {
                & $startScript
            } catch {
                Write-Log "  waarschuwing: Start-LabVMs.ps1 fout — $($_.Exception.Message)"
            }
        } else {
            $total = $SSWStartOrder.Count
            $i = 0
            foreach ($key in $SSWStartOrder) {
                $name = Get-SSWVMName $key
                if ($name) { Start-VMIfAbsent -vmName $name -delay (if ($key -eq 'DC01') { 8 } else { 4 }) }
                $i++
                $progress.Value = 60 + [int](($i / $total) * 35)
                Refresh-Status
            }
        }
    } else {
        $total = $M365StartOrder.Count
        $i = 0
        foreach ($name in $M365StartOrder) {
            Start-VMIfAbsent -vmName $name -delay (if ($name -like '*DC*') { 8 } else { 4 })
            $i++
            $progress.Value = 60 + [int](($i / $total) * 35)
            Refresh-Status
        }
    }

    $progress.Value = 100
    Write-Log ""
    Write-Log "======================================"
    Write-Log "  Klaar. Actief lab: $targetLab"
    Write-Log "======================================"

    Refresh-Status
    Set-Busy $false
}

# ── Event handlers ────────────────────────────────────────────
$btnSSW.Add_Click({
    $confirm = [System.Windows.MessageBox]::Show(
        "M365-Lab afsluiten en SSW-Lab starten?`n`nDit sluit alle M365 VMs $(if ($chkForce.IsChecked) { '(geforceerd)' } else { 'graceful' }) af.",
        "Lab Switcher",
        [System.Windows.MessageBoxButton]::OKCancel,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -eq 'OK') { Invoke-Switch 'SSW' }
})

$btnM365.Add_Click({
    $confirm = [System.Windows.MessageBox]::Show(
        "SSW-Lab afsluiten en M365-Lab starten?`n`nDit sluit alle SSW VMs $(if ($chkForce.IsChecked) { '(geforceerd)' } else { 'graceful' }) af.",
        "Lab Switcher",
        [System.Windows.MessageBoxButton]::OKCancel,
        [System.Windows.MessageBoxImage]::Question
    )
    if ($confirm -eq 'OK') { Invoke-Switch 'M365' }
})

$btnRefresh.Add_Click({ Refresh-Status })
$btnClose.Add_Click({   $reader.Close() })

$reader.Add_Loaded({
    Update-ForceBar
    Refresh-Status
    Write-Log "Lab Switcher gereed. Kies een lab om naar te schakelen."
})

$reader.ShowDialog() | Out-Null
