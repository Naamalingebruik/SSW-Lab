#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | 02-MAKE-ISOS.ps1
# Injecteert unattend.xml in MSDN ISO's voor W11 + WS2025.
# Dry Run is standaard AAN — zet vinkje uit om echt uit te voeren.
# ============================================================

. "$PSScriptRoot\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

function Get-W11Unattend($adminPass) {
    return @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"
          xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>nl-NL</UILanguage></SetupUILanguage>
      <InputLocale>nl-NL</InputLocale>
      <UILanguage>nl-NL</UILanguage>
      <SystemLocale>nl-NL</SystemLocale>
      <UserLocale>nl-NL</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>300</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>2</PartitionID></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>3</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label></ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
          <WillShowUI>OnError</WillShowUI>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>SSW Lab</FullName>
        <Organization>Sogeti SSW</Organization>
      </UserData>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <ComputerName>*</ComputerName>
      <RegisteredOrganization>Sogeti SSW</RegisteredOrganization>
      <TimeZone>W. Europe Standard Time</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
        <NetworkLocation>Work</NetworkLocation>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$adminPass</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password><Value>$adminPass</Value><PlainText>true</PlainText></Password>
            <DisplayName>$($SSWConfig.DomainAdmin)</DisplayName>
            <Group>Administrators</Group>
            <Name>$($SSWConfig.DomainAdmin)</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
    </component>
  </settings>
</unattend>
"@
}

function Get-WS2025Unattend($adminPass) {
    return @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend"
          xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <settings pass="windowsPE">
    <component name="Microsoft-Windows-International-Core-WinPE"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <SetupUILanguage><UILanguage>en-US</UILanguage></SetupUILanguage>
      <InputLocale>nl-NL</InputLocale><UILanguage>en-US</UILanguage>
      <SystemLocale>nl-NL</SystemLocale><UserLocale>nl-NL</UserLocale>
    </component>
    <component name="Microsoft-Windows-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <DiskConfiguration>
        <Disk wcm:action="add">
          <DiskID>0</DiskID>
          <WillWipeDisk>true</WillWipeDisk>
          <CreatePartitions>
            <CreatePartition wcm:action="add"><Order>1</Order><Type>EFI</Type><Size>300</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>2</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
            <CreatePartition wcm:action="add"><Order>3</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
          </CreatePartitions>
          <ModifyPartitions>
            <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>2</PartitionID></ModifyPartition>
            <ModifyPartition wcm:action="add"><Order>3</Order><PartitionID>3</PartitionID><Format>NTFS</Format><Label>Windows</Label></ModifyPartition>
          </ModifyPartitions>
        </Disk>
      </DiskConfiguration>
      <ImageInstall>
        <OSImage>
          <InstallTo><DiskID>0</DiskID><PartitionID>3</PartitionID></InstallTo>
          <WillShowUI>OnError</WillShowUI>
          <InstallToAvailablePartition>false</InstallToAvailablePartition>
        </OSImage>
      </ImageInstall>
      <UserData>
        <AcceptEula>true</AcceptEula>
        <FullName>SSW Lab</FullName>
        <Organization>Sogeti SSW</Organization>
      </UserData>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <ComputerName>*</ComputerName>
      <TimeZone>W. Europe Standard Time</TimeZone>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup"
               processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35"
               language="neutral" versionScope="nonSxS">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <HideLocalAccountScreen>true</HideLocalAccountScreen>
        <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
        <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
        <NetworkLocation>Work</NetworkLocation>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
      <UserAccounts>
        <AdministratorPassword>
          <Value>$adminPass</Value>
          <PlainText>true</PlainText>
        </AdministratorPassword>
        <LocalAccounts>
          <LocalAccount wcm:action="add">
            <Password><Value>$adminPass</Value><PlainText>true</PlainText></Password>
            <DisplayName>$($SSWConfig.DomainAdmin)</DisplayName>
            <Group>Administrators</Group>
            <Name>$($SSWConfig.DomainAdmin)</Name>
          </LocalAccount>
        </LocalAccounts>
      </UserAccounts>
    </component>
  </settings>
</unattend>
"@
}

