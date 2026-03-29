#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | Initialize-ManagementHost.ps1
# Installs PowerShell modules and RSAT tools on LAB-MGMT01
# via PowerShell Direct (no network required, VM must be Running).
#
# GUI: choose certification track (AZ-104 / MD-102 / MS-102 / SC-300 / Full)
#      check/uncheck modules and start installation.
# ============================================================

# WPF requires STA threading. PowerShell 7 uses MTA by default.
# Automatically restarts in Windows PowerShell 5.1 (always STA).
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    $script = $MyInvocation.MyCommand.Path
    Start-Process -FilePath "powershell.exe" `
        -ArgumentList "-STA -ExecutionPolicy Bypass -File `"$script`"" `
        -Verb RunAs
    exit
}

. "$PSScriptRoot\..\config.ps1"
$modulePath = Join-Path $PSScriptRoot '..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$vmName = "LAB-MGMT01"

# ── Module catalog ────────────────────────────────────────────────────────────
# Each module belongs to one or more certification tracks.
# 'RSAT' = Windows Capability (not a PSGallery module).
$catalog = @(
    [PSCustomObject]@{ Name = "Az";                       Certs = @("AZ-104","Full");                         Type = "PSGallery"; Desc = "Azure PowerShell - subscriptions, resources, VMs" }
    [PSCustomObject]@{ Name = "Microsoft.Graph";          Certs = @("AZ-104","MD-102","MS-102","SC-300","Full"); Type = "PSGallery"; Desc = "Microsoft Graph API - users, groups, policy" }
    [PSCustomObject]@{ Name = "ExchangeOnlineManagement"; Certs = @("MS-102","Full");                         Type = "PSGallery"; Desc = "Exchange Online management" }
    [PSCustomObject]@{ Name = "MicrosoftTeams";           Certs = @("MS-102","Full");                         Type = "PSGallery"; Desc = "Teams policy and configuration" }
    [PSCustomObject]@{ Name = "PnP.PowerShell";           Certs = @("MS-102","Full");                         Type = "PSGallery"; Desc = "SharePoint Online and OneDrive management" }
    [PSCustomObject]@{ Name = "WindowsAutoPilotIntune";   Certs = @("MD-102","Full");                         Type = "PSGallery"; Desc = "Autopilot device registration via Intune" }
    [PSCustomObject]@{ Name = "PSWindowsUpdate";          Certs = @("MD-102","Full");                         Type = "PSGallery"; Desc = "Remote Windows Update management" }
    [PSCustomObject]@{ Name = "RSAT: Active Directory";   Certs = @("MD-102","MS-102","SC-300","Full");        Type = "RSAT";      Desc = "AD Users & Computers, ADSI Edit" }
    [PSCustomObject]@{ Name = "RSAT: Group Policy";       Certs = @("MD-102","MS-102","SC-300","Full");        Type = "RSAT";      Desc = "Group Policy Management Console" }
    [PSCustomObject]@{ Name = "RSAT: DNS";                Certs = @("MD-102","MS-102","Full");                 Type = "RSAT";      Desc = "DNS Manager" }
    [PSCustomObject]@{ Name = "RSAT: DHCP";               Certs = @("MD-102","Full");                         Type = "RSAT";      Desc = "DHCP console" }
    [PSCustomObject]@{ Name = "RSAT: Certificates";       Certs = @("SC-300","Full");                         Type = "RSAT";      Desc = "Certificate Authority" }
)

