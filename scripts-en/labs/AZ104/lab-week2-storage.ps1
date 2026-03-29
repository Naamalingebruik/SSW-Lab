# ============================================================
# SSW-Lab | labs/AZ104/lab-week2-storage.ps1
# AZ-104 Week 2 — Azure Storage: blobs, shares, SAS, replication
# Cloud: Azure subscription
# ============================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AZ-104 | Week 2 — Azure Storage" Height="720" Width="700"
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
      <TextBlock Text="AZ-104 | Week 2 — Azure Storage" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Storage account · Blob containers · SAS tokens · File shares · Replication" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Steps in this lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Storage account aanmaken (LRS, StorageV2)"/>
        <LineBreak/><Run Text="2. Blob container aanmaken en bestand uploaden"/>
        <LineBreak/><Run Text="3. SAS-token genereren voor container-toegang"/>
        <LineBreak/><Run Text="4. Azure File Share aanmaken en koppelen"/>
        <LineBreak/><Run Text="5. Lifecycle management policy instellen"/>
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
      <Button x:Name="BtnNext" Content="Continue to Week 3 >" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text = "Dry Run — geen Azure-resources worden aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — Azure Storage resources worden aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Zet het vinkje terug voor Dry Run"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Show-DryRunState })
$chkDryRun.Add_Checked({ Show-DryRunState }); $chkDryRun.Add_Unchecked({ Show-DryRunState })
function Write-LabLog($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }
    $rgName       = "ssw-lab-rg"
    $location     = "westeurope"
    # Storage account names must be globally unique, lowercase 3-24 chars
    $saName       = "sswlab$(Get-Random -Minimum 1000 -Maximum 9999)"
    $containerName = "labdata"
    $shareName    = "labshare"

    # ── Stap 1: Storage account ──────────────────────────────
    Write-LabLog "${pre}Stap 1: Storage account aanmaken"
    $progress.Value = 16
    if ($isDry) {
        Write-LabLog "${pre}  `$saName = 'sswlab<random>'"
        Write-LabLog "${pre}  New-AzStorageAccount -ResourceGroupName '$rgName' -Name `$saName -Location '$location' -SkuName 'Standard_LRS' -Kind 'StorageV2'"
        Write-LabLog "${pre}  Get-AzStorageAccount -ResourceGroupName '$rgName' | Select-Object StorageAccountName, PrimaryLocation, Sku"
    } else {
        try {
            if (-not (Get-AzContext)) { Connect-AzAccount -ErrorAction Stop | Out-Null }
            $sa = Get-AzStorageAccount -ResourceGroupName $rgName | Where-Object { $_.StorageAccountName -like "sswlab*" } | Select-Object -First 1
            if (-not $sa) {
                Write-LabLog "  Aanmaken: $saName (Standard_LRS, StorageV2)"
                $sa = New-AzStorageAccount -ResourceGroupName $rgName -Name $saName -Location $location -SkuName "Standard_LRS" -Kind "StorageV2"
            } else {
                Write-LabLog "  Bestaand storage account gevonden: $($sa.StorageAccountName)"
            }
            $saName = $sa.StorageAccountName
            Write-LabLog "  Storage account: $saName [$($sa.PrimaryLocation)]"
        } catch { Write-LabLog "  Error: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: Blob container + upload ─────────────────────
    Write-LabLog "${pre}Stap 2: Blob container aanmaken en bestand uploaden"
    $progress.Value = 32
    if ($isDry) {
        Write-LabLog "${pre}  `$ctx = (Get-AzStorageAccount -Name `$saName -ResourceGroupName '$rgName').Context"
        Write-LabLog "${pre}  New-AzStorageContainer -Name '$containerName' -Context `$ctx -Permission Blob"
        Write-LabLog "${pre}  'Hello SSW-Lab' | Set-Content -Path `$env:TEMP\labfile.txt"
        Write-LabLog "${pre}  Set-AzStorageBlobContent -File `$env:TEMP\labfile.txt -Container '$containerName' -Blob 'labfile.txt' -Context `$ctx"
    } else {
        try {
            $ctx = (Get-AzStorageAccount -Name $saName -ResourceGroupName $rgName).Context
            $container = Get-AzStorageContainer -Name $containerName -Context $ctx -ErrorAction SilentlyContinue
            if (-not $container) {
                New-AzStorageContainer -Name $containerName -Context $ctx -Permission Blob | Out-Null
                Write-LabLog "  Container aangemaakt: $containerName"
            } else { Write-LabLog "  Container bestaat al: $containerName" }
            $localFile = Join-Path $env:TEMP "labfile.txt"
            "Hello SSW-Lab $(Get-Date)" | Set-Content -Path $localFile
            Set-AzStorageBlobContent -File $localFile -Container $containerName -Blob "labfile.txt" -Context $ctx -Force | Out-Null
            Write-LabLog "  Bestand geüpload: labfile.txt"
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 3: SAS-token ─────────────────────────────────────
    Write-LabLog "${pre}Stap 3: SAS-token genereren (container-niveau, read, 1 uur)"
    $progress.Value = 50
    if ($isDry) {
        Write-LabLog "${pre}  `$expiry = (Get-Date).AddHours(1)"
        Write-LabLog "${pre}  `$sasToken = New-AzStorageContainerSASToken -Name '$containerName' -Permission r -ExpiryTime `$expiry -Context `$ctx"
        Write-LabLog "${pre}  `$blobUrl = 'https://<accountname>.blob.core.windows.net/$containerName/labfile.txt' + `$sasToken"
    } else {
        try {
            $expiry   = (Get-Date).AddHours(1)
            $sasToken = New-AzStorageContainerSASToken -Name $containerName -Permission "r" -ExpiryTime $expiry -Context $ctx
            $blobUrl  = "https://$saName.blob.core.windows.net/$containerName/labfile.txt$sasToken"
            Write-LabLog "  SAS-URL (geldig 1 uur):"
            Write-LabLog "  $blobUrl"
            Write-LabLog "  Test: Invoke-WebRequest -Uri '<url>' | Select-Object -ExpandProperty Content"
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 4: Azure File Share ─────────────────────────────
    Write-LabLog "${pre}Stap 4: Azure File Share aanmaken"
    $progress.Value = 68
    if ($isDry) {
        Write-LabLog "${pre}  New-AzStorageShare -Name '$shareName' -Context `$ctx"
        Write-LabLog "${pre}  # Mountcommand (Windows via PowerShell Direct / MGMT01):"
        Write-LabLog "${pre}  net use Z: \\<accountname>.file.core.windows.net\$shareName <storagekey> /user:Azure\<accountname>"
    } else {
        try {
            $share = Get-AzStorageShare -Name $shareName -Context $ctx -ErrorAction SilentlyContinue
            if (-not $share) {
                New-AzStorageShare -Name $shareName -Context $ctx | Out-Null
                Write-LabLog "  File share aangemaakt: $shareName"
            } else { Write-LabLog "  File share bestaat al: $shareName" }
            $key = (Get-AzStorageAccountKey -ResourceGroupName $rgName -Name $saName)[0].Value
            Write-LabLog "  Mount command (run op client):"
            Write-LabLog "  net use Z: \\$saName.file.core.windows.net\$shareName `"$key`" /user:Azure\$saName"
        } catch { Write-LabLog "  Error: $_" }
    }

    # ── Stap 5: Lifecycle management ─────────────────────────
    Write-LabLog "${pre}Stap 5: Lifecycle management policy — cool-tier na 30 dagen"
    $progress.Value = 84
    if ($isDry) {
        Write-LabLog "${pre}  Azure portal > Storage account > Data management > Lifecycle management"
        Write-LabLog "${pre}  Voeg regel toe: alle blobs na 30 dagen naar Cool tier"
        Write-LabLog "${pre}  Na 90 dagen: naar Archive tier"
        Write-LabLog "${pre}  Na 365 dagen: verwijder blob"
        Write-LabLog "${pre}  (PowerShell: Set-AzStorageManagementPolicy)"
    } else {
        try {
            $rule = @{
                name    = "move-to-cool"
                enabled = $true
                type    = "Lifecycle"
                definition = @{
                    filters = @{ blobTypes = @("blockBlob") }
                    actions = @{
                        baseBlob = @{
                            tierToCool    = @{ daysAfterModificationGreaterThan = 30 }
                            tierToArchive = @{ daysAfterModificationGreaterThan = 90 }
                            delete        = @{ daysAfterModificationGreaterThan = 365 }
                        }
                    }
                }
            }
            Set-AzStorageManagementPolicy -ResourceGroupName $rgName -StorageAccountName $saName -Rule $rule -ErrorAction Stop | Out-Null
            Write-LabLog "  Lifecycle policy toegepast: Cool (30d) / Archive (90d) / Delete (365d)"
        } catch { Write-LabLog "  Fout (portal alternatief): $_ " }
    }

    $progress.Value = 100; Write-LabLog ""; Write-LabLog "Week 2 lab completed."; Write-LabLog ""
    Write-LabLog "━━━ KNOWLEDGE CHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-LabLog "1. Wat is het verschil tussen LRS, ZRS, GRS en GZRS?"
    Write-LabLog "2. Wanneer gebruik je een Service SAS versus een Account SAS?"
    Write-LabLog "3. Wat zijn de opslaglagen (access tiers) en hun use cases?"
    Write-LabLog "4. Hoe werkt Azure File Sync en wanneer gebruik je het?"
    Write-LabLog "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week3-compute.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week3-compute.ps1 not found.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null

