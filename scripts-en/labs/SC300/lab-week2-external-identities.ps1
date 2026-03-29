#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/SC300/lab-week2-external-identities.ps1
# SC-300 Week 2 — Externe identiteiten: B2B, Cross-tenant, Identity Protection
# Cloud: Entra ID (Azure AD B2B, Identity Protection)
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SC-300 | Week 2 — Externe identiteiten" Height="720" Width="700"
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
      <TextBlock Text="SC-300 | Week 2 — Externe identiteiten" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="B2B-invitations · Cross-tenant access · Identity Protection · Risk policy" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Steps in this lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. B2B-gastuser uitnodigen via Graph (New-MgInvitation)"/>
        <LineBreak/><Run Text="2. Cross-tenant accesssinstellingen bekijken"/>
        <LineBreak/><Run Text="3. Identity Protection — risicopolicy instellen"/>
        <LineBreak/><Run Text="4. Risky users en risky sign-ins bekijken"/>
        <LineBreak/><Run Text="5. Entra ID Protection simulatie (Tor-browser scenario)"/>
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
      <Button x:Name="BtnRun"  Content="Run lab" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="140"/>
      <Button x:Name="BtnNext" Content="Continue to Week 3 >" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text = "Dry Run — geen invitations worden verstuurd"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om LIVE uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — B2B uitnodiging wordt verstuurd naar Entra tenant"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
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

    # ── Stap 1: B2B gastuser uitnodigen ────────────────
    Write-Log "${pre}Stap 1: B2B uitnodiging versturen via Microsoft Graph"
    $progress.Value = 16
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'User.Invite.All','User.ReadWrite.All'"
        Write-Log "${pre}  `$invite = New-MgInvitation -InvitedUserEmailAddress 'gastuser@extern.com' -InviteRedirectUrl 'https://myapps.microsoft.com' -SendInvitationMessage:`$true -InvitedUserDisplayName 'SSW Gast Demo'"
        Write-Log "${pre}  `$invite.InvitedUser.Id  # Guest user object ID"
        Write-Log "${pre}  `$invite.InviteRedeemUrl  # Uitnodigings-URL voor acceptatie"
    } else {
        try {
            Connect-MgGraph -Scopes "User.Invite.All", "User.ReadWrite.All" -ErrorAction Stop | Out-Null
            Write-Log "  Verbonden met Graph. Voer een extern e-mailadres in:"
            $guestEmail = [Microsoft.VisualBasic.Interaction]::InputBox("Voer het e-mailadres in voor de B2B uitnodiging:", "B2B Uitnodiging", "gast@voorbeeld.com")
            if ($guestEmail -and $guestEmail -ne "gast@voorbeeld.com" -and $guestEmail -match "@") {
                $invite = New-MgInvitation -InvitedUserEmailAddress $guestEmail -InviteRedirectUrl "https://myapps.microsoft.com" -SendInvitationMessage:$true -InvitedUserDisplayName "SSW Lab Gast"
                Write-Log "  Uitnodiging verstuurd naar: $guestEmail"
                Write-Log "  Guest user ID: $($invite.InvitedUser.Id)"
                Write-Log "  Status: $($invite.Status)"
            } else { Write-Log "  Geen geldig e-mailadres ingevoerd — stap skipped" }
        } catch { Write-Log "  Error: $_" }
    }

    # ── Stap 2: Cross-tenant access ────────────────────────
    Write-Log "${pre}Stap 2: Cross-tenant accesssinstellingen (manueel)"
    $progress.Value = 32
    Write-Log "  Entra portal > External Identities > Cross-tenant access settings"
    Write-Log "  Default settings tab: bekijk inkomende/uitgaande B2B sync instellingen"
    Write-Log "  Organizational settings: voeg een specifieke tenant toe (deny/allow)"
    Write-Log "  TIP: schakel 'Trust MFA from external tenants' in voor partners"
    Write-Log "  URL: https://entra.microsoft.com/#view/Microsoft_AAD_IAM/CompanyRelationshipsMenuBlade"

    # ── Stap 3: Identity Protection risicopolicy ─────────────
    Write-Log "${pre}Stap 3: Identity Protection — risicopolicy configureren"
    $progress.Value = 50
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess'"
        Write-Log "${pre}  # Identity Protection policies zijn alleen via Entra portal te beheren"
        Write-Log "${pre}  # URL: Entra portal > Protection > Identity Protection > User risk policy"
    }
    Write-Log "  Entra portal > Protection > Identity Protection"
    Write-Log "  User risk policy:"
    Write-Log "    Assignments: All users"
    Write-Log "    User risk level: High"
    Write-Log "    Access: Require password change"
    Write-Log "  Sign-in risk policy:"
    Write-Log "    Sign-in risk level: Medium and above"
    Write-Log "    Access: Require MFA"
    Write-Log "    Zet policy op: Report-only (veilig voor lab)"

    # ── Stap 4: Risky users en sign-ins ─────────────────────
    Write-Log "${pre}Stap 4: Graph — risky users opvragen"
    $progress.Value = 68
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'IdentityRiskyUser.Read.All'"
        Write-Log "${pre}  Get-MgRiskyUser -Filter 'riskLevel eq `"high`"' | Select-Object UserPrincipalName, RiskLevel, RiskState, RiskLastUpdatedDateTime"
        Write-Log "${pre}  Get-MgAuditLogSignIn -Filter 'riskLevelDuringSignIn ne `"none`"' -Top 10 | Select-Object UserPrincipalName, RiskLevelDuringSignIn, Status"
    } else {
        try {
            Connect-MgGraph -Scopes "IdentityRiskyUser.Read.All", "AuditLog.Read.All" -ErrorAction Stop | Out-Null
            $riskyUsers = Get-MgRiskyUser -Filter "riskState eq 'atRisk'" -ErrorAction SilentlyContinue
            if ($riskyUsers) {
                Write-Log "  Users met risiconiveau:"
                $riskyUsers | ForEach-Object { Write-Log "  $($_.UserPrincipalName) — Risico: $($_.RiskLevel) [$($_.RiskState)]" }
            } else { Write-Log "  Geen risicousers gevonden (normaal in schone tenant)" }
        } catch { Write-Log "  Error (Entra P2 required): $_" }
    }

    # ── Stap 5: Simulatie / portal ───────────────────────────
    Write-Log "${pre}Stap 5: Manual — Identity Protection simulatie"
    $progress.Value = 84
    Write-Log "  Entra portal > Protection > Identity Protection > Risky users"
    Write-Log "  Klik op een user > Confirm user compromised (test)"
    Write-Log "  Bekijk hoe de risk state verandert naar 'Confirmed compromised'"
    Write-Log "  Daarna: Dismiss user risk (reset)"
    Write-Log "  Risky sign-ins bekijken: Identity Protection > Risky sign-ins"
    Write-Log "  Bekijk: IP, locatie, risicoreden, detectietype"

    $progress.Value = 100; Write-Log ""; Write-Log "Week 2 lab completed."; Write-Log ""
    Write-Log "━━━ KNOWLEDGE CHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen een B2B gastuser en een B2C user?"
    Write-Log "2. Welke Entra ID licentie is vereist voor Identity Protection?"
    Write-Log "3. Hoe werkt de 'Confirm user compromised' actie in Identity Protection?"
    Write-Log "4. Wat is het verschil tussen User risk en Sign-in risk?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week3-authentication.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week3-authentication.ps1 not found.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null






