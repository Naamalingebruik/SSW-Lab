#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MS102/lab-week4-exchange.ps1
# MS-102 Week 4 — Exchange Online beheer
# Cloud: Exchange admin center, Exchange Online PowerShell
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MS-102 | Week 4 — Exchange Online beheer" Height="700" Width="700"
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
      <TextBlock Text="MS-102 | Week 4 — Exchange Online beheer" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Mailboxen · Distribution lists · Mail flow rules · Anti-spam · DKIM" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Exchange Online PowerShell verbinden en mailboxen opvragen"/>
        <LineBreak/><Run Text="2. Shared mailbox aanmaken via PowerShell"/>
        <LineBreak/><Run Text="3. Distribution group aanmaken"/>
        <LineBreak/><Run Text="4. Mail flow rule: voeg disclaimer toe aan uitgaande mail"/>
        <LineBreak/><Run Text="5. Message trace uitvoeren"/>
        <LineBreak/><Run Text="6. Manueel: DKIM en DMARC controleren"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 5 >" Style="{StaticResource Btn}"
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
        $dryRunSub.Text = "Haal het vinkje weg om Exchange Online te verbinden"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — verbinding met Exchange Online wordt gemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
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

    # ── Stap 1: Module check en verbinding ───────────────────
    Write-Log "${pre}Stap 1: Exchange Online PowerShell verbinden"
    $progress.Value = 14
    $exoInstalled = Get-Module -ListAvailable -Name ExchangeOnlineManagement -ErrorAction SilentlyContinue
    if ($isDry) {
        Write-Log "${pre}  Install-Module ExchangeOnlineManagement  (als niet aanwezig)"
        Write-Log "${pre}  Connect-ExchangeOnline -UserPrincipalName admin@<tenant>.onmicrosoft.com"
        Write-Log "${pre}  Get-Mailbox | Select-Object DisplayName, PrimarySmtpAddress, MailboxType | Sort-Object DisplayName"
    } else {
        if (-not $exoInstalled) {
            Write-Log "  ExchangeOnlineManagement module niet gevonden"
            $install = [System.Windows.MessageBox]::Show(
                "ExchangeOnlineManagement module installeren?", "SSW-Lab", "YesNo", "Question")
            if ($install -eq "Yes") {
                try { Install-Module ExchangeOnlineManagement -Scope CurrentUser -Force; Write-Log "  Module geinstalleerd" }
                catch { Write-Log "  Installatie mislukt: $_"; $btnRun.IsEnabled = $true; return }
            } else { Write-Log "  Overgeslagen"; $btnRun.IsEnabled = $true; return }
        }
        try {
            Import-Module ExchangeOnlineManagement -ErrorAction Stop
            Connect-ExchangeOnline -ShowBanner:$false -ErrorAction Stop
            Write-Log "  Verbonden met Exchange Online"
        } catch { Write-Log "  Verbinding mislukt: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: Mailboxen opvragen ───────────────────────────
    Write-Log "${pre}Stap 2: Mailboxen opvragen"
    $progress.Value = 28
    if ($isDry) {
        Write-Log "${pre}  Get-Mailbox | Select-Object DisplayName, MailboxType | Sort-Object DisplayName | Select-Object -First 10"
    } else {
        try {
            $mailboxes = Get-Mailbox | Select-Object DisplayName, MailboxType | Sort-Object DisplayName | Select-Object -First 10
            $mailboxes | ForEach-Object { Write-Log "  $($_.MailboxType.ToString().PadRight(12)) $($_.DisplayName)" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: Shared mailbox aanmaken ─────────────────────
    Write-Log "${pre}Stap 3: Shared mailbox aanmaken (ssw-helpdesk)"
    $progress.Value = 42
    if ($isDry) {
        Write-Log "${pre}  New-Mailbox -Shared -Name 'SSW Helpdesk' -Alias 'ssw-helpdesk'"
        Write-Log "${pre}  Add-MailboxPermission -Identity ssw-helpdesk -User testuser01 -AccessRights FullAccess"
    } else {
        try {
            $existing = Get-Mailbox -Identity "ssw-helpdesk" -ErrorAction SilentlyContinue
            if (-not $existing) {
                New-Mailbox -Shared -Name "SSW Helpdesk" -Alias "ssw-helpdesk" | Out-Null
                Write-Log "  Shared mailbox aangemaakt: ssw-helpdesk"
                Add-MailboxPermission -Identity "ssw-helpdesk" -User "testuser01" -AccessRights FullAccess -ErrorAction SilentlyContinue | Out-Null
                Write-Log "  Full Access toegewezen aan testuser01"
            } else { Write-Log "  Shared mailbox al aanwezig: ssw-helpdesk" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 4: Distribution group ──────────────────────────
    Write-Log "${pre}Stap 4: Distribution group aanmaken (LAB-IT-DL)"
    $progress.Value = 55
    if ($isDry) {
        Write-Log "${pre}  New-DistributionGroup -Name 'LAB IT Distribution' -Alias 'lab-it-dl' -Type Distribution"
        Write-Log "${pre}  Add-DistributionGroupMember -Identity lab-it-dl -Member testuser01"
    } else {
        try {
            $dlExisting = Get-DistributionGroup -Identity "lab-it-dl" -ErrorAction SilentlyContinue
            if (-not $dlExisting) {
                New-DistributionGroup -Name "LAB IT Distribution" -Alias "lab-it-dl" -Type Distribution | Out-Null
                Write-Log "  Distribution group aangemaakt: lab-it-dl"
            } else { Write-Log "  Distribution group al aanwezig" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 5: Mail flow rule ───────────────────────────────
    Write-Log "${pre}Stap 5: Mail flow rule — disclaimer toevoegen"
    $progress.Value = 68
    if ($isDry) {
        Write-Log "${pre}  New-TransportRule -Name 'LAB Disclaimer' -FromScope InOrganization"
        Write-Log "${pre}    -ApplyHtmlDisclaimerLocation Append"
        Write-Log "${pre}    -ApplyHtmlDisclaimerText '<p>Dit bericht is afkomstig van SSW-Lab.</p>'"
    } else {
        try {
            $ruleExists = Get-TransportRule -Identity "LAB Disclaimer" -ErrorAction SilentlyContinue
            if (-not $ruleExists) {
                New-TransportRule -Name "LAB Disclaimer" -FromScope InOrganization `
                    -ApplyHtmlDisclaimerLocation Append `
                    -ApplyHtmlDisclaimerText "<p><i>Dit bericht is afkomstig van LAB-testomgeving.</i></p>" `
                    -ApplyHtmlDisclaimerFallbackAction Wrap | Out-Null
                Write-Log "  Transport rule aangemaakt: LAB Disclaimer"
            } else { Write-Log "  Transport rule al aanwezig" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 6: Message trace & DKIM ────────────────────────
    Write-Log "${pre}Stap 6: Message trace en DKIM controleren"
    $progress.Value = 84
    if ($isDry) {
        Write-Log "${pre}  Get-MessageTrace -SenderAddress testuser01@<tenant> -StartDate (Get-Date).AddDays(-1)"
        Write-Log "${pre}  Get-DkimSigningConfig | Select-Object Domain, Enabled, Status"
        Write-Log "${pre}  EAC: https://admin.exchange.microsoft.com > Mail flow > Message trace"
    } else {
        try {
            $dkim = Get-DkimSigningConfig | Select-Object Domain, Enabled, Status
            Write-Log "  DKIM configuratie:"
            $dkim | ForEach-Object { Write-Log "    $($_.Domain) | Enabled: $($_.Enabled) | Status: $($_.Status)" }
        } catch { Write-Log "  DKIM opvragen mislukt: $_" }
        try { Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue } catch {}
    }

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Browser openen naar Exchange Admin Center?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://admin.exchange.microsoft.com" }
    }

    $progress.Value = 100
    Write-Log ""; Write-Log "Week 4 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen een shared mailbox en een room mailbox?"
    Write-Log "2. Hoe werkt message trace en wanneer gebruik je het?"
    Write-Log "3. Wat doen Safe Attachments en Safe Links in Defender for Office 365?"
    Write-Log "4. Wat is het verschil tussen anti-spam en anti-phishing policies?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week5-sharepoint-teams.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week5-sharepoint-teams.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null
