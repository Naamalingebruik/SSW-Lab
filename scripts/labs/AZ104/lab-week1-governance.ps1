# ============================================================
# SSW-Lab | labs/AZ104/lab-week1-governance.ps1
# AZ-104 Week 1 — Azure identiteiten, governance en beheer
# Cloud: Azure subscription (Az PowerShell module)
# Vereiste module: Az (Install-Module Az -Force)
# ============================================================

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="AZ-104 | Week 1 — Identiteiten en governance" Height="720" Width="700"
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
      <TextBlock Text="AZ-104 | Week 1 — Identiteiten en governance" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Entra ID gebruikers · Groepen · RBAC · Azure Policy · Management groups" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Connect-AzAccount en subscription veriëren"/>
        <LineBreak/><Run Text="2. Resource group aanmaken (ssw-lab-rg)"/>
        <LineBreak/><Run Text="3. Entra ID gebruiker en groep aanmaken via Graph"/>
        <LineBreak/><Run Text="4. RBAC-rol toewijzen (Contributor op resource group)"/>
        <LineBreak/><Run Text="5. Azure Policy toewijzen: toegestane regio's"/>
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
      <Button x:Name="BtnNext" Content="Doorgaan naar Week 2 >" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text = "Dry Run — geen Azure-resources worden aangemaakt"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg om uit te voeren"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — Azure resources worden aangemaakt (kosten mogelijk)"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Zet het vinkje terug voor Dry Run"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({ Update-DryRunBar }); $chkDryRun.Add_Unchecked({ Update-DryRunBar })