# ── WPF GUI ───────────────────────────────────────────────────────────────────
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | MGMT01 Setup" Height="720" Width="680"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E2E" FontFamily="Segoe UI">
  <Window.Resources>
    <Style TargetType="TextBlock" x:Key="H1">
      <Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="FontSize" Value="20"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>
    <Style TargetType="TextBlock" x:Key="Sub">
      <Setter Property="Foreground" Value="#A6ADC8"/><Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="0,2,0,0"/>
    </Style>
    <Style TargetType="RadioButton" x:Key="TrajectBtn">
      <Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="FontSize" Value="13"/>
      <Setter Property="Margin" Value="0,0,12,0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
    </Style>
    <Style TargetType="CheckBox" x:Key="ModCb">
      <Setter Property="Foreground" Value="#CDD6F4"/><Setter Property="FontSize" Value="12"/>
      <Setter Property="Margin" Value="0,3,0,3"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="VerticalContentAlignment" Value="Center"/>
    </Style>
    <Style TargetType="Button" x:Key="PrimaryBtn">
      <Setter Property="Background" Value="#89B4FA"/><Setter Property="Foreground" Value="#1E1E2E"/>
      <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="14"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="40"/>
    </Style>
    <Style TargetType="Button" x:Key="SecBtn">
      <Setter Property="Background" Value="#313244"/><Setter Property="Foreground" Value="#CDD6F4"/>
      <Setter Property="FontSize" Value="13"/><Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="40"/>
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
    </Grid.RowDefinitions>

    <!-- Header -->
    <StackPanel Grid.Row="0" Margin="0,0,0,16">
      <TextBlock Text="MGMT01 Setup" Style="{StaticResource H1}"/>
      <TextBlock Text="Select a certification track — modules will be checked automatically" Style="{StaticResource Sub}"/>
    </StackPanel>

    <!-- Track buttons -->
    <Border Grid.Row="1" Background="#313244" CornerRadius="6" Padding="16,12" Margin="0,0,0,12">
      <StackPanel>
        <TextBlock Text="Certification track" Foreground="#A6ADC8" FontSize="11" Margin="0,0,0,10"/>
        <WrapPanel>
          <RadioButton x:Name="RadioAZ104"  Content="AZ-104"  Style="{StaticResource TrajectBtn}" GroupName="Traject"/>
          <RadioButton x:Name="RadioMD102"  Content="MD-102"  Style="{StaticResource TrajectBtn}" GroupName="Traject"/>
          <RadioButton x:Name="RadioMS102"  Content="MS-102"  Style="{StaticResource TrajectBtn}" GroupName="Traject"/>
          <RadioButton x:Name="RadioSC300"  Content="SC-300"  Style="{StaticResource TrajectBtn}" GroupName="Traject"/>
          <RadioButton x:Name="RadioFull"   Content="Full (all)"  Style="{StaticResource TrajectBtn}" GroupName="Traject" IsChecked="True"/>
        </WrapPanel>
      </StackPanel>
    </Border>

    <!-- Module list -->
    <Border Grid.Row="2" Background="#313244" CornerRadius="6" Padding="16,12" Margin="0,0,0,12">
      <StackPanel>
        <Grid Margin="0,0,0,8">
          <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
          </Grid.ColumnDefinitions>
          <TextBlock Text="Modules and RSAT tools" Foreground="#A6ADC8" FontSize="11" VerticalAlignment="Center"/>
          <StackPanel Grid.Column="1" Orientation="Horizontal">
            <Button x:Name="BtnSelectAll"   Content="Select all"  Style="{StaticResource SecBtn}" Width="90" Margin="0,0,6,0" Padding="8,0"/>
            <Button x:Name="BtnSelectNone"  Content="Select none" Style="{StaticResource SecBtn}" Width="90" Padding="8,0"/>
          </StackPanel>
        </Grid>
        <ItemsControl x:Name="ModuleList">
          <ItemsControl.ItemTemplate>
            <DataTemplate>
              <Grid Margin="0,2,0,2">
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="200"/>
                  <ColumnDefinition Width="*"/>
                  <ColumnDefinition Width="80"/>
                </Grid.ColumnDefinitions>
                <CheckBox Grid.Column="0" x:Name="ModCheck" IsChecked="{Binding Checked}"
                          Style="{StaticResource ModCb}" Margin="0,0,8,0"/>
                <TextBlock Grid.Column="1" Text="{Binding Name}" Foreground="#CDD6F4" FontSize="12" VerticalAlignment="Center"/>
                <TextBlock Grid.Column="2" Text="{Binding Desc}" Foreground="#6C7086" FontSize="11" VerticalAlignment="Center" TextTrimming="CharacterEllipsis"/>
                <TextBlock Grid.Column="3" Text="{Binding Type}" Foreground="#45475A" FontSize="10" VerticalAlignment="Center" HorizontalAlignment="Right"/>
              </Grid>
            </DataTemplate>
          </ItemsControl.ItemTemplate>
        </ItemsControl>
      </StackPanel>
    </Border>

    <!-- Log -->
    <Border Grid.Row="3" Background="#181825" CornerRadius="6" Margin="0,0,0,12">
      <ScrollViewer x:Name="LogScroll" VerticalScrollBarVisibility="Auto" Padding="12,8">
        <TextBlock x:Name="LogBox" Foreground="#A6ADC8" FontFamily="Consolas" FontSize="11"
                   TextWrapping="Wrap" Text="Ready to start. Select a track and click Install."/>
      </ScrollViewer>
    </Border>

    <!-- Progress -->
    <ProgressBar x:Name="Progress" Grid.Row="4" Height="6" Margin="0,0,0,12"
                 Background="#313244" Foreground="#89B4FA" BorderThickness="0"
                 Minimum="0" Maximum="100" Value="0"/>

    <!-- Buttons -->
    <Grid Grid.Row="5">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="12"/>
        <ColumnDefinition Width="160"/>
      </Grid.ColumnDefinitions>
      <Button x:Name="BtnClose"    Content="Close"   Grid.Column="0" Style="{StaticResource SecBtn}"/>
      <Button x:Name="BtnInstall"  Content="Install" Grid.Column="2" Style="{StaticResource PrimaryBtn}"/>
    </Grid>
  </Grid>
