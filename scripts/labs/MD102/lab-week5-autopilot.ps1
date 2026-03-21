#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MD102/lab-week5-autopilot.ps1
# MD-102 Week 5 — Windows Autopilot
# VMs:  LAB-W11-AUTOPILOT, LAB-MGMT01
# Cloud: Intune portal (intune.microsoft.com)
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MD-102 | Week 5 — Windows Autopilot" Height="720" Width="700"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Background" Value="#89B4FA"/><Setter Property="Foreground" Value="#1E1E2E"/>
      <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="36"/>
    </Style>
    <Style x:Key="Lbl" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#A6ADC8"/><Setter Property="FontSize" Value="11"/>
      <Setter Property="Margin" Value="0,8,0,2"/>
    </Style>
  </Window.Resources>
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Margin="0,0,0,16">
      <TextBlock Text="MD-102 | Week 5 — Windows Autopilot" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Hardware hash ophalen · Autopilot registratie · Deployment profile · OOBE" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. W11-AUTOPILOT: controleer/installeer Get-WindowsAutoPilotInfo module"/>
        <LineBreak/><Run Text="2. W11-AUTOPILOT: haal hardware hash op en exporteer naar CSV"/>
        <LineBreak/><Run Text="3. Kopieer hash.csv naar de host"/>
        <LineBreak/><Run Text="4. Manueel: upload hash naar Intune Autopilot devices"/>
        <LineBreak/><Run Text="5. Manueel: maak Autopilot deployment profile aan"/>
        <LineBreak/><Run Text="6. Manueel: reset VM en doorloop OOBE"/>
      </TextBlock>
    </StackPanel>

    <Border Grid.Row="2" Background="#181825" CornerRadius="6" Padding="10">
      <ScrollViewer VerticalScrollBarVisibility="Auto">
        <TextBox x:Name="LogBox" Background="Transparent" Foreground="#A6E3A1"
                 FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" BorderThickness="0"/>
      </ScrollViewer>
    </Border>

    <ProgressBar x:Name="Progress" Grid.Row="3" Height="6" Margin="0,10,0,0"
                 Background="#313244" Foreground="#89B4FA" BorderThickness="0" Minimum="0" Maximum="100" Value="0"/>

    <Border x:Name="DryRunBar" Grid.Row="4" CornerRadius="6" Margin="0,10,0,0" Padding="14,10" BorderThickness="1">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center">
          <TextBlock x:Name="DryRunTitle" FontWeight="SemiBold" FontSize="12"/>
          <TextBlock x:Name="DryRunSub"   FontSize="11" Margin="0,2,0,0"/>
        </StackPanel>
        <CheckBox x:Name="ChkDryRun" Grid.Column="1" IsChecked="True"
                  Content="Dry Run" FontWeight="SemiBold" FontSize="12"
                  VerticalContentAlignment="Center" Margin="16,0,0,0"/>
      </Grid>
    </Border>

    <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
      <Button x:Name="BtnRun"  Content="Lab uitvoeren" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="140"/>
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 6 >" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False" Width="220"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader      = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$logBox      = $reader.FindName("LogBox")
$progress    = $reader.FindName("Progress")
$btnRun      = $reader.FindName("BtnRun")
$btnNext     = $reader.FindName("BtnNext")
$chkDryRun   = $reader.FindName("ChkDryRun")
$dryRunBar   = $reader.FindName("DryRunBar")
$dryRunTitle = $reader.FindName("DryRunTitle")
$dryRunSub   = $reader.FindName("DryRunSub")
$conv        = [System.Windows.Media.BrushConverter]::new()

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "Dry Run — alleen lezen, geen wijzigingen"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk te verbinden met de VMs"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "LIVE — verbinding via PowerShell Direct naar lab-VMs"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({   Update-DryRunBar })
$chkDryRun.Add_Unchecked({ Update-DryRunBar })

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logBox.ScrollToEnd()
}

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked
    $pre   = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles   = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $apVM       = $profiles."W11-AUTOPILOT".Name
    $hashCsvHost = Join-Path $SSWConfig.VMPath "autopilot-hash.csv"

    # ── Stap 1: Module installatie/check ────────────────────
    Write-Log "${pre}Stap 1: W11-AUTOPILOT — Get-WindowsAutoPilotInfo module"
    $progress.Value = 12
    if ($isDry) {
        Write-Log "${pre}  Find-Module -Name Get-WindowsAutoPilotInfo"
        Write-Log "${pre}  Install-Script -Name Get-WindowsAutoPilotInfo -Force"
        Write-Log "${pre}  Vereist: NuGet provider en PSGallery toegang vanuit VM"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $apVM" -UserName "$apVM\$($SSWConfig.AdminUser)"
            $modStatus = Invoke-Command -VMName $apVM -Credential $cred -ScriptBlock {
                $m = Get-InstalledScript -Name "Get-WindowsAutoPilotInfo" -ErrorAction SilentlyContinue
                if ($m) {
                    "Versie $($m.Version) aanwezig"
                } else {
                    try {
                        Install-Script -Name "Get-WindowsAutoPilotInfo" -Force -Scope AllUsers -ErrorAction Stop
                        "Module geinstalleerd"
                    } catch {
                        "Installatie mislukt: $_  (controleer internet-verbinding VM)"
                    }
                }
            }
            Write-Log "  $modStatus"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: Hardware hash ophalen ───────────────────────
    Write-Log "${pre}Stap 2: W11-AUTOPILOT — hardware hash ophalen"
    $progress.Value = 35
    if ($isDry) {
        Write-Log "${pre}  Get-WindowsAutoPilotInfo -OutputFile C:\hash.csv"
        Write-Log "${pre}  Exporteert: SerialNumber, WindowsProductID, HardwareHash, GroupTag, AssignedUser"
        Write-Log "${pre}  Hash-bestand wordt tijdelijk opgeslagen op C:\hash.csv in de VM"
    } else {
        try {
            Invoke-Command -VMName $apVM -Credential $cred -ScriptBlock {
                if (Get-Command "Get-WindowsAutoPilotInfo" -ErrorAction SilentlyContinue) {
                    Get-WindowsAutoPilotInfo -OutputFile "C:\hash.csv"
                } else {
                    # Fallback: gebruik CIM voor basis hardware info
                    $serial = (Get-CimInstance Win32_BIOS).SerialNumber
                    $uuid   = (Get-CimInstance Win32_ComputerSystemProduct).UUID
                    "SerialNumber,UUID`n$serial,$uuid" | Set-Content "C:\hash.csv"
                    Write-Warning "Get-WindowsAutoPilotInfo niet beschikbaar — basis hash opgeslagen"
                }
            }
            Write-Log "  Hash opgeslagen als C:\hash.csv op $apVM"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: CSV kopiëren naar host ──────────────────────
    Write-Log "${pre}Stap 3: Hash CSV kopiëren van VM naar host"
    $progress.Value = 55
    if ($isDry) {
        Write-Log "${pre}  Copy-VMFile -SourcePath 'C:\hash.csv' -DestinationPath '$hashCsvHost'"
        Write-Log "${pre}  Of: gebruik SMB via \\\\<vmIP>\\C`$\\hash.csv"
    } else {
        try {
            Copy-VMFile -VMName $apVM -SourcePath "C:\hash.csv" `
                        -DestinationPath $hashCsvHost `
                        -FileSource Guest -ErrorAction Stop
            Write-Log "  CSV gekopieerd naar: $hashCsvHost"
            $csvContent = Import-Csv $hashCsvHost
            Write-Log "  SerialNumber: $($csvContent.SerialNumber)"
        } catch { Write-Log "  Fout: $_ (probeer handmatig via VM console)" }
    }

    # ── Stap 4: Manueel — upload naar Intune ────────────────
    Write-Log "${pre}Stap 4: Manueel — hardware hash uploaden naar Intune"
    $progress.Value = 68
    Write-Log "  Intune > Devices > Windows > Enrollment > Windows Autopilot devices > Import"
    Write-Log "  Selecteer: $hashCsvHost"
    Write-Log "  Wacht op verwerking (kan 5-15 minuten duren)"

    # ── Stap 5: Manueel — Deployment profile ────────────────
    Write-Log "${pre}Stap 5: Manueel — Deployment profile aanmaken"
    $progress.Value = 80
    Write-Log "  Intune > Devices > Windows > Enrollment > Deployment profiles > + Create"
    Write-Log "  Instellingen:"
    Write-Log "    Mode: User-driven"
    Write-Log "    Join type: Azure AD join"
    Write-Log "    Deployment mode: User-driven"
    Write-Log "    OOBE: Skip privacy settings, Hide EULA = Yes"
    Write-Log "  Assign aan: het Autopilot-device (via serial number)"

    # ── Stap 6: Manueel — VM resetten ───────────────────────
    Write-Log "${pre}Stap 6: Manueel — VM resetten voor OOBE test"
    $progress.Value = 90
    Write-Log "  Op W11-AUTOPILOT VM:"
    Write-Log "    Instellingen > Systeem > Herstel > Reset deze pc > Alles verwijderen"
    Write-Log "    OF: Hyper-V > Checkpoint terugzetten naar 'pre-enrollment'"
    Write-Log "  Doorloop OOBE en verifieer automatische enrollment + profiel-toepassing"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show(
            "Browser openen naar Intune Autopilot devices?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") {
            Start-Process "https://intune.microsoft.com/#view/Microsoft_Intune_Enrollment/AutopilotDevices.ReactView"
        }
    }

    $progress.Value = 100
    Write-Log ""
    Write-Log "Week 5 lab afgerond."
    Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen User-driven en Self-deploying Autopilot mode?"
    Write-Log "2. Waarvoor dient de Enrollment Status Page en hoe configureer je die?"
    Write-Log "3. Hoe reset je een Autopilot-profieltoewijzing als een device al geregistreerd is?"
    Write-Log "4. Wat is Windows Autopilot Reset en wanneer gebruik je het?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    $btnNext.IsEnabled = $true
    $btnRun.IsEnabled  = $true
})

$btnNext.Add_Click({
    $nextScript = Join-Path $PSScriptRoot "lab-week6-security.ps1"
    if (Test-Path $nextScript) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$nextScript`"" }
    else { [System.Windows.MessageBox]::Show("lab-week6-security.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null
