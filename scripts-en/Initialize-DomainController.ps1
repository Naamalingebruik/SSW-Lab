#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Initialize-DomainController.ps1
# Configures LAB-DC01 as a domain controller for ssw.lab.
# Dry Run is on by default — uncheck to apply changes.
# ============================================================

$modulePath = Join-Path $PSScriptRoot '..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force
$SSWConfig = Import-SSWLabConfig -ConfigPath (Join-Path $PSScriptRoot '..\config.ps1')

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Configure Domain Controller" Height="640" Width="640"
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
      <TextBlock Text="Configure Domain Controller" Foreground="#CDD6F4" FontSize="20" FontWeight="SemiBold"/>
      <TextBlock Text="Install AD DS and promote DC01 to domain controller"
                 Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock Text="VM name (Hyper-V)" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtVMName" Style="{StaticResource Fld}"/>
        <TextBlock Text="Domain name (FQDN)" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtDomain" Style="{StaticResource Fld}"/>
        <TextBlock Text="NetBIOS name" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtNetBIOS" Style="{StaticResource Fld}"/>
        <TextBlock Text="Static IP for DC" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtDCIP" Style="{StaticResource Fld}"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="Local admin password (VM local admin)" Style="{StaticResource Lbl}"/>
        <PasswordBox x:Name="PwdAdmin" Style="{StaticResource PwdFld}"/>
        <TextBlock Text="DSRM password (recovery password)" Style="{StaticResource Lbl}"/>
        <PasswordBox x:Name="PwdDSRM" Style="{StaticResource PwdFld}"/>
        <TextBlock Text="Extra domain admin username" Style="{StaticResource Lbl}"/>
        <TextBox x:Name="TxtDomainAdmin" Style="{StaticResource Fld}"/>
        <TextBlock Text="Will be created after DC promotion as Domain Admin (same password as Administrator)."
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
      <Button x:Name="BtnSetup" Content="Configure DC" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="140"/>
      <Button x:Name="BtnNext"  Content="Continue to Join-LabComputersToDomain →" Style="{StaticResource Btn}"
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

function Show-DryRunState {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "[DRY RUN] No changes in the VM"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Uncheck to actually apply changes"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "[LIVE] DC01 will be configured and restarted"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Check again to go back to Dry Run"
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
    Show-DryRunState
})

$chkDryRun.Add_Checked({   Show-DryRunState })
$chkDryRun.Add_Unchecked({ Show-DryRunState })

