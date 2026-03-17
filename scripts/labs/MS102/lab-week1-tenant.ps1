#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MS102/lab-week1-tenant.ps1
# MS-102 Week 1 — Microsoft 365 Tenant inrichten
# VMs:  SSW-DC01, SSW-MGMT01
# Cloud: M365 admin center, Entra admin center
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MS-102 | Week 1 — Microsoft 365 Tenant inrichten" Height="720" Width="700"
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
      <TextBlock Text="MS-102 | Week 1 — Microsoft 365 Tenant inrichten" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Azure AD Connect · Tenant config · Licenties · Entra verificatie" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. DC01: controleer Azure AD Connect service en sync status"/>
        <LineBreak/><Run Text="2. DC01: voer een delta-sync uit naar Entra ID"/>
        <LineBreak/><Run Text="3. Manueel: open M365 admin center en verifieer tenant"/>
        <LineBreak/><Run Text="4. Manueel: controleer gesynchroniseerde gebruikers in Entra"/>
        <LineBreak/><Run Text="5. Manueel: activeer M365 E5 licenties voor gebruikers"/>
        <LineBreak/><Run Text="6. Kennischeckvragen weergeven"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 2 >" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text       = "Dry Run — geen wijzigingen"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk uit te voeren"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "LIVE — verbinding met DC01 en cloud portals"
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
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $dcVM   = $profiles.DC01.Name

    # ── Stap 1: Azure AD Connect service status ──────────────
    Write-Log "${pre}Stap 1: DC01 — Azure AD Connect service controleren"
    $progress.Value = 14
    if ($isDry) {
        Write-Log "${pre}  Get-Service ADSync | Select-Object Name, Status, StartType"
        Write-Log "${pre}  Verwacht: Status=Running, StartType=Automatic"
        Write-Log "${pre}  Import-Module ADSync; Get-ADSyncScheduler | Select-Object SyncCycleEnabled, CurrentlyRunning, NextSyncCyclePolicyType"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $dcVM" -UserName "$dcVM\$($SSWConfig.AdminUser)"
            $syncInfo = Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                $svc = Get-Service ADSync -ErrorAction SilentlyContinue
                if (-not $svc) { return "Azure AD Connect NIET geinstalleerd op deze DC" }
                try {
                    Import-Module ADSync -ErrorAction Stop
                    $sched = Get-ADSyncScheduler
                    "Service: $($svc.Status) | Sync ingeschakeld: $($sched.SyncCycleEnabled) | Volgende sync: $($sched.NextSyncCyclePolicyType)"
                } catch {
                    "Service: $($svc.Status) | ADSync module niet beschikbaar: $_"
                }
            }
            Write-Log "  $syncInfo"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: Delta sync uitvoeren ─────────────────────────
    Write-Log "${pre}Stap 2: DC01 — Delta sync starten"
    $progress.Value = 30
    if ($isDry) {
        Write-Log "${pre}  Import-Module ADSync"
        Write-Log "${pre}  Start-ADSyncSyncCycle -PolicyType Delta"
        Write-Log "${pre}  Wacht 30-60 seconden en verifieer in Entra admin center"
    } else {
        try {
            Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                Import-Module ADSync -ErrorAction Stop
                Start-ADSyncSyncCycle -PolicyType Delta
            }
            Write-Log "  Delta sync gestart"
            Write-Log "  Wacht ca. 30-60 seconden voor verwerking..."
        } catch { Write-Log "  Fout (is Azure AD Connect geinstalleerd?): $_" }
    }

    # ── Stap 3: Microsoft Graph — gebruikers verifiëren ──────
    Write-Log "${pre}Stap 3: Microsoft Graph — gesynchroniseerde gebruikers ophalen"
    $progress.Value = 50
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'User.Read.All'"
        Write-Log "${pre}  Get-MgUser -Filter ""onPremisesSyncEnabled eq true"" | Select-Object DisplayName, UserPrincipalName, OnPremisesSyncEnabled"
        Write-Log "${pre}  Vereist: Microsoft.Graph PowerShell module"
        Write-Log "${pre}  Installeren: Install-Module Microsoft.Graph -Scope CurrentUser"
    } else {
        $mgInstalled = Get-Module -ListAvailable -Name Microsoft.Graph.Users -ErrorAction SilentlyContinue
        if (-not $mgInstalled) {
            Write-Log "  Microsoft.Graph module niet gevonden"
            Write-Log "  Installeer met: Install-Module Microsoft.Graph -Scope CurrentUser"
        } else {
            try {
                Import-Module Microsoft.Graph.Users -ErrorAction Stop
                Connect-MgGraph -Scopes "User.Read.All" -NoWelcome -ErrorAction Stop
                $syncedUsers = Get-MgUser -Filter "onPremisesSyncEnabled eq true" -Top 10 |
                               Select-Object DisplayName, UserPrincipalName
                Write-Log "  Gesynchroniseerde gebruikers (max 10):"
                $syncedUsers | ForEach-Object { Write-Log "    $($_.DisplayName)  <$($_.UserPrincipalName)>" }
            } catch { Write-Log "  Fout: $_" }
        }
    }

    # ── Stap 4: M365 admin center ────────────────────────────
    Write-Log "${pre}Stap 4: Manueel — M365 admin center"
    $progress.Value = 68
    Write-Log "  URL: https://admin.microsoft.com"
    Write-Log "  Taken:"
    Write-Log "    - Configureer tenantinformatie (naam, tijdzone, land)"
    Write-Log "    - Verificeer domein ssw.lab of custom domein"
    Write-Log "    - Bekijk licentie-overzicht: Billing > Licenses"

    # ── Stap 5: Licenties activeren ──────────────────────────
    Write-Log "${pre}Stap 5: Manueel — M365 E5 licenties activeren"
    $progress.Value = 82
    Write-Log "  M365 admin center > Users > Active users"
    Write-Log "  Selecteer een gesynchroniseerde gebruiker > Licenses and apps"
    Write-Log "  Wijs toe: Microsoft 365 E5 Developer"
    Write-Log "  Herhaal voor alle testgebruikers die Intune/Defender nodig hebben"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show(
            "Browser openen naar M365 admin center?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://admin.microsoft.com" }
    }

    $progress.Value = 100
    Write-Log ""
    Write-Log "Week 1 lab afgerond."
    Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen een managed domain en een federated domain?"
    Write-Log "2. Hoe werkt password hash synchronization versus pass-through authentication?"
    Write-Log "3. Welke DNS-records zijn vereist voor een custom domein in Microsoft 365?"
    Write-Log "4. Wat is het Microsoft 365 compliance center en waarvoor gebruik je het?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    $btnNext.IsEnabled = $true
    $btnRun.IsEnabled  = $true
})

$btnNext.Add_Click({
    $nextScript = Join-Path $PSScriptRoot "lab-week2-gebruikers.ps1"
    if (Test-Path $nextScript) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$nextScript`"" }
    else { [System.Windows.MessageBox]::Show("lab-week2-gebruikers.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null


