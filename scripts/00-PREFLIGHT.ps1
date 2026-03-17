#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | 00-PREFLIGHT.ps1
# Controleert of de laptop klaar is voor SSW-Lab.
# Toont resultaten in WPF GUI met traffic-light status.
# ============================================================

. "$PSScriptRoot\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# ── Checks definitie ─────────────────────────────────────────
function Get-PreflightChecks {
    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # 1. Hyper-V feature
    $hvState = (Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -ErrorAction SilentlyContinue).State
    $hvEnabled = $hvState -eq "Enabled"
    $results.Add([PSCustomObject]@{
        Check   = "Hyper-V geïnstalleerd"
        Status  = if ($hvEnabled) { "OK" } else { "FOUT" }
        Detail  = if ($hvEnabled) { "Hyper-V is actief" } else { "Voer uit: Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All" }
        Block   = -not $hvEnabled
    })

    # 2. BIOS virtualisatie
    # Sommige systemen rapporteren VirtualizationFirmwareEnabled onbetrouwbaar via WMI.
    # Daarom gebruiken we een fallback: als de hypervisor actief is, dan staat firmware-virtualisatie effectief aan.
    $cpuInfo = Get-CimInstance Win32_Processor
    $vmxFromCpu = @($cpuInfo.VirtualizationFirmwareEnabled) -contains $true
    $hypervisorPresent = (Get-CimInstance Win32_ComputerSystem).HypervisorPresent
    $vmx = $vmxFromCpu -or $hypervisorPresent

    $vmxDetail = if ($vmxFromCpu) {
      "Intel VT-x / AMD-V actief"
    } elseif ($hypervisorPresent) {
      "Virtualisatie actief (afgeleid via actieve hypervisor)"
    } else {
      "Schakel virtualisatie in via BIOS/UEFI"
    }

    $results.Add([PSCustomObject]@{
        Check   = "Virtualisatie in BIOS"
        Status  = if ($vmx) { "OK" } else { "FOUT" }
      Detail  = $vmxDetail
        Block   = -not $vmx
    })

    # 3. RAM check
    $ramGB = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
    $ramStatus = if ($ramGB -ge 32) { "OK" } elseif ($ramGB -ge 16) { "WAARSCHUWING" } else { "FOUT" }
    $ramDetail = switch ($ramStatus) {
        "OK"          { "$ramGB GB — alle presets beschikbaar" }
        "WAARSCHUWING" { "$ramGB GB — gebruik Minimal preset (DC01 + 1 client)" }
        "FOUT"        { "$ramGB GB — onvoldoende voor SSW-Lab (min. 16 GB)" }
    }
    $results.Add([PSCustomObject]@{
        Check   = "RAM beschikbaar"
        Status  = $ramStatus
        Detail  = $ramDetail
        Block   = ($ramGB -lt 16)
    })

    # 4. Schijfruimte (D:\ of C:\)
    $drive = if (Test-Path "D:\") { "D" } else { "C" }
    $disk = Get-PSDrive $drive
    $freeGB = [math]::Round($disk.Free / 1GB)
    $diskStatus = if ($freeGB -ge 150) { "OK" } elseif ($freeGB -ge 80) { "WAARSCHUWING" } else { "FOUT" }
    $results.Add([PSCustomObject]@{
      Check   = "Vrije schijfruimte ($($drive):\)"
        Status  = $diskStatus
        Detail  = switch ($diskStatus) {
            "OK"           { "$freeGB GB vrij — voldoende voor Full preset" }
            "WAARSCHUWING" { "$freeGB GB vrij — Minimal of Standard preset aanbevolen" }
            "FOUT"         { "$freeGB GB vrij — minimaal 80 GB nodig" }
        }
        Block   = ($freeGB -lt 80)
    })

    # 5. Windows versie
    $winVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").DisplayVersion
    $isW11  = [System.Environment]::OSVersion.Version.Build -ge 22000
    $results.Add([PSCustomObject]@{
        Check   = "Windows versie"
        Status  = if ($isW11) { "OK" } else { "WAARSCHUWING" }
        Detail  = if ($isW11) { "Windows 11 ($winVer)" } else { "Windows 10 — Hyper-V werkt, maar clientconfiguraties kunnen afwijken" }
        Block   = $false
    })

    # 6. Windows ADK (oscdimg voor 02-MAKE-ISOS)
    $oscdimg = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
    $adkOk = Test-Path $oscdimg
    $results.Add([PSCustomObject]@{
        Check    = "Windows ADK (Deployment Tools)"
        Status   = if ($adkOk) { "OK" } else { "WAARSCHUWING" }
        Detail   = if ($adkOk) { "oscdimg.exe gevonden — ISO-builder klaar" } else { "Vereist voor 02-MAKE-ISOS.ps1 — gebruik de downloadknop hieronder" }
        Block    = $false
        NeedsADK = -not $adkOk
    })

    # 7. Bestaande SSW vSwitch
    $existingSwitch = Get-VMSwitch -Name $SSWConfig.vSwitchName -ErrorAction SilentlyContinue
    $results.Add([PSCustomObject]@{
        Check   = "SSW-Internal vSwitch"
        Status  = if ($existingSwitch) { "OK" } else { "INFO" }
        Detail  = if ($existingSwitch) { "vSwitch bestaat al" } else { "Wordt aangemaakt door 01-NETWORK.ps1" }
        Block   = $false
    })

    return $results
}

# ── Preset aanbeveling ───────────────────────────────────────
function Get-PresetAdvice($checks) {
    $blocked = $checks | Where-Object { $_.Block }

    if ($blocked) { return "⛔  Lab kan niet starten — los de rode punten op." }

    $ramCheck = $checks | Where-Object { $_.Check -like "RAM*" }
    if ($ramCheck.Status -eq "WAARSCHUWING") {
        return "⚠️  Gebruik de Minimal preset (DC01 + 1 W11-client) — ca. 6 GB RAM."
    }
    $diskCheck = $checks | Where-Object { $_.Check -like "Vrije*" }
    if ($diskCheck.Status -eq "WAARSCHUWING") {
        return "⚠️  Gebruik Standard of Minimal — schijfruimte is beperkt."
    }

    return "✅  Systeem is gereed. Alle presets zijn beschikbaar."
}

# ── Certificeringstraject advies ─────────────────────────────
function Get-CertAdvice {
    param([string]$cert)

    $ramGB  = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB)
    $drive  = if (Test-Path "D:\") { "D" } else { "C" }
    $freeGB = [math]::Round((Get-PSDrive $drive).Free / 1GB)

    $requirements = @{
        "MD-102" = @{ MinRAM = 14; MinDisk = 300; Preset = "Standard"; VMs = "DC01 · MGMT01 · W11-01 · W11-02" }
        "MS-102" = @{ MinRAM = 14; MinDisk = 300; Preset = "Standard"; VMs = "DC01 · MGMT01 · W11-01 · W11-02" }
        "SC-300" = @{ MinRAM = 14; MinDisk = 300; Preset = "Standard"; VMs = "DC01 · MGMT01 · W11-01 · W11-02" }
        "AZ-104" = @{ MinRAM = 6;  MinDisk = 140; Preset = "Minimal";  VMs = "DC01 · W11-01" }
    }

    $req    = $requirements[$cert]
    $ramOk  = $ramGB  -ge $req.MinRAM
    $diskOk = $freeGB -ge $req.MinDisk

    if ($ramOk -and $diskOk) {
        return "✅  Jouw laptop is geschikt voor $cert — preset: $($req.Preset) ($($req.VMs))"
    }

    $issues = @()
    if (-not $ramOk)  { $issues += "RAM: $ramGB GB beschikbaar, $($req.MinRAM) GB vereist" }
    if (-not $diskOk) { $issues += "Schijf: $freeGB GB vrij, $($req.MinDisk) GB vereist" }
    return "⚠️  Hardware onvoldoende voor $cert — $($issues -join '  |  ')"
}

# ── WPF GUI ──────────────────────────────────────────────────
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
    <TextBlock Grid.Row="1" Style="{StaticResource Sub}" Text="Systeemvereisten voor SSW-Lab"/>

    <ScrollViewer Grid.Row="2" Margin="16,0,16,0" VerticalScrollBarVisibility="Auto">
      <StackPanel x:Name="CheckPanel"/>
    </ScrollViewer>

    <StackPanel Grid.Row="3" Margin="16,8,16,0">
      <Border Background="#313244" CornerRadius="6" Padding="12,10">
        <TextBlock x:Name="AdviceText" Style="{StaticResource Advice}" Text="Bezig met controleren…"/>
      </Border>

      <!-- ADK download banner — zichtbaar als ADK ontbreekt -->
      <Border x:Name="ADKBanner" Background="#2D1E2E" CornerRadius="6" Padding="14,10"
              Margin="0,6,0,0" BorderBrush="#CBA6F7" BorderThickness="1" Visibility="Collapsed">
        <Grid>
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <StackPanel Grid.Column="0" VerticalAlignment="Center">
            <TextBlock Text="Windows ADK vereist voor ISO-builder"
                       Foreground="#CBA6F7" FontSize="12" FontWeight="SemiBold"/>
            <TextBlock Text="Installeer alleen 'Deployment Tools' — ca. 80 MB. Herstart daarna 00-PREFLIGHT."
                       Foreground="#A6ADC8" FontSize="11" TextWrapping="Wrap" Margin="0,2,0,0"/>
          </StackPanel>
          <Button x:Name="BtnDownloadADK" Grid.Column="1"
                  Content="⬇  Download ADK"
                  Background="#CBA6F7" Foreground="#1E1E2E"
                  FontWeight="SemiBold" FontSize="12"
                  BorderThickness="0" Cursor="Hand"
                  Padding="14,8" Margin="12,0,0,0" Height="34"/>
        </Grid>
      </Border>
    </StackPanel>

    <Border Grid.Row="4" Background="#313244" CornerRadius="6" Margin="16,6,16,0" Padding="14,10">
      <StackPanel>
        <TextBlock Text="Voor welk certificeringstraject bereid je voor?"
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
        <StackPanel Orientation="Horizontal" Margin="0,8,0,0" VerticalAlignment="Center">
          <TextBlock x:Name="CertAdviceText"
                     Foreground="#CDD6F4" FontSize="12"
                     TextWrapping="Wrap" Text="" VerticalAlignment="Center"/>
          <Button x:Name="BtnStudyGuide" Content="📖  Studieprogramma" Visibility="Collapsed"
                  Background="#313244" Foreground="#89B4FA"
                  FontSize="11" FontWeight="SemiBold"
                  BorderThickness="1" BorderBrush="#89B4FA"
                  Cursor="Hand" Padding="10,4" Margin="12,0,0,0" Height="26"/>
        </StackPanel>
      </StackPanel>
    </Border>

    <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right" Margin="16,12,16,16">
      <Button x:Name="BtnRerun" Content="Opnieuw controleren" Style="{StaticResource PrimaryBtn}"
              Background="#A6E3A1" Margin="0,0,10,0"/>
      <Button x:Name="BtnNext" Content="Doorgaan naar 01-NETWORK →" Style="{StaticResource PrimaryBtn}"
              IsEnabled="False"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))