function Add-UiLog($msg) {
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

    if (-not $adminPwd -or -not $dsrmPwd) { [System.Windows.MessageBox]::Show("Enter local admin password and DSRM password.", "SSW-Lab"); $btnSetup.IsEnabled = $true; return }
    if (-not $domainAdmin) { [System.Windows.MessageBox]::Show("Enter an extra domain admin username.", "SSW-Lab"); $btnSetup.IsEnabled = $true; return }

    $policyResult = Test-SSWSecretPolicy -Secret $adminPwd
    if (-not $policyResult.IsValid) {
        [System.Windows.MessageBox]::Show(("Password does not meet the minimum lab policy:`n- " + ($policyResult.Findings -join "`n- ")), "SSW-Lab")
        $btnSetup.IsEnabled = $true
        return
    }

    if ($isDry) {
        Add-UiLog "${pre}Connection: PowerShell Direct -> $vmName as $localUser"
        Add-UiLog "${pre}Set-NetIPAddress $dcIP/24 on network adapter"
        Add-UiLog "${pre}Rename-Computer -NewName DC01"
        Add-UiLog "${pre}Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools"
        Add-UiLog "${pre}Install-ADDSForest -DomainName $domain -DomainNetbiosName $netbios -InstallDns"
        Add-UiLog "${pre}VM will restart after promotion"
        Add-UiLog "${pre}New-ADUser '$domainAdmin' - added to Domain Admins"
        Add-UiLog "${pre}Install-WindowsFeature DHCP - create scope 10.50.10.100-200"
        Add-UiLog "${pre}DHCP reservation 10.50.10.30 for LAB-W11-AUTOPILOT (based on MAC)"
        Add-UiLog "Dry Run complete - nothing applied."
        $progress.Value = 100
        $btnNext.IsEnabled = $true
        $btnSetup.IsEnabled = $true
        return
    }

    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm) { Add-UiLog "VM '$vmName' not found."; $btnSetup.IsEnabled = $true; return }
    if ($vm.State -ne "Running") {
        Add-UiLog "Starting VM..."
        Start-VM -Name $vmName
        Add-UiLog "Waiting 60 seconds..."
        Start-Sleep -Seconds 60
    }

    $cred = New-SSWCredential -UserName "$vmName\$localUser" -Password (ConvertTo-SSWSecureString -Value $adminPwd)

    try {
        Add-UiLog "Connecting via PowerShell Direct..."
        $progress.Value = 10

        Add-UiLog "Setting IP $dcIP..."
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            param($ip, $gw)
            $adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
            New-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -IPAddress $ip -PrefixLength 24 -DefaultGateway $gw -ErrorAction SilentlyContinue | Out-Null
            Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses "127.0.0.1" | Out-Null
        } -ArgumentList $dcIP, $SSWConfig.GatewayIP
        $progress.Value = 25

        $desiredName = ($vmName -replace "^LAB-","" ) # e.g. LAB-DC01 -> DC01, or use the full name
        $desiredName = $vmName                        # Windows name = Hyper-V VM name (e.g. LAB-DC01)
        Add-UiLog "Setting computer name ($desiredName)..."
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            param($n)
            if ($env:COMPUTERNAME -ne $n) { Rename-Computer -NewName $n -Force -ErrorAction SilentlyContinue }
        } -ArgumentList $desiredName
        $progress.Value = 35

        Add-UiLog "Installing AD DS..."
        Invoke-Command -VMName $vmName -Credential $cred -ScriptBlock {
            Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop | Out-Null
        }
        $progress.Value = 60
        Add-UiLog "AD DS installed."

        Add-UiLog "Creating forest '$domain'..."
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
        Add-UiLog "Forest created. DC restarting - waiting for DC to come back online..."
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
                Write-Verbose "DC not yet reachable via PS Direct: $($_.Exception.Message)"
            }
        }
        if (-not $online) { throw "DC is still not reachable after 5 minutes." }

        Add-UiLog "Creating extra domain admin '$domainAdmin' in AD..."
        Invoke-Command -VMName $vmName -Credential $domCred -ScriptBlock {
            param([string]$user, [securestring]$password)
            New-ADUser -Name $user -SamAccountName $user -AccountPassword $password `
                -Enabled $true -PasswordNeverExpires $true -ErrorAction Stop
            Add-ADGroupMember -Identity "Domain Admins" -Members $user -ErrorAction Stop
        } -ArgumentList $domainAdmin, (ConvertTo-SSWSecureString -Value $adminPwd)
        Add-UiLog "'$domainAdmin' created and added to Domain Admins."

        # ── DHCP server + Autopilot IP reservation ──────────────────────────────
        # After an Autopilot reset, Windows is reinstalled and a manually set static
        # IP is lost. Solution: DHCP on the DC with a fixed reservation based on the
        # Hyper-V MAC address. This MAC never changes, even after an Autopilot reset
        # or OS reinstallation.
        Add-UiLog "Installing DHCP server and creating Autopilot IP reservation..."

        # Get MAC address of Autopilot VM via Hyper-V (host side)
        $apVMName  = (Get-SSWVmProfile -Profiles $profiles -Name 'W11-AUTOPILOT').Name
        $apAdapter = Get-VMNetworkAdapter -VMName $apVMName -ErrorAction SilentlyContinue |
                     Select-Object -First 1
        $apReservedIP = '10.50.10.30'
        $apMAC = $null
        if ($apAdapter -and $apAdapter.MacAddress) {
            # Hyper-V provides '001234ABCDEF' -> DHCP expects '00-12-34-AB-CD-EF'
            $apMAC = ($apAdapter.MacAddress -replace '[:\-]', '') `
                     -replace '(..)(..)(..)(..)(..)(..)', '$1-$2-$3-$4-$5-$6'
        } else {
            Add-UiLog "  WARNING: MAC of '$apVMName' not found (VM not yet created?) - reservation can be set later via utility\Start-LabVMs.ps1."
        }

        $dhcpResult = Invoke-Command -VMName $vmName -Credential $domCred -ScriptBlock {
            param($scopeID, $scopeStart, $scopeEnd, $gateway, $dns, $apIP, $apMAC)
            $out = [System.Collections.Generic.List[string]]::new()

            # DHCP server feature
            $fqdn = "$env:COMPUTERNAME.$env:USERDNSDOMAIN"
            if (-not (Get-WindowsFeature DHCP).Installed) {
                Install-WindowsFeature DHCP -IncludeManagementTools -ErrorAction Stop | Out-Null
                Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12' `
                    -Name 'ConfigurationState' -Value 2 -ErrorAction SilentlyContinue
                $out.Add("DHCP server installed.")
            } else {
                $out.Add("DHCP server already present.")
            }
            # Always check and fix authorization (even if DHCP was already installed before)
            $authorized = Get-DhcpServerInDC -ErrorAction SilentlyContinue | Where-Object { $_.DnsName -ieq $fqdn }
            if (-not $authorized) {
                try {
                    Add-DhcpServerInDC -DnsName $fqdn -ErrorAction Stop
                    Restart-Service DHCPServer -ErrorAction SilentlyContinue
                    $out.Add("DHCP server authorized in AD ($fqdn) and service restarted.")
                } catch {
                    $out.Add("WARNING: DHCP authorization failed: $_")
                }
            } else {
                $out.Add("DHCP server already authorized in AD.")
            }

            # DHCP scope
            if (-not (Get-DhcpServerv4Scope -ScopeId $scopeID -ErrorAction SilentlyContinue)) {
                Add-DhcpServerv4Scope -Name 'SSW-Lab' `
                    -StartRange $scopeStart -EndRange $scopeEnd `
                    -SubnetMask '255.255.255.0' -State Active | Out-Null
                Set-DhcpServerv4OptionValue -ScopeId $scopeID `
                    -Router $gateway -DnsServer $dns -ErrorAction SilentlyContinue | Out-Null
                $out.Add("DHCP scope $scopeID created ($scopeStart - $scopeEnd).")
            } else {
                $out.Add("DHCP scope $scopeID already exists.")
            }

            # Exclusion range: .1-.99 are infrastructure IPs (gateway=.1, DC=.10, MGMT=.20, Autopilot=.30).
            # DHCP must never assign a random client an IP in this range - that causes IP conflicts.
            $excl = Get-DhcpServerv4ExclusionRange -ScopeId $scopeID -ErrorAction SilentlyContinue |
                    Where-Object { $_.StartRange -eq '10.50.10.1' }
            if (-not $excl) {
                Add-DhcpServerv4ExclusionRange -ScopeId $scopeID -StartRange '10.50.10.1' -EndRange '10.50.10.99' -ErrorAction SilentlyContinue
                $out.Add("DHCP exclusion 10.50.10.1-99 created (infrastructure IPs protected).")
            } else {
                $out.Add("DHCP exclusion 10.50.10.1-99 already exists.")
            }

            # Fixed reservation for Autopilot VM
            if ($apMAC) {
                $existing = Get-DhcpServerv4Reservation -ScopeId $scopeID -ErrorAction SilentlyContinue |
                            Where-Object { $_.ClientId -ieq $apMAC }
                if (-not $existing) {
                    Add-DhcpServerv4Reservation -ScopeId $scopeID -IPAddress $apIP `
                        -ClientId $apMAC -Description 'LAB-W11-AUTOPILOT - fixed DHCP reservation' | Out-Null
                    $out.Add("DHCP reservation $apIP created for Autopilot VM (MAC $apMAC).")
                } else {
                    $out.Add("DHCP reservation for Autopilot VM ($apIP) already exists.")
                }
            }
            return $out
        } -ArgumentList '10.50.10.0', '10.50.10.100', '10.50.10.200',
                         $SSWConfig.GatewayIP, $SSWConfig.DCIP, $apReservedIP, $apMAC

        foreach ($line in $dhcpResult) { Add-UiLog "  $line" }
        Add-UiLog "DHCP ready - Autopilot VM will always get $apReservedIP (even after Autopilot reset)."
        # ── End DHCP setup ──────────────────────────────────────────────────────

        $progress.Value = 100
        Add-UiLog "DC01 ready as domain controller for $domain"
        $btnNext.IsEnabled = $true
    } catch {
        Add-UiLog "ERROR: $_"
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



