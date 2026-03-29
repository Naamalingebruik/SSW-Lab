#Requires -RunAsAdministrator
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$modulePath = Join-Path $PSScriptRoot '..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force
$SSWConfig = Import-SSWLabConfig -ConfigPath (Join-Path $PSScriptRoot '..\config.ps1')
$profiles = Get-SSWVmProfiles -Config $SSWConfig
$templateMap = @{
    Client = @('W11-AUTOPILOT', 'W11-01', 'W11-02', 'MGMT01')
    Server = @('DC01')
}

function Get-TemplateProfile {
    param([string]$TemplateKey)
    return $profiles.PSObject.Properties[$TemplateKey].Value
}

function Get-DefaultVmName {
    param([string]$TemplateKey)

    switch ($TemplateKey) {
        'W11-AUTOPILOT' { 'LAB-W11-AUTOPILOT-02' }
        'W11-01' { 'LAB-W11-03' }
        'W11-02' { 'LAB-W11-04' }
        'MGMT01' { 'LAB-MGMT02' }
        'DC01' { 'LAB-DC02' }
        default { 'LAB-EXTRA-01' }
    }
}

function Invoke-ExtraVmScript {
    param(
        [string[]]$Arguments
    )

    $shell = if ($PSVersionTable.PSEdition -eq 'Core') { 'pwsh.exe' } else { 'powershell.exe' }
    & $shell @Arguments 2>&1 | ForEach-Object { $_.ToString() }
    return $LASTEXITCODE
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | Extra VM" Height="620" Width="720"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Margin="0,0,0,14">
      <TextBlock Text="Extra VM aanmaken" Foreground="#CDD6F4" FontSize="20" FontWeight="SemiBold"/>
      <TextBlock Text="Client = Windows 11 Enterprise unattended. Server = Windows Server Standard Desktop Experience unattended."
                 Foreground="#A6ADC8" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0"/>
    </StackPanel>

    <Grid Grid.Row="1" Margin="0,0,0,14">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="12"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <StackPanel Grid.Column="0">
        <TextBlock Text="Type" Foreground="#A6ADC8" Margin="0,0,0,4"/>
        <ComboBox x:Name="RoleBox" Height="32" SelectedIndex="0">
          <ComboBoxItem Content="Client"/>
          <ComboBoxItem Content="Server"/>
        </ComboBox>

        <TextBlock Text="Template" Foreground="#A6ADC8" Margin="0,10,0,4"/>
        <ComboBox x:Name="TemplateBox" Height="32"/>

        <TextBlock Text="VM-naam" Foreground="#A6ADC8" Margin="0,10,0,4"/>
        <TextBox x:Name="VmNameBox" Height="32"/>

        <CheckBox x:Name="StartAfterBox" Content="Start na aanmaken" Foreground="#CDD6F4" Margin="0,10,0,0"/>
      </StackPanel>

      <StackPanel Grid.Column="2">
        <TextBlock Text="RAM (GB, optioneel)" Foreground="#A6ADC8" Margin="0,0,0,4"/>
        <TextBox x:Name="MemoryBox" Height="32"/>

        <TextBlock Text="CPU (optioneel)" Foreground="#A6ADC8" Margin="0,10,0,4"/>
        <TextBox x:Name="CpuBox" Height="32"/>

        <TextBlock Text="Disk (GB, optioneel)" Foreground="#A6ADC8" Margin="0,10,0,4"/>
        <TextBox x:Name="DiskBox" Height="32"/>

        <TextBlock x:Name="SummaryText" Foreground="#F9E2AF" Margin="0,12,0,0" TextWrapping="Wrap"/>
      </StackPanel>
    </Grid>

    <Border Grid.Row="3" Background="#181825" CornerRadius="6" Padding="10">
      <ScrollViewer VerticalScrollBarVisibility="Auto">
        <TextBox x:Name="LogBox" Background="Transparent" Foreground="#A6E3A1"
                 FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" BorderThickness="0"/>
      </ScrollViewer>
    </Border>

    <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,14,0,0">
      <Button x:Name="PreviewBtn" Content="Preview" Width="110" Height="34" Margin="0,0,10,0"/>
      <Button x:Name="CreateBtn" Content="Aanmaken" Width="120" Height="34" Margin="0,0,10,0"/>
      <Button x:Name="CloseBtn" Content="Sluiten" Width="100" Height="34"/>
    </StackPanel>
  </Grid>
</Window>
"@

$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
$roleBox = $window.FindName('RoleBox')
$templateBox = $window.FindName('TemplateBox')
$vmNameBox = $window.FindName('VmNameBox')
$memoryBox = $window.FindName('MemoryBox')
$cpuBox = $window.FindName('CpuBox')
$diskBox = $window.FindName('DiskBox')
$startAfterBox = $window.FindName('StartAfterBox')
$summaryText = $window.FindName('SummaryText')
$logBox = $window.FindName('LogBox')
$previewBtn = $window.FindName('PreviewBtn')
$createBtn = $window.FindName('CreateBtn')
$closeBtn = $window.FindName('CloseBtn')

function Update-TemplateChoices {
    $role = ([string]($roleBox.SelectedItem.Content))
    $templateBox.Items.Clear()
    foreach ($templateKey in $templateMap[$role]) {
        [void]$templateBox.Items.Add($templateKey)
    }
    $templateBox.SelectedIndex = 0
}

function Update-DefaultsFromTemplate {
    if (-not $templateBox.SelectedItem) { return }
    $templateKey = [string]$templateBox.SelectedItem
    $templateProfile = Get-TemplateProfile -TemplateKey $templateKey
    $vmNameBox.Text = Get-DefaultVmName -TemplateKey $templateKey
    $memoryBox.Text = [string]$templateProfile.RAM_GB
    $cpuBox.Text = [string]$templateProfile.vCPU
    $diskBox.Text = [string]$templateProfile.Disk_GB
    $summaryText.Text = "{0} | {1} | {2} GB RAM | {3} vCPU | {4} GB disk" -f $templateKey, $templateProfile.OS, $templateProfile.RAM_GB, $templateProfile.vCPU, $templateProfile.Disk_GB
}

function Invoke-GuiAction {
    param([switch]$Preview)

    $logBox.Clear()

    $templateKey = [string]$templateBox.SelectedItem
    $vmName = $vmNameBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($vmName)) {
        [System.Windows.MessageBox]::Show("Vul een VM-naam in.", "SSW-Lab")
        return
    }

    $scriptArguments = @(
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', (Join-Path $PSScriptRoot 'New-LabExtraVm.ps1'),
        '-TemplateKey', $templateKey,
        '-VmName', $vmName
    )

    if ($memoryBox.Text.Trim()) { $scriptArguments += @('-MemoryGB', $memoryBox.Text.Trim()) }
    if ($cpuBox.Text.Trim()) { $scriptArguments += @('-CpuCount', $cpuBox.Text.Trim()) }
    if ($diskBox.Text.Trim()) { $scriptArguments += @('-DiskGB', $diskBox.Text.Trim()) }
    if ($startAfterBox.IsChecked) { $scriptArguments += '-StartAfter' }
    if ($Preview) { $scriptArguments += '-WhatIf' }

    $previewBtn.IsEnabled = $false
    $createBtn.IsEnabled = $false
    try {
        $output = Invoke-ExtraVmScript -Arguments $scriptArguments
        foreach ($line in $output) {
            $logBox.AppendText("$line`r`n")
        }
    } finally {
        $previewBtn.IsEnabled = $true
        $createBtn.IsEnabled = $true
    }
}

$roleBox.Add_SelectionChanged({
    Update-TemplateChoices
    Update-DefaultsFromTemplate
})

$templateBox.Add_SelectionChanged({
    Update-DefaultsFromTemplate
})

$previewBtn.Add_Click({ Invoke-GuiAction -Preview })
$createBtn.Add_Click({ Invoke-GuiAction })
$closeBtn.Add_Click({ $window.Close() })

Update-TemplateChoices
Update-DefaultsFromTemplate

$window.ShowDialog() | Out-Null
