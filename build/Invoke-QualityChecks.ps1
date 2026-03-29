[CmdletBinding()]
param()

$repoRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path $repoRoot 'modules\SSWLab\SSWLab.psd1'
$testsPath = Join-Path $repoRoot 'tests'

Import-Module $modulePath -Force

$pesterModule = Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1
if (-not $pesterModule) {
    throw 'Pester is niet beschikbaar. Installeer Pester om tests uit te voeren.'
}

Import-Module $pesterModule.Path -Force

Write-Output "Pester versie: $($pesterModule.Version)"
$pesterConfiguration = [PesterConfiguration]::Default
$pesterConfiguration.Run.Path = $testsPath
$pesterConfiguration.Run.Exit = $true
Invoke-Pester -Configuration $pesterConfiguration

$scriptAnalyzerModule = Get-Module -ListAvailable PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if ($scriptAnalyzerModule) {
    Import-Module $scriptAnalyzerModule.Path -Force
    Write-Output "PSScriptAnalyzer versie: $($scriptAnalyzerModule.Version)"
    $analysisPaths = @(
        (Join-Path $repoRoot 'modules'),
        (Join-Path $repoRoot 'build'),
        (Join-Path $repoRoot 'tests'),
        (Join-Path $repoRoot 'scripts\Build-UnattendedIsos.ps1'),
        (Join-Path $repoRoot 'scripts\Configure-HostNetwork.ps1'),
        (Join-Path $repoRoot 'scripts\Initialize-DomainController.ps1'),
        (Join-Path $repoRoot 'scripts\Initialize-ManagementHost.ps1'),
        (Join-Path $repoRoot 'scripts\Initialize-Preflight.ps1'),
        (Join-Path $repoRoot 'scripts\Join-LabComputersToDomain.ps1'),
        (Join-Path $repoRoot 'scripts\New-LabExtraVm.ps1'),
        (Join-Path $repoRoot 'scripts\New-LabExtraVmGui.ps1'),
        (Join-Path $repoRoot 'scripts\New-LabVMs.ps1')
    )

    $errorFindings = @()
    foreach ($analysisPath in $analysisPaths) {
        $findings = Invoke-ScriptAnalyzer -Path $analysisPath -Recurse
        if ($findings) {
            $findings | Write-Output
            $errorFindings += @($findings | Where-Object Severity -eq 'Error')
        }
    }

    if ($errorFindings.Count -gt 0) {
        throw "PSScriptAnalyzer rapporteerde $($errorFindings.Count) error(s)."
    }
} else {
    Write-Warning 'PSScriptAnalyzer niet gevonden. Linting is overgeslagen.'
}
