#Requires -RunAsAdministrator
# ============================================================
# SSW-Lab | labs/SC300/lab-week6-governance-pim.ps1
# SC-300 Week 6 — Identity Governance: Entitlement Management, Access Reviews, PIM
# Cloud: Entra ID Identity Governance (Entra P2 / Microsoft 365 E5 vereist)
# ============================================================

. "$PSScriptRoot\..\..\..\config.ps1"

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="SC-300 | Week 6 — Identity Governance en PIM" Height="720" Width="700"
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
      <TextBlock Text="SC-300 | Week 6 — Identity Governance en PIM" Foreground="#CDD6F4" FontSize="18" FontWeight="SemiBold"/>
      <TextBlock Text="Access packages · Access reviews · PIM JIT · Lifecycle workflows" Foreground="#A6ADC8" FontSize="12" Margin="0,2,0,0"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Margin="0,0,0,8">
      <TextBlock Style="{StaticResource Lbl}" Text="Stappen in dit lab:"/>
      <TextBlock Foreground="#CDD6F4" FontSize="12" TextWrapping="Wrap" Margin="0,4,0,0">
        <Run Text="1. Access package aanmaken via MS Graph (Entitlement Management)"/>
        <LineBreak/><Run Text="2. Access review aanmaken voor groepsleden"/>
        <LineBreak/><Run Text="3. PIM — eligible assignment voor Global Administrator"/>
        <LineBreak/><Run Text="4. PIM — JIT-activering simuleren en audit trail"/>
        <LineBreak/><Run Text="5. Kennischeck en eindpunt SC-300 leerpad"/>
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
      <Button x:Name="BtnNext" Content="SC-300 voltooid! ✓" Style="{StaticResource Btn}"
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
        $dryRunTitle.Text = "Dry Run — geen objects worden aangemaakt in Entra ID"; $dryRunTitle.Foreground = $conv.ConvertFrom("#A6E3A1")
        $dryRunSub.Text = "Haal het vinkje weg voor LIVE-uitvoering (Entra P2 vereist)"; $dryRunSub.Foreground = $conv.ConvertFrom("#5A8A6A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#A6E3A1")
    } else {
        $dryRunBar.Background = $conv.ConvertFrom("#2E1A1A"); $dryRunBar.BorderBrush = $conv.ConvertFrom("#F38BA8")
        $dryRunTitle.Text = "LIVE — Identity Governance objects worden aangemaakt in Entra ID"; $dryRunTitle.Foreground = $conv.ConvertFrom("#F38BA8")
        $dryRunSub.Text = "Vereiste: Entra ID P2 / Microsoft 365 E5 licentie actief"; $dryRunSub.Foreground = $conv.ConvertFrom("#8A5A5A")
        $chkDryRun.Foreground = $conv.ConvertFrom("#F38BA8")
    }
}
$reader.Add_Loaded({ Update-DryRunBar })
$chkDryRun.Add_Checked({ Update-DryRunBar }); $chkDryRun.Add_Unchecked({ Update-DryRunBar })
function Write-Log($msg) { $ts = Get-Date -Format "HH:mm:ss"; $logBox.Text += "[$ts] $msg`n"; $logBox.ScrollToEnd() }

