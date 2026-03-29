# ============================================================
# SSW-Lab | labs/AZ104/lab-week5-networking.ps1
# AZ-104 Week 5 — Azure Netwerken: VNet, NSG, Peering, DNS, VPN
# Cloud: Azure subscription
# ============================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AZ-104 | Week 5 — Azure Netwerken" Height="720" Width="700"
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
      <TextBlock Text="AZ-104 | Week 5 — Azure Netwerken" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="VNet · Subnets · NSG · VNet Peering · Private DNS · VPN Gateway" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Steps in this lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. VNet aanmaken met meerdere subnets"/>
        <LineBreak/><Run Text="2. NSG aanmaken met inbound RDP-regel"/>
        <LineBreak/><Run Text="3. VNet Peering instellen (Hub-Spoke)"/>
        <LineBreak/><Run Text="4. Private DNS Zone aanmaken en koppelen"/>
        <LineBreak/><Run Text="5. VPN Gateway aanmaken (manueel — portal)"/>
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
      <Button x:Name="BtnRun"  Content="Run lab" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="140"/>
      <Button x:Name="BtnNext" Content="Continue to Week 6 >" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text = "Dry Run — VNet-resources worden nog niet aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — Azure netwerk-resources worden aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "VPN Gateway aanmaken kost ~€80/maand — verwijder na lab"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
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
    $hubVnetName  = "ssw-hub-vnet"
    $spokeVnetName = "ssw-spoke-vnet"
    $nsgName  = "ssw-lab-nsg"
    $dnsZone  = "ssw.internal"

    # ── Stap 1: VNet met subnets ─────────────────────────────
    Write-LabLog "${pre}Stap 1: VNet aanmaken met Web en App subnets"
    $progress.Value = 16
    if ($isDry) {
        Write-LabLog "${pre}  `$webSubnet = New-AzVirtualNetworkSubnetConfig -Name 'WebSubnet' -AddressPrefix '10.1.1.0/24'"
        Write-LabLog "${pre}  `$appSubnet = New-AzVirtualNetworkSubnetConfig -Name 'AppSubnet' -AddressPrefix '10.1.2.0/24'"
        Write-LabLog "${pre}  New-AzVirtualNetwork -Name '$hubVnetName' -ResourceGroupName '$rgName' -Location '$location' -AddressPrefix '10.1.0.0/16' -Subnet `$webSubnet,`$appSubnet"
        Write-LabLog "${pre}  # Spoke VNet (10.2.0.0/16):"
        Write-LabLog "${pre}  New-AzVirtualNetwork -Name '$spokeVnetName' -ResourceGroupName '$rgName' -Location '$location' -AddressPrefix '10.2.0.0/16' -Subnet (New-AzVirtualNetworkSubnetConfig -Name 'DefaultSubnet' -AddressPrefix '10.2.0.0/24')"
    } else {
        try {
            if (-not (Get-AzContext)) { Connect-AzAccount -ErrorAction Stop | Out-Null }
            $hubVnet = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $hubVnet) {
                $webSub = New-AzVirtualNetworkSubnetConfig -Name "WebSubnet" -AddressPrefix "10.1.1.0/24"
                $appSub = New-AzVirtualNetworkSubnetConfig -Name "AppSubnet" -AddressPrefix "10.1.2.0/24"
                $hubVnet = New-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $rgName -Location $location -AddressPrefix "10.1.0.0/16" -Subnet $webSub, $appSub
                Write-LabLog "  Hub VNet aangemaakt: $hubVnetName (10.1.0.0/16)"
            } else { Write-LabLog "  Hub VNet bestaat al: $hubVnetName" }
            $spokeVnet = Get-AzVirtualNetwork -Name $spokeVnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $spokeVnet) {
                $defSub = New-AzVirtualNetworkSubnetConfig -Name "DefaultSubnet" -AddressPrefix "10.2.0.0/24"
                $spokeVnet = New-AzVirtualNetwork -Name $spokeVnetName -ResourceGroupName $rgName -Location $location -AddressPrefix "10.2.0.0/16" -Subnet $defSub
                Write-LabLog "  Spoke VNet aangemaakt: $spokeVnetName (10.2.0.0/16)"
            } else { Write-LabLog "  Spoke VNet bestaat al: $spokeVnetName" }
        } catch { Write-LabLog "  Error: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: NSG ──────────────────────────────────────────
    Write-LabLog "${pre}Stap 2: NSG aanmaken met RDP inbound-regel"
    $progress.Value = 32
    if ($isDry) {
        Write-LabLog "${pre}  `$rdpRule = New-AzNetworkSecurityRuleConfig -Name 'Allow-RDP' -Protocol Tcp -Direction Inbound -Priority 1000 -SourceAddressPrefix '*' -SourcePortRange '*' -DestinationAddressPrefix '*' -DestinationPortRange 3389 -Access Allow"
        Write-LabLog "${pre}  New-AzNetworkSecurityGroup -Name '$nsgName' -ResourceGroupName '$rgName' -Location '$location' -SecurityRules `$rdpRule"
        Write-LabLog "${pre}  # Voorzichtig: RDP vanuit Internet openzetten is beveiligingsrisico! Gebruik Just-In-Time VM Access in productie."
    } else {
        try {
            $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $nsg) {
                $rdpRule = New-AzNetworkSecurityRuleConfig -Name "Allow-RDP" -Protocol "Tcp" -Direction "Inbound" -Priority 1000 -SourceAddressPrefix "*" -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange "3389" -Access "Allow"
                $nsg = New-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rgName -Location $location -SecurityRules $rdpRule
                Write-LabLog "  NSG aangemaakt: $nsgName (Allow-RDP inbound)"
                Write-LabLog "  Let op: in productie altijd Just-In-Time VM Access gebruiken"
            } else { Write-LabLog "  NSG bestaat al: $nsgName" }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 3: VNet Peering ─────────────────────────────────
    Write-LabLog "${pre}Stap 3: VNet Peering — Hub naar Spoke en terug"
    $progress.Value = 50
    if ($isDry) {
        Write-LabLog "${pre}  Add-AzVirtualNetworkPeering -Name 'Hub-to-Spoke' -VirtualNetwork `$hubVnet -RemoteVirtualNetworkId `$spokeVnet.Id"
        Write-LabLog "${pre}  Add-AzVirtualNetworkPeering -Name 'Spoke-to-Hub' -VirtualNetwork `$spokeVnet -RemoteVirtualNetworkId `$hubVnet.Id"
        Write-LabLog "${pre}  Get-AzVirtualNetworkPeering -VirtualNetworkName '$hubVnetName' -ResourceGroupName '$rgName'"
    } else {
        try {
            $existingPeer = Get-AzVirtualNetworkPeering -VirtualNetworkName $hubVnetName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $existingPeer) {
                $hubVnet   = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $rgName
                $spokeVnet = Get-AzVirtualNetwork -Name $spokeVnetName -ResourceGroupName $rgName
                Add-AzVirtualNetworkPeering -Name "Hub-to-Spoke" -VirtualNetwork $hubVnet -RemoteVirtualNetworkId $spokeVnet.Id | Out-Null
                Add-AzVirtualNetworkPeering -Name "Spoke-to-Hub" -VirtualNetwork $spokeVnet -RemoteVirtualNetworkId $hubVnet.Id | Out-Null
                Write-LabLog "  VNet Peering aangemaakt: Hub ↔ Spoke"
            } else { Write-LabLog "  VNet Peering bestaat al" }
            Get-AzVirtualNetworkPeering -VirtualNetworkName $hubVnetName -ResourceGroupName $rgName | ForEach-Object { Write-LabLog "  $($_.Name): $($_.PeeringState)" }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 4: Private DNS Zone ─────────────────────────────
    Write-LabLog "${pre}Stap 4: Private DNS Zone ($dnsZone) koppelen aan Hub VNet"
    $progress.Value = 68
    if ($isDry) {
        Write-LabLog "${pre}  New-AzPrivateDnsZone -Name '$dnsZone' -ResourceGroupName '$rgName'"
        Write-LabLog "${pre}  New-AzPrivateDnsVirtualNetworkLink -ZoneName '$dnsZone' -ResourceGroupName '$rgName' -Name 'hub-link' -VirtualNetworkId `$hubVnet.Id -EnableRegistration"
        Write-LabLog "${pre}  New-AzPrivateDnsRecordSet -ZoneName '$dnsZone' -ResourceGroupName '$rgName' -Name 'dc01' -RecordType A -Ttl 300 -PrivateDnsRecords (New-AzPrivateDnsRecordConfig -Ipv4Address '10.1.1.10')"
    } else {
        try {
            $dnsZoneObj = Get-AzPrivateDnsZone -Name $dnsZone -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $dnsZoneObj) {
                $dnsZoneObj = New-AzPrivateDnsZone -Name $dnsZone -ResourceGroupName $rgName
                Write-LabLog "  Private DNS Zone aangemaakt: $dnsZone"
            } else { Write-LabLog "  DNS Zone bestaat al: $dnsZone" }
            $hubVnet = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $rgName
            $link = Get-AzPrivateDnsVirtualNetworkLink -ZoneName $dnsZone -ResourceGroupName $rgName -Name "hub-link" -ErrorAction SilentlyContinue
            if (-not $link) {
                New-AzPrivateDnsVirtualNetworkLink -ZoneName $dnsZone -ResourceGroupName $rgName -Name "hub-link" -VirtualNetworkId $hubVnet.Id -EnableRegistration | Out-Null
                Write-LabLog "  VNet link aangemaakt: hub-link (auto-registratie aan)"
            } else { Write-LabLog "  VNet link bestaat al" }
            $recSet = Get-AzPrivateDnsRecordSet -ZoneName $dnsZone -ResourceGroupName $rgName -Name "testhost" -RecordType A -ErrorAction SilentlyContinue
            if (-not $recSet) {
                $rec = New-AzPrivateDnsRecordConfig -Ipv4Address "10.1.1.10"
                New-AzPrivateDnsRecordSet -ZoneName $dnsZone -ResourceGroupName $rgName -Name "testhost" -RecordType A -Ttl 300 -PrivateDnsRecords $rec | Out-Null
                Write-LabLog "  A-record aangemaakt: testhost.$dnsZone → 10.1.1.10"
            }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 5: VPN Gateway (manueel) ────────────────────────
    Write-LabLog "${pre}Stap 5: VPN Gateway — manueel via portal (deploytijd ~45 min)"
    $progress.Value = 84
    Write-LabLog "  Azure portal > Maak 'GatewaySubnet' aan in de Hub VNet"
    Write-LabLog "  Subnetnaam: GatewaySubnet | Prefix: 10.1.255.0/27"
    Write-LabLog "  Maak een Public IP aan (ssw-vpn-pip)"
    Write-LabLog "  Maak een Virtual Network Gateway aan:"
    Write-LabLog "    Gateway type: VPN | VPN type: RouteBased | SKU: VpnGw1"
    Write-LabLog "  VNet: $hubVnetName | PIP: ssw-vpn-pip"
    Write-LabLog "  Deploytijd: ~30-45 minuten"
    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Azure portal openen?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://portal.azure.com/#create/Microsoft.VirtualNetworkGateway" }
    }

    $progress.Value = 100; Write-LabLog ""; Write-LabLog "Week 5 lab afgerond."; Write-LabLog ""
    Write-LabLog "━━━ KNOWLEDGE CHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-LabLog "1. Wat is het verschil tussen VNet Peering en VPN Gateway?"
    Write-LabLog "2. Hoe werken NSG-regels — wat is de evaluatievolgorde?"
    Write-LabLog "3. Wat is het verschil tussen een Public DNS Zone en een Private DNS Zone?"
    Write-LabLog "4. Wanneer gebruik je een Application Gateway vs. een Azure Load Balancer?"
    Write-LabLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week6-loadbalancing.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week6-loadbalancing.ps1 not found.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null

