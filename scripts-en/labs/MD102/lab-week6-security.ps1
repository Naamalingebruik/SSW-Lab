#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MD102/lab-week6-security.ps1
# MD-102 Week 6 — Security, Updates en Monitoring
# VMs:  LAB-W11-01, LAB-W11-02, LAB-MGMT01
# Cloud: Intune + Defender portal
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MD-102 | Week 6 — Security, Updates en Monitoring" Height="720" Width="700"
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
      <TextBlock Text="MD-102 | Week 6 — Security, Updates en Monitoring" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Defender status · Quick Scan · Update ring · EICAR test · Intune diagnostics" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Steps in this lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. W11-01: controleer Microsoft Defender status (Get-MpComputerStatus)"/>
        <LineBreak/><Run Text="2. W11-01: voer een Quick Scan uit (Start-MpScan)"/>
        <LineBreak/><Run Text="3. W11-01: controleer Windows Update status"/>
        <LineBreak/><Run Text="4. W11-02: simuleer EICAR detectie en verifieer alert"/>
        <LineBreak/><Run Text="5. Manual: Intune Update ring en Endpoint Security portal"/>
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
      <Button x:Name="BtnNext" Content="Naar MS-102 Week 1 >" Style="{StaticResource Btn}"
              Background="#CBA6F7" IsEnabled="False" Width="220"/>
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
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "Dry Run — alleen lezen, geen wijzigingen"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk te verbinden met de VMs"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "LIVE — verbinding via PowerShell Direct naar lab-VMs"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Check the box again to return to Dry Run"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

$reader.Add_Loaded({ Show-DryRunState })
$chkDryRun.Add_Checked({   Show-DryRunState })
$chkDryRun.Add_Unchecked({ Show-DryRunState })

