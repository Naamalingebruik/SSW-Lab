#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Configure-HostNetwork.ps1
# Maakt interne Hyper-V vSwitch + NAT aan voor SSW-Lab.
# Dry Run is standaard AAN — zet vinkje uit om echt uit te voeren.
# ============================================================

. "$PSScriptRoot\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Netwerk inrichten" Height="560" Width="640"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Window.Resources>
    <Style x:Key="Label" TargetType="TextBlock">
      <Setter Property="Foreground" Value="#A6ADC8"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="0,8,0,2"/>
    </Style>
    <Style x:Key="Field" TargetType="TextBox">
      <Setter Property="Background" Value="#313244"/>
      <Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="BorderBrush" Value="#45475A"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="8,6"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Height" Value="34"/>
    </Style>
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Background" Value="#89B4FA"/>
      <Setter Property="Foreground" Value="#1E1E2E"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="Padding" Value="20,8"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/>
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

    <StackPanel Grid.Row="0">
      <TextBlock Text="Netwerk inrichten" Foreground="#CDD6F4" FontSize="20" FontWeight="SemiBold"/>
      <TextBlock Text="Interne vSwitch + NAT voor SSW-Lab" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,16"/>
    </StackPanel>

    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="16"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock Text="vSwitch naam" Style="{StaticResource Label}"/>
        <TextBox x:Name="TxtSwitch" Style="{StaticResource Field}"/>
        <TextBlock Text="NAT naam" Style="{StaticResource Label}"/>
        <TextBox x:Name="TxtNAT" Style="{StaticResource Field}"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="NAT subnet (bijv. 10.50.10.0/24)" Style="{StaticResource Label}"/>
        <TextBox x:Name="TxtSubnet" Style="{StaticResource Field}"/>
        <TextBlock Text="Gateway IP" Style="{StaticResource Label}"/>
        <TextBox x:Name="TxtGateway" Style="{StaticResource Field}"/>
      </StackPanel>
    </Grid>

    <Border Grid.Row="2" Background="#181825" CornerRadius="6" Margin="0,16,0,0" Padding="12">
      <ScrollViewer VerticalScrollBarVisibility="Auto">
        <TextBox x:Name="LogBox" Background="Transparent" Foreground="#A6E3A1"
                 FontFamily="Consolas" FontSize="11" IsReadOnly="True"
                 TextWrapping="Wrap" BorderThickness="0"/>
      </ScrollViewer>
    </Border>

    <ProgressBar x:Name="Progress" Grid.Row="3" Height="6" Margin="0,12,0,0"
                 Background="#313244" Foreground="#89B4FA" BorderThickness="0"
                 Minimum="0" Maximum="100" Value="0"/>

    <Border x:Name="DryRunBar" Grid.Row="4" CornerRadius="6" Margin="0,10,0,0" Padding="14,10" BorderThickness="1">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
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
      <Button x:Name="BtnApply" Content="Uitvoeren" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="120"/>
      <Button x:Name="BtnNext" Content="Doorgaan →" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader      = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$txtSwitch   = $reader.FindName("TxtSwitch")
$txtNAT      = $reader.FindName("TxtNAT")
$txtSubnet   = $reader.FindName("TxtSubnet")
$txtGateway  = $reader.FindName("TxtGateway")
$logBox      = $reader.FindName("LogBox")
$progress    = $reader.FindName("Progress")
$btnApply    = $reader.FindName("BtnApply")
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
        $dryRunTitle.Text       = "[DRY RUN] Geen wijzigingen worden aangebracht"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk uit te voeren"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "[LIVE] Wijzigingen worden aangebracht op dit systeem"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

$reader.Add_Loaded({
    $txtSwitch.Text  = $SSWConfig.vSwitchName
    $txtNAT.Text     = $SSWConfig.NATName
    $txtSubnet.Text  = $SSWConfig.NATSubnet
    $txtGateway.Text = $SSWConfig.GatewayIP
    Update-DryRunBar
})

$chkDryRun.Add_Checked({   Update-DryRunBar })
$chkDryRun.Add_Unchecked({ Update-DryRunBar })

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logBox.ScrollToEnd()
}

$btnApply.Add_Click({
    $btnApply.IsEnabled = $false
    $logBox.Text = ""
    $progress.Value = 0
    $isDry      = $chkDryRun.IsChecked
    $switchName = $txtSwitch.Text.Trim()
    $natName    = $txtNAT.Text.Trim()
    $subnet     = $txtSubnet.Text.Trim()
    $gateway    = $txtGateway.Text.Trim()
    $pre        = if ($isDry) { "[DRY RUN] " } else { "" }

    try {
        $progress.Value = 10
        $existSwitch = Get-VMSwitch -Name $switchName -ErrorAction SilentlyContinue
        if ($existSwitch) {
            Write-Log ("{0}vSwitch {1} bestaat al - overgeslagen." -f $pre, $switchName)
        } else {
            Write-Log ("{0}New-VMSwitch -Name {1} -SwitchType Internal" -f $pre, $switchName)
            if (-not $isDry) { New-VMSwitch -Name $switchName -SwitchType Internal -ErrorAction Stop | Out-Null }
        }
        $progress.Value = 35

        $adapterName = "vEthernet ($switchName)"
        Write-Log ("{0}New-NetIPAddress -IPAddress {1} -PrefixLength 24 -InterfaceAlias {2}" -f $pre, $gateway, $adapterName)
        if (-not $isDry) {
            $netAdapter = Get-NetAdapter -Name $adapterName -ErrorAction SilentlyContinue
            if ($netAdapter) {
                $existIP = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue
                if (-not $existIP) {
                    New-NetIPAddress -IPAddress $gateway -PrefixLength 24 -InterfaceAlias $adapterName -ErrorAction Stop | Out-Null
                }
            }
        }
        $progress.Value = 60

        $existNAT = Get-NetNat -Name $natName -ErrorAction SilentlyContinue
        if ($existNAT) {
            Write-Log ("{0}NAT {1} bestaat al - overgeslagen." -f $pre, $natName)
        } else {
            Write-Log ("{0}New-NetNat -Name {1} -InternalIPInterfaceAddressPrefix {2}" -f $pre, $natName, $subnet)
            if (-not $isDry) { New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix $subnet -ErrorAction Stop | Out-Null }
        }

        $progress.Value = 100
        Write-Log $(if ($isDry) { "Dry Run klaar - niets gewijzigd." } else { "Netwerk gereed." })
        $btnNext.IsEnabled = $true
    } catch {
        Write-Log "FOUT: $_"
    }
    $btnApply.IsEnabled = $true
})

$btnNext.Add_Click({
    $reader.Close()

    # Vraag of de gebruiker de ISO-stap wil doen of overslaan
    $choice = [System.Windows.MessageBox]::Show(
        "Wil je nu unattended ISOs bouwen (aanbevolen)?`n`nJa  -> Build-UnattendedIsos.ps1`nNee -> New-LabVMs.ps1 (handmatige installatie)",
        "SSW-Lab | Volgende stap",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Question
    )
    $next = if ($choice -eq "Yes") {
        Join-Path $PSScriptRoot "Build-UnattendedIsos.ps1"
    } else {
        Join-Path $PSScriptRoot "New-LabVMs.ps1"
    }
    if (Test-Path $next) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" -Verb RunAs }
})

$reader.ShowDialog() | Out-Null

