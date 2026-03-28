param(
    [Parameter(Mandatory)]
    [string]$Path
)

$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$tokens, [ref]$errors)

if (-not $errors -or $errors.Count -eq 0) {
    Write-Output "PARSE_OK $Path"
    exit 0
}

Write-Output "PARSE_ERROR $Path"
foreach ($parseError in $errors) {
    $line = $parseError.Extent.StartLineNumber
    $column = $parseError.Extent.StartColumnNumber
    Write-Output ("{0}:{1} {2}" -f $line, $column, $parseError.Message)
}

exit 1
