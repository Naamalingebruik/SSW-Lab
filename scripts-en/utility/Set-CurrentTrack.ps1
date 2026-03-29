[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$TrackId
)

$modulePath = Join-Path $PSScriptRoot '..\..\modules\SSWLab\SSWLab.psd1'
Import-Module $modulePath -Force

$result = Set-SSWCurrentTrack -TrackId $TrackId

Write-Host "Actief traject ingesteld op $($result.TrackId) - $($result.TrackName)" -ForegroundColor Green
Write-Host "Statebestand: $($result.StatePath)"