function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }
    $rgName   = "ssw-lab-rg"
    $location = "westeurope"

    # ── Stap 1: Connect-AzAccount ────────────────────────────
    Write-Log "${pre}Stap 1: Verbinding met Azure subscription"
    $progress.Value = 16
    if ($isDry) {
        Write-Log "${pre}  Connect-AzAccount"
        Write-Log "${pre}  Get-AzSubscription | Select-Object Name, Id, State | Format-Table"
        Write-Log "${pre}  Get-AzContext | Select-Object Account, Subscription, Tenant"
    } else {
        try {
            Write-Log "  Verbinden met Azure..."
            Connect-AzAccount -ErrorAction Stop | Out-Null
            $ctx = Get-AzContext
            Write-Log "  Account     : $($ctx.Account)"
            Write-Log "  Subscription: $($ctx.Subscription.Name)"
            Write-Log "  Tenant      : $($ctx.Tenant.Id)"
        } catch { Write-Log "  Fout: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: Resource group ───────────────────────────────
    Write-Log "${pre}Stap 2: Resource group — $rgName"
    $progress.Value = 32
    if ($isDry) {
        Write-Log "${pre}  New-AzResourceGroup -Name '$rgName' -Location '$location' -Tag @{Cert='AZ-104'; Env='Lab'}"
        Write-Log "${pre}  Get-AzResourceGroup -Name '$rgName' | Select-Object ResourceGroupName, Location, ProvisioningState"
    } else {
        try {
            $rg = Get-AzResourceGroup -Name $rgName -ErrorAction SilentlyContinue
            if (-not $rg) {
                $rg = New-AzResourceGroup -Name $rgName -Location $location -Tag @{Cert = "AZ-104"; Env = "Lab" }
                Write-Log "  Resource group aangemaakt: $($rg.ResourceGroupName) ($location)"
            } else {
                Write-Log "  Resource group bestaat al: $($rg.ResourceGroupName) [$($rg.ProvisioningState)]"
            }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: Entra ID gebruiker + groep ──────────────────
    Write-Log "${pre}Stap 3: Entra ID — gebruiker en groep via Graph"
    $progress.Value = 48
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'User.ReadWrite.All','Group.ReadWrite.All'"
        Write-Log "${pre}  `$upn = 'az-labuser01@<tenant>.onmicrosoft.com'"
        Write-Log "${pre}  New-MgUser -DisplayName 'AZ Lab User 01' -UserPrincipalName `$upn ..."
        Write-Log "${pre}  New-MgGroup -DisplayName 'AZ104-Operators' -MailEnabled:`$false -SecurityEnabled:`$true ..."
        Write-Log "${pre}  New-MgGroupMember -GroupId <groupId> -DirectoryObjectId <userId>"
    } else {
        try {
            if (-not (Get-Module Microsoft.Graph.Users -ListAvailable)) {
                Write-Log "  Installeer Microsoft.Graph.Users: Install-Module Microsoft.Graph.Users -Force"
            } else {
                Connect-MgGraph -Scopes "User.ReadWrite.All", "Group.ReadWrite.All" -ErrorAction Stop | Out-Null
                $domain  = (Get-MgDomain | Where-Object { $_.IsDefault }).Id
                $upn     = "az-labuser01@$domain"
                $mgUser  = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ErrorAction SilentlyContinue
                if (-not $mgUser) {
                    $passProfile = @{ forceChangePasswordNextSignIn = $true; password = "LabAzure@2024!" }
                    $mgUser = New-MgUser -DisplayName "AZ Lab User 01" -UserPrincipalName $upn -AccountEnabled -PasswordProfile $passProfile -MailNickname "az-labuser01"
                    Write-Log "  Gebruiker aangemaakt: $($mgUser.UserPrincipalName)"
                } else { Write-Log "  Gebruiker bestaat al: $($mgUser.UserPrincipalName)" }
                $grp = Get-MgGroup -Filter "displayName eq 'AZ104-Operators'" -ErrorAction SilentlyContinue
                if (-not $grp) {
                    $grp = New-MgGroup -DisplayName "AZ104-Operators" -MailEnabled:$false -SecurityEnabled -MailNickname "az104ops"
                    Write-Log "  Groep aangemaakt: AZ104-Operators"
                } else { Write-Log "  Groep bestaat al: AZ104-Operators" }
                New-MgGroupMember -GroupId $grp.Id -DirectoryObjectId $mgUser.Id -ErrorAction SilentlyContinue
                Write-Log "  Gebruiker toegevoegd aan groep"
            }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 4: RBAC-toewijzing ──────────────────────────────
    Write-Log "${pre}Stap 4: RBAC — Contributor rol op resource group"
    $progress.Value = 66
    if ($isDry) {
        Write-Log "${pre}  `$rg = Get-AzResourceGroup -Name '$rgName'"
        Write-Log "${pre}  New-AzRoleAssignment -SignInName 'az-labuser01@<tenant>' -RoleDefinitionName 'Contributor' -Scope `$rg.ResourceId"
        Write-Log "${pre}  Get-AzRoleAssignment -ResourceGroupName '$rgName' | Select-Object DisplayName, RoleDefinitionName | Format-Table"
    } else {
        try {
            $rg = Get-AzResourceGroup -Name $rgName -ErrorAction Stop
            $existing = Get-AzRoleAssignment -ResourceGroupName $rgName | Where-Object { $_.DisplayName -like "AZ Lab User*" }
            if (-not $existing) {
                New-AzRoleAssignment -ObjectId $mgUser.Id -RoleDefinitionName "Contributor" -Scope $rg.ResourceId -ErrorAction Stop | Out-Null
                Write-Log "  Contributor rol toegewezen aan az-labuser01 op $rgName"
            } else { Write-Log "  Rol al toegewezen" }
            Get-AzRoleAssignment -ResourceGroupName $rgName | Select-Object DisplayName, RoleDefinitionName | ForEach-Object { Write-Log "  $($_.DisplayName) -> $($_.RoleDefinitionName)" }
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 5: Azure Policy ─────────────────────────────────
    Write-Log "${pre}Stap 5: Azure Policy — toegestane regio's"
    $progress.Value = 84
    if ($isDry) {
        Write-Log "${pre}  `$def = Get-AzPolicyDefinition | Where-Object {`$_.Properties.displayName -like '*Allowed locations*'}"
        Write-Log "${pre}  `$params = @{'listOfAllowedLocations'=@{value=@('westeurope','northeurope')}}"
        Write-Log "${pre}  New-AzPolicyAssignment -Name 'ssw-allowed-regions' -Scope `$rg.ResourceId -PolicyDefinition `$def -PolicyParameterObject `$params"
        Write-Log "${pre}  Azure portal > Policy > Assignments > ssw-allowed-regions"
    } else {
        try {
            $rg     = Get-AzResourceGroup -Name $rgName -ErrorAction Stop
            $def    = Get-AzPolicyDefinition | Where-Object { $_.Properties.displayName -eq "Allowed locations" } | Select-Object -First 1
            if ($def) {
                $params = @{ "listOfAllowedLocations" = @{ "value" = @("westeurope", "northeurope") } }
                $assign = Get-AzPolicyAssignment -Scope $rg.ResourceId | Where-Object { $_.Name -eq "ssw-allowed-regions" }
                if (-not $assign) {
                    New-AzPolicyAssignment -Name "ssw-allowed-regions" -Scope $rg.ResourceId -PolicyDefinition $def -PolicyParameterObject $params -ErrorAction Stop | Out-Null
                    Write-Log "  Policy toegewezen: West Europe + North Europe toegestaan"
                } else { Write-Log "  Policy al toegewezen op $rgName" }
            } else { Write-Log "  'Allowed locations' policy definitie niet gevonden" }
        } catch { Write-Log "  Fout: $_" }
    }

    $progress.Value = 100; Write-Log ""; Write-Log "Week 1 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen Entra ID Role en Azure RBAC Role?"
    Write-Log "2. Welke RBAC-scope-hiërarchie bestaat er in Azure?"
    Write-Log "3. Wat doet een Azure Policy vs. een RBAC Deny assignment?"
    Write-Log "4. Wanneer gebruik je Management Groups in plaats van Subscriptions?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $next = Join-Path $PSScriptRoot "lab-week2-storage.ps1"
    if (Test-Path $next) { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$next`"" }
    else { [System.Windows.MessageBox]::Show("lab-week2-storage.ps1 niet gevonden.", "SSW-Lab") }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null


