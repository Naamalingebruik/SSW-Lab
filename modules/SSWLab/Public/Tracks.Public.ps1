function Import-SSWTrackDefinitions {
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path $PSScriptRoot '..\..\..\profiles\learning-tracks.json')
    )

    if (-not (Test-Path $Path)) {
        throw "Trackdefinities niet gevonden: $Path"
    }

    $raw = Get-Content -Path $Path -Raw | ConvertFrom-Json
    if (-not $raw.tracks) {
        throw "Trackdefinities in $Path bevatten geen tracks."
    }

    return @($raw.tracks)
}

function Get-SSWTrackDefinition {
    [CmdletBinding()]
    param(
        [string]$TrackId,
        [object[]]$Definitions,
        [string]$CurrentTrackPath = (Join-Path $PSScriptRoot '..\..\..\profiles\current-track.local.json')
    )

    if (-not $Definitions) {
        $Definitions = Import-SSWTrackDefinitions
    }

    if ([string]::IsNullOrWhiteSpace($TrackId)) {
        if (Test-Path $CurrentTrackPath) {
            $currentState = Get-Content -Path $CurrentTrackPath -Raw | ConvertFrom-Json
            $TrackId = $currentState.trackId
        }
    }

    if ([string]::IsNullOrWhiteSpace($TrackId)) {
        return $null
    }

    $resolvedTrackId = Resolve-SSWTrackId -TrackId $TrackId
    return @($Definitions | Where-Object { $_.id -eq $resolvedTrackId }) | Select-Object -First 1
}

function Set-SSWCurrentTrack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TrackId,

        [string]$StatePath = (Join-Path $PSScriptRoot '..\..\..\profiles\current-track.local.json'),
        [object[]]$Definitions
    )

    if (-not $Definitions) {
        $Definitions = Import-SSWTrackDefinitions
    }

    $resolvedTrackId = Resolve-SSWTrackId -TrackId $TrackId
    $definition = Get-SSWTrackDefinition -TrackId $resolvedTrackId -Definitions $Definitions
    if (-not $definition) {
        throw "Onbekend track-id '$TrackId'."
    }

    $payload = [ordered]@{
        trackId = $definition.id
    }

    $payload | ConvertTo-Json | Set-Content -Path $StatePath -Encoding utf8

    return [pscustomobject]@{
        TrackId   = $definition.id
        TrackName = $definition.name
        StatePath = $StatePath
    }
}

function Get-SSWTrackProgress {
    [CmdletBinding()]
    param(
        [string]$TrackId,
        [object[]]$Definitions,
        [string]$CurrentTrackPath = (Join-Path $PSScriptRoot '..\..\..\profiles\current-track.local.json'),
        [string]$CheckpointStatePath = (Join-Path $PSScriptRoot '..\..\..\profiles\track-checkpoints.local.json')
    )

    if (-not $Definitions) {
        $Definitions = Import-SSWTrackDefinitions
    }

    $track = Get-SSWTrackDefinition -TrackId $TrackId -Definitions $Definitions -CurrentTrackPath $CurrentTrackPath
    if (-not $track) {
        throw 'Geen actief traject gevonden. Gebruik Set-CurrentTrack.ps1 of geef -TrackId op.'
    }

    $completedMap = @{}
    $noteMap = @{}

    if (Test-Path $CheckpointStatePath) {
        $checkpointState = Get-Content -Path $CheckpointStatePath -Raw | ConvertFrom-Json

        if ($checkpointState.completed) {
            foreach ($property in $checkpointState.completed.PSObject.Properties) {
                $completedMap[$property.Name] = @($property.Value)
            }
        }

        if ($checkpointState.notes) {
            foreach ($property in $checkpointState.notes.PSObject.Properties) {
                $trackNotes = @{}
                foreach ($noteProperty in $property.Value.PSObject.Properties) {
                    $trackNotes[$noteProperty.Name] = [string]$noteProperty.Value
                }
                $noteMap[$property.Name] = $trackNotes
            }
        }
    }

    $completedIds = @()
    if ($completedMap.ContainsKey($track.id)) {
        $completedIds = @($completedMap[$track.id])
    }

    $trackNotes = @{}
    if ($noteMap.ContainsKey($track.id)) {
        $trackNotes = $noteMap[$track.id]
    }

    $milestones = foreach ($milestone in $track.milestones) {
        [pscustomobject]@{
            Id          = $milestone.id
            Title       = $milestone.title
            Summary     = $milestone.summary
            ScriptPath  = $milestone.scriptPath
            IsCompleted = ($completedIds -contains $milestone.id)
            Note        = if ($trackNotes.ContainsKey($milestone.id)) { $trackNotes[$milestone.id] } else { $null }
        }
    }

    $completedCount = @($milestones | Where-Object IsCompleted).Count
    $totalCount = @($milestones).Count
    $nextMilestone = @($milestones | Where-Object { -not $_.IsCompleted }) | Select-Object -First 1

    [pscustomobject]@{
        TrackId           = $track.id
        TrackName         = $track.name
        Focus             = $track.focus
        RecommendedPreset = $track.recommendedPreset
        CompletedCount    = $completedCount
        TotalCount        = $totalCount
        PercentComplete   = if ($totalCount -gt 0) { [math]::Round(($completedCount / $totalCount) * 100, 0) } else { 0 }
        IsComplete        = ($totalCount -gt 0 -and $completedCount -eq $totalCount)
        NextMilestone     = $nextMilestone
        Milestones        = @($milestones)
    }
}
