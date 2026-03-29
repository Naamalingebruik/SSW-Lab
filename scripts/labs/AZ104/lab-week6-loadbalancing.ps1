# ============================================================
# SSW-Lab | labs/AZ104/lab-week6-loadbalancing.ps1
# AZ-104 Week 6 — Load Balancer, Application Gateway, Network Watcher
# Cloud: Azure subscription
# ============================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AZ-104 | Week 6 — Load Balancing" Height="720" Width="700"
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
      <TextBlock Text="AZ-104 | Week 6 — Load Balancing en Network Watcher" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Azure Load Balancer · Application Gateway · Traffic Manager · Network Watcher" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Public Load Balancer aanmaken met backend pool"/>
        <LineBreak/><Run Text="2. Health probe en load balancing rule configureren"/>
        <LineBreak/><Run Text="3. Application Gateway aanmaken (WAF mode manueel)"/>
        <LineBreak/><Run Text="4. Network Watcher — IP-flow verify en NSG flow logs"/>
        <LineBreak/><Run Text="5. Traffic Manager profiel instellen (priority routing)"/>
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

function Show-DryRunState {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background = $conv.ConvertFrom("#1A2E24"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text = "Dry Run — commando's getoond, geen resources aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — Load Balancer en App Gateway worden aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "App Gateway kost ~€0.25/uur — verwijder na lab"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Show-DryRunState })
$chkDryRun.Add_Checked({ Show-DryRunState }); $chkDryRun.Add_Unchecked({ Show-DryRunState })
function Write-LabLog($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry   = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }
    $rgName  = "ssw-lab-rg"
    $location = "westeurope"
    $lbName   = "ssw-lab-lb"
    $lbPipName = "ssw-lb-pip"

    # ── Stap 1: Public Load Balancer aanmaken ────────────────
    Write-LabLog "${pre}Stap 1: Public Load Balancer aanmaken"
    $progress.Value = 16
    if ($isDry) {
        Write-LabLog "${pre}  `$pip = New-AzPublicIpAddress -Name '$lbPipName' -ResourceGroupName '$rgName' -Location '$location' -AllocationMethod Static -Sku Standard"
        Write-LabLog "${pre}  `$feConfig = New-AzLoadBalancerFrontendIpConfig -Name 'FrontendSSW' -PublicIpAddress `$pip"
        Write-LabLog "${pre}  `$bePool   = New-AzLoadBalancerBackendAddressPoolConfig -Name 'BackendSSW'"
        Write-LabLog "${pre}  New-AzLoadBalancer -Name '$lbName' -ResourceGroupName '$rgName' -Location '$location' -Sku Standard -FrontendIpConfiguration `$feConfig -BackendAddressPool `$bePool"
    } else {
        try {
            if (-not (Get-AzContext)) { Connect-AzAccount -ErrorAction Stop | Out-Null }
            $lb = Get-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $lb) {
                $pip     = New-AzPublicIpAddress -Name $lbPipName -ResourceGroupName $rgName -Location $location -AllocationMethod Static -Sku Standard
                $feConfig = New-AzLoadBalancerFrontendIpConfig -Name "FrontendSSW" -PublicIpAddress $pip
                $bePool   = New-AzLoadBalancerBackendAddressPoolConfig -Name "BackendSSW"
                $lb = New-AzLoadBalancer -Name $lbName -ResourceGroupName $rgName -Location $location -Sku Standard -FrontendIpConfiguration $feConfig -BackendAddressPool $bePool
                Write-LabLog "  Load Balancer aangemaakt: $lbName"
                Write-LabLog "  Frontend IP: $($pip.IpAddress)"
            } else { Write-LabLog "  Load Balancer bestaat al: $lbName" }
        } catch { Write-LabLog "  Fout: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: Health probe en LB rule ─────────────────────
    Write-LabLog "${pre}Stap 2: Health probe (HTTP:80) en LB rule (port 80)"
    $progress.Value = 32
    if ($isDry) {
        Write-LabLog "${pre}  `$probe = New-AzLoadBalancerProbeConfig -Name 'HttpProbe' -Protocol Http -Port 80 -RequestPath '/' -IntervalInSeconds 15 -ProbeCount 2"
        Write-LabLog "${pre}  `$lbRule = New-AzLoadBalancerRuleConfig -Name 'HttpRule' -FrontendIpConfiguration `$feConfig -BackendAddressPool `$bePool -Probe `$probe -Protocol Tcp -FrontendPort 80 -BackendPort 80"
        Write-LabLog "${pre}  `$lb | Add-AzLoadBalancerProbeConfig -Probe `$probe | Set-AzLoadBalancer"
    } else {
        Write-LabLog "  Health probe en LB rule worden manueel geconfigureerd via portal"
        Write-LabLog "  Azure portal > Load balancers > $lbName > Health probes & Load balancing rules"
    }

    # ── Stap 3: Application Gateway (portal) ────────────────
    Write-LabLog "${pre}Stap 3: Manueel — Application Gateway met WAF inschakelen"
    $progress.Value = 50
    Write-LabLog "  Azure portal > Create a resource > Application Gateway"
    Write-LabLog "  SKU: WAF_v2 | Tier: WAF | VNet: ssw-hub-vnet | Subnet: AppSubnet"
    Write-LabLog "  Frontend IP: Public | Backend: HTTP (port 80)"
    Write-LabLog "  WAF mode: Detection (begin met Detection, switch naar Prevention)"
    Write-LabLog "  Routing rule: listener (http:80) → backend pool"
    Write-LabLog "  Deploytijd: 5-10 minuten"
    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Application Gateway aanmaken via portal?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://portal.azure.com/#create/Microsoft.ApplicationGateway" }
    }

    # ── Stap 4: Network Watcher ──────────────────────────────
    Write-LabLog "${pre}Stap 4: Network Watcher — IP-flow verify en NSG flow logs"
    $progress.Value = 68
    if ($isDry) {
        Write-LabLog "${pre}  # Network Watcher is automatisch aanwezig per regio"
        Write-LabLog "${pre}  `$nw = Get-AzNetworkWatcher -Location '$location'"
        Write-LabLog "${pre}  # IP-flow verify: test of NSG voorkomt dat VM2 VM1 kan bereiken"
        Write-LabLog "${pre}  Test-AzNetworkWatcherIPFlow -NetworkWatcher `$nw -TargetVirtualMachineId <vmId> -Direction Inbound -Protocol TCP -RemoteIPAddress '1.2.3.4' -LocalIPAddress '10.1.1.4' -LocalPort 3389 -RemotePort 0"
    } else {
        try {
            $nw = Get-AzNetworkWatcher -Location $location -ErrorAction SilentlyContinue
            if ($nw) {
                Write-LabLog "  Network Watcher beschikbaar: $($nw.Name) [$($nw.ProvisioningState)]"
                Write-LabLog "  IP-flow verify: portal > Network Watcher > IP flow verify"
                Write-LabLog "  NSG flow logs: portal > Network Watcher > NSG flow logs"
            } else {
                Write-LabLog "  Network Watcher niet gevonden voor $location — wordt automatisch aangemaakt met VNet"
            }
        } catch { Write-LabLog "  Fout: $_" }
    }

    # ── Stap 5: Traffic Manager ──────────────────────────────
    Write-LabLog "${pre}Stap 5: Traffic Manager profiel aanmaken (priority routing)"
    $progress.Value = 84
    if ($isDry) {
        Write-LabLog "${pre}  New-AzTrafficManagerProfile -Name 'ssw-trafficmgr' -ResourceGroupName '$rgName' -TrafficRoutingMethod Priority -RelativeDnsName 'sswlabtraffic' -Ttl 30 -MonitorProtocol Http -MonitorPort 80 -MonitorPath '/'"
        Write-LabLog "${pre}  New-AzTrafficManagerEndpoint -Name 'PrimaryEndpoint' -ProfileName 'ssw-trafficmgr' -ResourceGroupName '$rgName' -Type AzureEndpoints -TargetResourceId <appService.Id> -Priority 1 -EndpointStatus Enabled"
    } else {
        try {
            $tmProfile = Get-AzTrafficManagerProfile -Name "ssw-trafficmgr" -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $tmProfile) {
                $tmProfile = New-AzTrafficManagerProfile -Name "ssw-trafficmgr" -ResourceGroupName $rgName -TrafficRoutingMethod Priority -RelativeDnsName "sswlabtraffic$(Get-Random -Maximum 9999)" -Ttl 30 -MonitorProtocol Http -MonitorPort 80 -MonitorPath "/"
                Write-LabLog "  Traffic Manager aangemaakt: ssw-trafficmgr"
                Write-LabLog "  DNS: $($tmProfile.DnsConfig.Fqdn)"
            } else { Write-LabLog "  Traffic Manager bestaat al: ssw-trafficmgr" }
        } catch { Write-LabLog "  Fout: $_" }
    }

    $progress.Value = 100; Write-LabLog ""; Write-LabLog "Week 6 lab afgerond."; Write-LabLog ""
    Write-LabLog "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-LabLog "1. Wat is het verschil tussen een Standard en Basic SKU Load Balancer?"
    Write-LabLog "2. Wanneer gebruik je een Application Gateway vs. Azure Load Balancer?"
    Write-LabLog "3. Welke Traffic Manager routeringsmethoden bestaan er en wanneer gebruik je ze?"
    Write-LabLog "4. Wat zijn NSG flow logs en waarvoor gebruik je ze?"
    Write-LabLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week7-monitoring.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week7-monitoring.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null
