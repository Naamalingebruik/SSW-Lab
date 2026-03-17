#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MS102/lab-week3-hybrid-identity.ps1
# MS-102 Week 3 — Entra ID en hybride identiteit
# VMs:  SSW-DC01, SSW-MGMT01, SSW-W11-01
# Cloud: Entra admin center
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MS-102 | Week 3 — Hybride identiteit en MFA" Height="720" Width="700"
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
      <TextBlock Text="MS-102 | Week 3 — Hybride identiteit en MFA" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="ADSync scheduler · MFA registratie · Sign-in logs · B2B guest · Cross-tenant" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. DC01: controleer ADSync scheduler en voer delta sync uit"/>
        <LineBreak/><Run Text="2. DC01: controleer Password Writeback configuratie"/>
        <LineBreak/><Run Text="3. Manueel: configureer MFA via Entra admin center"/>
        <LineBreak/><Run Text="4. W11-01: registreer MFA-methode als testgebruiker"/>
        <LineBreak/><Run Text="5. Manueel: analyseer Sign-in logs in Entra ID"/>
        <LineBreak/><Run Text="6. Manueel: nodig een B2B guest-gebruiker uit"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 4 >" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False" Width="220"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader      = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$logBox      = $reader.FindName("LogBox"); $progress = $reader.FindName("Progress")
$btnRun      = $reader.FindName("BtnRun"); $btnNext   = $reader.FindName("BtnNext")
$chkDryRun   = $reader.FindName("ChkDryRun"); $dryRunBar = $reader.FindName("DryRunBar")
$dryRunTitle = $reader.FindName("DryRunTitle"); $dryRunSub = $reader.FindName("DryRunSub")
$conv        = [System.Windows.Media.BrushConverter]::new()

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background = $conv.ConvertFrom("#1A2E24"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text = "Dry Run — geen wijzigingen"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — verbinding met DC01"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
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
    $dcVM = $profiles.DC01.Name

    # ── Stap 1: ADSync scheduler ─────────────────────────────
    Write-Log "${pre}Stap 1: DC01 — ADSync scheduler en delta sync"
    $progress.Value = 14
    if ($isDry) {
        Write-Log "${pre}  Import-Module ADSync"
        Write-Log "${pre}  Get-ADSyncScheduler | Select-Object SyncCycleEnabled, NextSyncCyclePolicyType, NextSyncCycleStartTimeInUTC"
        Write-Log "${pre}  Start-ADSyncSyncCycle -PolicyType Delta"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $dcVM" -UserName "$dcVM\$($SSWConfig.AdminUser)"
            $syncResult = Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                try {
                    Import-Module ADSync -ErrorAction Stop
                    $sched = Get-ADSyncScheduler
                    "Scheduler: Enabled=$($sched.SyncCycleEnabled), Lopend=$($sched.CurrentlyRunning)"
                    Start-ADSyncSyncCycle -PolicyType Delta
                    "Delta sync gestart"
                } catch { "ADSync module niet beschikbaar: $_" }
            }
            $syncResult | ForEach-Object { Write-Log "  $_" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: Password Writeback ───────────────────────────
    Write-Log "${pre}Stap 2: DC01 — Password Writeback status"
    $progress.Value = 28
    if ($isDry) {
        Write-Log "${pre}  Import-Module ADSync"
        Write-Log "${pre}  Get-ADSyncAADPasswordWritebackConfiguration"
        Write-Log "${pre}  Verwacht: Enabled=True (vereist voor SSPR vanuit de cloud)"
    } else {
        try {
            $pwbResult = Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                try {
                    Import-Module ADSync -ErrorAction Stop
                    $cfg = Get-ADSyncAADPasswordWritebackConfiguration -ErrorAction SilentlyContinue
                    if ($cfg) { "Password Writeback: Enabled=$($cfg.Enabled)" }
                    else { "Password Writeback configuratie niet gevonden — controleer Azure AD Connect installatie" }
                } catch { "ADSync module niet beschikbaar: $_" }
            }
            Write-Log "  $pwbResult"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: MFA configureren ─────────────────────────────
    Write-Log "${pre}Stap 3: Manueel — MFA configureren via Entra admin center"
    $progress.Value = 44
    Write-Log "  URL: https://entra.microsoft.com"
    Write-Log "  Navigeer naar: Security > Multifactor authentication"
    Write-Log "  Aanbevolen: gebruik Authentication methods policy (niet per-user MFA)"
    Write-Log "  Schakel in: Microsoft Authenticator voor alle gebruikers"
    Write-Log "  Gebruik Conditional Access voor MFA-afdwinging (week 3 exam-onderwerp)"

    # ── Stap 4: MFA registratie ──────────────────────────────
    Write-Log "${pre}Stap 4: Manueel — MFA registreren als testuser01"
    $progress.Value = 58
    Write-Log "  Op W11-01, open Edge en ga naar: https://aka.ms/mfasetup"
    Write-Log "  Log in als testuser01@<tenant>.onmicrosoft.com"
    Write-Log "  Voeg Microsoft Authenticator toe als verificatiemethode"
    Write-Log "  Scan de QR code met de Authenticator app op je telefoon"

    # ── Stap 5: Sign-in logs ─────────────────────────────────
    Write-Log "${pre}Stap 5: Manueel — Sign-in logs analyseren"
    $progress.Value = 72
    Write-Log "  Entra admin center > Users > Sign-in logs"
    Write-Log "  Filter op: testuser01 | Datum: vandaag"
    Write-Log "  Controleer: MFA Required = Yes, MFA Result = Success"
    Write-Log "  Exporteer indien nodig naar CSV voor verdere analyse"

    # ── Stap 6: B2B guest uitnodigen ─────────────────────────
    Write-Log "${pre}Stap 6: Manueel — B2B guest-gebruiker uitnodigen"
    $progress.Value = 86
    Write-Log "  Entra admin center > Users > All users > + Invite external user"
    Write-Log "  Email: gebruik een persoonlijk account of een tweede MSDN tenant"
    Write-Log "  Rol: Guest | Bericht: 'SSW-Lab B2B test uitnodiging'"
    Write-Log "  Na acceptatie: guest zichtbaar onder External users"
    Write-Log "  Stel Cross-tenant access in: Security > Cross-tenant access settings"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Browser openen naar Entra Sign-in logs?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://entra.microsoft.com/#view/Microsoft_AAD_IAM/ActiveUsersMenuBlade/~/SignInLogs" }
    }

    $progress.Value = 100
    Write-Log ""; Write-Log "Week 3 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen MFA per gebruiker en Security Defaults?"
    Write-Log "2. Hoe werkt Seamless Single Sign-On (SSO) met Azure AD Connect?"
    Write-Log "3. Wat is Azure AD B2B en wanneer gebruik je B2B versus B2C?"
    Write-Log "4. Hoe troubleshoot je een sync-fout in Azure AD Connect?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week4-exchange.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week4-exchange.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null



