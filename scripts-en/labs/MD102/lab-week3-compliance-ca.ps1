#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | MD-102 | Week 3 — Compliance, Conditional Access en identiteit
# Doel: Test-users in AD, Azure AD Connect, CA-policy, compliance
# VMs:  SSW-DC01, SSW-MGMT01, SSW-W11-01, SSW-W11-02
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MD-102 | Week 3 — Compliance en Conditional Access" Height="720" Width="700"
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
      <TextBlock Text="MD-102 | Week 3 — Compliance en Conditional Access" Foreground="#CDD6F4" FontSize="17" FontWeight="SemiBold"/>
      <TextBlock Text="AD-gebruikers, Azure AD Connect sync, CA-policy, compliance policy" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap">
        <Run Text="1. DC01: maak TestUser01 en TestUser02 aan in AD"/>
        <LineBreak/><Run Text="2. DC01: controleer/start Azure AD Connect sync"/>
        <LineBreak/><Run Text="3. MGMT01: instructies CA-policy (MFA buiten netwerk)"/>
        <LineBreak/><Run Text="4. MGMT01: instructies compliance policy (Defender + BitLocker + min. W11 22H2)"/>
        <LineBreak/><Run Text="5. W11-02: controleer niet-compliant status"/>
        <LineBreak/><Run Text="6. Kennischeckvragen"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 4 →" Style="{StaticResource Btn}"
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
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24"); $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text = "Dry Run — geen wijzigingen"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om daadwerkelijk te verbinden"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — wijzigingen worden doorgevoerd in DC01"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Zet het vinkje terug om naar Dry Run te gaan"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({   Update-DryRunBar })
$chkDryRun.Add_Unchecked({ Update-DryRunBar })

function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

