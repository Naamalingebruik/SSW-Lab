#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MS102/lab-week2-gebruikers.ps1
# MS-102 Week 2 — Gebruikers- en Groepsbeheer
# VMs:  SSW-DC01, SSW-MGMT01, SSW-W11-01
# Cloud: M365 admin center, Entra admin center
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MS-102 | Week 2 — Gebruikers- en Groepsbeheer" Height="720" Width="700"
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
      <TextBlock Text="MS-102 | Week 2 — Gebruikers- en Groepsbeheer" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="OU-structuur · Bulk users · Beheerderrollen · Dynamische groepen · SSPR" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. DC01: maak OU-structuur aan (SSW > IT, HR, Finance)"/>
        <LineBreak/><Run Text="2. DC01: maak bulk testgebruikers aan via CSV"/>
        <LineBreak/><Run Text="3. DC01: start delta sync naar Entra ID"/>
        <LineBreak/><Run Text="4. Manueel: wijs Helpdesk Administrator rol toe in M365"/>
        <LineBreak/><Run Text="5. Manueel: maak dynamische groep aan in Entra ID"/>
        <LineBreak/><Run Text="6. Manueel: activeer SSPR voor IT-afdeling"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 3 >" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text       = "Dry Run — geen wijzigingen"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "LIVE — wijzigingen worden doorgevoerd in AD en Entra"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"; $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({ Update-DryRunBar }); $chkDryRun.Add_Unchecked({ Update-DryRunBar })

function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