$btnRun.Add_Click({
    $btnRun.IsEnabled = $false
    $isDry = $chkDryRun.IsChecked; $pre = if ($isDry) { "[DRY RUN] " } else { "" }

    # ── Stap 1: Access package aanmaken (Entitlement Management) ─────────────
    Write-Log "${pre}Stap 1: Access package aanmaken via MS Graph"
    $progress.Value = 12
    Write-Log "  Entra portal > Identity Governance > Entitlement management > Catalogs"
    Write-Log "  Maak catalog aan: 'SSW Lab Resources'"
    Write-Log "  Voeg resource toe: Security Group 'SSW-LabUsers'"
    Write-Log ""
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'EntitlementManagement.ReadWrite.All'"
        Write-Log "${pre}  # Catalog aanmaken"
        Write-Log "${pre}  `$catalog = New-MgEntitlementManagementAccessPackageCatalog -DisplayName 'SSW Lab Resources' -IsExternallyVisible:`$false"
        Write-Log "${pre}  # Access package aanmaken"
        Write-Log "${pre}  `$pkg = New-MgEntitlementManagementAccessPackage -DisplayName 'SSW Lab Toegang' -Description 'Toegang voor SSW lab-oefeningen' -CatalogId `$catalog.Id"
        Write-Log "${pre}  # Beleid toevoegen: interne gebruikers kunnen aanvragen, manager keurt goed"
        Write-Log "${pre}  `$policy = @{"
        Write-Log "${pre}    DisplayName = 'SSW Lab Request Policy'"
        Write-Log "${pre}    RequestorSettings = @{ ScopeType = 'AllExistingDirectoryMemberUsers'; AcceptRequests = `$true }"
        Write-Log "${pre}    RequestApprovalSettings = @{ IsApprovalRequired = `$true; ApprovalMode = 'SingleStage' }"
        Write-Log "${pre}    AccessReviewSettings = @{ IsEnabled = `$true; RecurrenceType = 'quarterly' }"
        Write-Log "${pre}  }"
        Write-Log "${pre}  New-MgEntitlementManagementAccessPackageAssignmentPolicy -AccessPackageId `$pkg.Id -BodyParameter `$policy"
    } else {
        try {
            Connect-MgGraph -Scopes "EntitlementManagement.ReadWrite.All" -ErrorAction Stop | Out-Null

            # Catalog
            $existCatalog = Get-MgEntitlementManagementAccessPackageCatalog -Filter "displayName eq 'SSW Lab Resources'" -ErrorAction SilentlyContinue
            if (-not $existCatalog) {
                $catalog = New-MgEntitlementManagementAccessPackageCatalog -DisplayName "SSW Lab Resources" -IsExternallyVisible:$false
                Write-Log "  Catalog aangemaakt: SSW Lab Resources (ID: $($catalog.Id))"
            } else {
                $catalog = $existCatalog
                Write-Log "  Catalog bestaat al: $($catalog.DisplayName)"
            }

            # Access package
            $existPkg = Get-MgEntitlementManagementAccessPackage -Filter "displayName eq 'SSW Lab Toegang'" -ErrorAction SilentlyContinue
            if (-not $existPkg) {
                $pkg = New-MgEntitlementManagementAccessPackage -DisplayName "SSW Lab Toegang" `
                    -Description "Toegang voor SSW lab-oefeningen" -CatalogId $catalog.Id
                Write-Log "  Access package aangemaakt: SSW Lab Toegang (ID: $($pkg.Id))"
                $script:accessPackageId = $pkg.Id
            } else {
                Write-Log "  Access package bestaat al: $($existPkg.DisplayName)"
                $script:accessPackageId = $existPkg.Id
            }
            Write-Log "  My Access portal: https://myaccess.microsoft.com"
            Write-Log "  TestUser01 kan package aanvragen via bovenstaande URL"
        } catch { Write-Log "  Fout: $_"; $btnRun.IsEnabled = $true; return }
    }

    # ── Stap 2: Access review aanmaken ──────────────────────────────────────
    Write-Log ""
    Write-Log "${pre}Stap 2: Access review aanmaken voor groepsleden"
    $progress.Value = 28
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'AccessReview.ReadWrite.All', 'Group.Read.All'"
        Write-Log "${pre}  # Haal de groep 'SSW-LabUsers' op"
        Write-Log "${pre}  `$grp = Get-MgGroup -Filter `"displayName eq 'SSW-LabUsers'`""
        Write-Log "${pre}  `$reviewBody = @{"
        Write-Log "${pre}    DisplayName = 'SSW Lab Quarterly Review'"
        Write-Log "${pre}    StartDateTime = (Get-Date).ToUniversalTime().ToString('o')"
        Write-Log "${pre}    EndDateTime = (Get-Date).AddDays(14).ToUniversalTime().ToString('o')"
        Write-Log "${pre}    Reviewers = @(@{ Query = '/v1.0/users/<admin-user-id>'; QueryType = 'MicrosoftGraph' })"
        Write-Log "${pre}    Scope = @{ Query = '/groups/<group-id>/members'; QueryType = 'MicrosoftGraph' }"
        Write-Log "${pre}    Settings = @{ MailNotificationsEnabled = `$true; DefaultDecision = 'Deny'; AutoApplyDecisionsEnabled = `$true }"
        Write-Log "${pre}  }"
        Write-Log "${pre}  New-MgIdentityGovernanceAccessReviewDefinition -BodyParameter `$reviewBody"
    } else {
        try {
            Write-Log "  Entra portal > Identity Governance > Access reviews > + New access review"
            Write-Log "  Selecteer: Review type = Groups and teams"
            Write-Log "  Scope: Alle leden van SSW-LabUsers"
            Write-Log "  Reviewers: Geselecteerde gebruikers (Admin of manager)"
            Write-Log "  Herhaling: Kwartaal | Duur: 14 dagen"
            Write-Log "  Einde: Beschikking automatisch toepassen"
            Write-Log "  Default beslissing als reviewer niet reageert: Deny (toegang intrekken)"
            Start-Process "https://entra.microsoft.com/#view/Microsoft_AAD_ERM/DashboardBlade/~/Controls"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 3: PIM — eligible assignment aanmaken ──────────────────────────
    Write-Log ""
    Write-Log "${pre}Stap 3: PIM — eligible assignment voor Global Administrator"
    $progress.Value = 48
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'PrivilegedEligibilitySchedule.ReadWrite.AzureADGroup', 'RoleEligibilitySchedule.ReadWrite.Directory'"
        Write-Log "${pre}  # Global Admin rol-definitie ophalen"
        Write-Log "${pre}  `$role = Get-MgRoleManagementDirectoryRoleDefinition -Filter `"displayName eq 'Global Administrator'`""
        Write-Log "${pre}  # Eligible assignment aanmaken voor TestUser01"
        Write-Log "${pre}  `$user = Get-MgUser -Filter `"displayName eq 'TestUser01'`""
        Write-Log "${pre}  `$scheduleReq = @{"
        Write-Log "${pre}    PrincipalId = `$user.Id"
        Write-Log "${pre}    RoleDefinitionId = `$role.Id"
        Write-Log "${pre}    Justification = 'SC-300 lab — PIM eligible assignment'"
        Write-Log "${pre}    ScheduleInfo = @{ StartDateTime = (Get-Date).ToUniversalTime().ToString('o'); Expiration = @{ Type = 'AfterDuration'; Duration = 'PT8H' } }"
        Write-Log "${pre}    Action = 'adminAssign'"
        Write-Log "${pre}  }"
        Write-Log "${pre}  New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter `$scheduleReq"
    } else {
        try {
            Write-Log "  Entra portal > Identity > Roles and admins > Privileged Identity Management"
            Write-Log "  OF: https://entra.microsoft.com/#view/Microsoft_Azure_PIMPrivilegedPIM/CommonMenuBlade/~/quickStart"
            Write-Log "  Selecteer: Manage > Entra roles"
            Write-Log "  Klik op 'Global Administrator' > + Add assignments"
            Write-Log "  Toewijzingstype: Eligible"
            Write-Log "  Gebruiker: TestUser01"
            Write-Log "  Geldigheid: 8 uur (voor labdoeleinden)"
            Write-Log "  Let op: Permanente eligible assignment is ook mogelijk voor labs"
            Start-Process "https://entra.microsoft.com/#view/Microsoft_Azure_PIMPrivilegedPIM/CommonMenuBlade/~/quickStart"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 4: PIM JIT-activering en audit trail ────────────────────────────
    Write-Log ""
    Write-Log "${pre}Stap 4: PIM — JIT-activering als TestUser01 en audit trail"
    $progress.Value = 68
    Write-Log "  Via W11-01 als TestUser01 (of InPrivate/aparte browser-sessie):"
    Write-Log "  1. Ga naar: https://entra.microsoft.com/#view/Microsoft_Azure_PIMPrivilegedPIM/UserActivateRolesBlade"
    Write-Log "  2. Klik 'Activate' naast Global Administrator"
    Write-Log "  3. Vul in: Tijdsduur (max. 1 uur voor lab), reden: 'SC-300 lab PIM test'"
    Write-Log "  4. Bevestig MFA-prompt (Authenticator push of FIDO2)"
    Write-Log "  5. Wacht ~30 sec → rol is actief"
    Write-Log ""
    Write-Log "  Audit trail bekijken (als Admin):"
    if ($isDry) {
        Write-Log "${pre}  Connect-MgGraph -Scopes 'AuditLog.Read.All'"
        Write-Log "${pre}  Get-MgAuditLogDirectoryAudit -Filter `"activityDisplayName eq 'Add member to role completed (PIM activation)'`" | Select-Object ActivityDateTime, InitiatedBy, Result"
        Write-Log "${pre}  # PIM-specifiek:"
        Write-Log "${pre}  Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId <policyId>"
    } else {
        try {
            Connect-MgGraph -Scopes "AuditLog.Read.All" -ErrorAction Stop | Out-Null
            $pimLogs = Get-MgAuditLogDirectoryAudit `
                -Filter "activityDisplayName eq 'Add member to role completed (PIM activation)'" `
                -Top 5 -ErrorAction SilentlyContinue
            if ($pimLogs) {
                Write-Log "  Recente PIM-activaties:"
                foreach ($log in $pimLogs) {
                    $who = $log.InitiatedBy.User.UserPrincipalName
                    Write-Log "    $($log.ActivityDateTime) | $who | $($log.Result)"
                }
            } else {
                Write-Log "  Geen recente PIM-activaties gevonden (voer stap 4 handmatig uit via portal)"
            }
            Write-Log ""
            Write-Log "  PIM audit in portal: Entra > Identity > PIM > Entra roles > Audit history"
            Start-Process "https://entra.microsoft.com/#view/Microsoft_Azure_PIMPrivilegedPIM/ResourceMenuBlade/~/audit"
        } catch { Write-Log "  Fout: $_" }
    }

    # ── Stap 5: Eligible vs Active vs Permanent vergelijking tonen ──────────
    Write-Log ""
    Write-Log "${pre}Stap 5: PIM — overzicht assignmenttypes"
    $progress.Value = 84
    if ($isDry) {
        Write-Log "${pre}  # Bekijk huidige eligible assignments:"
        Write-Log "${pre}  Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All | Select-Object PrincipalId, RoleDefinitionId, ScheduleInfo"
        Write-Log "${pre}  # Bekijk actieve assignments:"
        Write-Log "${pre}  Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All | Select-Object PrincipalId, RoleDefinitionId, AssignmentType"
    } else {
        try {
            Connect-MgGraph -Scopes "RoleEligibilitySchedule.Read.Directory", "RoleAssignmentSchedule.Read.Directory" -ErrorAction SilentlyContinue | Out-Null
            $eligible = Get-MgRoleManagementDirectoryRoleEligibilitySchedule -All -ErrorAction SilentlyContinue
            Write-Log "  Eligible assignments in tenant: $($eligible.Count)"
            $active   = Get-MgRoleManagementDirectoryRoleAssignmentSchedule -All -ErrorAction SilentlyContinue
            Write-Log "  Actieve role assignments: $($active.Count)"
            Write-Log ""
            Write-Log "  Eligible  = JIT — gebruiker moet zelf activeren, MFA + reden vereist"
            Write-Log "  Active    = Altijd actief gedurende ingestelde periode"
            Write-Log "  Permanent = Geen vervaldatum (vermijd dit voor beheerdersrollen)"
        } catch { Write-Log "  Fout: $_" }
    }

    $progress.Value = 100; Write-Log ""; Write-Log "Week 6 lab afgerond."; Write-Log ""
    Write-Log "━━━ KENNISCHECK ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log "1. Wat is het verschil tussen entitlement management en access reviews?"
    Write-Log "2. Hoe werkt PIM Just-in-Time access en waarom is het veiliger dan permanente rollentoewijzing?"
    Write-Log "3. Wat zijn lifecycle workflows en voor welke scenario's gebruik je ze?"
    Write-Log "4. Hoe configureer je separation of duties via incompatible access packages?"
    Write-Log "5. Wanneer kies je voor eligible vs. active assignment in PIM?"
    Write-Log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Log ""
    Write-Log "════════════════════════════════════════════════════════"
    Write-Log "  SC-300 LEERPAD VOLTOOID — alle 6 weken afgerond"
    Write-Log "  Volgend stap: Practice assessment op MS Learn"
    Write-Log "  https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications"
    Write-Log "════════════════════════════════════════════════════════"
    $btnNext.IsEnabled = $true; $btnRun.IsEnabled = $true
})

$btnNext.Add_Click({
    $open = [System.Windows.MessageBox]::Show(
        "SC-300 leerpad voltooid!`n`nPractice assessment openen op MS Learn?",
        "SSW-Lab — SC-300 afgerond",
        "YesNo",
        "Information"
    )
    if ($open -eq "Yes") {
        Start-Process "https://learn.microsoft.com/en-us/certifications/practice-assessments-for-microsoft-certifications"
    }
    $reader.Close()
})
$reader.ShowDialog() | Out-Null



