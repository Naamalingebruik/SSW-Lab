# ============================================================
# SSW-Lab | labs/MS102/lab-week5-sharepoint-teams.ps1
# MS-102 Week 5 — SharePoint Online en Microsoft Teams
# Cloud: SharePoint admin center, Teams admin center
# Geen lokale admin vereist — puur cloud
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MS-102 | Week 5 — SharePoint Online en Microsoft Teams" Height="700" Width="700"
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
      <TextBlock Text="MS-102 | Week 5 — SharePoint Online en Teams" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Sitecollecties · Externe deling · Teams policies · Usage reports" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. SharePoint Online PowerShell: sitecollecties opvragen"/>
        <LineBreak/><Run Text="2. Manueel: maak een Team site aan in SharePoint admin center"/>
        <LineBreak/><Run Text="3. Manueel: configureer externe delingsinstellingen"/>
        <LineBreak/><Run Text="4. Teams PowerShell: Teams en leden opvragen"/>
        <LineBreak/><Run Text="5. Manueel: Teams Meetings policy aanpassen"/>
        <LineBreak/><Run Text="6. Manueel: bekijk Teams usage reports in M365 admin center"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 6 >" Style="{StaticResource Btn}"
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
        $dryRunSub.Text = "Haal het vinkje weg om SharePoint/Teams te verbinden"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — verbinding met SharePoint en Teams wordt gemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
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

    # ── Stap 1: SharePoint Online module ────────────────────
    Write-Log "${pre}Stap 1: SharePoint Online PowerShell"
    $progress.Value = 14
    $spoInstalled = Get-Module -ListAvailable -Name Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue
    if ($isDry) {
        Write-Log "${pre}  Install-Module Microsoft.Online.SharePoint.PowerShell  (indien nodig)"
        Write-Log "${pre}  Connect-SPOService -Url https://<tenant>-admin.sharepoint.com"
        Write-Log "${pre}  Get-SPOSite | Select-Object Url, StorageUsageCurrent, SharingCapability"
    } else {
        if (-not $spoInstalled) {
            Write-Log "  SPO module niet gevonden — installeer met:"
            Write-Log "  Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser"
        } else {
            try {
                Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
                $tenantUrl = Read-Host "Voer je SharePoint tenant URL in (bijv. https://contoso-admin.sharepoint.com)"
                Connect-SPOService -Url $tenantUrl -ErrorAction Stop
                $sites = Get-SPOSite | Select-Object Url, StorageUsageCurrent | Select-Object -First 8
                Write-Log "  Sitecollecties (top 8):"
                $sites | ForEach-Object { Write-Log "    $($_.Url) ($($_.StorageUsageCurrent) MB)" }
            } catch { Write-Log "  Fout: $_" }
        }
    }

    # ── Stap 2: Team site aanmaken (manueel) ─────────────────
    Write-Log "${pre}Stap 2: Manueel — Team site aanmaken"
    $progress.Value = 28
    Write-Log "  SharePoint admin center: https://admin.microsoft.com > SharePoint"
    Write-Log "  Sites > Active sites > + Create > Team site"
    Write-Log "  Naam: SSW Lab Site | Eigenaar: testuser01@<tenant>"
    Write-Log "  Voeg testuser02 toe als site-lid"

    # ── Stap 3: Externe deling ───────────────────────────────
    Write-Log "${pre}Stap 3: Manueel — externe delingsinstellingen"
    $progress.Value = 40
    Write-Log "  SharePoint admin center > Policies > Sharing"
    Write-Log "  Stel tenant-niveau in op: New and existing guests"
    Write-Log "  Site-niveau voor SSW Lab Site: Existing guests only"
    Write-Log "  Test: upload document > Delen > voer extern emailadres in"

    # ── Stap 4: Teams PowerShell ─────────────────────────────
    Write-Log "${pre}Stap 4: Microsoft Teams PowerShell"
    $progress.Value = 54
    $teamsInstalled = Get-Module -ListAvailable -Name MicrosoftTeams -ErrorAction SilentlyContinue
    if ($isDry) {
        Write-Log "${pre}  Install-Module MicrosoftTeams  (indien nodig)"
        Write-Log "${pre}  Connect-MicrosoftTeams"
        Write-Log "${pre}  Get-Team | Select-Object DisplayName, Visibility, GuestSettings"
        Write-Log "${pre}  New-Team -DisplayName 'SSW Lab Team' -Visibility Private"
    } else {
        if (-not $teamsInstalled) {
            Write-Log "  MicrosoftTeams module niet gevonden — installeer met:"
            Write-Log "  Install-Module MicrosoftTeams -Scope CurrentUser"
        } else {
            try {
                Import-Module MicrosoftTeams -ErrorAction Stop
                Connect-MicrosoftTeams -ErrorAction Stop
                $teams = Get-Team | Select-Object DisplayName, Visibility | Select-Object -First 8
                Write-Log "  Teams (top 8):"
                $teams | ForEach-Object { Write-Log "    $($_.DisplayName) [$($_.Visibility)]" }
            } catch { Write-Log "  Fout: $_" }
        }
    }

    # ── Stap 5: Teams Meeting policy ─────────────────────────
    Write-Log "${pre}Stap 5: Manueel — Teams Meetings policy"
    $progress.Value = 70
    Write-Log "  Teams admin center: https://admin.teams.microsoft.com"
    Write-Log "  Meetings > Meeting policies > Global (Org-wide default)"
    Write-Log "  Wijzig: Allow cloud recording = Off voor gasten"
    Write-Log "  Of: maak een custom policy voor externe gebruikers"

    # ── Stap 6: Usage reports ────────────────────────────────
    Write-Log "${pre}Stap 6: Manueel — Usage reports bekijken"
    $progress.Value = 86
    Write-Log "  M365 admin center > Reports > Usage"
    Write-Log "  Selecteer: Microsoft Teams activity"
    Write-Log "  Bekijk: Active users, Messages, Meetings"
    Write-Log "  Teams admin center > Analytics & reports > Usage reports"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Browser openen naar M365 Usage Reports?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://admin.microsoft.com/AdminPortal/Home#/reportsUsage/TeamsUserActivity" }
    }

    $progress.Value = 100; Write-Log ""; Write-Log "Week 5 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen een Group site, Communication site en Hub site?"
    Write-Log "2. Hoe beheer je externe toegang in Teams op channel-niveau versus team-niveau?"
    Write-Log "3. Wat zijn sensitivity labels en hoe pas je ze toe op Teams en SharePoint?"
    Write-Log "4. Hoe gebruik je PowerShell (PnP / Teams module) voor bulk-beheer?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week6-defender.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week6-defender.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null


