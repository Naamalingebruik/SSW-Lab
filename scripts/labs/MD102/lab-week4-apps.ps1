#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/MD102/lab-week4-apps.ps1
# MD-102 Week 4 — Applicatiebeheer met Intune
# VMs:  SSW-MGMT01, SSW-W11-01, SSW-W11-02
# Cloud: Intune portal (intune.microsoft.com)
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="MD-102 | Week 4 — Applicatiebeheer met Intune" Height="720" Width="700"
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
      <TextBlock Text="MD-102 | Week 4 — Applicatiebeheer met Intune" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Win32 packaging · IME log · Microsoft 365 Apps · App protection policies" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. MGMT01: controleer IntuneWin32ContentPrep Tool aanwezigheid"/>
        <LineBreak/><Run Text="2. W11-01: analyseer IntuneManagementExtension.log"/>
        <LineBreak/><Run Text="3. W11-01: controleer geinstalleerde applicaties"/>
        <LineBreak/><Run Text="4. W11-02: controleer Office installatie via registry"/>
        <LineBreak/><Run Text="5. Manueel: open Intune Apps portal (intune.microsoft.com)"/>
        <LineBreak/><Run Text="6. Kennischeckvragen weergeven"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 5 >" Style="{StaticResource Btn}"
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

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked
    $pre   = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
    $mgmtVM = $profiles.MGMT01.Name
    $w11VM  = $profiles."W11-01".Name
    $w11VM2 = $profiles."W11-02".Name

    # ── Stap 1: MGMT01 — IntuneWin32ContentPrepTool ─────────
    Write-Log "${pre}Stap 1: MGMT01 — IntuneWin32ContentPrepTool aanwezigheid"
    $progress.Value = 15
    if ($isDry) {
        Write-Log "${pre}  Test-Path 'C:\Tools\IntuneWinAppUtil.exe'"
        Write-Log "${pre}  Download: https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool"
        Write-Log "${pre}  Gebruik: IntuneWinAppUtil.exe -c <bronmap> -s <setup.exe> -o <uitvoermap>"
    } else {
        try {
            $cred = Get-Credential -Message "Admin credentials voor $mgmtVM" -UserName "$mgmtVM\$($SSWConfig.AdminUser)"
            $toolFound = Invoke-Command -VMName $mgmtVM -Credential $cred -ScriptBlock {
                $paths = @(
                    "C:\Tools\IntuneWinAppUtil.exe",
                    "$env:USERPROFILE\Downloads\IntuneWinAppUtil.exe",
                    "C:\IntuneWinAppUtil.exe"
                )
                $found = $paths | Where-Object { Test-Path $_ } | Select-Object -First 1
                if ($found) { "Gevonden: $found" }
                else { "Niet gevonden — download van https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool" }
            }
            Write-Log "  $toolFound"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: W11-01 — IME log analyseren ─────────────────
    Write-Log "${pre}Stap 2: W11-01 — IntuneManagementExtension.log (laatste 20 regels)"
    $progress.Value = 32
    if ($isDry) {
        Write-Log "${pre}  Pad: C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
        Write-Log "${pre}  Zoek op: 'Win32App', 'Successfully installed', 'Failed'"
        Write-Log "${pre}  Get-Content <pad> | Select-Object -Last 20"
    } else {
        try {
            $cred3 = Get-Credential -Message "Admin credentials voor $w11VM" -UserName "$w11VM\$($SSWConfig.AdminUser)"
            $imeLog = Invoke-Command -VMName $w11VM -Credential $cred3 -ScriptBlock {
                $logPath = "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
                if (Test-Path $logPath) {
                    $lines = Get-Content $logPath | Select-Object -Last 15
                    $lines
                } else {
                    "IME log niet gevonden — is het device enrolled in Intune?"
                }
            }
            $imeLog | ForEach-Object { Write-Log "  $_" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: W11-01 — geinstalleerde apps ────────────────
    Write-Log "${pre}Stap 3: W11-01 — geinstalleerde applicaties (Win32 + Store)"
    $progress.Value = 50
    if ($isDry) {
        Write-Log "${pre}  Get-AppxPackage | Select-Object Name, Version | Sort-Object Name"
        Write-Log "${pre}  Get-WmiObject -Class Win32_Product | Select-Object Name, Version"
        Write-Log "${pre}  Controleer of Intune-deployed apps aanwezig zijn"
    } else {
        try {
            $apps = Invoke-Command -VMName $w11VM -Credential $cred3 -ScriptBlock {
                $store = Get-AppxPackage | Where-Object { $_.SignatureKind -ne 'System' } |
                         Select-Object Name | Sort-Object Name | Select-Object -First 10
                $store | ForEach-Object { "Store: $($_.Name)" }
            }
            $apps | ForEach-Object { Write-Log "  $_" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 4: W11-02 — Office installatie ─────────────────
    Write-Log "${pre}Stap 4: W11-02 — Microsoft 365 Apps installatie verifiëren"
    $progress.Value = 68
    if ($isDry) {
        Write-Log "${pre}  Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
        Write-Log "${pre}  Verwacht na Intune M365 Apps deployment: VersionToReport aanwezig"
        Write-Log "${pre}  Test-Path 'C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE'"
    } else {
        try {
            $cred4 = Get-Credential -Message "Admin credentials voor $w11VM2" -UserName "$w11VM2\$($SSWConfig.AdminUser)"
            $officeStatus = Invoke-Command -VMName $w11VM2 -Credential $cred4 -ScriptBlock {
                $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -ErrorAction SilentlyContinue
                $word = Test-Path "C:\Program Files\Microsoft Office\root\Office16\WINWORD.EXE"
                if ($reg) {
                    "Office versie: $($reg.VersionToReport) | Word aanwezig: $word | Kanaal: $($reg.CDNBaseUrl)"
                } else {
                    "Microsoft 365 Apps niet geinstalleerd (nog geen Intune assignment?)"
                }
            }
            Write-Log "  $officeStatus"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 5: Manueel — Intune Apps portal ────────────────
    Write-Log "${pre}Stap 5: Manueel — Intune Apps portal"
    $progress.Value = 85
    Write-Log "  URL: https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/AppsMenu/~/overview"
    Write-Log "  Taken:"
    Write-Log "    - Pak een .exe in als .intunewin met IntuneWin32ContentPrepTool"
    Write-Log "    - Upload Win32 app > Assign aan W11-01 (Required)"
    Write-Log "    - Maak M365 Apps deployment aan (Apps > Windows > + Add > Microsoft 365)"
    Write-Log "    - Configureer App protection policy voor Microsoft Edge"

    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Browser openen naar Intune Apps?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") {
            Start-Process "https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/AppsMenu/~/overview"
        }
    }

    $progress.Value = 100
    Write-Log ""
    Write-Log "Week 4 lab afgerond."
    Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen een Required en Available app-assignment?"
    Write-Log "2. Wanneer gebruik je Win32 app packaging versus Microsoft Store for Business?"
    Write-Log "3. Wat doet de IntuneManagementExtension.log en waar staat die?"
    Write-Log "4. Wat zijn de voordelen van MAM zonder MDM-enrollment?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    $btnNext.IsEnabled = $true
    $btnRun.IsEnabled  = $true
})

$btnNext.Add_Click({
    $nextScript = Join-Path $PSScriptRoot "lab-week5-autopilot.ps1"
    if (Test-Path $nextScript) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$nextScript`"" }
    else { [System.Windows.MessageBox]::Show("lab-week5-autopilot.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null


