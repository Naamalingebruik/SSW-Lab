[CmdletBinding()]
param(
    [string]$TrackId,
    [string]$OutputPath = "$PSScriptRoot\..\..\status.md",
    [string]$NextStepsPath = "$PSScriptRoot\..\..\next-steps.md",
    [switch]$PassThru
)

$modulePath = Join-Path $PSScriptRoot '..\..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force

$progress = Get-SSWTrackProgress -TrackId $TrackId

$trackName = $progress.TrackName
$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm'
$percent = [int]$progress.PercentComplete
$statusBadge = if ($progress.IsComplete) { 'Afgerond' } else { 'In uitvoering' }

$statusLines = [System.Collections.Generic.List[string]]::new()
$statusLines.Add("# $trackName")
$statusLines.Add('')
$statusLines.Add("- Status: **$statusBadge**")
$statusLines.Add("- Voortgang: **$percent%** ($($progress.CompletedCount)/$($progress.TotalCount) checkpoints)")
$statusLines.Add("- Aanbevolen preset: **$($progress.RecommendedPreset)**")
$statusLines.Add("- Laatst bijgewerkt: **$timestamp**")
$statusLines.Add('')
$statusLines.Add('## Checkpoints')
$statusLines.Add('')

foreach ($milestone in $progress.Milestones) {
    $prefix = if ($milestone.IsCompleted) { '- [x]' } else { '- [ ]' }
    $line = "$prefix **$($milestone.Title)**"
    if ($milestone.ScriptPath) {
        $line += ' (`' + $milestone.ScriptPath + '`)'
    }
    $statusLines.Add($line)

    if ($milestone.Summary) {
        $statusLines.Add("  $($milestone.Summary)")
    }

    if ($milestone.Note) {
        $statusLines.Add("  Notitie: $($milestone.Note)")
    }
}

$nextLines = [System.Collections.Generic.List[string]]::new()
$nextLines.Add("# Volgende stap - $trackName")
$nextLines.Add('')

if ($progress.IsComplete) {
    $nextLines.Add('Dit traject is volledig afgerond. Kies een nieuw traject met `scripts/utility/Set-CurrentTrack.ps1` als je wilt doorpakken.')
} else {
    $nextLines.Add("Werk nu aan **$($progress.NextMilestone.Title)**.")
    $nextLines.Add('')
    $nextLines.Add('- Script: `' + $progress.NextMilestone.ScriptPath + '`')
    $nextLines.Add("- Waarom nu: $($progress.NextMilestone.Summary)")
    $nextLines.Add('- Daarna markeren: `.\scripts\utility\Set-TrackCheckpoint.ps1 -CheckpointId ' + $progress.NextMilestone.Id + '`')
}

$statusLines -join [Environment]::NewLine | Set-Content -Path $OutputPath -Encoding utf8
$nextLines -join [Environment]::NewLine | Set-Content -Path $NextStepsPath -Encoding utf8

Write-Host "Track-status bijgewerkt: $OutputPath" -ForegroundColor Green
Write-Host "Volgende stap bijgewerkt: $NextStepsPath" -ForegroundColor Green

if ($PassThru) {
    $progress
}
