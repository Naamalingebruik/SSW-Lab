#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | MD-102 | Week 1 — Windows client deployment
# Doel: Verifieer deploy-readiness, Windows 11 build, ADK-installatie
#       en demonstreer unattended/SIM-concepten.
# VMs:  SSW-DC01, SSW-MGMT01, SSW-W11-01
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="MD-102 | Week 1 — Windows client deployment" Height="700" Width="700"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Lbl" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#A6ADC8"/><Setter Property="FontSize" Value="11"/>
      <Setter Property="Margin" Value="0,8,0,2"/>
    </Style>
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Background" Value="#89B4FA"/><Setter Property="Foreground" Value="#1E1E2E"/>
      <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="36"/>
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
      <TextBlock Text="MD-102 | Week 1 — Windows client deployment" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Verifieer Windows 11 build, AD-domein en ADK-aanwezigheid op MGMT01" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. DC01: controleer AD-domein ssw.lab via Get-ADDomain"/>
        <LineBreak/><Run Text="2. MGMT01: controleer of Windows ADK aanwezig is"/>
        <LineBreak/><Run Text="3. W11-01: haal Windows 11 build-nummer op"/>
        <LineBreak/><Run Text="4. W11-01: analyseer Windows Update log"/>
        <LineBreak/><Run Text="5. Kennischeckvragen weergeven"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 2 →" Style="{StaticResource Btn}"
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
    Write-Log "1. Wat is het verschil tussen wipe-and-load en in-place upgrade?"
    Write-Log "2. Welke minimale build heeft Windows 11 nodig voor Intune-enrollment?"
    Write-Log "3. Wat doet oscdimg.exe en waarom is het nodig voor unattended deployments?"
    Write-Log "4. Wanneer gebruik je DISM versus sysprep?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked
    $pre   = if ($isDry) { "[DRY RUN] " } else { "" }
    $profiles = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json

    $dcVM   = $profiles.DC01.Name
    $mgmtVM = $profiles.MGMT01.Name
    $w11VM  = $profiles."W11-01".Name

    # ── Stap 1: DC01 — Get-ADDomain ──────────────────────────
    Write-Log "${pre}Stap 1: DC01 — controleer AD-domein ssw.lab"
    $progress.Value = 15
    if ($isDry) {
        Write-Log "${pre}  Invoke-Command -VMName $dcVM → Get-ADDomain"
        Write-Log "${pre}  Verwacht resultaat: Name=ssw, DNSRoot=ssw.lab, ForestMode=WinThreshold"
    } else {
        try {
            $cred = Get-Credential -Message "Lokale admin credentials voor $dcVM" -UserName "$dcVM\$($SSWConfig.AdminUser)"
            $adInfo = Invoke-Command -VMName $dcVM -Credential $cred -ScriptBlock {
                (Get-ADDomain).DNSRoot + " | Forest: " + (Get-ADForest).Name + " | DCs: " + ((Get-ADDomainController -Filter *).Name -join ", ")
            }
            Write-Log "  ✔ $adInfo"
        } catch {
            Write-Log "  ✖ Fout: $_"
        }
    }

    # ── Stap 2: MGMT01 — ADK aanwezig? ───────────────────────
    Write-Log "${pre}Stap 2: MGMT01 — controleer Windows ADK (Deployment Tools)"
    $progress.Value = 35
    if ($isDry) {
        Write-Log "${pre}  Controleer pad: '${env:ProgramFiles(x86)}\Windows Kits\10\...\oscdimg.exe'"
        Write-Log "${pre}  Als niet aanwezig: download ADK via aka.ms/adk"
    } else {
        try {
            $cred2 = Get-Credential -Message "Lokale admin credentials voor $mgmtVM" -UserName "$mgmtVM\$($SSWConfig.AdminUser)"
            $adkOk = Invoke-Command -VMName $mgmtVM -Credential $cred2 -ScriptBlock {
                $p = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
                [System.IO.File]::Exists($p)
            }
            if ($adkOk) { Write-Log "  ✔ Windows ADK aanwezig op MGMT01" }
            else { Write-Log "  ⚠ Windows ADK NIET gevonden — download via aka.ms/adk" }
        } catch {
            Write-Log "  ✖ Fout: $_"
        }
    }

    # ── Stap 3: W11-01 — Build nummer ────────────────────────
    Write-Log "${pre}Stap 3: W11-01 — Windows 11 build nummer ophalen"
    $progress.Value = 55
    if ($isDry) {
        Write-Log "${pre}  Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'"
        Write-Log "${pre}  Verwacht: DisplayVersion=24H2, CurrentBuildNumber=26100 of hoger"
    } else {
        try {
            $cred3 = Get-Credential -Message "Lokale admin credentials voor $w11VM" -UserName "$w11VM\$($SSWConfig.AdminUser)"
            $buildInfo = Invoke-Command -VMName $w11VM -Credential $cred3 -ScriptBlock {
                $reg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
                "Build: $($reg.CurrentBuildNumber) | UBR: $($reg.UBR) | Versie: $($reg.DisplayVersion)"
            }
            Write-Log "  ✔ $buildInfo"
        } catch {
            Write-Log "  ✖ Fout: $_"
        }
    }

    # ── Stap 4: W11-01 — Windows Update log ─────────────────
    Write-Log "${pre}Stap 4: W11-01 — Windows Update log analyseren"
    $progress.Value = 75
    if ($isDry) {
        Write-Log "${pre}  Get-WindowsUpdateLog (converteert ETL naar WindowsUpdate.log)"
        Write-Log "${pre}  Analyse: zoek op 'SUCCESS', 'FAILED', 'REBOOT' entries"
    } else {
        try {
            Invoke-Command -VMName $w11VM -Credential $cred3 -ScriptBlock {
                Get-WindowsUpdateLog -LogPath "C:\Temp\WULog.txt" -ErrorAction SilentlyContinue | Out-Null
                if (Test-Path "C:\Temp\WULog.txt") {
                    $lines = Get-Content "C:\Temp\WULog.txt" | Select-Object -Last 20
                    $lines -join "`n"
                } else { "Get-WindowsUpdateLog aangemaakt — bekijk C:\Temp\WULog.txt op de VM" }
            } | ForEach-Object { Write-Log "  $_" }
        } catch {
            Write-Log "  ✖ Fout: $_"
        }
    }

    $progress.Value = 100
    Write-Log ""
    Write-Log "✔ Week 1 lab afgerond."
    Write-KennisCheck
    $btnNext.IsEnabled = $true
    $btnRun.IsEnabled  = $true
})

$btnNext.Add_Click({
    $nextScript = Join-Path $PSScriptRoot "lab-week2-intune.ps1"
    if (Test-Path $nextScript) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$nextScript`"" }
    else { [System.Windows.MessageBox]::Show("lab-week2-intune.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})

$reader.ShowDialog() | Out-Null