</Window>
"@

# ── Bindable model ────────────────────────────────────────────────────────────
Add-Type -AssemblyName WindowsBase
$moduleItems = [System.Collections.ObjectModel.ObservableCollection[PSCustomObject]]::new()

foreach ($m in $catalog) {
    $obj = [PSCustomObject]@{
        Name    = $m.Name
        Desc    = $m.Desc
        Type    = $m.Type
        Certs   = $m.Certs
        Checked = $true   # Full selected by default
    }
    # Add INotifyPropertyChanged behaviour via hashtable wrapper
    $moduleItems.Add($obj)
}

# ── Load window ───────────────────────────────────────────────────────────────
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

$modList    = $window.FindName("ModuleList")
$logBox     = $window.FindName("LogBox")
$logScroll  = $window.FindName("LogScroll")
$progress   = $window.FindName("Progress")
$btnInstall = $window.FindName("BtnInstall")
$btnClose   = $window.FindName("BtnClose")
$btnAll     = $window.FindName("BtnSelectAll")
$btnNone    = $window.FindName("BtnSelectNone")

$modList.ItemsSource = $moduleItems

# ── Helper: add log line ──────────────────────────────────────────────────────
function Add-Log {
    param([string]$text, [string]$color = "#A6ADC8")
    $lineText = "$text`n"
    $brushColor = $color
    $window.Dispatcher.Invoke([action]{
        $logBox.Inlines.Add((
            [System.Windows.Documents.Run]@{ Text = $lineText; Foreground = [Windows.Media.BrushConverter]::new().ConvertFromString($brushColor) }
        ))
        $logScroll.ScrollToBottom()
    })
}

function Save-SelectedTrack {
    param([string]$TrackName)

    if ([string]::IsNullOrWhiteSpace($TrackName) -or $TrackName -eq 'Full') {
        return
    }

    try {
        Set-SSWCurrentTrack -TrackId $TrackName | Out-Null
    } catch {
        Add-Log "Track state not updated: $($_.Exception.Message)" "#F9E2AF"
    }
}

# ── Track selection -> update checkboxes ─────────────────────────────────────
$updateChecks = {
    param([string]$traject)
    foreach ($item in $moduleItems) {
        $item.Checked = $item.Certs -contains $traject
    }
    $modList.Items.Refresh()
}

$window.FindName("RadioAZ104").Add_Checked({ & $updateChecks "AZ-104"; Save-SelectedTrack -TrackName 'AZ-104' })
$window.FindName("RadioMD102").Add_Checked({ & $updateChecks "MD-102"; Save-SelectedTrack -TrackName 'MD-102' })
$window.FindName("RadioMS102").Add_Checked({ & $updateChecks "MS-102"; Save-SelectedTrack -TrackName 'MS-102' })
$window.FindName("RadioSC300").Add_Checked({ & $updateChecks "SC-300"; Save-SelectedTrack -TrackName 'SC-300' })
$window.FindName("RadioFull").Add_Checked({  & $updateChecks "Full"   })

