# ============================================================
# SSW-Lab | labs/AZ104/lab-week3-compute.ps1
# AZ-104 Week 3 — Azure Compute: VMs, schijven, snapshots, backup
# Cloud: Azure subscription
# ============================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AZ-104 | Week 3 — Azure Compute" Height="720" Width="700"
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
      <TextBlock Text="AZ-104 | Week 3 — Azure Compute" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="VM aanmaken · Schijven en snapshots · Availability set · Azure Backup" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Steps in this lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Azure VM aanmaken (Windows Server 2022, B2s)"/>
        <LineBreak/><Run Text="2. Data disk toevoegen en snapshot maken"/>
        <LineBreak/><Run Text="3. VM-grootte aanpassen (resize)"/>
        <LineBreak/><Run Text="4. Azure Backup configureren (Recovery Services Vault)"/>
        <LineBreak/><Run Text="5. VM stoppen en dealloceren (kosten besparen)"/>
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
      <Button x:Name="BtnNext" Content="Continue to Week 4 >" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text = "Dry Run — geen VM wordt aangemaakt (kosten voorkomen)"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om LIVE uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — VM aanmaken genereert Azure kosten"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Stop en verwijder VM na het lab om kosten te beperken"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Show-DryRunState })
$chkDryRun.Add_Checked({ Show-DryRunState }); $chkDryRun.Add_Unchecked({ Show-DryRunState })
function Write-LabLog($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }
    $rgName  = "ssw-lab-rg"
    $location = "westeurope"
    $vmName  = "ssw-lab-vm01"
    $vaultName = "ssw-lab-vault"

    # ── Stap 1: Azure VM aanmaken ────────────────────────────
    Write-LabLog "${pre}Stap 1: Azure VM aanmaken ($vmName, B2s, WinServer 2022)"
    $progress.Value = 16
    if ($isDry) {
        Write-LabLog "${pre}  `$cred = Get-Credential -Message 'Local admin wachtwoord voor VM'"
        Write-LabLog "${pre}  `$vmConfig = New-AzVMConfig -VMName '$vmName' -VMSize 'Standard_B2s'"
        Write-LabLog "${pre}  `$vmConfig = Set-AzVMOperatingSystem -VM `$vmConfig -Windows -ComputerName '$vmName' -Credential `$cred"
        Write-LabLog "${pre}  `$vmConfig = Set-AzVMSourceImage -VM `$vmConfig -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' -Skus '2022-datacenter' -Version 'latest'"
        Write-LabLog "${pre}  New-AzVM -ResourceGroupName '$rgName' -Location '$location' -VM `$vmConfig"
        Write-LabLog "${pre}  # Deploytijd: 3-6 minuten"
    } else {
        try {
            if (-not (Get-AzContext)) { Connect-AzAccount -ErrorAction Stop | Out-Null }
            $existing = Get-AzVM -ResourceGroupName $rgName -Name $vmName -ErrorAction SilentlyContinue
            if ($existing) {
                Write-LabLog "  VM bestaat al: $vmName [$($existing.ProvisioningState)]"
            } else {
                Write-LabLog "  Aanmaken VM — dit duurt enkele minuten..."
                $vmCred   = Get-Credential -Message "Lokale admin voor $vmName (min. 12 tekens)"
                $vmConfig = New-AzVMConfig -VMName $vmName -VMSize "Standard_B2s"
                $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $vmCred
                $vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2022-datacenter" -Version "latest"
                $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id (New-AzNetworkInterface -Name "$vmName-nic" -ResourceGroupName $rgName -Location $location -SubnetId (New-AzVirtualNetworkSubnetConfig -Name "default" -AddressPrefix "10.0.0.0/24" | New-AzVirtualNetwork -ResourceGroupName $rgName -Location $location -Name "ssw-lab-vnet" -AddressPrefix "10.0.0.0/16").Subnets[0].Id).Id
                New-AzVM -ResourceGroupName $rgName -Location $location -VM $vmConfig | Out-Null
                Write-LabLog "  VM aangemaakt: $vmName"
            }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 2: Data disk + snapshot ────────────────────────
    Write-LabLog "${pre}Stap 2: Data disk toevoegen (32 GB) en snapshot maken"
    $progress.Value = 34
    if ($isDry) {
        Write-LabLog "${pre}  `$diskConfig = New-AzDiskConfig -Location '$location' -CreateOption Empty -DiskSizeGB 32 -SkuName 'Standard_LRS'"
        Write-LabLog "${pre}  `$disk = New-AzDisk -ResourceGroupName '$rgName' -DiskName '$vmName-data01' -Disk `$diskConfig"
        Write-LabLog "${pre}  `$vm = Get-AzVM -ResourceGroupName '$rgName' -Name '$vmName'"
        Write-LabLog "${pre}  Add-AzVMDataDisk -VM `$vm -Name '$vmName-data01' -ManagedDiskId `$disk.Id -Lun 0 -CreateOption Attach | Update-AzVM"
        Write-LabLog "${pre}  # Snapshot van OS-disk:"
        Write-LabLog "${pre}  `$snapshotConfig = New-AzSnapshotConfig -SourceUri `$vm.StorageProfile.OsDisk.ManagedDisk.Id -Location '$location' -CreateOption Copy"
        Write-LabLog "${pre}  New-AzSnapshot -ResourceGroupName '$rgName' -SnapshotName '$vmName-snap01' -Snapshot `$snapshotConfig"
    } else {
        try {
            $vm = Get-AzVM -ResourceGroupName $rgName -Name $vmName -ErrorAction Stop
            $diskExists = Get-AzDisk -ResourceGroupName $rgName -DiskName "$vmName-data01" -ErrorAction SilentlyContinue
            if (-not $diskExists) {
                $diskConfig = New-AzDiskConfig -Location $location -CreateOption Empty -DiskSizeGB 32 -SkuName "Standard_LRS"
                $disk = New-AzDisk -ResourceGroupName $rgName -DiskName "$vmName-data01" -Disk $diskConfig
                $vm = Add-AzVMDataDisk -VM $vm -Name "$vmName-data01" -ManagedDiskId $disk.Id -Lun 0 -CreateOption Attach
                Update-AzVM -ResourceGroupName $rgName -VM $vm | Out-Null
                Write-LabLog "  Data disk toegevoegd: $vmName-data01 (32 GB)"
            } else { Write-LabLog "  Data disk bestaat al" }
            $snapConfig = New-AzSnapshotConfig -SourceUri $vm.StorageProfile.OsDisk.ManagedDisk.Id -Location $location -CreateOption Copy
            New-AzSnapshot -ResourceGroupName $rgName -SnapshotName "$vmName-snap01" -Snapshot $snapConfig -ErrorAction SilentlyContinue | Out-Null
            Write-LabLog "  Snapshot aangemaakt: $vmName-snap01"
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 3: VM resize ────────────────────────────────────
    Write-LabLog "${pre}Stap 3: VM-grootte aanpassen (B2s → B1ms)"
    $progress.Value = 52
    if ($isDry) {
        Write-LabLog "${pre}  `$vm = Get-AzVM -ResourceGroupName '$rgName' -Name '$vmName'"
        Write-LabLog "${pre}  Stop-AzVM -ResourceGroupName '$rgName' -Name '$vmName' -Force"
        Write-LabLog "${pre}  `$vm.HardwareProfile.VmSize = 'Standard_B1ms'"
        Write-LabLog "${pre}  Update-AzVM -VM `$vm -ResourceGroupName '$rgName'"
        Write-LabLog "${pre}  Start-AzVM -ResourceGroupName '$rgName' -Name '$vmName'"
    } else {
        Write-LabLog "  VM resize vereist stopzetting — wordt overgeslagen in dit lab (doe manueel)"
        Write-LabLog "  Commando's: Stop-AzVM > vm.HardwareProfile.VmSize = '...' > Update-AzVM > Start-AzVM"
    }

    # ── Stap 4: Azure Backup ─────────────────────────────────
    Write-LabLog "${pre}Stap 4: Azure Backup — Recovery Services Vault aanmaken"
    $progress.Value = 70
    if ($isDry) {
        Write-LabLog "${pre}  New-AzRecoveryServicesVault -Name '$vaultName' -ResourceGroupName '$rgName' -Location '$location'"
        Write-LabLog "${pre}  `$vault = Get-AzRecoveryServicesVault -Name '$vaultName'"
        Write-LabLog "${pre}  Set-AzRecoveryServicesBackupProtectionPolicy -Policy <defaultPolicy> -WorkloadType AzureVM"
        Write-LabLog "${pre}  Enable-AzRecoveryServicesBackupProtection -ResourceGroupName '$rgName' -Name '$vmName' -Policy <policy>"
    } else {
        try {
            $vault = Get-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $vault) {
                $vault = New-AzRecoveryServicesVault -Name $vaultName -ResourceGroupName $rgName -Location $location
                Write-LabLog "  Recovery Services Vault aangemaakt: $vaultName"
            } else { Write-LabLog "  Vault bestaat al: $vaultName" }
            Set-AzRecoveryServicesVaultContext -Vault $vault
            $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name "DefaultPolicy" -ErrorAction SilentlyContinue
            if ($policy) {
                Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $rgName -Name $vmName -Policy $policy -ErrorAction Stop | Out-Null
                Write-LabLog "  Backup ingeschakeld voor $vmName (DefaultPolicy)"
            } else { Write-LabLog "  DefaultPolicy niet gevonden — backup via portal configureren" }
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 5: VM dealloceren ───────────────────────────────
    Write-LabLog "${pre}Stap 5: VM stoppen en dealloceren (kosten beperken)"
    $progress.Value = 88
    if ($isDry) {
        Write-LabLog "${pre}  Stop-AzVM -ResourceGroupName '$rgName' -Name '$vmName' -Force"
        Write-LabLog "${pre}  Get-AzVM -ResourceGroupName '$rgName' -Name '$vmName' -Status | Select-Object -ExpandProperty Statuses"
    } else {
        $stopNow = [System.Windows.MessageBox]::Show("VM stoppen en dealloceren? (kosten sparen)", "SSW-Lab", "YesNo", "Question")
        if ($stopNow -eq "Yes") {
            try {
                Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force | Out-Null
                Write-LabLog "  VM gestopt: $vmName"
            } catch { Write-LabLog "  Fout bij stoppen: $_" }
        } else { Write-LabLog "  VM blijft draaien — vergeet hem niet te stoppen!" }
    }

    $progress.Value = 100; Write-LabLog ""; Write-LabLog "Week 3 lab afgerond."; Write-LabLog ""
    Write-LabLog "━━━ KNOWLEDGE CHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-LabLog "1. Wat is het verschil tussen Stop-AzVM en Deallocate?"
    Write-LabLog "2. Welke VM-groottereeks is goedkoopst voor lichte workloads?"
    Write-LabLog "3. Hoe werkt een Azure VM Availability Set (update/fault domains)?"
    Write-LabLog "4. Wat is het verschil tussen Azure Backup en Azure Site Recovery?"
    Write-LabLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week4-appservices.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week4-appservices.ps1 not found.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null

