#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MS102/lab-week6-defender.ps1
# MS-102 Week 6 — Microsoft 365 Defender en bedreigingsbeheer
# VMs:  SSW-W11-01
# Cloud: Microsoft 365 Defender portal, Entra
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MS-102 | Week 6 — Microsoft 365 Defender" Height="720" Width="700"
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
      <TextBlock Text="MS-102 | Week 6 — Microsoft 365 Defender" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Defender onboarding · EICAR detectie · Attack simulation · Secure Score" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. W11-01: controleer Defender for Endpoint onboarding status"/>
        <LineBreak/><Run Text="2. W11-01: EICAR testbestand downloaden en detectie verifiëren"/>
        <LineBreak/><Run Text="3. Manueel: analyseer het incident in Defender portal"/>
        <LineBreak/><Run Text="4. Manueel: voer Attack Simulation Training uit"/>
        <LineBreak/><Run Text="5. Manueel: analyseer Microsoft Secure Score"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 7 >" Style="{StaticResource Btn}"
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
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — verbinding met W11-01 en Defender portal"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
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
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $w11VM = $profiles."W11-01".Name

    # ── Stap 1: Defender for Endpoint onboarding ────────────
    Write-Log "${pre}Stap 1: W11-01 — Defender for Endpoint onboarding status"
    $progress.Value = 16
    if ($isDry) {
        Write-Log "${pre}  Get-MpComputerStatus | Select-Object AMRunningMode, IsTamperProtected"
        Write-Log "${pre}  Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status'"
        Write-Log "${pre}  Verwacht na Intune MDE onboarding: OnboardingState=1"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $w11VM" -UserName "$w11VM\$($SSWConfig.AdminUser)"
            $mdeStatus = Invoke-Command -VMName $w11VM -Credential $cred -ScriptBlock {
                $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status" -ErrorAction SilentlyContinue
                $mp  = Get-MpComputerStatus -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    Onboarded    = if ($reg) { $reg.OnboardingState -eq 1 } else { $false }
                    TamperProt   = if ($mp) { $mp.IsTamperProtected } else { $false }
                    RunningMode  = if ($mp) { $mp.AMRunningMode } else { "Onbekend" }
                }
            }
            Write-Log "  MDE onboarded   : $($mdeStatus.Onboarded)"
            Write-Log "  Tamper bescherm : $($mdeStatus.TamperProt)"
            Write-Log "  Defender modus  : $($mdeStatus.RunningMode)"
            if (-not $mdeStatus.Onboarded) {
                Write-Log "  Let op: Activeer MDE onboarding via Intune (Endpoint security > MDE)"
            }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: EICAR detectie ───────────────────────────────
    Write-Log "${pre}Stap 2: W11-01 — EICAR detectietest"
    $progress.Value = 32
    Write-Log "  Let op: EICAR is een veilig standaard testbestand — GEEN echte malware"
    if ($isDry) {
        Write-Log "${pre}  New-Item -Path C:\Temp -Force"
        Write-Log "${pre}  Invoke-WebRequest https://www.eicar.org/download/eicar.com.txt -OutFile C:\Temp\eicar.txt"
        Write-Log "${pre}  Start-Sleep -Seconds 5"
        Write-Log "${pre}  Test-Path C:\Temp\eicar.txt  # Moet False zijn na Defender-detectie"
    } else {
        try {
            $eicarResult = Invoke-Command -VMName $w11VM -Credential $cred -ScriptBlock {
                New-Item -ItemType Directory -Path C:\Temp -Force | Out-Null
                try {
                    Invoke-WebRequest "https://www.eicar.org/download/eicar.com.txt" -OutFile "C:\Temp\eicar.txt" -TimeoutSec 15 -ErrorAction Stop
                    Start-Sleep -Seconds 5
                    if (Test-Path "C:\Temp\eicar.txt") {
                        "EICAR bestand NIET verwijderd - controleer Defender realtime protection en onboarding"
                    } else {
                        "EICAR door Defender verwijderd (gewenst gedrag)"
                    }
                } catch { "Download mislukt: $_ — geen internetverbinding vanuit VM?" }
            }
            Write-Log "  $eicarResult"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: Incident analyseren ──────────────────────────
    Write-Log "${pre}Stap 3: Manueel — Incident analyseren in Defender portal"
    $progress.Value = 50
    Write-Log "  URL: https://security.microsoft.com"
    Write-Log "  Navigeer naar: Incidents & alerts > Incidents"
    Write-Log "  Zoek de EICAR detectie-alert van W11-01"
    Write-Log "  Bekijk: Attack story graph, Entities, Evidence"
    Write-Log "  Sla het incident op als 'Opgelost' na verificatie"

    # ── Stap 4: Attack Simulation Training ──────────────────
    Write-Log "${pre}Stap 4: Manueel — Attack Simulation Training"
    $progress.Value = 68
    Write-Log "  Defender portal > Email & collaboration > Attack simulation training"
    Write-Log "  + Launch a simulation"
    Write-Log "  Techniek: Credential harvest | Payload: Microsoft login phishing"
    Write-Log "  Target: testuser01@<tenant>.onmicrosoft.com"
    Write-Log "  Bekijk resultaten na 24-48 uur (click rate, compromised users)"

    # ── Stap 5: Secure Score ─────────────────────────────────
    Write-Log "${pre}Stap 5: Manueel — Microsoft Secure Score analyseren"
    $progress.Value = 84
    Write-Log "  Defender portal > Secure score"
    Write-Log "  Bekijk: huidige score, improvement actions"
    Write-Log "  Kies een verbetering (bijv. 'Require MFA for all users')"
    Write-Log "  Implementeer de aanbeveling en observeer score-stijging"
    Write-Log "  Score bijhouden in rapporten: Overview > Score history"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Browser openen naar Microsoft 365 Defender portal?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://security.microsoft.com" }
    }

    $progress.Value = 100; Write-Log ""; Write-Log "Week 6 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen Defender for Office 365 Plan 1 en Plan 2?"
    Write-Log "2. Hoe werkt Automated Investigation and Response (AIR) in Defender?"
    Write-Log "3. Wat toont de Threat Explorer en wanneer gebruik je het?"
    Write-Log "4. Hoe verhoog je de Microsoft Secure Score effectief?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week7-purview.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week7-purview.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null