# Bulk gebruikers CSV (aangemaakt in geheugen)
$csvUsers = @"
SamAccountName,GivenName,Surname,Department,Title
testuser01,Test,User01,IT,Engineer
testuser02,Test,User02,IT,Analyst
testuser03,Test,User03,HR,Manager
testuser04,Test,User04,Finance,Consultant
testuser05,Test,User05,Finance,Analyst
"@

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked
    $pre   = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $dcVM  = $profiles.DC01.Name
    $domain = $SSWConfig.DomainName
    $nb     = $SSWConfig.DomainNetBIOS

    # ── Stap 1: OU-structuur aanmaken ───────────────────────
    Write-Log "${pre}Stap 1: DC01 — OU-structuur aanmaken"
    $progress.Value = 14
    if ($isDry) {
        Write-Log "${pre}  New-ADOrganizationalUnit -Name 'SSW' -Path 'DC=ssw,DC=lab'"
        Write-Log "${pre}  New-ADOrganizationalUnit -Name 'IT'  -Path 'OU=SSW,DC=ssw,DC=lab'"
        Write-Log "${pre}  New-ADOrganizationalUnit -Name 'HR'  -Path 'OU=SSW,DC=ssw,DC=lab'"
        Write-Log "${pre}  New-ADOrganizationalUnit -Name 'Finance' -Path 'OU=SSW,DC=ssw,DC=lab'"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $dcVM" -UserName "$dcVM\$($SSWConfig.AdminUser)"
            $ouResult = Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                param($dom)
                $base = "DC=" + ($dom -replace "\.",",.DC=")
                $ous  = @("SSW", "IT:OU=SSW,$base", "HR:OU=SSW,$base", "Finance:OU=SSW,$base")
                foreach ($ou in $ous) {
                    $parts = $ou -split ":"
                    $name  = $parts[0]
                    $path  = if ($parts.Count -gt 1) { $parts[1] } else { $base }
                    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$name'" -SearchBase $path -ErrorAction SilentlyContinue)) {
                        New-ADOrganizationalUnit -Name $name -Path $path -ErrorAction SilentlyContinue
                        "Aangemaakt: OU=$name"
                    } else {
                        "Al aanwezig: OU=$name"
                    }
                }
            } -ArgumentList $domain
            $ouResult | ForEach-Object { Write-Log "  $_" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: Bulk gebruikers aanmaken ────────────────────
    Write-Log "${pre}Stap 2: DC01 — bulk testgebruikers aanmaken"
    $progress.Value = 30
    if ($isDry) {
        Write-Log "${pre}  Import-Csv users.csv | ForEach-Object { New-ADUser -Name ... }"
        Write-Log "${pre}  Gebruikers: testuser01 t/m testuser05 (IT, HR, Finance)"
        Write-Log "${pre}  Wachtwoord: SSWLab@2024 (uitsluitend voor labtesting)"
    } else {
        try {
            $csvPath = "$env:TEMP\ssw-lab-users.csv"
            $csvUsers | Set-Content $csvPath
            Copy-Item $csvPath -Destination "\\$dcVM\C$\Temp\ssw-users.csv" -ErrorAction SilentlyContinue
            Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                param($dom, $nb)
                $base    = "DC=" + ($dom -replace "\.",",.DC=")
                $csvPath = "C:\Temp\ssw-users.csv"
                if (-not (Test-Path $csvPath)) { Write-Warning "CSV niet gevonden op $csvPath"; return }
                $users   = Import-Csv $csvPath
                foreach ($u in $users) {
                    $ouPath = "OU=$($u.Department),OU=SSW,$base"
                    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($u.Department)'" -ErrorAction SilentlyContinue)) {
                        $ouPath = "OU=SSW,$base"
                    }
                    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.SamAccountName)'" -ErrorAction SilentlyContinue)) {
                        $pwd = ConvertTo-SecureString "SSWLab@2024" -AsPlainText -Force
                        New-ADUser -SamAccountName $u.SamAccountName `
                                   -GivenName $u.GivenName -Surname $u.Surname `
                                   -Name "$($u.GivenName) $($u.Surname)" `
                                   -UserPrincipalName "$($u.SamAccountName)@$dom" `
                                   -Department $u.Department -Title $u.Title `
                                   -Path $ouPath -AccountPassword $pwd -Enabled $true
                        "Aangemaakt: $($u.SamAccountName)"
                    } else {
                        "Al aanwezig: $($u.SamAccountName)"
                    }
                }
            } -ArgumentList $domain, $nb | ForEach-Object { Write-Log "  $_" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: Delta sync ───────────────────────────────────
    Write-Log "${pre}Stap 3: DC01 — delta sync naar Entra ID"
    $progress.Value = 48
    if ($isDry) {
        Write-Log "${pre}  Import-Module ADSync; Start-ADSyncSyncCycle -PolicyType Delta"
    } else {
        try {
            Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                Import-Module ADSync -ErrorAction SilentlyContinue
                Start-ADSyncSyncCycle -PolicyType Delta -ErrorAction SilentlyContinue
            }
            Write-Log "  Delta sync gestart"
        } catch { Write-Log "  Waarschuwing: $_" }
    }

    # ── Stap 4: Manueel — Helpdesk Administrator ─────────────
    Write-Log "${pre}Stap 4: Manueel — Helpdesk Administrator rol toewijzen"
    $progress.Value = 62
    Write-Log "  M365 admin center > Roles > Role assignments > Helpdesk Administrator"
    Write-Log "  Voeg testuser01 toe als Helpdesk Administrator"
    Write-Log "  Verifieer: testuser01 kan wachtwoorden resetten maar geen Global Admin-taken"

    # ── Stap 5: Manueel — Dynamische groep ──────────────────
    Write-Log "${pre}Stap 5: Manueel — Dynamische groep aanmaken"
    $progress.Value = 74
    Write-Log "  Entra admin center > Groups > New group"
    Write-Log "  Type: Security | Membership: Dynamic User"
    Write-Log "  Regel: (user.department -eq ""IT"")"
    Write-Log "  Testgebruikers met Department=IT worden automatisch lid"

    # ── Stap 6: Manueel — SSPR activeren ────────────────────
    Write-Log "${pre}Stap 6: Manueel — Self-Service Password Reset activeren"
    $progress.Value = 88
    Write-Log "  Entra admin center > Users > Password reset"
    Write-Log "  Self service password reset: Selected"
    Write-Log "  Selecteer groep: SSW-IT (de dynamische groep die je aanmaakte)"
    Write-Log "  Verificatie: 2 methoden verplicht (Authenticator + email)"
    Write-Log "  Test als testuser01: https://aka.ms/sspr"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show(
            "Browser openen naar Entra admin center > Groups?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://entra.microsoft.com/#view/Microsoft_AAD_IAM/GroupsManagementMenuBlade/~/AllGroups" }
    }

    $progress.Value = 100
    Write-Log ""
    Write-Log "Week 2 lab afgerond."
    Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het principe van least privilege bij het toewijzen van beheerderrollen?"
    Write-Log "2. Wat is het verschil tussen een beveiligingsgroep en een Microsoft 365-groep?"
    Write-Log "3. Hoe werkt bulk user creation via de Microsoft 365 admin center?"
    Write-Log "4. Wanneer gebruik je dynamic groups versus assigned groups?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week3-hybrid-identity.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week3-hybrid-identity.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null



