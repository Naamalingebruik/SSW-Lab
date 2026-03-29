[CmdletBinding()]
param(
    [string]$TrackId,

    [Parameter(Mandatory)]
    [string]$CheckpointId,

    [string]$Note,

    [switch]$Reset
)

$modulePath = Join-Path $PSScriptRoot '..\..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force

$definition = Get-SSWTrackDefinition -TrackId $TrackId
if (-not $definition) {
    throw 'Geen geldig traject gevonden. Stel eerst een traject in met Set-CurrentTrack.ps1 of geef -TrackId op.'
}

$checkpoint = @($definition.milestones | Where-Object { $_.id -eq $CheckpointId }) | Select-Object -First 1
if (-not $checkpoint) {
    throw "Checkpoint '$CheckpointId' bestaat niet binnen traject '$($definition.id)'."
}

$statePath = Join-Path $PSScriptRoot '..\..\profiles\track-checkpoints.local.json'
$state = @{
    completed = @{}
    notes     = @{}
}

if (Test-Path $statePath) {
    $rawState = Get-Content -Path $statePath -Raw | ConvertFrom-Json

    if ($rawState.completed) {
        foreach ($property in $rawState.completed.PSObject.Properties) {
            $state.completed[$property.Name] = @($property.Value)
        }
    }

    if ($rawState.notes) {
        foreach ($property in $rawState.notes.PSObject.Properties) {
            $noteMap = @{}
            foreach ($noteProperty in $property.Value.PSObject.Properties) {
                $noteMap[$noteProperty.Name] = [string]$noteProperty.Value
            }
            $state.notes[$property.Name] = $noteMap
        }
    }
}

if (-not $state.completed.ContainsKey($definition.id)) {
    $state.completed[$definition.id] = @()
}

if (-not $state.notes.ContainsKey($definition.id)) {
    $state.notes[$definition.id] = @{}
}

$updatedCompleted = [System.Collections.Generic.List[string]]::new()
foreach ($item in $state.completed[$definition.id]) {
    if (-not [string]::IsNullOrWhiteSpace($item) -and -not $updatedCompleted.Contains($item)) {
        $updatedCompleted.Add($item)
    }
}

if ($Reset) {
    $updatedCompleted.Remove($CheckpointId) | Out-Null
    $state.notes[$definition.id].Remove($CheckpointId) | Out-Null
} else {
    if (-not $updatedCompleted.Contains($CheckpointId)) {
        $updatedCompleted.Add($CheckpointId)
    }

    if ($PSBoundParameters.ContainsKey('Note')) {
        if ([string]::IsNullOrWhiteSpace($Note)) {
            $state.notes[$definition.id].Remove($CheckpointId) | Out-Null
        } else {
            $state.notes[$definition.id][$CheckpointId] = $Note
        }
    }
}

$state.completed[$definition.id] = @($updatedCompleted.ToArray())

$payload = [ordered]@{
    completed = [ordered]@{}
    notes     = [ordered]@{}
}

foreach ($trackKey in ($state.completed.Keys | Sort-Object)) {
    $payload.completed[$trackKey] = @($state.completed[$trackKey])
}

foreach ($trackKey in ($state.notes.Keys | Sort-Object)) {
    $payload.notes[$trackKey] = [ordered]@{}
    foreach ($checkpointKey in ($state.notes[$trackKey].Keys | Sort-Object)) {
        $payload.notes[$trackKey][$checkpointKey] = $state.notes[$trackKey][$checkpointKey]
    }
}

$payload | ConvertTo-Json -Depth 6 | Set-Content -Path $statePath -Encoding utf8

if ($Reset) {
    Write-Host "Checkpoint '$CheckpointId' teruggezet voor traject $($definition.id)." -ForegroundColor Yellow
} else {
    Write-Host "Checkpoint '$CheckpointId' gemarkeerd als afgerond voor traject $($definition.id)." -ForegroundColor Green
}

Write-Host "Statebestand: $statePath"

