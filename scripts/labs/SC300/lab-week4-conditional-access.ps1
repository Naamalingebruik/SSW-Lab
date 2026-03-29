#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/SC300/lab-week4-conditional-access.ps1
# SC-300 Week 4 — Conditional Access: beleid, What-If, Named Locations
# Cloud: Entra ID – Conditional Access via Microsoft Graph
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SC-300 | Week 4 — Conditional Access" Height="720" Width="700"
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
      <TextBlock Text="SC-300 | Week 4 — Conditional Access" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="CA beleid aanmaken · Named Locations · What-If · Sign-in logs" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Bestaande CA-beleidsregels ophalen via Graph"/>
        <LineBreak/><Run Text="2. MFA-vereiste CA-policy aanmaken (report-only mode)"/>
        <LineBreak/><Run Text="3. Named Location aanmaken (Nederland)"/>
        <LineBreak/><Run Text="4. CA What-If tool gebruiken (manueel - portal)"/>
        <LineBreak/><Run Text="5. Sign-in logging analyseren in Entra portal"/>
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

function Show-DryRunState {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background = $conv.ConvertFrom("#1A2E24"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text = "Dry Run — CA policies worden niet aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "CA policies in Report-only mode zijn veilig om live te testen"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — CA beleid aanmaken (report-only, geen blokkade)"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Schakel nooit CA policies in op alle gebruikers zonder MFA setup"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Show-DryRunState })
$chkDryRun.Add_Checked({ Show-DryRunState }); $chkDryRun.Add_Unchecked({ Show-DryRunState })
function Write-LabLog($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }

    # ── Stap 1: Bestaande CA policies ophalen ────────────────
    Write-LabLog "${pre}Stap 1: Graph — bestaande Conditional Access policies"
    $progress.Value = 16
    if ($isDry) {
        Write-LabLog "${pre}  Connect-MgGraph -Scopes 'Policy.Read.All'"
        Write-LabLog "${pre}  Get-MgIdentityConditionalAccessPolicy | Select-Object DisplayName, State, Id | Format-Table"
    } else {
        try {
            Connect-MgGraph -Scopes "Policy.Read.All", "Policy.ReadWrite.ConditionalAccess" -ErrorAction Stop | Out-Null
            $policies = Get-MgIdentityConditionalAccessPolicy
            Write-LabLog "  Conditional Access policies ($($policies.Count) totaal):"
            $policies | ForEach-Object { Write-LabLog "  [$($_.State.PadRight(12))] $($_.DisplayName)" }
        } catch { Write-LabLog "  Fout: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: MFA CA policy aanmaken (report-only) ─────────
    Write-LabLog "${pre}Stap 2: CA policy aanmaken — MFA vereist (report-only)"
    $progress.Value = 32
    if ($isDry) {
        Write-LabLog "${pre}  `$conditions = @{"
        Write-LabLog "${pre}    users = @{ includeUsers = @('All'); excludeUsers = @('<break-glass-account-id>') }"
        Write-LabLog "${pre}    applications = @{ includeApplications = @('All') }"
        Write-LabLog "${pre}  }"
        Write-LabLog "${pre}  `$grantControls = @{ operator = 'OR'; builtInControls = @('mfa') }"
        Write-LabLog "${pre}  New-MgIdentityConditionalAccessPolicy -DisplayName 'SSW - Require MFA for All Users' -State 'enabledForReportingButNotEnforcing' -Conditions `$conditions -GrantControls `$grantControls"
    } else {
        try {
            $existingPolicy = Get-MgIdentityConditionalAccessPolicy | Where-Object { $_.DisplayName -eq "SSW - Require MFA for All Users" }
            if (-not $existingPolicy) {
                $params = @{
                    DisplayName   = "SSW - Require MFA for All Users"
                    State         = "enabledForReportingButNotEnforcing"
                    Conditions    = @{
                        Users        = @{ IncludeUsers = @("All") }
                        Applications = @{ IncludeApplications = @("All") }
                    }
                    GrantControls = @{
                        Operator       = "OR"
                        BuiltInControls = @("mfa")
                    }
                }
                $newPolicy = New-MgIdentityConditionalAccessPolicy @params
                Write-LabLog "  CA policy aangemaakt: $($newPolicy.DisplayName)"
                Write-LabLog "  State: report-only (geen blokkade)"
                Write-LabLog "  ID: $($newPolicy.Id)"
            } else {
                Write-LabLog "  Policy bestaat al: $($existingPolicy.DisplayName) [$($existingPolicy.State)]"
            }
        } catch { Write-LabLog "  Fout: $_" }
    }

    # ── Stap 3: Named Location voor Nederland ────────────────
    Write-LabLog "${pre}Stap 3: Named Location aanmaken (Nederland)"
    $progress.Value = 50
    if ($isDry) {
        Write-LabLog "${pre}  `$location = @{ '@odata.type' = '#microsoft.graph.countryNamedLocation'; displayName = 'Nederland'; countriesAndRegions = @('NL'); includeUnknownCountriesAndRegions = `$false }"
        Write-LabLog "${pre}  Invoke-MgGraphRequest -Method POST -Uri '/v1.0/identity/conditionalAccess/namedLocations' -Body (`$location | ConvertTo-Json)"
    } else {
        try {
            $existingLoc = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations"
            $nlLocation  = $existingLoc.value | Where-Object { $_.displayName -eq "Nederland" }
            if (-not $nlLocation) {
                $body = @{
                    "@odata.type"                    = "#microsoft.graph.countryNamedLocation"
                    displayName                      = "Nederland"
                    countriesAndRegions              = @("NL")
                    includeUnknownCountriesAndRegions = $false
                }
                $nlLocation = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations" -Body ($body | ConvertTo-Json) -ContentType "application/json"
                Write-LabLog "  Named Location aangemaakt: Nederland (NL)"
                Write-LabLog "  ID: $($nlLocation.id)"
            } else { Write-LabLog "  Named Location bestaat al: $($nlLocation.displayName)" }
        } catch { Write-LabLog "  Fout: $_" }
    }

    # ── Stap 4: What-If tool (portal) ───────────────────────
    Write-LabLog "${pre}Stap 4: Manueel — CA What-If tool"
    $progress.Value = 68
    Write-LabLog "  Entra portal > Protection > Conditional Access > What If"
    Write-LabLog "  Simuleer scenario:"
    Write-LabLog "    User: testuser01@<tenant>"
    Write-LabLog "    Application: Microsoft Azure Management"
    Write-LabLog "    IP: 87.212.76.1 (NL - een willekeurig NL IP)"
    Write-LabLog "    Device platform: Windows"
    Write-LabLog "  Klik 'What If' en bekijk welke policies van toepassing zijn"
    Write-LabLog "  Verifieer: 'SSW - Require MFA for All Users' staat in de lijst"
    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Entra portal - CA What-If tool openen?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://entra.microsoft.com/#view/Microsoft_AAD_IAM/ConditionalAccessBlade/~/WhatIf" }
    }

    # ── Stap 5: Sign-in logs analyseren ─────────────────────
    Write-LabLog "${pre}Stap 5: Graph — Sign-in logs met CA policy resultaten"
    $progress.Value = 84
    if ($isDry) {
        Write-LabLog "${pre}  Connect-MgGraph -Scopes 'AuditLog.Read.All'"
        Write-LabLog "${pre}  Get-MgAuditLogSignIn -Top 5 | Select-Object UserPrincipalName, AppDisplayName, Status, ConditionalAccessStatus | Format-Table"
    } else {
        try {
            Connect-MgGraph -Scopes "AuditLog.Read.All" -ErrorAction Stop | Out-Null
            $signIns = Get-MgAuditLogSignIn -Top 5
            Write-LabLog "  Laatste 5 aanmeldingen:"
            $signIns | ForEach-Object {
                Write-LabLog "  $($_.UserPrincipalName) → $($_.AppDisplayName) [$($_.ConditionalAccessStatus)]"
            }
        } catch { Write-LabLog "  Fout (Entra P1 vereist voor sign-in logs): $_" }
    }

    $progress.Value = 100; Write-LabLog ""; Write-LabLog "Week 4 lab afgerond."; Write-LabLog ""
    Write-LabLog "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-LabLog "1. Wat is het verschil tussen 'Report-only' en 'Enabled' CA policies?"
    Write-LabLog "2. Hoe werkt Continuous Access Evaluation (CAE) in combinatie met CA?"
    Write-LabLog "3. Wanneer gebruik je een Named Location vs. een IP-filter?"
    Write-LabLog "4. Wat is 'Require compliant device' en welk MDM-systeem is vereist?"
    Write-LabLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week5-appregistrations.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week5-appregistrations.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null


