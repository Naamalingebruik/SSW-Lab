#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | 05-JOIN-DOMAIN.ps1
# Voegt geselecteerde VMs toe aan ssw.lab via PowerShell Direct.
# Dry Run is standaard AAN — zet vinkje uit om echt uit te voeren.
# ============================================================

. "$PSScriptRoot\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="SSW-Lab | Domain Join" Height="640" Width="620"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Lbl" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#A6ADC8"/><Setter Property="FontSize" Value="11"/>
      <Setter Property="Margin" Value="0,8,0,2"/>
    </Style>
    <Style x:Key="Fld" TargetType="TextBox">
      <Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="BorderBrush" Value="#45475A"/><Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="8,6"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="Height" Value="34"/>
    </Style>
    <Style x:Key="PwdFld" TargetType="PasswordBox">
      <Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="BorderBrush" Value="#45475A"/><Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="8,6"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="Height" Value="34"/>
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
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Margin="0,0,0,16">
      <TextBlock Text="Domain Join" Foreground="#CDD6F4" FontSize="20" FontWeight="SemiBold"/>
      <TextBlock Text="Voeg client-VMs toe aan het lab-domein" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock Text="Domein (FQDN)" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtDomain" Style="{StaticResource Fld}"/>
        <TextBlock Text="Domain admin gebruikersnaam" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtDomainAdmin" Style="{StaticResource Fld}"/>
        <TextBlock Text="Domain admin wachtwoord" Style="{StaticResource Lbl}"/>
        <PasswordBox x:Name="PwdDomain" Style="{StaticResource PwdFld}"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="Lokale admin gebruikersnaam (VMs)" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtLocalAdmin" Style="{StaticResource Fld}"/>
        <TextBlock Text="Lokaal admin wachtwoord (VMs)" Style="{StaticResource Lbl}"/>
        <PasswordBox x:Name="PwdLocal" Style="{StaticResource PwdFld}"/>
      </StackPanel>
    </Grid>

    <Border Grid.Row="2" Background="#313244" CornerRadius="6" Padding="16,12" Margin="0,12,0,0">
      <StackPanel>
        <TextBlock Text="Selecteer VMs om te joinen (DC01 overgeslagen)" Foreground="#A6ADC8" FontSize="11" Margin="0,0,0,8"/>
        <WrapPanel x:Name="VMPanel"/>
        <Button x:Name="BtnRefresh" Content="↻  VMs vernieuwen" Width="140" HorizontalAlignment="Left"
                Background="#45475A" Foreground="#CDD6F4" BorderThickness="0" Cursor="Hand"
                Height="28" FontSize="11" Margin="0,8,0,0"/>
      </StackPanel>
    </Border>

    <Border Grid.Row="3" Background="#181825" CornerRadius="6" Margin="0,12,0,0" Padding="10">
      <ScrollViewer VerticalScrollBarVisibility="Auto">
        <TextBox x:Name="LogBox" Background="Transparent" Foreground="#A6E3A1"
                 FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" BorderThickness="0"/>
      </ScrollViewer>
    </Border>

    <ProgressBar x:Name="Progress" Grid.Row="4" Height="6" Margin="0,10,0,0"
                 Background="#313244" Foreground="#89B4FA" BorderThickness="0" Minimum="0" Maximum="100" Value="0"/>

    <Border x:Name="DryRunBar" Grid.Row="5" CornerRadius="6" Margin="0,10,0,0" Padding="14,10" BorderThickness="1">
      <Grid>
        <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center">
          <TextBlock x:Name="DryRunTitle" FontWeight="SemiBold" FontSize="12"/>
          <TextBlock x:Name="DryRunSub" FontSize="11" Margin="0,2,0,0"/>
        </StackPanel>
        <CheckBox x:Name="ChkDryRun" Grid.Column="1" IsChecked="True"
                  Content="Dry Run" FontWeight="SemiBold" FontSize="12"
                  VerticalContentAlignment="Center" Margin="16,0,0,0"/>
      </Grid>
    </Border>

    <StackPanel Grid.Row="6" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
      <Button x:Name="BtnJoin" Content="Domain Join uitvoeren" Style="{StaticResource Btn}" Width="200"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader        = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$txtDomain     = $reader.FindName("TxtDomain")
$txtDomAdm     = $reader.FindName("TxtDomainAdmin")
$txtLocalAdm   = $reader.FindName("TxtLocalAdmin")
$pwdDomain     = $reader.FindName("PwdDomain")
$pwdLocal      = $reader.FindName("PwdLocal")
$vmPanel       = $reader.FindName("VMPanel")
$logBox        = $reader.FindName("LogBox")
$progress      = $reader.FindName("Progress")
$btnJoin       = $reader.FindName("BtnJoin")
$btnRefresh    = $reader.FindName("BtnRefresh")
$chkDryRun     = $reader.FindName("ChkDryRun")
$dryRunBar     = $reader.FindName("DryRunBar")
$dryRunTitle   = $reader.FindName("DryRunTitle")
$dryRunSub     = $reader.FindName("DryRunSub")
$conv          = [System.Windows.Media.BrushConverter]::new()
$profiles      = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json
$checkBoxes    = @{}

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "🔒  Dry Run — geen VMs worden gejoined"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk uit te voeren"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "⚠  LIVE UITVOERING — VMs worden gejoined en herstarten"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logBox.ScrollToEnd()
}