$checkPanel     = $reader.FindName("CheckPanel")
$adviceText     = $reader.FindName("AdviceText")
$adkBanner      = $reader.FindName("ADKBanner")
$btnDownloadADK = $reader.FindName("BtnDownloadADK")
$btnRerun       = $reader.FindName("BtnRerun")
$btnNext        = $reader.FindName("BtnNext")
$certAdviceText  = $reader.FindName("CertAdviceText")
$btnStudyGuide   = $reader.FindName("BtnStudyGuide")
$radioMD102      = $reader.FindName("RadioMD102")
$radioMS102      = $reader.FindName("RadioMS102")
$radioSC300      = $reader.FindName("RadioSC300")
$radioAZ104      = $reader.FindName("RadioAZ104")

$script:currentCert = $null

$studyGuideUrls = @{
    "MD-102" = "https://github.com/Naamalingebruik/SSW-Lab/blob/main/docs/study-guide-MD102.md"
    "MS-102" = "https://github.com/Naamalingebruik/SSW-Lab/blob/main/docs/study-guide-MS102.md"
    "SC-300" = "https://github.com/Naamalingebruik/SSW-Lab/blob/main/docs/study-guide-SC300.md"
    "AZ-104" = "https://github.com/Naamalingebruik/SSW-Lab/blob/main/docs/study-guide-AZ104.md"
}

