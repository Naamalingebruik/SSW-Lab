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
$statusBadge = if ($progress.IsComplete) { 'Completed' } else { 'In progress' }

$statusLines = [System.Collections.Generic.List[string]]::new()
$statusLines.Add("# $trackName")
$statusLines.Add('')
$statusLines.Add("- Status: **$statusBadge**")
$statusLines.Add("- Progress: **$percent%** ($($progress.CompletedCount)/$($progress.TotalCount) checkpoints)")
$statusLines.Add("- Recommended preset: **$($progress.RecommendedPreset)**")
$statusLines.Add("- Last updated: **$timestamp**")
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
        $statusLines.Add("  Note: $($milestone.Note)")
    }
}

$nextLines = [System.Collections.Generic.List[string]]::new()
$nextLines.Add("# Next step - $trackName")
$nextLines.Add('')

if ($progress.IsComplete) {
    $nextLines.Add('This track is fully complete. Choose a new track with `scripts/utility/Set-CurrentTrack.ps1` if you want to continue.')
} else {
    $nextLines.Add("Work now on **$($progress.NextMilestone.Title)**.")
    $nextLines.Add('')
    $nextLines.Add('- Script: `' + $progress.NextMilestone.ScriptPath + '`')
    $nextLines.Add("- Why now: $($progress.NextMilestone.Summary)")
    $nextLines.Add('- Mark after completion: `.\scripts\utility\Set-TrackCheckpoint.ps1 -CheckpointId ' + $progress.NextMilestone.Id + '`')
}

$statusLines -join [Environment]::NewLine | Set-Content -Path $OutputPath -Encoding utf8
$nextLines -join [Environment]::NewLine | Set-Content -Path $NextStepsPath -Encoding utf8

Write-Host "Track status updated: $OutputPath" -ForegroundColor Green
Write-Host "Next step updated: $NextStepsPath" -ForegroundColor Green

if ($PassThru) {
    $progress
}

