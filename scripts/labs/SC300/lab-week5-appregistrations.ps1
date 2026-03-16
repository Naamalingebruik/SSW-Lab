#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/SC300/lab-week5-appregistrations.ps1
# SC-300 Week 5 — App Registrations, App Proxy, OAuth2, Managed Identity
# Cloud: Entra ID — app registraties, API-machtigingen, enterprise apps
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="SC-300 | Week 5 — App Registrations en App Proxy" Height="720" Width="700"
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
      <TextBlock Text="SC-300 | Week 5 — App Registrations en App Proxy" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="App registratie · API-rechten · Client secret · App Proxy · Managed Identity" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. App registratie aanmaken via Graph"/>
        <LineBreak/><Run Text="2. API-machtigingen toevoegen (Graph + Exchange)"/>
        <LineBreak/><Run Text="3. Client secret aanmaken en testen met token-aanvraag"/>
        <LineBreak/><Run Text="4. Enterprise app en consent bekijken"/>
        <LineBreak/><Run Text="5. App Proxy connector info (manueel portal)"/>
      </TextContent>
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
        $dryRunTitle.Text = "Dry Run — geen app-registratie wordt aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om LIVE te registreren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — app-registratie en client secret worden aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Sla client secret veilig op — eenmalig zichtbaar!"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({ Update-DryRunBar }); $chkDryRun.Add_Unchecked({ Update-DryRunBar })
