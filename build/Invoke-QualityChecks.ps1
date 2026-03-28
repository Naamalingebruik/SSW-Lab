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

Write-Host "Pester versie: $($pesterModule.Version)"
$pesterConfiguration = [PesterConfiguration]::Default
$pesterConfiguration.Run.Path = $testsPath
$pesterConfiguration.Run.Exit = $true
Invoke-Pester -Configuration $pesterConfiguration

$scriptAnalyzerModule = Get-Module -ListAvailable PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if ($scriptAnalyzerModule) {
    Import-Module $scriptAnalyzerModule.Path -Force
    Write-Host "PSScriptAnalyzer versie: $($scriptAnalyzerModule.Version)"
    $analysisPaths = @(
        (Join-Path $repoRoot 'scripts'),
        (Join-Path $repoRoot 'modules'),
        (Join-Path $repoRoot 'build')
    )

    foreach ($analysisPath in $analysisPaths) {
        Invoke-ScriptAnalyzer -Path $analysisPath -Recurse
    }
} else {
    Write-Warning 'PSScriptAnalyzer niet gevonden. Linting is overgeslagen.'
}
