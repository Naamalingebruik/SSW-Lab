#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/SC300/lab-week1-hybrid-identity.ps1
# SC-300 Week 1 — Hybrid Identity: AD DS, Azure AD Connect, Entra ID
# VMs:  SSW-DC01, SSW-MGMT01
# Cloud: Entra ID (via Microsoft Graph)
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="SC-300 | Week 1 — Hybrid Identity" Height="720" Width="700"
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
      <TextBlock Text="SC-300 | Week 1 — Hybrid Identity" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="AD DS forest · Azure AD Connect · Delta sync · Entra audit logs" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. DC01: AD DS forest informatie ophalen"/>
        <LineBreak/><Run Text="2. MGMT01: Azure AD Connect sync status controleren"/>
        <LineBreak/><Run Text="3. MGMT01: Delta sync uitvoeren en loggen"/>
        <LineBreak/><Run Text="4. Graph: gesynchroniseerde gebruikers verifiëren"/>
        <LineBreak/><Run Text="5. Entra portal: audit logs bekijken"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 2 >" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False" Width="220"/>
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
        $dryRunSub.Text = "Haal het vinkje weg om te verbinden met DC01 en MGMT01"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — verbinding met DC01, MGMT01 en Entra ID"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Zet het vinkje terug voor Dry Run"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({ Update-DryRunBar }); $chkDryRun.Add_Unchecked({ Update-DryRunBar })
