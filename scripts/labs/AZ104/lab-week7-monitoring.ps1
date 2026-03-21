# ============================================================
# SSW-Lab | labs/AZ104/lab-week7-monitoring.ps1
# AZ-104 Week 7 — Azure Monitor: Log Analytics, alerts, KQL, Backup
# Cloud: Azure subscription
# ============================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AZ-104 | Week 7 — Azure Monitor en Backup" Height="720" Width="700"
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
      <TextBlock Text="AZ-104 | Week 7 — Azure Monitor en Backup" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Log Analytics · VM Insights · KQL alerts · Azure Monitor Workbooks" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Log Analytics Workspace aanmaken"/>
        <LineBreak/><Run Text="2. VM Insights inschakelen op ssw-lab-vm01"/>
        <LineBreak/><Run Text="3. KQL-query uitvoeren op hartslag en performance"/>
        <LineBreak/><Run Text="4. Alert-regel aanmaken (CPU > 80%)"/>
        <LineBreak/><Run Text="5. Azure Monitor Workbook bekijken"/>
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
      <Button x:Name="BtnNext" Content="AZ-104 voltooid! Naar SC-300 >" Style="{StaticResource Btn}"
              Background="#A6E3A1" IsEnabled="False" Width="260"/>
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

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background = $conv.ConvertFrom("#1A2E24"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text = "Dry Run — Log Analytics workspace nog niet aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — Log Analytics workspace wordt aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Haal KQL-query's op na 5-10 minuten data-ingestie"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({ Update-DryRunBar }); $chkDryRun.Add_Unchecked({ Update-DryRunBar })
function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry    = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }
    $rgName   = "ssw-lab-rg"
    $location = "westeurope"
    $lawName  = "ssw-lab-law"
    $vmName   = "ssw-lab-vm01"

    # ── Stap 1: Log Analytics Workspace ─────────────────────
    Write-Log "${pre}Stap 1: Log Analytics Workspace aanmaken ($lawName)"
    $progress.Value = 16
    if ($isDry) {
        Write-Log "${pre}  New-AzOperationalInsightsWorkspace -ResourceGroupName '$rgName' -Name '$lawName' -Location '$location' -Sku PerGB2018"
        Write-Log "${pre}  `$law = Get-AzOperationalInsightsWorkspace -ResourceGroupName '$rgName' -Name '$lawName'"
        Write-Log "${pre}  `$law.CustomerId  # Workspace ID"
        Write-Log "${pre}  (Get-AzOperationalInsightsWorkspaceSharedKeys -ResourceGroupName '$rgName' -Name '$lawName').PrimarySharedKey"
    } else {
        try {
            if (-not (Get-AzContext)) { Connect-AzAccount -ErrorAction Stop | Out-Null }
            $law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgName -Name $lawName -ErrorAction SilentlyContinue
            if (-not $law) {
                $law = New-AzOperationalInsightsWorkspace -ResourceGroupName $rgName -Name $lawName -Location $location -Sku PerGB2018
                Write-Log "  Log Analytics Workspace aangemaakt: $lawName"
            } else { Write-Log "  Workspace bestaat al: $lawName" }
            Write-Log "  Workspace ID: $($law.CustomerId)"
        } catch { Write-Log "  Fout: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: VM Insights inschakelen ─────────────────────
    Write-Log "${pre}Stap 2: VM Insights inschakelen op $vmName"
    $progress.Value = 32
    if ($isDry) {
        Write-Log "${pre}  `$vm = Get-AzVM -ResourceGroupName '$rgName' -Name '$vmName'"
        Write-Log "${pre}  Set-AzVMExtension -ResourceGroupName '$rgName' -VMName '$vmName' -Name 'MmaAgent' -Publisher 'Microsoft.EnterpriseCloud.Monitoring' -ExtensionType 'MicrosoftMonitoringAgent' -TypeHandlerVersion '1.0' -Settings @{workspaceId='<id>'} -ProtectedSettings @{workspaceKey='<key>'}"
        Write-Log "${pre}  # Alternatief via portal: VM > Insights > Inschakelen"
    } else {
        Write-Log "  VM Insights inschakelen via portal: Azure portal > VM > Insights > Enable"
        Write-Log "  Selecteer workspace: $lawName in $rgName"
        Write-Log "  Dit installeert automatisch MMA en Dependency Agent"
        if (-not $isDry) {
            $open = [System.Windows.MessageBox]::Show("Azure portal openen (VM Insights)?", "SSW-Lab", "YesNo", "Question")
            if ($open -eq "Yes") { Start-Process "https://portal.azure.com/#resource/subscriptions//resourceGroups/$rgName/providers/Microsoft.Compute/virtualMachines/$vmName/performance" }
        }
    }

    # ── Stap 3: KQL queries ──────────────────────────────────
    Write-Log "${pre}Stap 3: KQL-queries in Log Analytics"
    $progress.Value = 50
    Write-Log "  Azure portal > Log Analytics workspaces > $lawName > Logs"
    Write-Log ""
    Write-Log "  Query 1 — Heartbeat laatste 24 uur:"
    Write-Log "  Heartbeat | where TimeGenerated > ago(24h) | summarize count() by Computer | order by count_ desc"
    Write-Log ""
    Write-Log "  Query 2 — Hoog CPU gebruik:"
    Write-Log "  Perf | where ObjectName == 'Processor' and CounterName == '% Processor Time' | where CounterValue > 80 | project TimeGenerated, Computer, CounterValue"
    Write-Log ""
    Write-Log "  Query 3 — Windows Events (fouten):"
    Write-Log "  Event | where EventLevelName == 'Error' | project TimeGenerated, Computer, Source, RenderedDescription | take 20"

    # ── Stap 4: Alert-regel ──────────────────────────────────
    Write-Log "${pre}Stap 4: Alert-regel aanmaken (CPU > 80%)"
    $progress.Value = 68
    if ($isDry) {
        Write-Log "${pre}  # Via Azure portal: Monitor > Alerts > Create alert rule"
        Write-Log "${pre}  Resource: $vmName | Signal: CPU Percentage"
        Write-Log "${pre}  Operator: Greater than | Threshold: 80 | Aggregation: Average over 5 min"
        Write-Log "${pre}  Action group: e-mail naar admin@<tenant>"
        Write-Log "${pre}  Alert rule name: 'ssw-vm-cpu-alert'"
    } else {
        try {
            $law = Get-AzOperationalInsightsWorkspace -ResourceGroupName $rgName -Name $lawName -ErrorAction Stop
            Write-Log "  Alert aanmaken via Azure portal:"
            Write-Log "  Monitor > Alerts > + Create > Alert rule"
            Write-Log "  Scope: $vmName | Condition: CPU percentage > 80%"
            Write-Log "  Action Group: maak een nieuwe aan met e-mail melding"
            $open = [System.Windows.MessageBox]::Show("Azure Monitor Alerts openen?", "SSW-Lab", "YesNo", "Question")
            if ($open -eq "Yes") { Start-Process "https://portal.azure.com/#view/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/~/alertsV2" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 5: Monitor Workbook ─────────────────────────────
    Write-Log "${pre}Stap 5: Azure Monitor Workbook bekijken"
    $progress.Value = 84
    Write-Log "  Azure portal > Monitor > Workbooks"
    Write-Log "  Kies: 'Virtual Machine Performance' werkmap"
    Write-Log "  Filter op: workspaceId = $lawName"
    Write-Log "  Bekijk: CPU trend, memory, disk I/O over 24 uur"
    Write-Log "  Maak een eigen werkmap: + New | voeg KQL-tile toe"
    Write-Log "  Sla op als 'SSW-Lab Monitoring'"

    $progress.Value = 100; Write-Log ""; Write-Log "Week 7 lab afgerond — AZ-104 track volledig!"; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen Azure Monitor Metrics en Logs?"
    Write-Log "2. Welke drie soorten alerts bestaan er in Azure Monitor?"
    Write-Log "3. Hoe gebruik je KQL om events in de laatste 7 dagen samen te vatten per dag?"
    Write-Log "4. Wat is het verschil tussen Alert Rules en Alert Processing Rules?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "..\..\labs\SC300\lab-week1-hybrid-identity.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("SC-300 lab-week1-hybrid-identity.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null