function Build-UnattendISO {
    param([string]$SourceISO, [string]$OutputISO, [string]$UnattendXml, [scriptblock]$Log)

    $tmpWork = Join-Path $env:TEMP "SSW-ISO-Work-$(Get-Random)"
    try {
        & $Log "Unblock-File op $SourceISO…"
        Unblock-File -Path $SourceISO -ErrorAction SilentlyContinue
        & $Log "ISO koppelen…"
        $mount = Mount-DiskImage -ImagePath $SourceISO -PassThru -ErrorAction Stop
        $driveLetter = ($mount | Get-Volume).DriveLetter
        if (-not $driveLetter) { throw "Geen driveletter toegewezen." }
        $srcDrive = "${driveLetter}:\"
        & $Log "Inhoud kopiëren…"
        New-Item -ItemType Directory -Path $tmpWork -Force | Out-Null
        robocopy $srcDrive $tmpWork /E /NP /NFL /NDL /NJH /NJS | Out-Null
        & $Log "unattend.xml injecteren…"
        $UnattendXml | Set-Content -Path (Join-Path $tmpWork "autounattend.xml") -Encoding UTF8 -Force
        & $Log "ISO bouwen met oscdimg…"
        $oscdimg = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"
        if (-not (Test-Path $oscdimg)) { throw "oscdimg.exe niet gevonden. Installeer Windows ADK (Deployment Tools)." }
        $bootData = "2#p0,e,b`"$tmpWork\boot\etfsboot.com`"#pEF,e,b`"$tmpWork\efi\microsoft\boot\efisys.bin`""
        & $oscdimg -m -o -u2 -udfver102 "-bootdata:$bootData" $tmpWork $OutputISO 2>&1 | Out-Null
        if (-not (Test-Path $OutputISO)) { throw "oscdimg heeft geen ISO aangemaakt." }
        & $Log "✔ ISO aangemaakt: $OutputISO"
    } finally {
        Dismount-DiskImage -ImagePath $SourceISO -ErrorAction SilentlyContinue
        if (Test-Path $tmpWork) { Remove-Item $tmpWork -Recurse -Force -ErrorAction SilentlyContinue }
    }
}

