#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Initialize-DomainController.ps1
# Configureert LAB-DC01 als domain controller voor ssw.lab.
# Dry Run is standaard AAN — zet vinkje uit om echt uit te voeren.
# ============================================================

$modulePath = Join-Path $PSScriptRoot '..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force
$SSWConfig = Import-SSWLabConfig -ConfigPath (Join-Path $PSScriptRoot '..\config.ps1')

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
      <Button x:Name="BtnNext"  Content="Doorgaan naar Join-LabComputersToDomain →" Style="{StaticResource Btn}"
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
$profiles      = Get-SSWVmProfiles -Config $SSWConfig

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "[DRY RUN] Geen wijzigingen in de VM"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk uit te voeren"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "[LIVE] DC01 wordt geconfigureerd en herstart"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

$reader.Add_Loaded({
    $txtVM.Text             = (Get-SSWVmProfile -Profiles $profiles -Name 'DC01').Name
    $txtDomain.Text         = $SSWConfig.DomainName
    $txtNB.Text             = $SSWConfig.DomainNetBIOS
    $txtDCIP.Text           = $SSWConfig.DCIP
    $txtDomainAdmin.Text    = $SSWConfig.DomainAdmin
    $savedSecret            = Get-SSWSecret -Name 'SSWLab-LabPassword' -Config $SSWConfig -ConfigValueName 'LabPassword' -EnvironmentVariableName 'SSW_LAB_PASSWORD' -AsPlainText
    if ($savedSecret) {
        $pwdAdmin.Password = $savedSecret
    }
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

    if (-not $adminPwd) {
        $adminPwd = Get-SSWSecret -Name 'SSWLab-LabPassword' -Config $SSWConfig -ConfigValueName 'LabPassword' -EnvironmentVariableName 'SSW_LAB_PASSWORD' -AsPlainText
    }
    if (-not $dsrmPwd) {
        $dsrmPwd = Get-SSWSecret -Name 'SSWLab-DSRMPassword' -EnvironmentVariableName 'SSW_DSRM_PASSWORD' -AsPlainText
    }
    if (-not $dsrmPwd) {
        $dsrmPwd = $adminPwd
    }

    if (-not $adminPwd -or -not $dsrmPwd) { [System.Windows.MessageBox]::Show("Vul lokaal admin wachtwoord en DSRM wachtwoord in.", "SSW-Lab"); $btnSetup.IsEnabled = $true; return }
    if (-not $domainAdmin) { [System.Windows.MessageBox]::Show("Vul een extra domain admin gebruikersnaam in.", "SSW-Lab"); $btnSetup.IsEnabled = $true; return }

    $policyResult = Test-SSWSecretPolicy -Secret $adminPwd
    if (-not $policyResult.IsValid) {
        [System.Windows.MessageBox]::Show(("Wachtwoord voldoet niet aan het minimale labbeleid:`n- " + ($policyResult.Findings -join "`n- ")), "SSW-Lab")
        $btnSetup.IsEnabled = $true
        return
    }

    if ($isDry) {
        Write-Log "${pre}Verbinding: PowerShell Direct -> $vmName als $localUser"
        Write-Log "${pre}Set-NetIPAddress $dcIP/24 op netwerk adapter"
        Write-Log "${pre}Rename-Computer -NewName DC01"
        Write-Log "${pre}Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
        Write-Log "${pre}Install-ADDSForest -DomainName $domain -DomainNetbiosName $netbios -InstallDns"
        Write-Log "${pre}VM wordt herstart na promotie"
        Write-Log "${pre}New-ADUser '$domainAdmin' - lid van Domain Admins"
        Write-Log "${pre}Install-WindowsFeature DHCP - scope 10.50.10.100-200 aanmaken"
        Write-Log "${pre}DHCP-reservering 10.50.10.30 voor LAB-W11-AUTOPILOT (op basis van MAC)"
        Write-Log "Dry Run klaar - niets uitgevoerd."
        $progress.Value = 100
        $btnNext.IsEnabled = $true
        $btnSetup.IsEnabled = $true
        return
    }

    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm) { Write-Log "VM '$vmName' niet gevonden."; $btnSetup.IsEnabled = $true; return }
    if ($vm.State -ne "Running") {
        Write-Log "VM starten..."
        Start-VM -Name $vmName
        Write-Log "Wachten 60 sec..."
        Start-Sleep -Seconds 60
    }

    $cred = New-SSWCredential -UserName "$vmName\$localUser" -Password (ConvertTo-SSWSecureString -Value $adminPwd)

    try {
        Write-Log "Verbinding via PowerShell Direct..."
        $progress.Value = 10

        Write-Log "IP $dcIP instellen..."
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            param($ip, $gw)
            $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
            New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $ip -PrefixLength 24 -DefaultGateway $gw -ErrorAction SilentlyContinue | Out-Null
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "127.0.0.1" | Out-Null
        } -ArgumentList $dcIP, $SSWConfig.GatewayIP
        $progress.Value = 25

        $desiredName = ($vmName -replace "^LAB-","" ) # bijv. LAB-DC01 → DC01, of gebruik de volledige naam
        $desiredName = $vmName                        # Windows-naam = Hyper-V VM-naam (bijv. LAB-DC01)
        Write-Log "Computernaam instellen ($desiredName)..."
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            param($n)
            if ($env:COMPUTERNAME -ne $n) { Rename-Computer -NewName $n -Force -ErrorAction SilentlyContinue }
        } -ArgumentList $desiredName
        $progress.Value = 35

        Write-Log "AD DS installeren..."
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop | Out-Null
        }
        $progress.Value = 60
        Write-Log "AD DS geïnstalleerd."

        Write-Log "Forest '$domain' aanmaken..."
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            param($dom, $nb, $dsrm)
            $secDSRM = New-Object System.Security.SecureString
            foreach ($character in $dsrm.ToCharArray()) {
                $secDSRM.AppendChar($character)
            }
            $secDSRM.MakeReadOnly()
            Install-ADDSForest -DomainName $dom -DomainNetbiosName $nb `
                -SafeModeAdministratorPassword $secDSRM -InstallDns:$true `
                -NoRebootOnCompletion:$false -Force -ErrorAction Stop | Out-Null
        } -ArgumentList $domain, $netbios, $dsrmPwd
        $progress.Value = 90
        Write-Log "Forest aangemaakt. DC herstart - wachten tot DC weer online is..."
        $domCred = New-SSWCredential -UserName "$domain\Administrator" -Password (ConvertTo-SSWSecureString -Value $adminPwd)
        $online = $false
        $deadline = (Get-Date).AddMinutes(5)
        while (-not $online -and (Get-Date) -lt $deadline) {
            Start-Sleep -Seconds 15
            try {
                Invoke-Command -VMName $vmName -Credential $domCred `
                    -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop | Out-Null
                $online = $true
            } catch {
                Write-Verbose "DC nog niet bereikbaar via PS Direct: $($_.Exception.Message)"
            }
        }
        if (-not $online) { throw "DC is na 5 minuten nog niet bereikbaar." }

        Write-Log "Extra domain admin '$domainAdmin' aanmaken in AD..."
        Invoke-Command -VMName $vmName -Credential $domCred -ScriptBlock {
            param([string]$user, [securestring]$password)
            New-ADUser -Name $user -SamAccountName $user -AccountPassword $password `
                -Enabled $true -PasswordNeverExpires $true -ErrorAction Stop
            Add-ADGroupMember -Identity "Domain Admins" -Members $user -ErrorAction Stop
        } -ArgumentList $domainAdmin, (ConvertTo-SSWSecureString -Value $adminPwd)
        Write-Log "'$domainAdmin' aangemaakt en toegevoegd aan Domain Admins."

        # ── DHCP-server + Autopilot IP-reservering ──────────────────────────────
        # Na een Autopilot-reset wordt Windows opnieuw geïnstalleerd en raakt een
        # handmatig ingesteld statisch IP kwijt. De oplossing: DHCP op de DC met
        # een vaste reservering op basis van het Hyper-V MAC-adres. Dit MAC-adres
        # verandert nooit, ook niet na een Autopilot-reset of OS-herinstallatie.
        Write-Log "DHCP-server installeren en Autopilot IP-reservering aanmaken..."

        # MAC-adres van Autopilot-VM ophalen via Hyper-V (host-kant)
        $apVMName  = (Get-SSWVmProfile -Profiles $profiles -Name 'W11-AUTOPILOT').Name
        $apAdapter = Get-VMNetworkAdapter -VMName $apVMName -ErrorAction SilentlyContinue |
                     Select-Object -First 1
        $apReservedIP = '10.50.10.30'
        $apMAC = $null
        if ($apAdapter -and $apAdapter.MacAddress) {
            # Hyper-V levert '001234ABCDEF' -> DHCP verwacht '00-12-34-AB-CD-EF'
            $apMAC = ($apAdapter.MacAddress -replace '[:\-]', '') `
                     -replace '(..)(..)(..)(..)(..)(..)', '$1-$2-$3-$4-$5-$6'
        } else {
            Write-Log "  WAARSCHUWING: MAC van '$apVMName' niet gevonden (VM nog niet aangemaakt?) - reservering later instelbaar via utility\Start-LabVMs.ps1."
        }

        $dhcpResult = Invoke-Command -VMName $vmName -Credential $domCred -ScriptBlock {
            param($scopeID, $scopeStart, $scopeEnd, $gateway, $dns, $apIP, $apMAC)
            $out = [System.Collections.Generic.List[string]]::new()

            # DHCP-server feature
            $fqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN"
            if (-not (Get-WindowsFeature DHCP).Installed) {
                Install-WindowsFeature DHCP -IncludeManagementTools -ErrorAction Stop | Out-Null
                Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' `
                    -Name 'ConfigurationState' -Value 2 -ErrorAction SilentlyContinue
                $out.Add("DHCP-server geïnstalleerd.")
            } else {
                $out.Add("DHCP-server was al aanwezig.")
            }
            # Autorisatie altijd controleren en herstellen (ook als DHCP al eerder was geïnstalleerd)
            $authorized = Get-DhcpServerInDC -ErrorAction SilentlyContinue | Where-Object { $_.DnsName -ieq $fqdn }
            if (-not $authorized) {
                try {
                    Add-DhcpServerInDC -DnsName $fqdn -ErrorAction Stop
                    Restart-Service DHCPServer -ErrorAction SilentlyContinue
                    $out.Add("DHCP-server geautoriseerd in AD ($fqdn) en service herstart.")
                } catch {
                    $out.Add("WAARSCHUWING: DHCP-autorisatie mislukt: $_")
                }
            } else {
                $out.Add("DHCP-server was al geautoriseerd in AD.")
            }

            # DHCP-scope
            if (-not (Get-DhcpServerv4Scope -ScopeId $scopeID -ErrorAction SilentlyContinue)) {
                Add-DhcpServerv4Scope -Name 'SSW-Lab' `
                    -StartRange $scopeStart -EndRange $scopeEnd `
                    -SubnetMask '255.255.255.0' -State Active | Out-Null
                Set-DhcpServerv4OptionValue -ScopeId $scopeID `
                    -Router $gateway -DnsServer $dns -ErrorAction SilentlyContinue | Out-Null
                $out.Add("DHCP-scope $scopeID aangemaakt ($scopeStart - $scopeEnd).")
            } else {
                $out.Add("DHCP-scope $scopeID bestond al.")
            }

            # Exclusion range: .1-.99 zijn infrastructuur-IPs (gateway=.1, DC=.10, MGMT=.20, Autopilot=.30).
            # DHCP mag nooit een willekeurige client een IP in dit bereik geven - dat veroorzaakt IP-conflicten.
            $excl = Get-DhcpServerv4ExclusionRange -ScopeId $scopeID -ErrorAction SilentlyContinue |
                    Where-Object { $_.StartRange -eq '10.50.10.1' }
            if (-not $excl) {
                Add-DhcpServerv4ExclusionRange -ScopeId $scopeID -StartRange '10.50.10.1' -EndRange '10.50.10.99' -ErrorAction SilentlyContinue
                $out.Add("DHCP-exclusie 10.50.10.1-99 aangemaakt (infrastructuur-IPs beschermd).")
            } else {
                $out.Add("DHCP-exclusie 10.50.10.1-99 bestond al.")
            }

            # Vaste reservering voor Autopilot-VM
            if ($apMAC) {
                $existing = Get-DhcpServerv4Reservation -ScopeId $scopeID -ErrorAction SilentlyContinue |
                            Where-Object { $_.ClientId -ieq $apMAC }
                if (-not $existing) {
                    Add-DhcpServerv4Reservation -ScopeId $scopeID -IPAddress $apIP `
                        -ClientId $apMAC -Description 'LAB-W11-AUTOPILOT - vaste DHCP-reservering' | Out-Null
                    $out.Add("DHCP-reservering $apIP aangemaakt voor Autopilot-VM (MAC $apMAC).")
                } else {
                    $out.Add("DHCP-reservering voor Autopilot-VM ($apIP) bestond al.")
                }
            }
            return $out
        } -ArgumentList '10.50.10.0', '10.50.10.100', '10.50.10.200',
                         $SSWConfig.GatewayIP, $SSWConfig.DCIP, $apReservedIP, $apMAC

        foreach ($line in $dhcpResult) { Write-Log "  $line" }
        Write-Log "DHCP gereed - Autopilot-VM krijgt altijd $apReservedIP (ook na Autopilot-reset)."
        # ── Einde DHCP-setup ────────────────────────────────────────────────────

        $progress.Value = 100
        Write-Log "DC01 klaar als domain controller voor $domain"
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
    $next = Join-Path $PSScriptRoot "Join-LabComputersToDomain.ps1"
    if (Test-Path $next) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" -Verb RunAs }
})

$reader.ShowDialog() | Out-Null

