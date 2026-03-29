#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Initialize-Preflight.ps1
# Checks whether the laptop is ready for SSW-Lab.
# Displays results in a WPF GUI with traffic-light status.
# ============================================================

# WPF requires STA threading. PowerShell 7 uses MTA by default.
# Automatically restarts in Windows PowerShell 5.1 (always STA).
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $script = $MyInvocation.MyCommand.Path
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-STA -ExecutionPolicy Bypass -File `"$script`"" `
        -Verb RunAs
    exit
}

. "$PSScriptRoot\..\config.ps1"
$modulePath = Join-Path $PSScriptRoot '..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ── Check definitions ─────────────────────────────────────────
function Get-PreflightCheck {
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. Hyper-V feature
    $hvState = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue).State
    $hvEnabled = $hvState -eq "Enabled"
    $results.Add([PSCustomObject]@{
        Check   = "Hyper-V installed"
        Status  = if ($hvEnabled) { "OK" } else { "ERROR" }
        Detail  = if ($hvEnabled) { "Hyper-V is active" } else { "Run: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All" }
        Block   = -not $hvEnabled
    })

    # 2. BIOS virtualization
    # VirtualizationFirmwareEnabled returns False on some laptops even when Hyper-V is running.
    # If Hyper-V is active, virtualization is by definition enabled in the BIOS.
    $vmx = (Get-CimInstance Win32_Processor).VirtualizationFirmwareEnabled
    $hvRunning = (Get-Service -Name vmms -ErrorAction SilentlyContinue).Status -eq 'Running'
    $virtOk = $vmx -or $hvRunning
    $results.Add([PSCustomObject]@{
        Check   = "Virtualization in BIOS"
        Status  = if ($virtOk) { "OK" } else { "ERROR" }
        Detail  = if ($virtOk) { "Intel VT-x / AMD-V active" } else { "Enable virtualization in BIOS/UEFI" }
        Block   = -not $virtOk
    })

    # 3. RAM check
    $ramGB = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
    $ramStatus = if ($ramGB -ge 32) { "OK" } elseif ($ramGB -ge 16) { "WARNING" } else { "ERROR" }
    $ramDetail = switch ($ramStatus) {
        "OK"      { "$ramGB GB - all presets available" }
        "WARNING" { "$ramGB GB - use Minimal preset (DC01 + 1 client)" }
        "ERROR"   { "$ramGB GB - insufficient for SSW-Lab (min. 16 GB)" }
    }
    $results.Add([PSCustomObject]@{
        Check   = "Available RAM"
        Status  = $ramStatus
        Detail  = $ramDetail
        Block   = ($ramGB -lt 16)
    })

    # 4. Disk space (D:\ or C:\)
    $drive = if (Test-Path "D:\") { "D" } else { "C" }
    $disk = Get-PSDrive $drive
    $freeGB = [math]::Round($disk.Free / 1GB)
    $diskStatus = if ($freeGB -ge 150) { "OK" } elseif ($freeGB -ge 80) { "WARNING" } else { "ERROR" }
    $results.Add([PSCustomObject]@{
        Check   = ("Free disk space ({0}:)" -f $drive)
        Status  = $diskStatus
        Detail  = switch ($diskStatus) {
            "OK"      { "$freeGB GB free - sufficient for Full preset" }
            "WARNING" { "$freeGB GB free - Minimal or Standard preset recommended" }
            "ERROR"   { "$freeGB GB free - at least 80 GB required" }
        }
        Block   = ($freeGB -lt 80)
    })

    # 5. Windows version
    $winVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    $isW11  = [System.Environment]::OSVersion.Version.Build -ge 22000
    $results.Add([PSCustomObject]@{
        Check   = "Windows version"
        Status  = if ($isW11) { "OK" } else { "WARNING" }
        Detail  = if ($isW11) { "Windows 11 ($winVer)" } else { "Windows 10 - Hyper-V works, but client configurations may differ" }
        Block   = $false
    })

    # 6. Windows ADK (oscdimg for Build-UnattendedIsos.ps1)
    $oscdimg = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    $adkOk = Test-Path $oscdimg
    $results.Add([PSCustomObject]@{
        Check    = "Windows ADK (Deployment Tools)"
        Status   = if ($adkOk) { "OK" } else { "WARNING" }
        Detail   = if ($adkOk) { "oscdimg.exe found - ISO builder ready" } else { "Required for Build-UnattendedIsos.ps1 - use the download button below" }
        Block    = $false
        NeedsADK = -not $adkOk
    })

    # 7. Existing SSW vSwitch
    $existingSwitch = Get-VMSwitch -Name $SSWConfig.vSwitchName -ErrorAction SilentlyContinue
    $results.Add([PSCustomObject]@{
        Check   = "SSW-Internal vSwitch"
        Status  = if ($existingSwitch) { "OK" } else { "INFO" }
        Detail  = if ($existingSwitch) { "vSwitch already exists" } else { "Will be created by Configure-HostNetwork.ps1" }
        Block   = $false
    })

    return $results
}

# ── Preset recommendation ─────────────────────────────────────
function Get-PresetAdvice($checks) {
    $blocked = $checks | Where-Object { $_.Block }

    if ($blocked) { return "[BLOCKED] Lab cannot start - resolve the red items." }

    $ramCheck = $checks | Where-Object { $_.Check -like "Available*" }
    if ($ramCheck.Status -eq "WARNING") {
        return "[NOTE] Use the Minimal preset (DC01 + 1 W11 client) - approx. 6 GB RAM."
    }
    $diskCheck = $checks | Where-Object { $_.Check -like "Free disk*" }
    if ($diskCheck.Status -eq "WARNING") {
        return "[NOTE] Use Standard or Minimal - disk space is limited."
    }

    return "[OK] System is ready. All presets are available."
}

# ── Certification track advice ────────────────────────────────
function Get-CertAdvice {
    param([string]$cert)

    $ramGB  = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
    $drive  = if (Test-Path "D:\") { "D" } else { "C" }
    $freeGB = [math]::Round((Get-PSDrive $drive).Free / 1GB)

    $requirements = @{
        "MD-102" = @{ MinRAM = 14; MinDisk = 300; Preset = "Standard"; VMs = "DC01 | MGMT01 | W11-01 | W11-02" }
        "MS-102" = @{ MinRAM = 14; MinDisk = 300; Preset = "Standard"; VMs = "DC01 | MGMT01 | W11-01 | W11-02" }
        "SC-300" = @{ MinRAM = 14; MinDisk = 300; Preset = "Standard"; VMs = "DC01 | MGMT01 | W11-01 | W11-02" }
        "AZ-104" = @{ MinRAM = 6;  MinDisk = 140; Preset = "Minimal";  VMs = "DC01 | W11-01" }
    }

    $req    = $requirements[$cert]
    $ramOk  = $ramGB  -ge $req.MinRAM
    $diskOk = $freeGB -ge $req.MinDisk

    if ($ramOk -and $diskOk) {
        return "[OK] Your laptop is suitable for $cert - preset: $($req.Preset) ($($req.VMs))"
    }

    $issues = @()
    if (-not $ramOk)  { $issues += "RAM: $ramGB GB available, $($req.MinRAM) GB required" }
    if (-not $diskOk) { $issues += "Disk: $freeGB GB free, $($req.MinDisk) GB required" }
    return "[NOTE] Hardware insufficient for $cert - $($issues -join '  |  ')"
}

# ── WPF GUI ───────────────────────────────────────────────────
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Preflight Check" Height="740" Width="680"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Header" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="FontSize" Value="20"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Margin" Value="24,20,0,4"/>
    </Style>
    <Style x:Key="Sub" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#A6ADC8"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="24,0,0,16"/>
    </Style>
    <Style x:Key="Advice" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Margin" Value="24,8,24,0"/>
      <Setter Property="TextWrapping" Value="Wrap"/>
    </Style>
    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Background" Value="#89B4FA"/>
      <Setter Property="Foreground" Value="#1E1E2E"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Padding" Value="20,8"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="36"/>
    </Style>
  </Window.Resources>
  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <TextBlock Grid.Row="0" Style="{StaticResource Header}" Text="Preflight Check"/>
    <TextBlock Grid.Row="1" Style="{StaticResource Sub}" Text="System requirements for SSW-Lab"/>

    <ScrollViewer Grid.Row="2" Margin="16,0,16,0" VerticalScrollBarVisibility="Auto">
      <StackPanel x:Name="CheckPanel"/>
    </ScrollViewer>

    <StackPanel Grid.Row="3" Margin="16,8,16,0">
      <Border Background="#313244" CornerRadius="6" Padding="12,10">
        <TextBlock x:Name="AdviceText" Style="{StaticResource Advice}" Text="Checking..."/>
      </Border>

      <!-- Hyper-V install banner - visible if Hyper-V is missing -->
      <Border x:Name="HyperVBanner" Background="#1E2D2E" CornerRadius="6" Padding="14,10"
              Margin="0,6,0,0" BorderBrush="#89DCEB" BorderThickness="1" Visibility="Collapsed">
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" VerticalAlignment="Center">
            <TextBlock Text="Hyper-V is not installed"
                       Foreground="#89DCEB" FontSize="12" FontWeight="SemiBold"/>
            <TextBlock Text="Click the button to install Hyper-V. A restart is required after installation."
                       Foreground="#A6ADC8" FontSize="11" TextWrapping="Wrap" Margin="0,2,0,0"/>
          </StackPanel>
          <Button x:Name="BtnInstallHyperV" Grid.Column="1"
                  Content="Install Hyper-V"
                  Background="#89DCEB" Foreground="#1E1E2E"
                  FontWeight="SemiBold" FontSize="12"
                  BorderThickness="0" Cursor="Hand"
                  Padding="14,8" Margin="12,0,0,0" Height="34"/>
        </Grid>
      </Border>

      <!-- ADK download banner - visible if ADK is missing -->
      <Border x:Name="ADKBanner" Background="#2D1E2E" CornerRadius="6" Padding="14,10"
              Margin="0,6,0,0" BorderBrush="#CBA6F7" BorderThickness="1" Visibility="Collapsed">
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" VerticalAlignment="Center">
            <TextBlock Text="Windows ADK required for ISO builder"
                       Foreground="#CBA6F7" FontSize="12" FontWeight="SemiBold"/>
            <TextBlock Text="Install only 'Deployment Tools' - approx. 80 MB. Then restart Initialize-Preflight.ps1."
                       Foreground="#A6ADC8" FontSize="11" TextWrapping="Wrap" Margin="0,2,0,0"/>
          </StackPanel>
          <Button x:Name="BtnDownloadADK" Grid.Column="1"
                  Content="Download ADK"
                  Background="#CBA6F7" Foreground="#1E1E2E"
                  FontWeight="SemiBold" FontSize="12"
                  BorderThickness="0" Cursor="Hand"
                  Padding="14,8" Margin="12,0,0,0" Height="34"/>
        </Grid>
      </Border>
    </StackPanel>

    <Border Grid.Row="4" Background="#313244" CornerRadius="6" Margin="16,6,16,0" Padding="14,10">
      <StackPanel>
        <TextBlock Text="Which certification track are you preparing for?"
                   Foreground="#CDD6F4" FontSize="12" FontWeight="SemiBold" Margin="0,0,0,8"/>
        <StackPanel Orientation="Horizontal">
          <RadioButton x:Name="RadioMD102" Content="MD-102" GroupName="Cert"
                       Foreground="#CDD6F4" FontSize="12" Margin="0,0,20,0"/>
          <RadioButton x:Name="RadioMS102" Content="MS-102" GroupName="Cert"
                       Foreground="#CDD6F4" FontSize="12" Margin="0,0,20,0"/>
          <RadioButton x:Name="RadioSC300" Content="SC-300" GroupName="Cert"
                       Foreground="#CDD6F4" FontSize="12" Margin="0,0,20,0"/>
          <RadioButton x:Name="RadioAZ104" Content="AZ-104" GroupName="Cert"
                       Foreground="#CDD6F4" FontSize="12"/>
        </StackPanel>
        <Grid Margin="0,8,0,0">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <TextBlock x:Name="CertAdviceText" Grid.Column="0"
                     Foreground="#CDD6F4" FontSize="12"
                     TextWrapping="Wrap" Text="" VerticalAlignment="Center"/>
          <Button x:Name="BtnStudyGuide" Grid.Column="1" Content="Study guide" Visibility="Collapsed"
                  Background="#313244" Foreground="#89B4FA"
                  FontSize="11" FontWeight="SemiBold"
                  BorderThickness="1" BorderBrush="#89B4FA"
                  Cursor="Hand" Padding="10,4" Margin="12,0,0,0" Height="26"/>
        </Grid>
      </StackPanel>
    </Border>

    <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right" Margin="16,12,16,16">
      <Button x:Name="BtnRerun" Content="Run checks again" Style="{StaticResource PrimaryBtn}"
              Background="#A6E3A1" Margin="0,0,10,0"/>
      <Button x:Name="BtnNext" Content="Continue to Configure-HostNetwork →" Style="{StaticResource PrimaryBtn}"
              IsEnabled="False"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))

$checkPanel      = $reader.FindName("CheckPanel")
$adviceText      = $reader.FindName("AdviceText")
$hyperVBanner    = $reader.FindName("HyperVBanner")
$btnInstallHyperV = $reader.FindName("BtnInstallHyperV")
$adkBanner       = $reader.FindName("ADKBanner")
$btnDownloadADK  = $reader.FindName("BtnDownloadADK")
$btnRerun       = $reader.FindName("BtnRerun")
$btnNext        = $reader.FindName("BtnNext")
$certAdviceText  = $reader.FindName("CertAdviceText")
$btnStudyGuide   = $reader.FindName("BtnStudyGuide")
$radioMD102      = $reader.FindName("RadioMD102")
$radioMS102      = $reader.FindName("RadioMS102")
$radioSC300      = $reader.FindName("RadioSC300")
$radioAZ104      = $reader.FindName("RadioAZ104")

$script:currentCert = $null

function Save-CurrentCertSelection {
    param([string]$Certification)

    if ([string]::IsNullOrWhiteSpace($Certification)) {
        return
    }

    try {
        Set-SSWCurrentTrack -TrackId $Certification | Out-Null
    } catch {
        Write-Verbose "Track could not be saved: $($_.Exception.Message)"
    }
}

$studyGuideUrls = @{
    "MD-102" = "d:\GitHub\SSW-Lab\docs\study-guide-md102.md"
    "MS-102" = "d:\GitHub\SSW-Lab\docs\study-guide-ms102.md"
    "SC-300" = "d:\GitHub\SSW-Lab\docs\study-guide-sc300.md"
    "AZ-104" = "d:\GitHub\SSW-Lab\docs\study-guide-az104.md"
}

$certClickHandler = {
    param($s, $e)
    $null = $e
    $script:currentCert = $s.Content
    Save-CurrentCertSelection -Certification $script:currentCert
    $advice = Get-CertAdvice $script:currentCert
    $certAdviceText.Text = $advice
    $certColor = if ($advice.StartsWith("[OK]")) { "#A6E3A1" } else { "#F9E2AF" }
    $certAdviceText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom($certColor)
    $btnStudyGuide.Visibility = "Visible"
}

$btnStudyGuide.Add_Click({
    if ($script:currentCert -and $studyGuideUrls.ContainsKey($script:currentCert)) {
        Start-Process $studyGuideUrls[$script:currentCert]
    }
})

$radioMD102.Add_Checked($certClickHandler)
$radioMS102.Add_Checked($certClickHandler)
$radioSC300.Add_Checked($certClickHandler)
$radioAZ104.Add_Checked($certClickHandler)

$btnInstallHyperV.Add_Click({
    $btnInstallHyperV.IsEnabled = $false
    $btnInstallHyperV.Content = "Installing..."
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction Stop | Out-Null
        [System.Windows.MessageBox]::Show(
            "Hyper-V has been installed.`n`nRestart your laptop and then run Initialize-Preflight.ps1 again.",
            "Restart required",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show(
            "Installation failed:`n$($_.Exception.Message)",
            "Error",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Error
        ) | Out-Null
        $btnInstallHyperV.IsEnabled = $true
        $btnInstallHyperV.Content = "Install Hyper-V"
    }
})

