function ConvertTo-SSWXmlSafeValue {
    [CmdletBinding()]
    param(
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Value
    )

    return [System.Security.SecurityElement]::Escape($Value)
}