# ── GUI ───────────────────────────────────────────────────────
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
  xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SSW-Lab | ISO's voorbereiden" Height="660" Width="680"
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
      <Setter Property="Padding" Value="8,6"/><Setter Property="FontSize" Value="12"/>
      <Setter Property="Height" Value="32"/>
    </Style>
    <Style x:Key="Btn" TargetType="Button">
      <Setter Property="Background" Value="#89B4FA"/><Setter Property="Foreground" Value="#1E1E2E"/>
      <Setter Property="FontWeight" Value="SemiBold"/><Setter Property="FontSize" Value="12"/>
      <Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Height" Value="32"/>
    </Style>
  </Window.Resources>
  <Grid Margin="24">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <StackPanel Grid.Row="0" Margin="0,0,0,8">
      <TextBlock Text="ISO's voorbereiden" Foreground="#CDD6F4" FontSize="20" FontWeight="SemiBold"/>
      <TextBlock Text="Inject unattend.xml into MSDN ISOs" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>

    <!-- ADK banner -->
    <Border x:Name="ADKBanner" Grid.Row="1" Background="#2D1E2E" CornerRadius="6" Padding="14,10"
            Margin="0,0,0,10" BorderBrush="#CBA6F7" BorderThickness="1">
      <Grid>
      <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
        <StackPanel Grid.Column="0" VerticalAlignment="Center">
          <TextBlock Text="Vereiste: Windows ADK — Deployment Tools"
                     Foreground="#CBA6F7" FontSize="12" FontWeight="SemiBold"/>
          <TextBlock Text="Installeer alleen 'Deployment Tools' (ca. 80 MB) — alleen oscdimg.exe is nodig."
                     Foreground="#A6ADC8" FontSize="11" TextWrapping="Wrap" Margin="0,2,0,0"/>
        </StackPanel>
        <Button x:Name="BtnDownloadADK" Grid.Column="1" Content="⬇  Download ADK"
                Background="#CBA6F7" Foreground="#1E1E2E" FontWeight="SemiBold" FontSize="12"
                BorderThickness="0" Cursor="Hand" Padding="14,8" Margin="12,0,0,0" Height="34"/>
      <Button x:Name="BtnOpenMSDN" Grid.Column="2" Content="🧭  Open MSDN"
        Background="#89B4FA" Foreground="#1E1E2E" FontWeight="SemiBold" FontSize="12"
        BorderThickness="0" Cursor="Hand" Padding="14,8" Margin="8,0,0,0" Height="34"/>
      </Grid>
    </Border>

    <!-- ISO paden + admin account -->
    <Grid Grid.Row="2">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/><ColumnDefinition Width="8"/><ColumnDefinition Width="80"/>
      </Grid.ColumnDefinitions>
      <Grid.RowDefinitions>
        <RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/>
        <RowDefinition/><RowDefinition/><RowDefinition/><RowDefinition/>
      </Grid.RowDefinitions>

      <TextBlock Grid.Row="0" Grid.ColumnSpan="3" Text="Windows 11 Enterprise ISO (MSDN)" Style="{StaticResource Lbl}"/>
      <TextBox   Grid.Row="1" Grid.Column="0" x:Name="TxtW11ISO" Style="{StaticResource Fld}"/>
      <Button    Grid.Row="1" Grid.Column="2" x:Name="BtnW11ISO" Content="Bladeren" Style="{StaticResource Btn}" Background="#45475A" Foreground="#CDD6F4"/>

      <TextBlock Grid.Row="2" Grid.ColumnSpan="3" Text="Windows Server 2025 ISO (MSDN)" Style="{StaticResource Lbl}"/>
      <TextBox   Grid.Row="3" Grid.Column="0" x:Name="TxtSrvISO" Style="{StaticResource Fld}"/>
      <Button    Grid.Row="3" Grid.Column="2" x:Name="BtnSrvISO" Content="Bladeren" Style="{StaticResource Btn}" Background="#45475A" Foreground="#CDD6F4"/>

      <TextBlock Grid.Row="4" Grid.ColumnSpan="3" Text="Uitvoermap voor unattended ISO's" Style="{StaticResource Lbl}"/>
      <TextBox   Grid.Row="5" Grid.Column="0" x:Name="TxtOutDir" Style="{StaticResource Fld}"/>
      <Button    Grid.Row="5" Grid.Column="2" x:Name="BtnOutDir" Content="Bladeren" Style="{StaticResource Btn}" Background="#45475A" Foreground="#CDD6F4"/>

      <TextBlock Grid.Row="6" Grid.ColumnSpan="3" Text="Wachtwoord (Administrator en LabAdmin krijgen beide dit wachtwoord)" Style="{StaticResource Lbl}"/>
      <PasswordBox Grid.Row="7" Grid.Column="0" Grid.ColumnSpan="3" x:Name="PwdAdmin"
                   Background="#313244" Foreground="#CDD6F4" BorderBrush="#45475A"
                   BorderThickness="1" Padding="8,6" FontSize="12" Height="32"/>
    </Grid>

    <!-- ISO selectie -->
    <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,10,0,0">
      <CheckBox x:Name="ChkW11" Content="Windows 11 ISO bouwen" IsChecked="True"
                Foreground="#CDD6F4" FontSize="12" Margin="0,0,20,0" VerticalContentAlignment="Center"/>
      <CheckBox x:Name="ChkSrv" Content="Server 2025 ISO bouwen" IsChecked="True"
                Foreground="#CDD6F4" FontSize="12" VerticalContentAlignment="Center"/>
    </StackPanel>

    <Border Grid.Row="4" Background="#181825" CornerRadius="6" Margin="0,10,0,0" Padding="10">
      <ScrollViewer VerticalScrollBarVisibility="Auto">
        <TextBox x:Name="LogBox" Background="Transparent" Foreground="#A6E3A1"
                 FontFamily="Consolas" FontSize="11" IsReadOnly="True" TextWrapping="Wrap" BorderThickness="0"/>
      </ScrollViewer>
    </Border>

    <ProgressBar x:Name="Progress" Grid.Row="5" Height="6" Margin="0,10,0,0"
                 Background="#313244" Foreground="#89B4FA" BorderThickness="0" Minimum="0" Maximum="100" Value="0"/>

    <!-- Dry Run toggle -->
    <Border x:Name="DryRunBar" Grid.Row="6" CornerRadius="6" Margin="0,10,0,0" Padding="14,10" BorderThickness="1">
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

    <StackPanel Grid.Row="7" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,12,0,0">
      <Button x:Name="BtnBuild" Content="ISO('s) bouwen" Style="{StaticResource Btn}" Margin="0,0,10,0" Width="140"/>
      <Button x:Name="BtnNext"  Content="Doorgaan naar 03-VMS →" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False" Width="200"/>
    </StackPanel>
  </Grid>