$btnAll.Add_Click({
    foreach ($item in $moduleItems) { $item.Checked = $true }
    $modList.Items.Refresh()
})
$btnNone.Add_Click({
    foreach ($item in $moduleItems) { $item.Checked = $false }
    $modList.Items.Refresh()
})

$btnClose.Add_Click({ $window.Close() })

# ── Installation ──────────────────────────────────────────────────────────────
$btnInstall.Add_Click({
    $selected = $moduleItems | Where-Object { $_.Checked }
    if (-not $selected) {
        [System.Windows.MessageBox]::Show("Select at least one module.", "No selection", "OK", "Warning") | Out-Null
        return
    }

    # VM check
    $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
    if (-not $vm -or $vm.State -ne "Running") {
        [System.Windows.MessageBox]::Show("VM '$vmName' is not available or not Running.", "VM error", "OK", "Error") | Out-Null
        return
    }

    $btnInstall.IsEnabled = $false
    $btnClose.IsEnabled   = $false
    $logBox.Text          = ""
    $progress.Value       = 0

    $psModules  = @($selected | Where-Object { $_.Type -eq "PSGallery" } | Select-Object -ExpandProperty Name)
    $rsatItems  = @($selected | Where-Object { $_.Type -eq "RSAT"      } | Select-Object -ExpandProperty Name)

    # Prompt for credentials — normalize username to .\user or DOMAIN\user
    $cred = $null
    try {
        $cred = Get-Credential -Message "Credentials for $vmName`nUse: LAB\Administrator or .\Administrator"
    } catch {
        Write-Verbose "Credential prompt was cancelled or failed: $($_.Exception.Message)"
    }
    if (-not $cred) {
        $btnInstall.IsEnabled = $true; $btnClose.IsEnabled = $true; return
    }

    # Normalize: "administrator" (no prefix) -> ".\administrator"
    $user = $cred.UserName
    if ($user -notmatch '\\' -and $user -notmatch '@') {
        $cred = [System.Management.Automation.PSCredential]::new(
            ".\$user", $cred.Password
        )
    }

    # Pre-flight connection test so an error is immediately visible
    try {
        Invoke-Command -VMName $vmName -Credential $cred -ErrorAction Stop -ScriptBlock { $null } | Out-Null
    } catch {
        $errMsg = $_.Exception.Message
        $window.Dispatcher.Invoke([action]{
            [System.Windows.MessageBox]::Show(
                "Cannot connect to $vmName.`n`nUsername: $($cred.UserName)`nError: $errMsg`n`nUse LAB\Administrator or .\Administrator.",
                "Connection failed", "OK", "Error"
            ) | Out-Null
            $btnInstall.IsEnabled = $true
            $btnClose.IsEnabled   = $true
        })
        return
    }

    # Map RSAT display names to Capability names
    $rsatMap = @{
        "RSAT: Active Directory" = "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
        "RSAT: Group Policy"     = "Rsat.GroupPolicy.Management.Tools~~~~0.0.1.0"
        "RSAT: DNS"              = "Rsat.Dns.Tools~~~~0.0.1.0"
        "RSAT: DHCP"             = "Rsat.DHCP.Tools~~~~0.0.1.0"
        "RSAT: Certificates"     = "Rsat.CertificateServices.Tools~~~~0.0.1.0"
    }
    $rsatCaps = @($rsatItems | ForEach-Object { $rsatMap[$_] } | Where-Object { $_ })

    $total = 3  # step 1 prep, step 2 modules, step 3 RSAT
    $step  = 0

    $job = [System.Threading.Thread]::new([System.Threading.ThreadStart]{
        try {
            # ── Step 1: NuGet + PSGallery ─────────────────────────────────
            Add-Log "=== Step 1/3 — NuGet and PSGallery ===" "#89B4FA"
            Invoke-Command -VMName $vmName -Credential $cred -ErrorAction Stop -ScriptBlock {
                $nuget = Get-PackageProvider NuGet -ListAvailable -ErrorAction SilentlyContinue |
                         Sort-Object Version -Descending | Select-Object -First 1
                if (-not $nuget -or $nuget.Version -lt [version]"2.8.5.201") {
                    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope AllUsers | Out-Null
                    "  NuGet provider installed."
                } else { "  NuGet OK ($($nuget.Version))" }

                $gallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
                if ($gallery.InstallationPolicy -ne "Trusted") {
                    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
                    "  PSGallery: Trusted."
                } else { "  PSGallery: already Trusted." }

                $psg = Get-Module PowerShellGet -ListAvailable | Sort-Object Version -Desc | Select-Object -First 1
                if ($psg.Version -lt [version]"2.2.5") {
                    Install-Module PowerShellGet -Force -AllowClobber -Scope AllUsers | Out-Null
                    "  PowerShellGet updated."
                } else { "  PowerShellGet OK ($($psg.Version))" }
            } | ForEach-Object { Add-Log "  $_" }

            $step++
            $window.Dispatcher.Invoke([action]{ $progress.Value = ($step / $total) * 100 })

            # ── Step 2: PSGallery modules ─────────────────────────────────
            Add-Log "=== Step 2/3 — PSGallery modules ($($psModules.Count)) ===" "#89B4FA"
            if ($psModules.Count -gt 0) {
                Invoke-Command -VMName $vmName -Credential $cred -ArgumentList (,$psModules) -ErrorAction Stop -ScriptBlock {
                    param([string[]]$names)
                    foreach ($name in $names) {
                        $inst = Get-Module $name -ListAvailable -EA SilentlyContinue | Sort-Object Version -Desc | Select-Object -First 1
                        if ($inst) {
                            try {
                                $online = Find-Module $name -EA Stop
                                if ($online.Version -gt $inst.Version) {
                                    Update-Module $name -Force -Scope AllUsers -EA Stop
                                    "  UPDATED  $name  $($inst.Version) -> $($online.Version)"
                                } else { "  OK       $name  v$($inst.Version)" }
                            } catch { "  SKIP     $name  (version check failed)" }
                        } else {
                            try {
                                Install-Module $name -Force -AllowClobber -Scope AllUsers -EA Stop
                                "  INSTALLED $name"
                            } catch { "  ERROR    $name`: $_" }
                        }
                    }
                } | ForEach-Object {
                    $color = if ($_ -match "^  ERROR") { "#F38BA8" } elseif ($_ -match "UPDATED|INSTALLED") { "#A6E3A1" } else { "#A6ADC8" }
                    Add-Log $_ $color
                }
            } else { Add-Log "  No PSGallery modules selected — skipped." "#6C7086" }

            $step++
            $window.Dispatcher.Invoke([action]{ $progress.Value = ($step / $total) * 100 })

            # ── Step 3: RSAT ──────────────────────────────────────────────
            Add-Log "=== Step 3/3 — RSAT Windows features ($($rsatCaps.Count)) ===" "#89B4FA"
            if ($rsatCaps.Count -gt 0) {
                Invoke-Command -VMName $vmName -Credential $cred -ArgumentList (,$rsatCaps) -ErrorAction Stop -ScriptBlock {
                    param([string[]]$caps)
                    foreach ($cap in $caps) {
                        $label = ($cap -split '\.')[1]
                        $state = (Get-WindowsCapability -Online -Name $cap -EA SilentlyContinue).State
                        if ($state -eq "Installed") { "  OK       $label" }
                        else {
                            try {
                                Add-WindowsCapability -Online -Name $cap -EA Stop | Out-Null
                                "  INSTALLED $label"
                            } catch { "  ERROR    $label`: $_" }
                        }
                    }
                } | ForEach-Object {
                    $color = if ($_ -match "^  ERROR") { "#F38BA8" } elseif ($_ -match "INSTALLED") { "#A6E3A1" } else { "#A6ADC8" }
                    Add-Log $_ $color
                }
            } else { Add-Log "  No RSAT features selected — skipped." "#6C7086" }

            $step++
            $window.Dispatcher.Invoke([action]{ $progress.Value = 100 })
            Add-Log ""
            Add-Log "Done! MGMT01 setup complete." "#A6E3A1"

        } catch {
            Add-Log "ERROR: $($_.Exception.Message)" "#F38BA8"
        } finally {
            $window.Dispatcher.Invoke([action]{
                $btnInstall.IsEnabled = $true
                $btnClose.IsEnabled   = $true
            })
        }
    })
    $job.IsBackground = $true
    $job.Start()
})

# ── Show window ───────────────────────────────────────────────────────────────
$window.ShowDialog() | Out-Null

