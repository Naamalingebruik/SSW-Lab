#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | 04-SETUP-DC.ps1
# Configureert SSW-DC01 als domain controller voor ssw.lab.
# Dry Run is standaard AAN — zet vinkje uit om echt uit te voeren.
# ============================================================

. "$PSScriptRoot\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Domain Controller inrichten" Height="640" Width="640"
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
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Background" Value="#89B4FA"/><Setter Property="Foreground" Value="#1E1E2E"/>
      <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="36"/>
    </Style>
    <Style x:Key="PwdFld" TargetType="PasswordBox">
      <Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="BorderBrush" Value="#45475A"/><Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="8,6"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="Height" Value="34"/>
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
      <TextBlock Text="Domain Controller inrichten" Foreground="#CDD6F4" FontSize="20" FontWeight="SemiBold"/>
      <TextBlock Text="AD DS installeren en DC01 promoveren tot domain controller"
                 Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock Text="VM naam (Hyper-V)" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtVMName" Style="{StaticResource Fld}"/>
        <TextBlock Text="Domeinnaam (FQDN)" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtDomain" Style="{StaticResource Fld}"/>
        <TextBlock Text="NetBIOS naam" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtNetBIOS" Style="{StaticResource Fld}"/>
        <TextBlock Text="Statisch IP voor DC" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtDCIP" Style="{StaticResource Fld}"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="Lokaal admin wachtwoord (VM lokale admin)" Style="{StaticResource Lbl}"/>
        <PasswordBox x:Name="PwdAdmin" Style="{StaticResource PwdFld}"/>
        <TextBlock Text="DSRM wachtwoord (herstelwachtwoord)" Style="{StaticResource Lbl}"/>
        <PasswordBox x:Name="PwdDSRM" Style="{StaticResource PwdFld}"/>
        <TextBlock Text="Extra domain admin gebruikersnaam" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtDomainAdmin" Style="{StaticResource Fld}"/>
        <TextBlock Text="Wordt na DC-promotie aangemaakt als Domain Admin (zelfde wachtwoord als Administrator)."
                   Foreground="#A6ADC8" FontSize="10" TextWrapping="Wrap" Margin="0,4,0,0"/>
      </StackPanel>
    </Grid>

    <Border Grid.Row="2" Background="#181825" CornerRadius="6" Margin="0,16,0,0" Padding="10">
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
          <TextBlock x:Name="DryRunSub" FontSize="11" Margin="0,2,0,0"/>
        </StackPanel>
        <CheckBox x:Name="ChkDryRun" Grid.Column="1" IsChecked="True"
                  Content="Dry Run" FontWeight="SemiBold" FontSize="12"
                  VerticalContentAlignment="Center" Margin="16,0,0,0"/>
      </Grid>
    </Border>

    <StackPanel Grid.Row="5" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
      <Button x:Name="BtnSetup" Content="DC inrichten" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="140"/>
      <Button x:Name="BtnNext"  Content="Doorgaan naar 05-JOIN-DOMAIN →" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False" Width="240"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader        = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$txtVM          = $reader.FindName("TxtVMName")
$txtDomain      = $reader.FindName("TxtDomain")
$txtNB          = $reader.FindName("TxtNetBIOS")
$txtDomainAdmin = $reader.FindName("TxtDomainAdmin")
$pwdAdmin       = $reader.FindName("PwdAdmin")
$pwdDSRM        = $reader.FindName("PwdDSRM")
$txtDCIP        = $reader.FindName("TxtDCIP")
$logBox        = $reader.FindName("LogBox")
$progress      = $reader.FindName("Progress")
$btnSetup      = $reader.FindName("BtnSetup")
$btnNext       = $reader.FindName("BtnNext")
$chkDryRun     = $reader.FindName("ChkDryRun")
$dryRunBar     = $reader.FindName("DryRunBar")
$dryRunTitle   = $reader.FindName("DryRunTitle")
$dryRunSub     = $reader.FindName("DryRunSub")
$conv          = [System.Windows.Media.BrushConverter]::new()
$profiles      = Get-Content $SSWConfig.ProfilePath -Raw | ConvertFrom-Json

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "🔒  Dry Run — geen wijzigingen in de VM"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk uit te voeren"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
        $btnSetup.Content       = "Simuleren (Dry Run)"
        $btnSetup.Background    = $conv.ConvertFrom("#89B4FA")
        $btnSetup.Foreground    = $conv.ConvertFrom("#1E1E2E")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "⚠  LIVE UITVOERING — DC01 wordt geconfigureerd en herstart"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
        $btnSetup.Content       = "LIVE DC inrichten"
        $btnSetup.Background    = $conv.ConvertFrom("#F38BA8")
        $btnSetup.Foreground    = $conv.ConvertFrom("#1E1E2E")
    }
}

$reader.Add_Loaded({
    $txtVM.Text             = $profiles.DC01.Name
    $txtDomain.Text         = $SSWConfig.DomainName
    $txtNB.Text             = $SSWConfig.DomainNetBIOS
    $txtDCIP.Text           = $SSWConfig.DCIP
    $txtDomainAdmin.Text    = $SSWConfig.DomainAdmin
    Update-DryRunBar
})

$chkDryRun.Add_Checked({   Update-DryRunBar })
$chkDryRun.Add_Unchecked({ Update-DryRunBar })

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logBox.ScrollToEnd()
}

