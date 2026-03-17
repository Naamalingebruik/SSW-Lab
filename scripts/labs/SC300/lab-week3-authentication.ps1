#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/SC300/lab-week3-authentication.ps1
# SC-300 Week 3 — Authenticatiemethoden: MFA, FIDO2, Windows Hello, SSPR
# VMs:  SSW-W11-01 (WHfB demonstratie)
# Cloud: Entra ID authenticatiemethoden beheer
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SC-300 | Week 3 — Authenticatiemethoden" Height="720" Width="700"
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
      <TextBlock Text="SC-300 | Week 3 — Authenticatiemethoden" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="MFA · SSPR · FIDO2 · Windows Hello for Business · Authentication Strength" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Graph: Authentication Methods Policy ophalen"/>
        <LineBreak/><Run Text="2. SSPR configureren en testen"/>
        <LineBreak/><Run Text="3. FIDO2 inschakelen in authenticatiemethoden beleid"/>
        <LineBreak/><Run Text="4. Windows Hello for Business status controleren op W11-01"/>
        <LineBreak/><Run Text="5. Authentication Strength aanmaken (Phishing-resistant MFA)"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 4 >" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text = "Dry Run — geen beleid wordt aangepast"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — authenticatiemethoden worden aangepast in Entra ID"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Wijzigingen zijn tenant-breed — ga voorzichtig te werk"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
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
    $w11VM    = $profiles."W11-01".Name

    # ── Stap 1: Authentication Methods Policy via Graph ──────
    Write-Log "${pre}Stap 1: Graph — Authentication Methods Policy"
    $progress.Value = 16
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'Policy.Read.All','Policy.ReadWrite.AuthenticationMethod'"
        Write-Log "${pre}  Invoke-MgGraphRequest -Method GET -Uri '/beta/policies/authenticationMethodsPolicy'"
        Write-Log "${pre}  # Toont alle ingeschakelde methoden: SMS, Voice, TOTP, FIDO2, Authenticator, etc."
    } else {
        try {
            Connect-MgGraph -Scopes "Policy.Read.All", "Policy.ReadWrite.AuthenticationMethod" -ErrorAction Stop | Out-Null
            $policy = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy"
            Write-Log "  Authenticatiemethoden (ingeschakeld):"
            foreach ($method in $policy.authenticationMethodConfigurations) {
                if ($method.state -eq "enabled") { Write-Log "  [ON]  $($method.id)" }
                else { Write-Log "  [OFF] $($method.id)" }
            }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: SSPR configureren ────────────────────────────
    Write-Log "${pre}Stap 2: SSPR — Self-Service Password Reset"
    $progress.Value = 32
    Write-Log "  Entra portal > Protection > Password reset"
    Write-Log "  Self service password reset enabled: Kies 'Selected' (niet All)"
    Write-Log "  Groep: SG-SSPR (maak aan via Entra > Groups)"
    Write-Log "  Methoden vereist: 2 | Methoden: Email + Mobile app notification"
    Write-Log "  Registration: Vereist bij volgende aanmelding — Duration: 180 dagen"
    Write-Log "  Notifications: Notify users and admins on password reset"
    Write-Log "  Test: Meld aan als testuser01 op https://aka.ms/sspr"

    # ── Stap 3: FIDO2 inschakelen ────────────────────────────
    Write-Log "${pre}Stap 3: FIDO2 security keys inschakelen"
    $progress.Value = 50
    if ($isDry) {
        Write-Log "${pre}  `$body = @{ state = 'enabled'; includeTargets = @(@{ targetType = 'group'; id = 'all_users'; isRegistrationRequired = `$false }) }"
        Write-Log "${pre}  Invoke-MgGraphRequest -Method PATCH -Uri '/beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/Fido2' -Body (`$body | ConvertTo-Json)"
    } else {
        try {
            $body = @{
                "@odata.type" = "#microsoft.graph.fido2AuthenticationMethodConfiguration"
                state         = "enabled"
                isAttestationEnforced = $false
                isSelfServiceRegistrationAllowed = $true
                includeTargets = @(@{ targetType = "group"; id = "all_users"; isRegistrationRequired = $false })
            }
            Invoke-MgGraphRequest -Method PATCH -Uri "https://graph.microsoft.com/beta/policies/authenticationMethodsPolicy/authenticationMethodConfigurations/Fido2" -Body ($body | ConvertTo-Json -Depth 5) -ContentType "application/json" | Out-Null
            Write-Log "  FIDO2 ingeschakeld voor alle gebruikers"
        } catch { Write-Log "  Fout (of al ingeschakeld): $_" }
    }

    # ── Stap 4: Windows Hello for Business op W11-01 ─────────
    Write-Log "${pre}Stap 4: W11-01 — Windows Hello for Business status"
    $progress.Value = 68
    if ($isDry) {
        Write-Log "${pre}  Get-MgUserAuthenticationWindowsHelloForBusinessMethod -UserId 'testuser01@<tenant>'"
        Write-Log "${pre}  # Op W11-01 als gebruiker: certutil -store -user 'MY' | findstr 'Smart Card'"
        Write-Log "${pre}  dsregcmd /status | Select-String 'WindowsHelloForBusiness'"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $w11VM" -UserName "$w11VM\$($SSWConfig.AdminUser)"
            $whfbStatus = Invoke-Command -VMName $w11VM -Credential $cred -ScriptBlock {
                $dsreg = dsregcmd /status 2>&1
                $whfb  = ($dsreg | Where-Object { $_ -match "WindowsHelloForBusiness" }) -join "`n"
                $azureJoined = ($dsreg | Where-Object { $_ -match "AzureAdJoined" }) -join ""
                [PSCustomObject]@{ WHfBInfo = $whfb; AzureJoined = $azureJoined }
            }
            Write-Log "  Azure AD Joined: $($whfbStatus.AzureJoined)"
            Write-Log "  $($whfbStatus.WHfBInfo)"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 5: Authentication Strength ─────────────────────
    Write-Log "${pre}Stap 5: Authentication Strength — Phishing-resistant MFA"
    $progress.Value = 84
    Write-Log "  Entra portal > Protection > Authentication methods > Authentication strengths"
    Write-Log "  + New authentication strength"
    Write-Log "  Naam: 'Phishing-resistant MFA'"
    Write-Log "  Selecteer: Windows Hello for Business, FIDO2 security key, Certificate-based authentication"
    Write-Log "  Gebruik in Conditional Access policy als 'Grant access - Require auth strength'"
    if ($isDry) {
        Write-Log "${pre}  # Via Graph API (beta):"
        Write-Log "${pre}  POST /identity/conditionalAccess/authenticationStrength/policies"
        Write-Log "${pre}  Body: { displayName: 'Phishing-resistant MFA', allowedCombinations: ['fido2', 'windowsHelloForBusiness'] }"
    } else {
        $open = [System.Windows.MessageBox]::Show("Entra portal openen (Authentication strengths)?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://entra.microsoft.com/#view/Microsoft_AAD_IAM/AuthenticationMethodsMenuBlade/~/AuthStrengths" }
    }

    $progress.Value = 100; Write-Log ""; Write-Log "Week 3 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat onderscheidt FIDO2 van een TOTP authenticator-app?"
    Write-Log "2. Hoe werkt de verificatieregistratiestroom voor SSPR?"
    Write-Log "3. Wat is Temporary Access Pass (TAP) en wanneer gebruik je het?"
    Write-Log "4. Hoe werkt Windows Hello for Business met Entra ID Join (Cloud Trust)?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week4-conditional-access.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week4-conditional-access.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null


