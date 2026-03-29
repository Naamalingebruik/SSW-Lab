function Resolve-SSWTrackId {
    [CmdletBinding()]
    param(
        [string]$TrackId
    )

    if ([string]::IsNullOrWhiteSpace($TrackId)) {
        return $null
    }

    $normalized = ($TrackId -replace '[^A-Za-z0-9]', '').ToUpperInvariant()
    switch ($normalized) {
        'MD102' { return 'MD102' }
        'MS102' { return 'MS102' }
        'SC300' { return 'SC300' }
        'AZ104' { return 'AZ104' }
        default { return $normalized }
    }
}