function Write-KennisCheck {
    Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Welke signalen gebruikt Conditional Access voor een access-beslissing?"
    Write-Log "2. Wat is het verschil tussen Block en Grant with controls in CA?"
    Write-Log "3. Hoe verhoudt Azure AD Connect Sync zich tot Cloud Sync?"
    Write-Log "4. Wat doet de Named Locations instelling in CA?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry    = $chkDryRun.IsChecked
    $pre      = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $dcVM     = $profiles.DC01.Name
    $w11bVM   = $profiles."W11-02".Name
    $domain   = $SSWConfig.DomainName

    # ── Stap 1: DC01 — Maak testgebruikers aan ───────────────
    Write-Log "${pre}Stap 1: DC01 — TestUser01 en TestUser02 aanmaken"
    $progress.Value = 15
    if ($isDry) {
        Write-Log "${pre}  New-ADUser -Name 'TestUser01' -SamAccountName testuser01 -UserPrincipalName testuser01@$domain"
        Write-Log "${pre}             -AccountPassword (Read-Host -AsSecureString) -Enabled `$true -Path 'CN=Users,DC=ssw,DC=lab'"
        Write-Log "${pre}  New-ADUser -Name 'TestUser02' -SamAccountName testuser02 ... (zelfde structuur)"
        Write-Log "${pre}  Add-ADGroupMember -Identity 'Domain Users' -Members testuser01, testuser02"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $dcVM" -UserName "$dcVM\$($SSWConfig.AdminUser)"
            $pwd  = Read-Host "Wachtwoord voor TestUser01/02" -AsSecureString
            Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                param($dom, $pass)
                $ou = "CN=Users,DC=$($dom.Split('.')[0]),DC=$($dom.Split('.')[1])"
                foreach ($u in @("TestUser01","TestUser02")) {
                    if (-not (Get-ADUser -Filter { SamAccountName -eq $u } -ErrorAction SilentlyContinue)) {
                        New-ADUser -Name $u -SamAccountName $u.ToLower() `
                            -UserPrincipalName "$($u.ToLower())@$dom" `
                            -AccountPassword $pass -Enabled $true -Path $ou
                        Write-Host "Aangemaakt: $u"
                    } else { Write-Host "Bestaat al: $u" }
                }
            } -ArgumentList $domain, $pwd
            Write-Log "  ✔ Testgebruikers aangemaakt/geverifieerd"
        } catch { Write-Log "  ✖ Fout: $_" }
    }

    # ── Stap 2: DC01 — Azure AD Connect sync ─────────────────
    Write-Log "${pre}Stap 2: DC01 — Azure AD Connect delta sync starten"
    $progress.Value = 35
    if ($isDry) {
        Write-Log "${pre}  Import-Module ADSync"
        Write-Log "${pre}  Start-ADSyncSyncCycle -PolicyType Delta"
        Write-Log "${pre}  Get-ADSyncScheduler → verifieer NextSyncCycleStartTimeInUTC"
    } else {
        try {
            Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                if (Get-Module -ListAvailable -Name ADSync) {
                    Import-Module ADSync
                    Start-ADSyncSyncCycle -PolicyType Delta
                    "Sync gestart: $(Get-Date)"
                } else { "Azure AD Connect niet geinstalleerd op DC01 — installeer eerst via 04-SETUP-DC.ps1" }
            } | ForEach-Object { Write-Log "  $_" }
        } catch { Write-Log "  ✖ Fout: $_" }
    }

    # ── Stap 3: MGMT01 — CA-policy instructies ───────────────
    Write-Log "${pre}Stap 3: MGMT01 — Conditional Access policy aanmaken (handmatig)"
    $progress.Value = 55
    Write-Log "  → Ga naar: entra.microsoft.com → Protection → Conditional Access → New policy"
    Write-Log "  → Naam: 'MD102-Lab-MFA-Outside-CorpNetwork'"
    Write-Log "  → Users: TestUser01"
    Write-Log "  → Cloud apps: All cloud apps"
    Write-Log "  → Conditions: Locations → Exclude 'All trusted locations'"
    Write-Log "  → Grant: Grant access → Require MFA"
    Write-Log "  → Enable policy: Report-only (tests eerst) → daarna On"

    # ── Stap 4: MGMT01 — Compliance policy instructies ───────
    Write-Log "${pre}Stap 4: MGMT01 — Compliance policy aanmaken (handmatig)"
    $progress.Value = 72
    Write-Log "  → Ga naar: intune.microsoft.com → Devices → Compliance → Create policy → Windows 10 and later"
    Write-Log "  → Naam: 'MD102-Lab-Compliance-Baseline'"
    Write-Log "  → Instellingen:"
    Write-Log "      Device Health: BitLocker required, Secure Boot enabled"
    Write-Log "      System Security: Defender real-time protection required"
    Write-Log "      OS Version: minimum 10.0.22000 (Windows 11 21H2)"
    Write-Log "  → Assign aan: All devices"

    # ── Stap 5: W11-02 — niet-compliant status ───────────────
    Write-Log "${pre}Stap 5: W11-02 — niet-compliant device demonstreren"
    $progress.Value = 88
    if ($isDry) {
        Write-Log "${pre}  dsregcmd /status → kijk naar 'ComplianceState'"
        Write-Log "${pre}  Intune portal: Devices → W11-02 → Device compliance → kijk op status"
    } else {
        try {
            $cred2 = Get-Credential -Message "Admin credentials voor $w11bVM" -UserName "$w11bVM\$($SSWConfig.AdminUser)"
            $comp = Invoke-Command -VMName $w11bVM -Credential $cred2 -ScriptBlock {
                $raw = & dsregcmd /status 2>&1
                ($raw | Select-String "AzureAdJoined|MDMUrl|ComplianceState") -join "`n"
            }
            Write-Log "  W11-02 status:`n  $comp"
        } catch { Write-Log "  ✖ Fout: $_" }
    }

    $progress.Value = 100
    Write-Log ""
    Write-Log "✔ Week 3 lab afgerond."
    Write-KennisCheck
    $btnNext.IsEnabled = $true
    $btnRun.IsEnabled  = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week4-apps.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week4-apps.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null