function Write-LabLog($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logBox.ScrollToEnd()
}

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked
    $pre   = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $w11VM  = $profiles."W11-01".Name
    $w11VM2 = $profiles."W11-02".Name
    $cred   = $null

    # ── Stap 1: Defender status controleren ─────────────────
    Write-LabLog "${pre}Stap 1: W11-01 — Microsoft Defender status"
    $progress.Value = 12
    if ($isDry) {
        Write-LabLog "${pre}  Get-MpComputerStatus | Select-Object AMRunningMode, RealTimeProtectionEnabled,"
        Write-LabLog "${pre}    AntivirusSignatureLastUpdated, QuickScanAge, FullScanAge"
        Write-LabLog "${pre}  Verwacht: RealTimeProtectionEnabled=True, QuickScanAge < 7"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $w11VM" -UserName "$w11VM\$($SSWConfig.AdminUser)"
            $mpStatus = Invoke-Command -VMName $w11VM -Credential $cred -ScriptBlock {
                $s = Get-MpComputerStatus
                [PSCustomObject]@{
                    Realtime     = $s.RealTimeProtectionEnabled
                    Mode         = $s.AMRunningMode
                    SigAge       = $s.AntivirusSignatureAge
                    QuickScanAge = $s.QuickScanAge
                    FullScanAge  = $s.FullScanAge
                }
            }
            Write-LabLog "  Realtime bescherming : $($mpStatus.Realtime)"
            Write-LabLog "  Modus                : $($mpStatus.Mode)"
            Write-LabLog "  Handtekening leeftijd: $($mpStatus.SigAge) dag(en)"
            Write-LabLog "  Quick scan leeftijd  : $($mpStatus.QuickScanAge) dag(en)"
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 2: Quick Scan uitvoeren ────────────────────────
    Write-LabLog "${pre}Stap 2: W11-01 — Defender Quick Scan uitvoeren"
    $progress.Value = 28
    if ($isDry) {
        Write-LabLog "${pre}  Start-MpScan -ScanType QuickScan"
        Write-LabLog "${pre}  Scan duurt ca. 1-3 minuten"
        Write-LabLog "${pre}  Resultaten via Get-MpThreatDetection na afloop"
    } else {
        try {
            Write-LabLog "  Scan starten (dit kan enkele minuten duren)..."
            Invoke-Command -VMName $w11VM -Credential $cred -ScriptBlock {
                Start-MpScan -ScanType QuickScan -ErrorAction Stop
            }
            Write-LabLog "  Scan voltooid"
            $threats = Invoke-Command -VMName $w11VM -Credential $cred -ScriptBlock {
                (Get-MpThreatDetection | Select-Object -Last 5 | ForEach-Object { $_.ThreatName })
            }
            if ($threats) {
                Write-LabLog "  Recente detecties: $($threats -join ', ')"
            } else {
                Write-LabLog "  Geen bedreigingen gedetecteerd"
            }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 3: Windows Update status ───────────────────────
    Write-LabLog "${pre}Stap 3: W11-01 — Windows Update status"
    $progress.Value = 45
    if ($isDry) {
        Write-LabLog "${pre}  Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5"
        Write-LabLog "${pre}  (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install').LastSuccessTime"
    } else {
        try {
            $updates = Invoke-Command -VMName $w11VM -Credential $cred -ScriptBlock {
                $last5 = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5
                $last5 | ForEach-Object { "$($_.InstalledOn.ToString('yyyy-MM-dd'))  $($_.HotFixID)  $($_.Description)" }
            }
            Write-LabLog "  Recentste patches:"
            $updates | ForEach-Object { Write-LabLog "    $_" }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 4: EICAR testbestand ────────────────────────────
    Write-LabLog "${pre}Stap 4: W11-02 — EICAR detectietest"
    $progress.Value = 62
    Write-LabLog "  EICAR is een standaard testbestand dat Defender als gevaarlijk markeert"
    Write-LabLog "  Let op: gebruik NOOIT echt malware in een lab — EICAR is veilig"
    if ($isDry) {
        Write-LabLog "${pre}  Invoke-WebRequest https://www.eicar.org/download/eicar.com.txt -OutFile C:\Temp\eicar.txt"
        Write-LabLog "${pre}  Verwacht: Defender detecteert en verwijdert het bestand automatisch"
        Write-LabLog "${pre}  Alert zichtbaar in: Defender portal > Incidents & alerts"
    } else {
        try {
            $cred2 = Get-Credential -Message "Admin credentials voor $w11VM2" -UserName "$w11VM2\$($SSWConfig.AdminUser)"
            Invoke-Command -VMName $w11VM2 -Credential $cred2 -ScriptBlock {
                New-Item -ItemType Directory -Path C:\Temp -Force | Out-Null
                try {
                    Invoke-WebRequest "https://www.eicar.org/download/eicar.com.txt" `
                                      -OutFile "C:\Temp\eicar.txt" -TimeoutSec 10 -ErrorAction Stop
                    Start-Sleep -Seconds 5
                    if (-not (Test-Path "C:\Temp\eicar.txt")) {
                        "EICAR verwijderd door Defender (gewenst gedrag)"
                    } else {
                        "EICAR NIET verwijderd - controleer Defender realtime protection"
                    }
                } catch {
                    "Download mislukt (geen internet in VM?) - gebruik Invoke-WebRequest in VM console"
                }
            } | ForEach-Object { Write-LabLog "  $_" }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 5: Manual — Intune portals ────────────────────
    Write-LabLog "${pre}Stap 5: Manual — Intune Update ring en Endpoint Security"
    $progress.Value = 82
    Write-LabLog "  Update ring configureren:"
    Write-LabLog "    Intune > Devices > Update rings for Windows 10 and later > + Create"
    Write-LabLog "    Kanaal: Semi-Annual | Defer updates: 7 dagen"
    Write-LabLog ""
    Write-LabLog "  Defender for Endpoint activeren:"
    Write-LabLog "    Intune > Endpoint security > Microsoft Defender for Endpoint"
    Write-LabLog "    Schakel in: Automatic onboarding"
    Write-LabLog ""
    Write-LabLog "  Device diagnostics opvragen:"
    Write-LabLog "    Intune > Devices > W11-01 > ... > Collect diagnostics"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show(
            "Browser openen naar Intune Endpoint Security?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") {
            Start-Process "https://intune.microsoft.com/#view/Microsoft_Intune_Workflows/SecurityManagementMenu/~/overview"
        }
    }

    $progress.Value = 100
    Write-LabLog ""
    Write-LabLog "MD-102 lab (alle 6 weken) voltooid!"
    Write-LabLog ""
    Write-LabLog "━━━ KNOWLEDGE CHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-LabLog "1. Wat is het verschil tussen een Update ring en een Feature update policy?"
    Write-LabLog "2. Hoe werkt Co-management tussen Intune en Configuration Manager?"
    Write-LabLog "3. Wat toont het Endpoint analytics dashboard in Intune?"
    Write-LabLog "4. Hoe gebruik je Remote actions (wipe, retire, sync) in Intune?"
    Write-LabLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-LabLog ""
    Write-LabLog "Next step: start MD-102 examenvoorbereiding"
    Write-LabLog "  Practice assessment: https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications"

    $btnNext.IsEnabled = $true
    $btnRun.IsEnabled  = $true
})

$btnNext.Add_Click({
    $nextScript = Join-Path $PSScriptRoot "..\MS102\lab-week1-tenant.ps1"
    if (Test-Path $nextScript) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$nextScript`"" }
    else { [System.Windows.MessageBox]::Show("MS-102 labs niet gevonden in ..\MS102\", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null