function Refresh-VMs {
    $vmPanel.Children.Clear()
    $checkBoxes.Clear()
    $vms = Get-VM | Where-Object { $_.Name -like "SSW-*" -and $_.Name -ne $profiles.DC01.Name }
    foreach ($vm in $vms) {
        $cb = [System.Windows.Controls.CheckBox]::new()
        $cb.Content = $vm.Name
        $cb.Tag = $vm.Name
        $cb.Foreground = $conv.ConvertFrom("#CDD6F4")
        $cb.FontSize = 12
        $cb.IsChecked = $true
        $cb.Margin = [System.Windows.Thickness]::new(0,0,16,4)
        $cb.VerticalContentAlignment = "Center"
        $vmPanel.Children.Add($cb)
        $checkBoxes[$vm.Name] = $cb
    }
    if ($vms.Count -eq 0) {
        $lbl = [System.Windows.Controls.TextBlock]::new()
        $lbl.Text = "Geen SSW-VMs gevonden (behalve DC01)."
        $lbl.Foreground = $conv.ConvertFrom("#F9E2AF")
        $lbl.FontSize = 12
        $vmPanel.Children.Add($lbl)
    }
}

$reader.Add_Loaded({
    $txtDomain.Text   = $SSWConfig.DomainName
    $txtDomAdm.Text   = $SSWConfig.DomainAdmin
    $txtLocalAdm.Text = $SSWConfig.AdminUser
    Refresh-VMs
    Update-DryRunBar
})

$chkDryRun.Add_Checked({   Update-DryRunBar })
$chkDryRun.Add_Unchecked({ Update-DryRunBar })
$btnRefresh.Add_Click({ Refresh-VMs })

$btnJoin.Add_Click({
    $btnJoin.IsEnabled = $false
    $logBox.Text = ""
    $progress.Value = 0
    $isDry      = $chkDryRun.IsChecked
    $domain     = $txtDomain.Text.Trim()
    $domAdmin   = $txtDomAdm.Text.Trim()
    $localAdmin = $txtLocalAdm.Text.Trim()
    $localPwd   = $pwdLocal.Password
    $domainPwd  = $pwdDomain.Password
    $pre        = if ($isDry) { "[DRY RUN] " } else { "" }

    if (-not $localAdmin) { [System.Windows.MessageBox]::Show("Vul een lokale admin gebruikersnaam in.", "SSW-Lab"); $btnJoin.IsEnabled = $true; return }
    if (-not $localPwd -or -not $domainPwd) { [System.Windows.MessageBox]::Show("Vul beide wachtwoorden in.", "SSW-Lab"); $btnJoin.IsEnabled = $true; return }

    $sel = $checkBoxes.GetEnumerator() | Where-Object { $_.Value.IsChecked } | ForEach-Object { $_.Key }
    if ($sel.Count -eq 0) { Write-Log "Geen VMs geselecteerd."; $btnJoin.IsEnabled = $true; return }

    $step = [math]::Floor(100 / $sel.Count); $done = 0

    foreach ($vmName in $sel) {
        Write-Log "${pre}Add-Computer '$vmName' → $domain (lokaal: $localAdmin, domain admin: $domAdmin)"

        if (-not $isDry) {
            $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
            if (-not $vm) { Write-Log "$vmName niet gevonden."; continue }
            if ($vm.State -ne "Running") { Start-VM -Name $vmName; Start-Sleep -Seconds 30 }

            $localCred = [PSCredential]::new(
                "$vmName\$localAdmin",
                (ConvertTo-SecureString $localPwd -AsPlainText -Force)
            )
            $domCred = [PSCredential]::new(
                "$($SSWConfig.DomainNetBIOS)\$domAdmin",
                (ConvertTo-SecureString $domainPwd -AsPlainText -Force)
            )
            try {
                Invoke-Command -VMName $vmName -Credential $localCred -ScriptBlock {
                    param($dom, $cred)
                    Add-Computer -DomainName $dom -Credential $cred -Restart -Force -ErrorAction Stop
                } -ArgumentList $domain, $domCred
                Write-Log "✔ $vmName wordt herstart en joint $domain"
            } catch { Write-Log "FOUT $vmName`: $_" }
        }

        $done += $step
        $progress.Value = [math]::Min($done, 100)
    }

    $progress.Value = 100
    Write-Log $(if ($isDry) { "✔ Dry Run klaar — niets uitgevoerd." } else { "✔ Domain join voltooid." })
    $btnJoin.IsEnabled = $true
})

$reader.ShowDialog() | Out-Null
