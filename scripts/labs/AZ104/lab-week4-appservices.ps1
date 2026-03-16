# ============================================================
# SSW-Lab | labs/AZ104/lab-week4-appservices.ps1
# AZ-104 Week 4 — App Services, Container Instances en schalen
# Cloud: Azure subscription
# ============================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AZ-104 | Week 4 — App Services" Height="720" Width="700"
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
      <TextBlock Text="AZ-104 | Week 4 — App Services en containers" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Web App · Deployment slots · ACI · Autoscale · App Service Plan" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. App Service Plan aanmaken (B1)"/>
        <LineBreak/><Run Text="2. Web App deployen (HTML met az CLI-simulatie)"/>
        <LineBreak/><Run Text="3. Deployment slot (staging) aanmaken en swappen"/>
        <LineBreak/><Run Text="4. Azure Container Instance deployen (nginx)"/>
        <LineBreak/><Run Text="5. Autoscale-regel configureren"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 5 >" Style="{StaticResource Btn}"
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

function Update-DryRunBar {
    if ($chkDryRun.IsChecked) {
        $dryRunBar.Background = $conv.ConvertFrom("#1A2E24"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#A6E3A1")
        $dryRunTitle.Text = "Dry Run — commando's worden getoond maar niet uitgevoerd"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — App Service en ACI worden aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Vergeet resources te verwijderen na het lab"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({ Update-DryRunBar }); $chkDryRun.Add_Unchecked({ Update-DryRunBar })
function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry  = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }
    $rgName = "ssw-lab-rg"
    $planName = "ssw-lab-asp"
    $appName  = "sswlabweb$(Get-Random -Minimum 100 -Maximum 999)"
    $aciName  = "sswlabaci"
    $location = "westeurope"

    # ── Stap 1: App Service Plan ─────────────────────────────
    Write-Log "${pre}Stap 1: App Service Plan aanmaken ($planName, B1, Linux)"
    $progress.Value = 16
    if ($isDry) {
        Write-Log "${pre}  New-AzAppServicePlan -Name '$planName' -ResourceGroupName '$rgName' -Location '$location' -Tier 'Basic' -NumberofWorkers 1 -WorkerSize 'Small' -Linux"
    } else {
        try {
            if (-not (Get-AzContext)) { Connect-AzAccount -ErrorAction Stop | Out-Null }
            $plan = Get-AzAppServicePlan -Name $planName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $plan) {
                $plan = New-AzAppServicePlan -Name $planName -ResourceGroupName $rgName -Location $location -Tier "Basic" -NumberofWorkers 1 -WorkerSize "Small" -Linux
                Write-Log "  App Service Plan aangemaakt: $planName (B1 Linux)"
            } else { Write-Log "  App Service Plan bestaat al: $planName [$($plan.Sku.Tier)]" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 2: Web App deployen ─────────────────────────────
    Write-Log "${pre}Stap 2: Web App aanmaken ($appName)"
    $progress.Value = 32
    if ($isDry) {
        Write-Log "${pre}  New-AzWebApp -Name '$appName' -ResourceGroupName '$rgName' -AppServicePlan '$planName'"
        Write-Log "${pre}  # URL: https://$appName.azurewebsites.net"
        Write-Log "${pre}  # Deployment opties: GitHub Actions, ZIP deploy, Local Git"
    } else {
        try {
            $app = Get-AzWebApp -Name $appName -ResourceGroupName $rgName -ErrorAction SilentlyContinue
            if (-not $app) {
                $app = New-AzWebApp -Name $appName -ResourceGroupName $rgName -AppServicePlan $planName
                Write-Log "  Web App aangemaakt: $appName"
                Write-Log "  URL: https://$appName.azurewebsites.net"
            } else { Write-Log "  Web App bestaat al: $appName" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: Deployment slot ──────────────────────────────
    Write-Log "${pre}Stap 3: Deployment slot — staging aanmaken en swappen"
    $progress.Value = 50
    if ($isDry) {
        Write-Log "${pre}  New-AzWebAppSlot -ResourceGroupName '$rgName' -Name '$appName' -Slot 'staging'"
        Write-Log "${pre}  # Deploy naar staging slot:"
        Write-Log "${pre}  Publish-AzWebapp -ResourceGroupName '$rgName' -Name '$appName' -Slot 'staging' -ArchivePath <app.zip>"
        Write-Log "${pre}  # Swap staging → production:"
        Write-Log "${pre}  Switch-AzWebAppSlot -ResourceGroupName '$rgName' -Name '$appName' -SourceSlotName 'staging' -DestinationSlotName 'production' -Swap"
    } else {
        try {
            $slot = Get-AzWebAppSlot -ResourceGroupName $rgName -Name $appName -Slot "staging" -ErrorAction SilentlyContinue
            if (-not $slot) {
                New-AzWebAppSlot -ResourceGroupName $rgName -Name $appName -Slot "staging" | Out-Null
                Write-Log "  Staging slot aangemaakt voor $appName"
            } else { Write-Log "  Staging slot bestaat al" }
            Write-Log "  Staging URL: https://$appName-staging.azurewebsites.net"
            Write-Log "  Swap via: Switch-AzWebAppSlot -Swap (na deployen naar staging)"
        } catch { Write-Log "  Fout (B1 supports slots niet): $_" }
    }

    # ── Stap 4: Azure Container Instance ────────────────────
    Write-Log "${pre}Stap 4: Azure Container Instance — nginx deployen"
    $progress.Value = 68
    if ($isDry) {
        Write-Log "${pre}  New-AzContainerGroup -ResourceGroupName '$rgName' -Name '$aciName' -Image 'nginx' -OsType Linux -DnsNameLabel '$aciName-lab' -Port 80"
        Write-Log "${pre}  # URL: http://$aciName-lab.$location.azurecontainer.io"
        Write-Log "${pre}  Get-AzContainerGroup -ResourceGroupName '$rgName' -Name '$aciName' | Select-Object Name, IPAddressType, Fqdn, ProvisioningState"
    } else {
        try {
            $aci = Get-AzContainerGroup -ResourceGroupName $rgName -Name $aciName -ErrorAction SilentlyContinue
            if (-not $aci) {
                $aci = New-AzContainerGroup -ResourceGroupName $rgName -Name $aciName -Image "nginx" -OsType Linux -DnsNameLabel "$aciName-lab" -Port 80
                Write-Log "  ACI aangemaakt: $aciName"
                Write-Log "  URL: http://$($aci.Fqdn)"
            } else { Write-Log "  ACI bestaat al: $aciName [$($aci.ProvisioningState)]" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 5: Autoscale ────────────────────────────────────
    Write-Log "${pre}Stap 5: Autoscale-regel configureren"
    $progress.Value = 84
    Write-Log "  Azure portal > App Service Plan > Scale out (App Service Plan)"
    Write-Log "  Kies: Custom autoscaling"
    Write-Log "  Voeg een regel toe: CPU > 70% → scale out +1 instance"
    Write-Log "  Voeg een rule toe: CPU < 25% → scale in -1 instance"
    Write-Log "  Min instances: 1 | Max: 3 | Default: 1"
    if (-not $isDry) {
        $open = [System.Windows.MessageBox]::Show("Azure portal openen?", "SSW-Lab", "YesNo", "Question")
        if ($open -eq "Yes") { Start-Process "https://portal.azure.com/#resource/subscriptions//resourceGroups/$rgName/providers/Microsoft.Web/serverFarms/$planName/scaleSettings" }
    }

    $progress.Value = 100; Write-Log ""; Write-Log "Week 4 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen App Service Plan tiers (Free, Basic, Standard, Premium)?"
    Write-Log "2. Waarom gebruik je deployment slots voor blue/green deploys?"
    Write-Log "3. Wanneer kies je voor ACI (Container Instances) vs. AKS?"
    Write-Log "4. Wat is het verschil tussen Scale Out (horizontal) en Scale Up (vertical)?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week5-networking.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week5-networking.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null
