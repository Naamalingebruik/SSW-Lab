#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | MD-102 | Week 2 — Intune enrollment en device management
# Doel: Demonstreer enrollment-stappen, BitLocker-policy, compliance
# VMs:  LAB-W11-01, LAB-W11-02, LAB-MGMT01
# Cloud: Intune portal (intune.microsoft.com)
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MD-102 | Week 2 — Intune enrollment" Height="700" Width="700"
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
      <TextBlock Text="MD-102 | Week 2 — Intune enrollment en device management" Foreground="#CDD6F4" FontSize="17" FontWeight="SemiBold"/>
      <TextBlock Text="Enrollment, BitLocker-policy, compliance — W11-01, W11-02, MGMT01" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. W11-01: controleer MDM-enrollment status"/>
        <LineBreak/><Run Text="2. W11-01: verifieer BitLocker status (manage-bde)"/>
        <LineBreak/><Run Text="3. W11-02: controleer MDM-enrollment status"/>
        <LineBreak/><Run Text="4. MGMT01: open Intune-portal in Edge (handmatig)"/>
        <LineBreak/><Run Text="5. Toon instructies voor Configuration profile en compliance policy"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 3 →" Style="{StaticResource Btn}"
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
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({   Update-DryRunBar })
$chkDryRun.Add_Unchecked({ Update-DryRunBar })

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logBox.ScrollToEnd()
}

function Write-KennisCheck {
    Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen MDM-enrollment en Hybrid Azure AD Join?"
    Write-Log "2. Welke enrollment-methodes bestaan in Intune en wanneer gebruik je welke?"
    Write-Log "3. Wat betekent Compliant versus Not compliant in Intune?"
    Write-Log "4. Hoe werkt de Enrollment Status Page bij Autopilot?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry    = $chkDryRun.IsChecked
    $pre      = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $w11aVM   = $profiles."W11-01".Name
    $w11bVM   = $profiles."W11-02".Name

    # ── Stap 1: W11-01 MDM enrollment status ─────────────────
    Write-Log "${pre}Stap 1: W11-01 — MDM enrollment status controleren"
    $progress.Value = 15
    if ($isDry) {
        Write-Log "${pre}  dsregcmd /status → kijk naar 'AzureAdJoined', 'MDMUrl', 'EnterpriseJoined'"
        Write-Log "${pre}  Verwacht na enrollment: AzureAdJoined=YES, MDMUrl=https://enrollment.manage.microsoft.com"
    } else {
        try {
            $cred1 = Get-Credential -Message "Admin credentials voor $w11aVM" -UserName "$w11aVM\$($SSWConfig.AdminUser)"
            $result = Invoke-Command -VMName $w11aVM -Credential $cred1 -ScriptBlock {
                $raw = & dsregcmd /status 2>&1
                $raw | Select-String "AzureAdJoined|MDMUrl|EnterpriseJoined|WorkplaceJoined"
            }
            $result | ForEach-Object { Write-Log "  $_" }
        } catch { Write-Log "  ✖ Fout: $_" }
    }

    # ── Stap 2: W11-01 BitLocker status ──────────────────────
    Write-Log "${pre}Stap 2: W11-01 — BitLocker status (manage-bde -status)"
    $progress.Value = 30
    if ($isDry) {
        Write-Log "${pre}  manage-bde -status C:"
        Write-Log "${pre}  Verwacht: Protection Status=Protection On, Encryption Method=XTS-AES 128"
        Write-Log "${pre}  Als OFF: Intune BitLocker-policy nog niet toegepast of niet enrolled"
    } else {
        try {
            $bl = Invoke-Command -VMName $w11aVM -Credential $cred1 -ScriptBlock {
                $vol = Get-BitLockerVolume -MountPoint "C:" -ErrorAction SilentlyContinue
                if ($vol) { "Status: $($vol.ProtectionStatus) | Methode: $($vol.EncryptionMethod) | KeyProtectors: $($vol.KeyProtector.KeyProtectorType -join ', ')" }
                else { "BitLocker-module niet beschikbaar — voer manage-bde -status C: uit in de VM" }
            }
            Write-Log "  ✔ $bl"
        } catch { Write-Log "  ✖ Fout: $_" }
    }

    # ── Stap 3: W11-02 enrollment status ─────────────────────
    Write-Log "${pre}Stap 3: W11-02 — MDM enrollment status controleren"
    $progress.Value = 50
    if ($isDry) {
        Write-Log "${pre}  dsregcmd /status op W11-02"
        Write-Log "${pre}  Vergelijk met W11-01 — beide moeten enrolled zijn"
    } else {
        try {
            $cred2 = Get-Credential -Message "Admin credentials voor $w11bVM" -UserName "$w11bVM\$($SSWConfig.AdminUser)"
            $result2 = Invoke-Command -VMName $w11bVM -Credential $cred2 -ScriptBlock {
                $raw = & dsregcmd /status 2>&1
                $raw | Select-String "AzureAdJoined|MDMUrl|EnterpriseJoined|WorkplaceJoined"
            }
            $result2 | ForEach-Object { Write-Log "  $_" }
        } catch { Write-Log "  ✖ Fout: $_" }
    }

    # ── Stap 4: MGMT01 — portaalinstructies ──────────────────
    Write-Log "${pre}Stap 4: MGMT01 — Intune portal acties (handmatig)"
    $progress.Value = 70
    Write-Log "  → Open intune.microsoft.com in Edge op MGMT01"
    Write-Log "  → Ga naar: Devices → All devices → verifieer W11-01 en W11-02"
    Write-Log "  → Maak Configuration profile: Endpoint security → Disk encryption → BitLocker"
    Write-Log "      Assign aan: alle devices / groep met W11-01"
    Write-Log "  → Maak Compliance policy: Devices → Compliance → Create policy"
    Write-Log "      Vereisten: OS minimaal 10.0.22000 (W11), Defender actief, BitLocker aan"

    # ── Stap 5: Intune sync forceren ──────────────────────────
    Write-Log "${pre}Stap 5: W11-01 — forceer Intune sync"
    $progress.Value = 85
    if ($isDry) {
        Write-Log "${pre}  Start-Process ms-settings:workplace"
        Write-Log "${pre}  Klik op Info → Sync → wacht 2-5 min op policy-toepassing"
    } else {
        try {
            Invoke-Command -VMName $w11aVM -Credential $cred1 -ScriptBlock {
                # Trigger MDM sync via scheduled task
                Get-ScheduledTask | Where-Object { $_.TaskPath -like "*Microsoft*EnterpriseMgmt*" } |
                    ForEach-Object { Start-ScheduledTask -TaskPath $_.TaskPath -TaskName $_.TaskName -ErrorAction SilentlyContinue }
            }
            Write-Log "  ✔ MDM sync-tasks getriggerd op W11-01"
        } catch { Write-Log "  ✖ Fout: $_" }
    }

    $progress.Value = 100
    Write-Log ""
    Write-Log "✔ Week 2 lab afgerond."
    Write-KennisCheck
    $btnNext.IsEnabled = $true
    $btnRun.IsEnabled  = $true
})

$btnNext.Add_Click({
    $nextScript = Join-Path $PSScriptRoot "lab-week3-compliance-ca.ps1"
    if (Test-Path $nextScript) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$nextScript`"" }
    else { [System.Windows.MessageBox]::Show("lab-week3-compliance-ca.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null