function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry    = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $dcVM     = $profiles.DC01.Name
    $mgmtVM   = $profiles.MGMT01.Name
    $domainDN = "DC=$($SSWConfig.DomainName -replace '\.', ',DC=')"

    # ── Stap 1: AD DS forest op DC01 ────────────────────────
    Write-Log "${pre}Stap 1: DC01 — AD DS forest informatie"
    $progress.Value = 16
    if ($isDry) {
        Write-Log "${pre}  Get-ADForest | Select-Object Name, ForestMode, Domains, GlobalCatalogs"
        Write-Log "${pre}  Get-ADDomain | Select-Object Name, DomainMode, PDCEmulator, RIDMaster"
        Write-Log "${pre}  Get-ADUser -Filter * -SearchBase '$domainDN' | Measure-Object | Select-Object Count"
        Write-Log "${pre}  Get-ADGroup -Filter * | Measure-Object | Select-Object Count"
    } else {
        try {
            $cred = Get-Credential -Message "Domain admin voor $dcVM" -UserName "$($SSWConfig.DomainNetBIOS)\$($SSWConfig.AdminUser)"
            $forestInfo = Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                $f = Get-ADForest; $d = Get-ADDomain
                [PSCustomObject]@{
                    ForestName   = $f.Name; ForestMode = $f.ForestMode
                    DomainMode   = $d.DomainMode; PDCEmulator = $d.PDCEmulator
                    UserCount    = (Get-ADUser -Filter * | Measure-Object).Count
                    GroupCount   = (Get-ADGroup -Filter * | Measure-Object).Count
                    ComputerCount = (Get-ADComputer -Filter * | Measure-Object).Count
                }
            }
            Write-Log "  Forest: $($forestInfo.ForestName) [$($forestInfo.ForestMode)]"
            Write-Log "  PDC Emulator: $($forestInfo.PDCEmulator)"
            Write-Log "  Gebruikers: $($forestInfo.UserCount) | Groepen: $($forestInfo.GroupCount) | Computers: $($forestInfo.ComputerCount)"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: Azure AD Connect status op MGMT01 ───────────
    Write-Log "${pre}Stap 2: MGMT01 — Azure AD Connect sync status"
    $progress.Value = 32
    if ($isDry) {
        Write-Log "${pre}  Get-ADSyncScheduler | Select-Object SyncCycleEnabled, NextSyncCyclePolicyType, NextSyncCycleStartTimeInUTC"
        Write-Log "${pre}  Get-ADSyncConnector | Select-Object Name, ConnectorTypeName, Enabled | Format-Table"
        Write-Log "${pre}  Get-ADSyncRunProfileResult -ConnectorName '<name>' | Select-Object -First 5 | Format-Table"
    } else {
        try {
            $mgmtCred = Get-Credential -Message "Admin credentials voor $mgmtVM" -UserName "$mgmtVM\$($SSWConfig.AdminUser)"
            $syncStatus = Invoke-Command -VMName $mgmtVM -Credential $mgmtCred -ScriptBlock {
                try {
                    $sched = Get-ADSyncScheduler
                    $conn  = Get-ADSyncConnector | Where-Object { $_.ConnectorTypeName -eq "Extensible2" }
                    [PSCustomObject]@{
                        SyncEnabled  = $sched.SyncCycleEnabled
                        NextSync     = $sched.NextSyncCycleStartTimeInUTC
                        PolicyType   = $sched.NextSyncCyclePolicyType
                        ConnectorName = if ($conn) { $conn.Name } else { "Niet gevonden" }
                    }
                } catch { [PSCustomObject]@{ Error = $_.Exception.Message } }
            }
            if ($syncStatus.Error) { Write-Log "  AAD Connect module niet beschikbaar: $($syncStatus.Error)" }
            else {
                Write-Log "  Sync ingeschakeld: $($syncStatus.SyncEnabled)"
                Write-Log "  Volgende sync: $($syncStatus.NextSync) [$($syncStatus.PolicyType)]"
                Write-Log "  Connector: $($syncStatus.ConnectorName)"
            }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: Delta sync uitvoeren ────────────────────────
    Write-Log "${pre}Stap 3: MGMT01 — Delta synchronisatie uitvoeren"
    $progress.Value = 50
    if ($isDry) {
        Write-Log "${pre}  Start-ADSyncSyncCycle -PolicyType Delta"
        Write-Log "${pre}  # Wachten tot sync klaar: Get-ADSyncScheduler | Select-Object SyncCycleInProgress"
    } else {
        try {
            $syncResult = Invoke-Command -VMName $mgmtVM -Credential $mgmtCred -ScriptBlock {
                try {
                    Start-ADSyncSyncCycle -PolicyType Delta
                    Start-Sleep -Seconds 5
                    $scheduler = Get-ADSyncScheduler
                    [PSCustomObject]@{ Started = $true; InProgress = $scheduler.SyncCycleInProgress }
                } catch { [PSCustomObject]@{ Started = $false; Error = $_.Exception.Message } }
            }
            if ($syncResult.Started) { Write-Log "  Delta sync gestart. Bezig: $($syncResult.InProgress)" }
            else { Write-Log "  Sync niet gestart: $($syncResult.Error)" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 4: Gesynchroniseerde gebruikers via Graph ───────
    Write-Log "${pre}Stap 4: Graph — gesynchroniseerde gebruikers tellen"
    $progress.Value = 68
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'User.Read.All'"
        Write-Log "${pre}  Get-MgUser -Filter 'onPremisesSyncEnabled eq true' -All | Measure-Object"
        Write-Log "${pre}  Get-MgUser -Filter 'onPremisesSyncEnabled eq true' -Top 5 | Select-Object DisplayName, UserPrincipalName, AccountEnabled"
    } else {
        try {
            Connect-MgGraph -Scopes "User.Read.All" -ErrorAction Stop | Out-Null
            $syncedUsers = Get-MgUser -Filter "onPremisesSyncEnabled eq true" -All
            Write-Log "  Gesynchroniseerde gebruikers: $($syncedUsers.Count)"
            $syncedUsers | Select-Object -First 5 | ForEach-Object { Write-Log "  $($_.UserPrincipalName) [$($_.AccountEnabled)]" }
        } catch { Write-Log "  Fout (Graph): $_" }
    }

    # ── Stap 5: Entra audit logs ─────────────────────────────
    Write-Log "${pre}Stap 5: Manueel — Entra ID audit logs bekijken"
    $progress.Value = 84
    Write-Log "  URL: https://entra.microsoft.com"
    Write-Log "  Navigeer naar: Identity > Monitoring & health > Audit logs"
    Write-Log "  Filter: Service = Azure AD Connect | Datum = afgelopen 24 uur"
    Write-Log "  Bekijk de sync-activiteiten in de audit log"
    Write-Log "  Sign-in logs: Identity > Monitoring > Sign-in logs"
    Write-Log "  Filter op: Status = Failure → bekijk de foutcode en reden"

    $progress.Value = 100; Write-Log ""; Write-Log "Week 1 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen Azure AD Connect en Azure AD Connect cloud sync?"
    Write-Log "2. Welke attributen worden standaard gesynchroniseerd met Azure AD Connect?"
    Write-Log "3. Wat is Password Hash Sync vs. Pass-through Authentication vs. Federation?"
    Write-Log "4. Hoe herstel je van een mislukte sync (AADConnect troubleshooting stappen)?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week2-external-identities.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week2-external-identities.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null