$certClickHandler = {
    param($s, $e)
    $script:currentCert = $s.Content
    $advice = Get-CertAdvice $script:currentCert
  $certColor = if ($advice.StartsWith("✅")) { "#A6E3A1" } else { "#F9E2AF" }
    $certAdviceText.Text = $advice
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

$btnDownloadADK.Add_Click({
    Start-Process "https://go.microsoft.com/fwlink/?linkid=2289980"
})

function Render-Checks {
    $checkPanel.Children.Clear()
    $checks = Get-PreflightChecks

    $adkMissing = $false

    foreach ($c in $checks) {
        $color = switch ($c.Status) {
            "OK"           { "#A6E3A1" }
            "WAARSCHUWING" { "#F9E2AF" }
            "FOUT"         { "#F38BA8" }
            default        { "#89B4FA" }
        }
        $icon = switch ($c.Status) {
            "OK"           { "✔" }
            "WAARSCHUWING" { "⚠" }
            "FOUT"         { "✘" }
            default        { "ℹ" }
        }

        if ($c.PSObject.Properties["NeedsADK"] -and $c.NeedsADK) { $adkMissing = $true }

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

    # ADK banner tonen/verbergen
    $adkBanner.Visibility = if ($adkMissing) { "Visible" } else { "Collapsed" }

    $blocked = $checks | Where-Object { $_.Block }
    $btnNext.IsEnabled = (-not $blocked)

    if ($script:currentCert -and $certAdviceText) {
        $advice = Get-CertAdvice $script:currentCert
      $certColor = if ($advice.StartsWith("✅")) { "#A6E3A1" } else { "#F9E2AF" }
        $certAdviceText.Text = $advice
      $certAdviceText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom($certColor)
    }
}

$btnRerun.Add_Click({ Render-Checks })
$btnNext.Add_Click({

    # ── Keuze: wel of geen unattended ISOs ──────────────────────
    [xml]$choiceXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Volgende stap" Height="280" Width="540"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Grid Margin="28">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <TextBlock Grid.Row="0" Text="Hoe wil je verder?"
               Foreground="#CDD6F4" FontSize="17" FontWeight="SemiBold" Margin="0,0,0,6"/>
    <TextBlock Grid.Row="1" TextWrapping="Wrap"
               Foreground="#A6ADC8" FontSize="12" Margin="0,0,0,18"
               Text="Kies of je eerst unattended ISOs wilt bouwen (aanbevolen voor volledig geautomatiseerde VM-installatie), of direct doorgaat naar netwerk- en VM-configuratie."/>

    <StackPanel Grid.Row="2" Margin="0,0,0,0">
      <RadioButton x:Name="RadioUnattended" IsChecked="True"
                   Foreground="#CDD6F4" FontSize="13" Margin="0,0,0,10">
        <StackPanel>
          <TextBlock Text="✅  Unattended ISOs bouwen (02-MAKE-ISOS)" FontWeight="SemiBold" Foreground="#A6E3A1"/>
          <TextBlock Text="Aanbevolen — Windows installeert zichzelf volledig automatisch in de VMs."
                     FontSize="11" Foreground="#A6ADC8" Margin="0,2,0,0"/>
        </StackPanel>
      </RadioButton>
      <RadioButton x:Name="RadioAttended"
                   Foreground="#CDD6F4" FontSize="13">
        <StackPanel>
          <TextBlock Text="⏭  Direct doorgaan naar 01-NETWORK" FontWeight="SemiBold" Foreground="#F9E2AF"/>
          <TextBlock Text="Handmatige installatie — je doorloopt de Windows Setup wizard zelf in elke VM."
                     FontSize="11" Foreground="#A6ADC8" Margin="0,2,0,0"/>
        </StackPanel>
      </RadioButton>
    </StackPanel>

    <StackPanel Grid.Row="3" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,20,0,0">
      <Button x:Name="BtnCancel" Content="Annuleren"
              Background="#45475A" Foreground="#CDD6F4"
              FontSize="12" Padding="16,7" BorderThickness="0"
              Cursor="Hand" Margin="0,0,10,0" Height="34"/>
      <Button x:Name="BtnConfirm" Content="Doorgaan →"
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

    if (-not $script:choiceResult) { return }   # gebruiker klikte Annuleren

    $reader.Close()

    $nextScript = if ($script:choiceResult -eq "unattended") {
        Join-Path $PSScriptRoot "02-MAKE-ISOS.ps1"
    } else {
        Join-Path $PSScriptRoot "01-NETWORK.ps1"
    }

    if (Test-Path $nextScript) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$nextScript`"" -Verb RunAs
    } else {
        [System.Windows.MessageBox]::Show("$([System.IO.Path]::GetFileName($nextScript)) niet gevonden in $PSScriptRoot", "SSW-Lab")
    }
})

$reader.Add_Loaded({ Render-Checks })
$reader.ShowDialog() | Out-Null
