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
if ($pesterModule.Version.Major -ge 5) {
    $pesterConfiguration = [PesterConfiguration]::Default
    $pesterConfiguration.Run.Path = $testsPath
    $pesterConfiguration.Run.Exit = $true
    Invoke-Pester -Configuration $pesterConfiguration
} else {
    $result = Invoke-Pester -Script $testsPath -PassThru
    if ($result.FailedCount -gt 0) {
        exit 1
    }
}

$scriptAnalyzerModule = Get-Module -ListAvailable PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if ($scriptAnalyzerModule) {
    Import-Module $scriptAnalyzerModule.Path -Force
    Write-Output "PSScriptAnalyzer versie: $($scriptAnalyzerModule.Version)"
    $analysisPaths = @(
        (Join-Path $repoRoot 'modules'),
        (Join-Path $repoRoot 'build'),
        (Join-Path $repoRoot 'tests'),
        (Join-Path $repoRoot 'scripts'),
        (Join-Path $repoRoot 'scripts-en')
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

Write-Output 'JSON validatie...'
$jsonFiles = @(
    (Join-Path $repoRoot 'profiles\vm-profiles.json'),
    (Join-Path $repoRoot 'profiles\learning-tracks.json')
)

foreach ($jsonFile in $jsonFiles) {
    if (-not (Test-Path -LiteralPath $jsonFile)) {
        throw "JSON bestand niet gevonden: $jsonFile"
    }

    try {
        $null = Get-Content -LiteralPath $jsonFile -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Output "OK: $(Split-Path $jsonFile -Leaf)"
    } catch {
        throw "Ongeldige JSON in $(Split-Path $jsonFile -Leaf): $($_.Exception.Message)"
    }
}
