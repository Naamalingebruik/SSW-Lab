#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MS102/lab-week2-users.ps1
# MS-102 Week 2 — User and Group Management
# VMs:  LAB-DC01, LAB-MGMT01, LAB-W11-01
# Cloud: M365 admin center, Entra admin center
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function Convert-PlainTextToSecureString {
    param([Parameter(Mandatory)][string]$Value)

    $secureString = New-Object System.Security.SecureString
    $Value.ToCharArray() | ForEach-Object { $secureString.AppendChar($_) }
    $secureString.MakeReadOnly()
    $secureString
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MS-102 | Week 2 — User and Group Management" Height="720" Width="700"
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
      <TextBlock Text="MS-102 | Week 2 — User and Group Management" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="OU structure · Bulk users · Admin roles · Dynamic groups · SSPR" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Steps in this lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. DC01: maak OU structure aan (LAB > IT, HR, Finance)"/>
        <LineBreak/><Run Text="2. DC01: maak bulk testusers aan via CSV"/>
        <LineBreak/><Run Text="3. DC01: start delta sync naar Entra ID"/>
        <LineBreak/><Run Text="4. Manual: wijs Helpdesk Administrator rol toe in M365"/>
        <LineBreak/><Run Text="5. Manual: maak dynamische groep aan in Entra ID"/>
        <LineBreak/><Run Text="6. Manual: activeer SSPR voor IT-afdeling"/>
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
      <Button x:Name="BtnRun"  Content="Run lab" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="140"/>
      <Button x:Name="BtnNext" Content="Continue to Week 3 >" Style="{StaticResource Btn}"
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

function Show-DryRunState {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24"); $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "Dry Run - no changes"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Clear the checkbox to execute for real"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "LIVE - changes will be applied in AD and Entra"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Check the box again to return to Dry Run"; $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

$reader.Add_Loaded({ Show-DryRunState })
$chkDryRun.Add_Checked({ Show-DryRunState }); $chkDryRun.Add_Unchecked({ Show-DryRunState })

function Write-LabLog($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

# Bulk users CSV (aangemaakt in geheugen)
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
    # ── Stap 1: OU structure create ───────────────────────
    Write-LabLog "${pre}Stap 1: DC01 — OU structure create"
    $progress.Value = 14
    if ($isDry) {
        Write-LabLog "${pre}  New-ADOrganizationalUnit -Name 'LAB' -Path 'DC=ssw,DC=lab'"
        Write-LabLog "${pre}  New-ADOrganizationalUnit -Name 'IT'  -Path 'OU=LAB,DC=ssw,DC=lab'"
        Write-LabLog "${pre}  New-ADOrganizationalUnit -Name 'HR'  -Path 'OU=LAB,DC=ssw,DC=lab'"
        Write-LabLog "${pre}  New-ADOrganizationalUnit -Name 'Finance' -Path 'OU=LAB,DC=ssw,DC=lab'"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $dcVM" -UserName "$dcVM\$($SSWConfig.AdminUser)"
            $ouResult = Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                param($dom)
                $base = "DC=" + ($dom -replace "\.",",.DC=")
                $ous  = @("LAB", "IT:OU=LAB,$base", "HR:OU=LAB,$base", "Finance:OU=LAB,$base")
                foreach ($ou in $ous) {
                    $parts = $ou -split ":"
                    $name  = $parts[0]
                    $path  = if ($parts.Count -gt 1) { $parts[1] } else { $base }
                    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$name'" -SearchBase $path -ErrorAction SilentlyContinue)) {
                        New-ADOrganizationalUnit -Name $name -Path $path -ErrorAction SilentlyContinue
                        "Created: OU=$name"
                    } else {
                        "Already present: OU=$name"
                    }
                }
            } -ArgumentList $domain
            $ouResult | ForEach-Object { Write-LabLog "  $_" }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 2: Bulk users create ────────────────────
    Write-LabLog "${pre}Stap 2: DC01 — bulk testusers create"
    $progress.Value = 30
    if ($isDry) {
        Write-LabLog "${pre}  Import-Csv users.csv | ForEach-Object { New-ADUser -Name ... }"
        Write-LabLog "${pre}  Users: testuser01 t/m testuser05 (IT, HR, Finance)"
        Write-LabLog "${pre}  Wachtwoord: SSWLab@2024 (uitsluitend voor labtesting)"
    } else {
        try {
            $csvPath = "$env:TEMP\ssw-lab-users.csv"
            $csvUsers | Set-Content $csvPath
            Copy-Item $csvPath -Destination "\\$dcVM\C$\Temp\ssw-users.csv" -ErrorAction SilentlyContinue
            Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                param($dom)
                $base    = "DC=" + ($dom -replace "\.",",.DC=")
                $csvPath = "C:\Temp\ssw-users.csv"
                if (-not (Test-Path $csvPath)) { Write-Warning "CSV not found at $csvPath"; return }
                $users   = Import-Csv $csvPath
                foreach ($u in $users) {
                    $ouPath = "OU=$($u.Department),OU=LAB,$base"
                    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$($u.Department)'" -ErrorAction SilentlyContinue)) {
                        $ouPath = "OU=LAB,$base"
                    }
                    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.SamAccountName)'" -ErrorAction SilentlyContinue)) {
                        $userPassword = Convert-PlainTextToSecureString -Value "SSWLab@2024"
                        New-ADUser -SamAccountName $u.SamAccountName `
                                   -GivenName $u.GivenName -Surname $u.Surname `
                                   -Name "$($u.GivenName) $($u.Surname)" `
                                   -UserPrincipalName "$($u.SamAccountName)@$dom" `
                                   -Department $u.Department -Title $u.Title `
                                   -Path $ouPath -AccountPassword $userPassword -Enabled $true
                        "Created: $($u.SamAccountName)"
                    } else {
                        "Already present: $($u.SamAccountName)"
                    }
                }
            } -ArgumentList $domain | ForEach-Object { Write-LabLog "  $_" }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 3: Delta sync ───────────────────────────────────
    Write-LabLog "${pre}Stap 3: DC01 — delta sync naar Entra ID"
    $progress.Value = 48
    if ($isDry) {
        Write-LabLog "${pre}  Import-Module ADSync; Start-ADSyncSyncCycle -PolicyType Delta"
    } else {
        try {
            Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                Import-Module ADSync -ErrorAction SilentlyContinue
                Start-ADSyncSyncCycle -PolicyType Delta -ErrorAction SilentlyContinue
            }
            Write-LabLog "  Delta sync gestart"
        } catch { Write-LabLog "  Warning: $_" }
    }

    # ── Stap 4: Manual — Helpdesk Administrator ─────────────
    Write-LabLog "${pre}Stap 4: Manual — Helpdesk Administrator rol toewijzen"
    $progress.Value = 62
    Write-LabLog "  M365 admin center > Roles > Role assignments > Helpdesk Administrator"
    Write-LabLog "  Voeg testuser01 toe als Helpdesk Administrator"
    Write-LabLog "  Verify: testuser01 kan passworden resetten maar geen Global Admin-taken"

    # ── Stap 5: Manual — Dynamische groep ──────────────────
    Write-LabLog "${pre}Stap 5: Manual — Dynamische groep create"
    $progress.Value = 74
    Write-LabLog "  Entra admin center > Groups > New group"
    Write-LabLog "  Type: Security | Membership: Dynamic User"
    Write-LabLog "  Regel: (user.department -eq ""IT"")"
    Write-LabLog "  Testusers met Department=IT worden automatisch lid"

    # ── Stap 6: Manual — SSPR activeren ────────────────────
    Write-LabLog "${pre}Stap 6: Manual — Self-Service Password Reset activeren"
    $progress.Value = 88
    Write-LabLog "  Entra admin center > Users > Password reset"
    Write-LabLog "  Self service password reset: Selected"
    Write-LabLog "  Selecteer groep: LAB-IT (de dynamische groep die je aanmaakte)"
    Write-LabLog "  Verificatie: 2 methoden verplicht (Authenticator + email)"
    Write-LabLog "  Test als testuser01: https://aka.ms/sspr"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show(
            "Browser openen naar Entra admin center > Groups?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://entra.microsoft.com/#view/Microsoft_AAD_IAM/GroupsManagementMenuBlade/~/AllGroups" }
    }

    $progress.Value = 100
    Write-LabLog ""
    Write-LabLog "Week 2 lab completed."
    Write-LabLog ""
    Write-LabLog "━━━ KNOWLEDGE CHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-LabLog "1. Wat is het principe van least privilege bij het toewijzen van beheerderrollen?"
    Write-LabLog "2. Wat is het verschil tussen een beveiligingsgroep en een Microsoft 365-groep?"
    Write-LabLog "3. Hoe werkt bulk user creation via de Microsoft 365 admin center?"
    Write-LabLog "4. Wanneer gebruik je dynamic groups versus assigned groups?"
    Write-LabLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week3-hybrid-identity.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week3-hybrid-identity.ps1 not found.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null



