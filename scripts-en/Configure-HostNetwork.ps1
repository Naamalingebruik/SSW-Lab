#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Configure-HostNetwork.ps1
# Creates an internal Hyper-V vSwitch + NAT for SSW-Lab.
# Dry Run is on by default — uncheck to apply changes.
# ============================================================

. "$PSScriptRoot\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Configure Network" Height="560" Width="640"
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
      <TextBlock Text="Configure Network" Foreground="#CDD6F4" FontSize="20" FontWeight="SemiBold"/>
      <TextBlock Text="Internal vSwitch + NAT for SSW-Lab" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,16"/>
    </StackPanel>

    <Grid Grid.Row="1">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="16"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>
      <StackPanel Grid.Column="0">
        <TextBlock Text="vSwitch name" Style="{StaticResource Label}"/>
        <TextBox x:Name="TxtSwitch" Style="{StaticResource Field}"/>
        <TextBlock Text="NAT name" Style="{StaticResource Label}"/>
        <TextBox x:Name="TxtNAT" Style="{StaticResource Field}"/>
      </StackPanel>
      <StackPanel Grid.Column="2">
        <TextBlock Text="NAT subnet (e.g. 10.50.10.0/24)" Style="{StaticResource Label}"/>
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
      <Button x:Name="BtnApply" Content="Apply" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="120"/>
      <Button x:Name="BtnNext" Content="Continue →" Style="{StaticResource Btn}"
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

function Show-DryRunState {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "[DRY RUN] No changes will be made"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Uncheck to actually apply changes"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "[LIVE] Changes will be applied to this system"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Check again to go back to Dry Run"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
    }
}

$reader.Add_Loaded({
    $txtSwitch.Text  = $SSWConfig.vSwitchName
    $txtNAT.Text     = $SSWConfig.NATName
    $txtSubnet.Text  = $SSWConfig.NATSubnet
    $txtGateway.Text = $SSWConfig.GatewayIP
    Show-DryRunState
})

$chkDryRun.Add_Checked({   Show-DryRunState })
$chkDryRun.Add_Unchecked({ Show-DryRunState })

function Add-UiLog($msg) {
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
            Add-UiLog ("{0}vSwitch {1} already exists - skipped." -f $pre, $switchName)
        } else {
            Add-UiLog ("{0}New-VMSwitch -Name {1} -SwitchType Internal" -f $pre, $switchName)
            if (-not $isDry) { New-VMSwitch -Name $switchName -SwitchType Internal -ErrorAction Stop | Out-Null }
        }
        $progress.Value = 35

        $adapterName = "vEthernet ($switchName)"
        Add-UiLog ("{0}New-NetIPAddress -IPAddress {1} -PrefixLength 24 -InterfaceAlias {2}" -f $pre, $gateway, $adapterName)
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
            Add-UiLog ("{0}NAT {1} already exists - skipped." -f $pre, $natName)
        } else {
            Add-UiLog ("{0}New-NetNat -Name {1} -InternalIPInterfaceAddressPrefix {2}" -f $pre, $natName, $subnet)
            if (-not $isDry) { New-NetNat -Name $natName -InternalIPInterfaceAddressPrefix $subnet -ErrorAction Stop | Out-Null }
        }

        $progress.Value = 100
        Add-UiLog $(if ($isDry) { "Dry Run complete - nothing changed." } else { "Network ready." })
        $btnNext.IsEnabled = $true
    } catch {
        Add-UiLog "ERROR: $_"
    }
    $btnApply.IsEnabled = $true
})

$btnNext.Add_Click({
    $reader.Close()

    # Ask whether to build unattended ISOs or skip
    $choice = [System.Windows.MessageBox]::Show(
        "Do you want to build unattended ISOs now (recommended)?`n`nYes -> Build-UnattendedIsos.ps1`nNo  -> New-LabVMs.ps1 (manual installation)",
        "SSW-Lab | Next step",
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