$btnDownloadADK.Add_Click({
    Start-Process "https://go.microsoft.com/fwlink/?linkid=2289980"
})

function Show-PreflightCheck {
    $checkPanel.Children.Clear()
    $checks = Get-PreflightCheck

    $adkMissing  = $false
    $hvMissing   = $false

    foreach ($c in $checks) {
        $color = switch ($c.Status) {
            "OK"      { "#A6E3A1" }
            "WARNING" { "#F9E2AF" }
            "ERROR"   { "#F38BA8" }
            default   { "#89B4FA" }
        }
        $icon = switch ($c.Status) {
            "OK"      { "OK" }
            "WARNING" { "!" }
            "ERROR"   { "X" }
            default   { "i" }
        }

        if ($c.PSObject.Properties["NeedsADK"] -and $c.NeedsADK) { $adkMissing = $true }
        if ($c.Check -like "Hyper-V*" -and $c.Status -eq "ERROR") { $hvMissing = $true }

        $row = [System.Windows.Controls.Border]::new()
        $row.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#2A2A3E")
        $row.CornerRadius = [System.Windows.CornerRadius]::new(6)
        $row.Margin = [System.Windows.Thickness]::new(0, 4, 0, 0)
        $row.Padding = [System.Windows.Thickness]::new(14, 10, 14, 10)

        $grid = [System.Windows.Controls.Grid]::new()
        $col1 = [System.Windows.Controls.ColumnDefinition]::new()
        $col1.Width = [System.Windows.GridLength]::new(30)
        $col2 = [System.Windows.Controls.ColumnDefinition]::new()
        $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        $grid.ColumnDefinitions.Add($col1)
        $grid.ColumnDefinitions.Add($col2)

        $iconTB = [System.Windows.Controls.TextBlock]::new()
        $iconTB.Text = $icon
        $iconTB.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom($color)
        $iconTB.FontSize = 16
        $iconTB.VerticalAlignment = "Center"
        [System.Windows.Controls.Grid]::SetColumn($iconTB, 0)
        $grid.Children.Add($iconTB)

        $sp = [System.Windows.Controls.StackPanel]::new()
        [System.Windows.Controls.Grid]::SetColumn($sp, 1)

        $title = [System.Windows.Controls.TextBlock]::new()
        $title.Text = $c.Check
        $title.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#CDD6F4")
        $title.FontSize = 13
        $title.FontWeight = "SemiBold"

        $detail = [System.Windows.Controls.TextBlock]::new()
        $detail.Text = $c.Detail
        $detail.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#A6ADC8")
        $detail.FontSize = 11
        $detail.TextWrapping = "Wrap"

        $sp.Children.Add($title)
        $sp.Children.Add($detail)
        $grid.Children.Add($sp)
        $row.Child = $grid
        $checkPanel.Children.Add($row)
    }

    $advice = Get-PresetAdvice $checks
    $adviceText.Text = $advice

    # Show/hide Hyper-V banner
    $hyperVBanner.Visibility = if ($hvMissing) { "Visible" } else { "Collapsed" }

    # Show/hide ADK banner
    $adkBanner.Visibility = if ($adkMissing) { "Visible" } else { "Collapsed" }

    $blocked = $checks | Where-Object { $_.Block }
    $btnNext.IsEnabled = (-not $blocked)

    if ($script:currentCert -and $certAdviceText) {
        $advice = Get-CertAdvice $script:currentCert
        $certAdviceText.Text = $advice
        $certColor2 = if ($advice.StartsWith("[OK]")) { "#A6E3A1" } else { "#F9E2AF" }
        $certAdviceText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom($certColor2)
    }
}

