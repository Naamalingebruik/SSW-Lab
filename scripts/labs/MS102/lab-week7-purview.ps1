#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MS102/lab-week7-purview.ps1
# MS-102 Week 7 — Microsoft Purview: compliance, DLP, eDiscovery
# VMs:  SSW-W11-01 (label toepassen in Word)
# Cloud: Microsoft Purview compliance portal
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MS-102 | Week 7 — Microsoft Purview" Height="720" Width="700"
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
      <TextBlock Text="MS-102 | Week 7 — Microsoft Purview" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Sensitivity labels · DLP · eDiscovery · Compliance Manager" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. MGMT01: Verbinding met Microsoft Information Protection PowerShell"/>
        <LineBreak/><Run Text="2. Manueel: Sensitivity label aanmaken in Purview portal"/>
        <LineBreak/><Run Text="3. Manueel: DLP-beleid instellen voor BSN in e-mail"/>
        <LineBreak/><Run Text="4. Manueel: eDiscovery Core zoekopdracht aanmaken"/>
        <LineBreak/><Run Text="5. Manueel: Compliance Manager bekijken"/>
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
        <CheckBox x:Name="ChkDryRun" Grid.Column="1" IsChecked="True" Content="Dry Run"
                  FontWeight="SemiBold" FontSize="12" VerticalContentAlignment="Center" Margin="16,0,0,0"/>
      </Grid>
    </Border>
    <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
      <Button x:Name="BtnRun"  Content="Lab uitvoeren" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="140"/>
      <Button x:Name="BtnNext" Content="MS-102 voltooid! Naar AZ-104 >" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False" Width="260"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$logBox = $reader.FindName("LogBox"); $progress = $reader.FindName("Progress")
$btnRun = $reader.FindName("BtnRun"); $btnNext = $reader.FindName("BtnNext")
$chkDryRun = $reader.FindName("ChkDryRun"); $dryRunBar = $reader.FindName("DryRunBar")
$dryRunTitle = $reader.FindName("DryRunTitle"); $dryRunSub = $reader.FindName("DryRunSub")
$conv = [System.Windows.Media.BrushConverter]::new()

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background = $conv.ConvertFrom("#1A2E24"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text = "Dry Run — geen wijzigingen"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — verbinding met Purview compliance portal"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Zet het vinkje terug voor Dry Run"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({ Update-DryRunBar }); $chkDryRun.Add_Unchecked({ Update-DryRunBar })
function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $mgmtVM  = $profiles.MGMT01.Name

    # ── Stap 1: MIP module op MGMT01 ───────────────────────
    Write-Log "${pre}Stap 1: MGMT01 — Verificatie Exchange/Compliance module"
    $progress.Value = 14
    if ($isDry) {
        Write-Log "${pre}  Get-InstalledModule ExchangeOnlineManagement"
        Write-Log "${pre}  Connect-IPPSSession -UserPrincipalName admin@<tenant>.onmicrosoft.com"
        Write-Log "${pre}  Get-Label | Select-Object DisplayName, Priority, IsEnabled | Format-Table"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $mgmtVM" -UserName "$mgmtVM\$($SSWConfig.AdminUser)"
            $labelCheck = Invoke-Command -VMName $mgmtVM -Credential $cred -ScriptBlock {
                $mod = Get-Module ExchangeOnlineManagement -ListAvailable
                [PSCustomObject]@{
                    ModuleVersie = if ($mod) { ($mod | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString() } else { "Niet geïnstalleerd" }
                }
            }
            Write-Log "  ExchangeOnlineManagement: $($labelCheck.ModuleVersie)"
            if ($labelCheck.ModuleVersie -eq "Niet geïnstalleerd") {
                Write-Log "  Installatie: Install-Module ExchangeOnlineManagement -Force"
            }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: Sensitivity label ────────────────────────────
    Write-Log "${pre}Stap 2: Manueel — Sensitivity label aanmaken"
    $progress.Value = 28
    Write-Log "  URL: https://compliance.microsoft.com"
    Write-Log "  Navigeer naar: Information protection > Labels"
    Write-Log "  + Create a label"
    Write-Log "  Naam: 'Vertrouwelijk - Intern'"
    Write-Log "  Encryptie: inschakelen | Owner: admin"
    Write-Log "  Content marking: watermark 'VERTROUWELIJK'"
    Write-Log "  Scope: Files and emails"
    Write-Log "  Publiceer het label via Label policies"

    # ── Stap 3: DLP-beleid ────────────────────────────────────
    Write-Log "${pre}Stap 3: Manueel — DLP-beleid voor BSN-nummers"
    $progress.Value = 42
    Write-Log "  Compliance portal > Data Loss Prevention > Policies"
    Write-Log "  + Create a DLP policy"
    Write-Log "  Template: Privacy > Netherlands > Dutch Citizen Card Number"
    Write-Log "  Scope: Exchange Online e-mail"
    Write-Log "  Actie: Block + stuur melding aan gebruiker en admin"
    Write-Log "  Test: stuur mail met BSN-patroon (bijv. 123456789) → DLP alert"
    Write-Log "  Monitor alerts via: Data loss prevention > Alerts"

    # ── Stap 4: eDiscovery Core ──────────────────────────────
    Write-Log "${pre}Stap 4: Manueel — eDiscovery Core zoekopdracht"
    $progress.Value = 58
    Write-Log "  Compliance portal > eDiscovery > Core"
    Write-Log "  + Create a case: naam 'SSW-TestCase'"
    Write-Log "  Voeg een hold toe op de mailbox van testuser01"
    Write-Log "  Maak een Search: alle items in testuser01-mailbox (geen filter)"
    Write-Log "  Exporteer resultaten (Preview) — let op licentievereiste"
    Write-Log "  Bekijk de statistieken: aantal items, totale grootte"

    # ── Stap 5: Compliance Manager ───────────────────────────
    Write-Log "${pre}Stap 5: Manueel — Compliance Manager bekijken"
    $progress.Value = 74
    Write-Log "  Compliance portal > Compliance Manager"
    Write-Log "  Bekijk de huidige Compliance Score van de tenant"
    Write-Log "  Lees minstens 2 improvement actions in detail"
    Write-Log "  Bekijk het AVG-assessment (GDPR) en openstaande items"
    Write-Log "  Vergelijk met Microsoft 365 Data Protection Baseline"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Browser openen naar Microsoft Purview compliance portal?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://compliance.microsoft.com" }
    }

    $progress.Value = 100; Write-Log ""; Write-Log "Week 7 lab afgerond — MS-102 track volledig!"
    Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het onderscheid tussen MIP labels en DLP-beleid?"
    Write-Log "2. In welk scenario gebruik je eDiscovery versus Content Search?"
    Write-Log "3. Welke licentie is vereist voor eDiscovery Premium (vroeger: AeD)?"
    Write-Log "4. Wat is de rol van Compliance Manager versus Compliance Score?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "..\..\labs\AZ104\lab-week1-governance.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("AZ-104 lab-week1-governance.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null