</Window>
"@

$reader      = [System.Windows.Markup.XamlReader]::Load([System.Xml.XmlNodeReader]::new($xaml))
$txtW11      = $reader.FindName("TxtW11ISO")
$txtSrv      = $reader.FindName("TxtSrvISO")
$txtOut      = $reader.FindName("TxtOutDir")
$pwdAdmin    = $reader.FindName("PwdAdmin")
$chkW11      = $reader.FindName("ChkW11")
$chkSrv      = $reader.FindName("ChkSrv")
$logBox      = $reader.FindName("LogBox")
$progress    = $reader.FindName("Progress")
$btnBuild    = $reader.FindName("BtnBuild")
$btnNext     = $reader.FindName("BtnNext")
$btnADK      = $reader.FindName("BtnDownloadADK")
$btnMSDN     = $reader.FindName("BtnOpenMSDN")
$adkBanner   = $reader.FindName("ADKBanner")
$chkDryRun   = $reader.FindName("ChkDryRun")
$dryRunBar   = $reader.FindName("DryRunBar")
$dryRunTitle = $reader.FindName("DryRunTitle")
$dryRunSub   = $reader.FindName("DryRunSub")
$conv        = [System.Windows.Media.BrushConverter]::new()
$oscdimg     = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background   = $conv.ConvertFrom("#1A2E24")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text       = "🔒  Dry Run — geen ISO's worden aangemaakt"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text         = "Haal het vinkje weg om daadwerkelijk uit te voeren"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#A6E3A1")
        $btnBuild.Content       = "Simulate (Dry Run)"
        $btnBuild.Background    = $conv.ConvertFrom("#89B4FA")
        $btnBuild.Foreground    = $conv.ConvertFrom("#1E1E2E")
    } else {
        $dryRunBar.Background   = $conv.ConvertFrom("#2E1A1A")
        $dryRunBar.BorderBrush  = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text       = "⚠  LIVE EXECUTION — ISO's worden daadwerkelijk gebouwd"
        $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text         = "Zet het vinkje terug om naar Dry Run te gaan"
        $dryRunSub.Foreground   = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground   = $conv.ConvertFrom("#F38BA8")
        $btnBuild.Content       = "LIVE ISO('s) bouwen"
        $btnBuild.Background    = $conv.ConvertFrom("#F38BA8")
        $btnBuild.Foreground    = $conv.ConvertFrom("#1E1E2E")
    }
}

