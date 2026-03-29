[CmdletBinding()]
param(
    [string]$OutputPath
)

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$resolvedOutputPath = if ($OutputPath) {
    $OutputPath
} else {
    Join-Path $repoRoot 'docs\lab-dependency-graph.md'
}
$modulePath = Join-Path $repoRoot 'modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force

$tracks = Import-SSWTrackDefinitions
$generatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm zzz'

$setupSteps = @(
    [pscustomobject]@{ Id = 'preflight'; Title = 'Initialize-Preflight'; ScriptPath = 'scripts/Initialize-Preflight.ps1' }
    [pscustomobject]@{ Id = 'network'; Title = 'Configure-HostNetwork'; ScriptPath = 'scripts/Configure-HostNetwork.ps1' }
    [pscustomobject]@{ Id = 'iso'; Title = 'Build-UnattendedIsos'; ScriptPath = 'scripts/Build-UnattendedIsos.ps1' }
    [pscustomobject]@{ Id = 'vms'; Title = 'New-LabVMs'; ScriptPath = 'scripts/New-LabVMs.ps1' }
    [pscustomobject]@{ Id = 'dc'; Title = 'Initialize-DomainController'; ScriptPath = 'scripts/Initialize-DomainController.ps1' }
    [pscustomobject]@{ Id = 'join'; Title = 'Join-LabComputersToDomain'; ScriptPath = 'scripts/Join-LabComputersToDomain.ps1' }
)

$mermaidLines = [System.Collections.Generic.List[string]]::new()
$mermaidLines.Add('```mermaid')
$mermaidLines.Add('flowchart TD')
$mermaidLines.Add('  Start([Start]) --> preflight["Initialize-Preflight"]')
for ($index = 0; $index -lt $setupSteps.Count - 1; $index++) {
    $mermaidLines.Add(('  {0} --> {1}' -f $setupSteps[$index].Id, $setupSteps[$index + 1].Id))
}

foreach ($track in $tracks) {
    $branchId = ('track_{0}' -f $track.id)
    $mermaidLines.Add(('  join --> {0}["{1} ({2})"]' -f $branchId, $track.id, $track.recommendedPreset))

    $previousNode = $branchId
    foreach ($milestone in $track.milestones) {
        $nodeId = ('{0}_{1}' -f $track.id, $milestone.id)
        $label = '{0}: {1}' -f $milestone.id, $milestone.title
        $mermaidLines.Add(('  {0} --> {1}["{2}"]' -f $previousNode, $nodeId, $label))
        $previousNode = $nodeId
    }
}
$mermaidLines.Add('```')

$content = [System.Collections.Generic.List[string]]::new()
$content.Add('# Lab Dependency Graph')
$content.Add('')
$content.Add("> Gegenereerd op $generatedAt. Dit document beschrijft de aanbevolen uitvoervolgorde van de SSW-Lab setupflow en de 26 labscripts per certificeringstraject.")
$content.Add('')
$content.Add('## Overzicht')
$content.Add('')
$content.Add('De setupflow is voor alle trajecten gelijk tot en met `Join-LabComputersToDomain.ps1`. Daarna vertakt het lab in het gekozen traject uit `profiles/learning-tracks.json`.')
$content.Add('')
$content.AddRange($mermaidLines)
$content.Add('')
$content.Add('## Setupflow')
$content.Add('')
$content.Add('| Stap | Script | Doel |')
$content.Add('|------|--------|------|')
foreach ($step in $setupSteps) {
    $purpose = switch ($step.Id) {
        'preflight' { 'Controleert host, RAM, Hyper-V en trajectkeuze.' }
        'network' { 'Maakt vSwitch, NAT en hostgateway aan.' }
        'iso' { 'Bouwt unattended ISO`s uit MSDN-bron-ISO`s.' }
        'vms' { 'Maakt de basis-VMs aan volgens het gekozen preset.' }
        'dc' { 'Promoveert de domain controller en richt basisservices in.' }
        'join' { 'Joint de geselecteerde clients aan het labdomein.' }
    }
    $content.Add(('| {0} | `{1}` | {2} |' -f $step.Title, $step.ScriptPath, $purpose))
}

$content.Add('')
$content.Add('## Trajecten')
$content.Add('')
foreach ($track in $tracks) {
    $content.Add(('### {0}' -f $track.name))
    $content.Add('')
    $content.Add(('- Recommended preset: `{0}`' -f $track.recommendedPreset))
    $content.Add(('- Focus: {0}' -f $track.focus))
    $content.Add('')
    $content.Add('| Volgorde | Script | Samenvatting |')
    $content.Add('|----------|--------|--------------|')
    foreach ($milestone in $track.milestones) {
        $content.Add(('| {0} | `{1}` | {2} |' -f $milestone.title, $milestone.scriptPath, $milestone.summary))
    }
    $content.Add('')
}

$content.Add('## Gebruik')
$content.Add('')
$content.Add('Werk dit document bij nadat `profiles/learning-tracks.json` verandert:')
$content.Add('')
$content.Add('```powershell')
$content.Add('.\scripts\utility\Export-LabDependencyGraph.ps1')
$content.Add('```')

$content -join [Environment]::NewLine | Set-Content -Path $resolvedOutputPath -Encoding utf8
Write-Output "Dependency graph bijgewerkt: $resolvedOutputPath"