$btnRerun.Add_Click({ Show-PreflightCheck })
$btnNext.Add_Click({

    # ── Choice: with or without unattended ISOs ───────────────────
    [xml]$choiceXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Next step" Height="280" Width="540"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Grid Margin="28">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <TextBlock Grid.Row="0" Text="How do you want to continue?"
               Foreground="#CDD6F4" FontSize="17" FontWeight="SemiBold" Margin="0,0,0,6"/>
    <TextBlock Grid.Row="1" TextWrapping="Wrap"
               Foreground="#A6ADC8" FontSize="12" Margin="0,0,0,18"
               Text="Choose whether to build unattended ISOs first (recommended for a fully automated VM installation), or continue directly to network and VM configuration."/>

    <StackPanel Grid.Row="2" Margin="0,0,0,0">
      <RadioButton x:Name="RadioUnattended" IsChecked="True"
                   Foreground="#CDD6F4" FontSize="13" Margin="0,0,0,10">
        <StackPanel>
          <TextBlock Text="[OK] Build unattended ISOs (Build-UnattendedIsos.ps1)" FontWeight="SemiBold" Foreground="#A6E3A1"/>
          <TextBlock Text="Recommended - Windows installs itself completely automatically in the VMs."
                     FontSize="11" Foreground="#A6ADC8" Margin="0,2,0,0"/>
        </StackPanel>
      </RadioButton>
      <RadioButton x:Name="RadioAttended"
                   Foreground="#CDD6F4" FontSize="13">
        <StackPanel>
          <TextBlock Text="Continue directly to Configure-HostNetwork" FontWeight="SemiBold" Foreground="#F9E2AF"/>
          <TextBlock Text="Manual installation - you go through the Windows Setup wizard yourself in each VM."
                     FontSize="11" Foreground="#A6ADC8" Margin="0,2,0,0"/>
        </StackPanel>
      </RadioButton>
    </StackPanel>

    <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,20,0,0">
      <Button x:Name="BtnCancel" Content="Cancel"
              Background="#45475A" Foreground="#CDD6F4"
              FontSize="12" Padding="16,7" BorderThickness="0"
              Cursor="Hand" Margin="0,0,10,0" Height="34"/>
      <Button x:Name="BtnConfirm" Content="Continue ->"
              Background="#89B4FA" Foreground="#1E1E2E"
              FontWeight="SemiBold" FontSize="12"
              Padding="18,7" BorderThickness="0"
              Cursor="Hand" Height="34"/>
    </StackPanel>
  </Grid>
</Window>
"@

    $choiceReader = [System.Windows.Markup.XamlReader]::Load(
        [System.Xml.XmlNodeReader]::new($choiceXaml)
    )
    $radioUnattended = $choiceReader.FindName("RadioUnattended")
    $btnCancel       = $choiceReader.FindName("BtnCancel")
    $btnConfirm      = $choiceReader.FindName("BtnConfirm")

    $script:choiceResult = $null

    $btnCancel.Add_Click({ $choiceReader.Close() })
    $btnConfirm.Add_Click({
        $script:choiceResult = if ($radioUnattended.IsChecked) { "unattended" } else { "attended" }
        $choiceReader.Close()
    })

    $choiceReader.ShowDialog() | Out-Null

    if (-not $script:choiceResult) { return }   # user clicked Cancel

    $reader.Close()

    $nextScript = if ($script:choiceResult -eq "unattended") {
        Join-Path $PSScriptRoot "Build-UnattendedIsos.ps1"
    } else {
        Join-Path $PSScriptRoot "Configure-HostNetwork.ps1"
    }

    if (Test-Path $nextScript) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$nextScript`"" -Verb RunAs
    } else {
        [System.Windows.MessageBox]::Show("$([System.IO.Path]::GetFileName($nextScript)) not found in $PSScriptRoot", "SSW-Lab")
    }
})

$reader.Add_Loaded({ Show-PreflightCheck })
$reader.ShowDialog() | Out-Null