$btnADK.Add_Click({ Start-Process "https://go.microsoft.com/fwlink/?linkid=2289980" })
$btnMSDN.Add_Click({ Start-Process "https://my.visualstudio.com/Downloads" })

$reader.Add_Loaded({
    $txtOut.Text      = $SSWConfig.ISOPath
    $adkBanner.Visibility = if (Test-Path $oscdimg) { "Collapsed" } else { "Visible" }
    Update-DryRunBar
})

$chkDryRun.Add_Checked({   Update-DryRunBar })
$chkDryRun.Add_Unchecked({ Update-DryRunBar })

function Write-Log($msg) {
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.Text += "[$ts] $msg`n"
    $logBox.ScrollToEnd()
}

foreach ($pair in @(@("BtnW11ISO",$txtW11,"ISO"), @("BtnSrvISO",$txtSrv,"ISO"), @("BtnOutDir",$txtOut,"DIR"))) {
    $btn = $reader.FindName($pair[0]); $box = $pair[1]; $type = $pair[2]
    $btn.Add_Click({
        if ($type -eq "ISO") {
            $dlg = [System.Windows.Forms.OpenFileDialog]::new()
            $dlg.Filter = "ISO bestanden (*.iso)|*.iso"
            if ($dlg.ShowDialog() -eq "OK") { $box.Text = $dlg.FileName }
        } else {
            $dlg = [System.Windows.Forms.FolderBrowserDialog]::new()
            if ($dlg.ShowDialog() -eq "OK") { $box.Text = $dlg.SelectedPath }
        }
    }.GetNewClosure())
}

$btnBuild.Add_Click({
    $btnBuild.IsEnabled = $false
    $isDry     = $chkDryRun.IsChecked
    $outDir    = $txtOut.Text.Trim()
    $adminPass = $pwdAdmin.Password
    $pre       = if ($isDry) { "[DRY RUN] " } else { "" }

    if (-not $adminPass) { [System.Windows.MessageBox]::Show("Vul een admin wachtwoord in.", "SSW-Lab"); $btnBuild.IsEnabled = $true; return }

    if (-not $isDry) {
        if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    }

    $jobs = @()
    if ($chkW11.IsChecked -and $txtW11.Text) { $jobs += "W11" }
    if ($chkSrv.IsChecked -and $txtSrv.Text) { $jobs += "SRV" }

    if ($jobs.Count -eq 0) { Write-Log "Geen ISO geselecteerd."; $btnBuild.IsEnabled = $true; return }

    $step = [math]::Floor(100 / $jobs.Count); $done = 0

    foreach ($job in $jobs) {
        if ($job -eq "W11") {
            $src = $txtW11.Text.Trim()
            $dst = Join-Path $outDir "SSW-W11-Unattend.iso"
            $xml = Get-W11Unattend $adminPass
            Write-Log "${pre}W11 ISO bouwen: $src → $dst"
        } else {
            $src = $txtSrv.Text.Trim()
            $dst = Join-Path $outDir "SSW-WS2025-Unattend.iso"
            $xml = Get-WS2025Unattend $adminPass
            Write-Log "${pre}WS2025 ISO bouwen: $src → $dst"
        }
        if (-not $isDry) {
            try { Build-UnattendISO -SourceISO $src -OutputISO $dst -UnattendXml $xml -Log { param($m) Write-Log $m } }
            catch { Write-Log "FOUT bij $job`: $_" }
        }
        $done += $step
        $progress.Value = [math]::Min($done, 100)
    }

    $progress.Value = 100
    Write-Log $(if ($isDry) { "✔ Dry Run klaar — niets aangemaakt." } else { "✔ Klaar." })
    $btnNext.IsEnabled = $true
    $btnBuild.IsEnabled = $true
})

$btnNext.Add_Click({
    $reader.Close()
    $next = Join-Path $PSScriptRoot "03-VMS.ps1"
    if (Test-Path $next) { Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" -Verb RunAs }
})

$reader.ShowDialog() | Out-Null