function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }

    # ── Stap 1: App registratie aanmaken ─────────────────────
    Write-Log "${pre}Stap 1: App registratie aanmaken (SSW-Lab-App)"
    $progress.Value = 16
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'Application.ReadWrite.All'"
        Write-Log "${pre}  New-MgApplication -DisplayName 'SSW-Lab-App' -SignInAudience 'AzureADMyOrg'"
        Write-Log "${pre}  `$app.AppId  # Application (client) ID"
        Write-Log "${pre}  `$app.Id     # Object ID"
    } else {
        try {
            Connect-MgGraph -Scopes "Application.ReadWrite.All", "AppRoleAssignment.ReadWrite.All" -ErrorAction Stop | Out-Null
            $existingApp = Get-MgApplication -Filter "displayName eq 'SSW-Lab-App'" -ErrorAction SilentlyContinue
            if (-not $existingApp) {
                $app = New-MgApplication -DisplayName "SSW-Lab-App" -SignInAudience "AzureADMyOrg"
                Write-Log "  App aangemaakt: SSW-Lab-App"
                Write-Log "  App ID (client): $($app.AppId)"
                Write-Log "  Object ID: $($app.Id)"
                $script:appId = $app.AppId
                $script:appObjectId = $app.Id
            } else {
                Write-Log "  App bestaat al: $($existingApp.DisplayName)"
                Write-Log "  App ID (client): $($existingApp.AppId)"
                $script:appId = $existingApp.AppId
                $script:appObjectId = $existingApp.Id
            }
        } catch { Write-Log "  Fout: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: API-machtigingen toevoegen ───────────────────
    Write-Log "${pre}Stap 2: API-machtigingen toevoegen (User.Read + Mail.Read)"
    $progress.Value = 32
    if ($isDry) {
        Write-Log "${pre}  # Microsoft Graph API (00000003-0000-0000-c000-000000000000)"
        Write-Log "${pre}  # User.Read = e1fe6dd8-ba31-4d61-89e7-88639da4683d (delegated)"
        Write-Log "${pre}  # Mail.Read = 570282fd-fa5c-430d-a7fd-fc8dc98a9dca (delegated)"
        Write-Log "${pre}  `$requiredAccess = @{ resourceAppId = '00000003-0000-0000-c000-000000000000'; resourceAccess = @(@{id='e1fe6dd8-ba31-4d61-89e7-88639da4683d'; type='Scope'},@{id='570282fd-fa5c-430d-a7fd-fc8dc98a9dca';type='Scope'}) }"
        Write-Log "${pre}  Update-MgApplication -ApplicationId `$app.Id -RequiredResourceAccess @(`$requiredAccess)"
    } else {
        try {
            $requiredAccess = @{
                ResourceAppId = "00000003-0000-0000-c000-000000000000"
                ResourceAccess = @(
                    @{ Id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"; Type = "Scope" }  # User.Read
                    @{ Id = "570282fd-fa5c-430d-a7fd-fc8dc98a9dca"; Type = "Scope" }  # Mail.Read
                )
            }
            Update-MgApplication -ApplicationId $script:appObjectId -RequiredResourceAccess @($requiredAccess)
            Write-Log "  API-machtigingen toegevoegd: User.Read + Mail.Read (delegated)"
            Write-Log "  Admin consent vereist in Entra portal voor tenant-brede toegang"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: Client secret aanmaken ───────────────────────
    Write-Log "${pre}Stap 3: Client secret aanmaken (geldigheid 1 jaar)"
    $progress.Value = 50
    if ($isDry) {
        Write-Log "${pre}  `$secretParam = @{ displayName = 'LabSecret'; endDateTime = (Get-Date).AddYears(1) }"
        Write-Log "${pre}  `$secret = Add-MgApplicationPassword -ApplicationId `$app.Id -PasswordCredential `$secretParam"
        Write-Log "${pre}  `$secret.SecretText  # EENMALIG ZICHTBAAR — sla dit direct op!"
        Write-Log "${pre}  # Token aanvragen voor test:"
        Write-Log "${pre}  `$body = @{ grant_type='client_credentials'; client_id=`$appId; client_secret=`$secret; scope='https://graph.microsoft.com/.default' }"
        Write-Log "${pre}  Invoke-RestMethod -Uri 'https://login.microsoftonline.com/<tenantId>/oauth2/v2.0/token' -Method Post -Body `$body"
    } else {
        try {
            $secretParam = @{ DisplayName = "LabSecret"; EndDateTime = (Get-Date).AddYears(1) }
            $secret = Add-MgApplicationPassword -ApplicationId $script:appObjectId -PasswordCredential $secretParam
            Write-Log "  Client secret aangemaakt: LabSecret"
            Write-Log "  SECRET (sla dit op, eenmalig zichtbaar!):"
            Write-Log "  $($secret.SecretText)"
            Write-Log "  Vervalt: $($secret.EndDateTime)"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 4: Enterprise app consent ───────────────────────
    Write-Log "${pre}Stap 4: Manueel — Enterprise app en consent bekijken"
    $progress.Value = 68
    Write-Log "  Entra portal > Applications > Enterprise applications > SSW-Lab-App"
    Write-Log "  Permissions tab > Grant admin consent for <tenant>"
    Write-Log "  Bekijk de verleende machtigingen (consent)"
    Write-Log "  Users and groups tab: wijs een testgebruiker toe aan de app"
    Write-Log "  Single sign-on tab: bekijk de configuratie-opties (SAML, OIDC)"

    # ── Stap 5: App Proxy ────────────────────────────────────
    Write-Log "${pre}Stap 5: Manueel — App Proxy connector bekijken"
    $progress.Value = 84
    Write-Log "  Entra portal > Applications > Enterprise applications > Application proxy"
    Write-Log "  Vereiste: Entra Application Proxy Connector op MGMT01 installeren"
    Write-Log "  Download: https://aka.ms/aadappproxy"
    Write-Log "  Connector installeert als Windows service: WAPCSvc"
    Write-Log "  Na installatie: nieuwe connector verschijnt in portal"
    Write-Log "  + Configure an app: stel intern ULR en externe URL in"
    Write-Log "  Intern URL: http://mgmt01.ssw.lab/intranet"
    Write-Log "  Extern URL: https://sswlab-intranet.<tenant>.msappproxy.net"
    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Entra portal openen (App Proxy)?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://entra.microsoft.com/#view/Microsoft_AAD_IAM/StartboardApplicationsMenuBlade/~/AppProxy" }
    }

    $progress.Value = 100; Write-Log ""; Write-Log "Week 5 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen Delegated permissions en Application permissions?"
    Write-Log "2. Wanneer is Admin consent vereist voor API-machtigingen?"
    Write-Log "3. Hoe werkt de OAuth2 authorization code flow met PKCE?"
    Write-Log "4. Welk voordeel heeft een Managed Identity boven een client secret?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week6-governance-pim.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week6-governance-pim.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null