$btnSetup.Add_Click({
    $btnSetup.IsEnabled = $false
    $isDry          = $chkDryRun.IsChecked
    $vmName         = $txtVM.Text.Trim()
    $domain         = $txtDomain.Text.Trim()
    $netbios        = $txtNB.Text.Trim()
    $adminPwd       = $pwdAdmin.Password
    $dsrmPwd        = $pwdDSRM.Password
    $domainAdmin    = $txtDomainAdmin.Text.Trim()
    $dcIP           = $txtDCIP.Text.Trim()
    $localUser      = $SSWConfig.AdminUser
    $pre            = if ($isDry) { "[DRY RUN] " } else { "" }

    if (-not $adminPwd -or -not $dsrmPwd) { [System.Windows.MessageBox]::Show("Vul lokaal admin wachtwoord en DSRM wachtwoord in.", "SSW-Lab"); $btnSetup.IsEnabled = $true; return }
    if (-not $domainAdmin) { [System.Windows.MessageBox]::Show("Vul een extra domain admin gebruikersnaam in.", "SSW-Lab"); $btnSetup.IsEnabled = $true; return }

    if ($isDry) {
        Write-Log "${pre}Verbinding: PowerShell Direct → $vmName als $localUser"
        Write-Log "${pre}Set-NetIPAddress $dcIP/24 op netwerk adapter"
        Write-Log "${pre}Rename-Computer -NewName DC01"
        Write-Log "${pre}Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
        Write-Log "${pre}Install-ADDSForest -DomainName $domain -DomainNetbiosName $netbios -InstallDns"
        Write-Log "${pre}VM wordt herstart na promotie"
        Write-Log "${pre}New-ADUser '$domainAdmin' — lid van Domain Admins"
        Write-Log "✔ Dry Run klaar — niets uitgevoerd."
        $progress.Value = 100
        $btnNext.IsEnabled = $true
        $btnSetup.IsEnabled = $true
        return
    }

    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm) { Write-Log "VM '$vmName' niet gevonden."; $btnSetup.IsEnabled = $true; return }
    if ($vm.State -ne "Running") {
        Write-Log "VM starten…"
        Start-VM -Name $vmName
        Write-Log "Wachten 60 sec…"
        Start-Sleep -Seconds 60
    }

    $cred = [PSCredential]::new(
      ".\$localUser",
        (ConvertTo-SecureString $adminPwd -AsPlainText -Force)
    )

    try {
        Write-Log "Verbinding via PowerShell Direct…"
        $progress.Value = 10

        Write-Log "IP $dcIP instellen…"
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            param($ip, $gw)
            $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
            New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $ip -PrefixLength 24 -DefaultGateway $gw -ErrorAction SilentlyContinue | Out-Null
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "127.0.0.1" | Out-Null
        } -ArgumentList $dcIP, $SSWConfig.GatewayIP
        $progress.Value = 25

        Write-Log "Computernaam instellen (DC01)…"
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            if ($env:COMPUTERNAME -ne "DC01") { Rename-Computer -NewName "DC01" -Force -ErrorAction SilentlyContinue }
        }
        $progress.Value = 35

        Write-Log "AD DS installeren…"
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop | Out-Null
        }
        $progress.Value = 60
        Write-Log "AD DS geïnstalleerd."

        Write-Log "Forest '$domain' aanmaken…"
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            param($dom, $nb, $dsrm)
            $secDSRM = ConvertTo-SecureString $dsrm -AsPlainText -Force
            Install-ADDSForest -DomainName $dom -DomainNetbiosName $nb `
                -SafeModeAdministratorPassword $secDSRM -InstallDns:$true `
                -NoRebootOnCompletion:$false -Force -ErrorAction Stop | Out-Null
        } -ArgumentList $domain, $netbios, $dsrmPwd
        $progress.Value = 90
        Write-Log "Forest aangemaakt. DC herstart — wachten tot DC weer online is…"
        $domCred = [PSCredential]::new(
          "$netbios\Administrator",
            (ConvertTo-SecureString $adminPwd -AsPlainText -Force)
        )
        $online = $false
        $deadline = (Get-Date).AddMinutes(5)
        while (-not $online -and (Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 15
            try {
                Invoke-Command -VMName $vmName -Credential $domCred `
                    -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop | Out-Null
                $online = $true
            } catch { }
        }
        if (-not $online) { throw "DC is na 5 minuten nog niet bereikbaar." }

        Write-Log "Extra domain admin '$domainAdmin' aanmaken in AD…"
        Invoke-Command -VMName $vmName -Credential $domCred -ScriptBlock {
          param($user, $plainPassword, $nb)
          $sec = ConvertTo-SecureString $plainPassword -AsPlainText -Force
            New-ADUser -Name $user -SamAccountName $user -AccountPassword $sec `
                -Enabled $true -PasswordNeverExpires $true -ErrorAction Stop
            Add-ADGroupMember -Identity "Domain Admins" -Members $user -ErrorAction Stop
        } -ArgumentList $domainAdmin, $adminPwd, $netbios
        Write-Log "✔ '$domainAdmin' aangemaakt en toegevoegd aan Domain Admins."

        $progress.Value = 100
        Write-Log "✔ DC01 klaar als domain controller voor $domain"
        $btnNext.IsEnabled = $true
    } catch {
        Write-Log "FOUT: $_"
        $btnSetup.IsEnabled = $true
        return
    }
    $btnSetup.IsEnabled = $true
})

$btnNext.Add_Click({
    $reader.Close()
    $next = Join-Path $PSScriptRoot "05-JOIN-DOMAIN.ps1"
    if (Test-Path $next) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" -Verb RunAs }
})

$reader.ShowDialog() | Out-Null


