#Requires -Version 7.0
[CmdletBinding()]
param(
  [string]$OutputDir = "",
  [string]$BrowserPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
if (-not $OutputDir) {
  $OutputDir = Join-Path $repoRoot "docs\pdfs"
}

function Resolve-BrowserPath {
  param([string]$PreferredPath)

  if ($PreferredPath) {
    if (Test-Path $PreferredPath) { return (Resolve-Path $PreferredPath).Path }
    throw "Browser niet gevonden op opgegeven pad: $PreferredPath"
  }

  $candidates = @(
    "C:\Program Files\Google\Chrome\Application\chrome.exe",
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    "C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) { return $candidate }
  }

  throw "Geen ondersteunde browser gevonden. Installeer Chrome of Edge, of geef -BrowserPath mee."
}

function New-HtmlDocument {
  param(
    [string]$Title,
    [string]$BodyHtml
  )

  @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>$Title</title>
  <style>
    @page { size: A4; margin: 16mm 14mm 18mm 14mm; }
    body {
      font-family: "Segoe UI", Calibri, Arial, sans-serif;
      color: #1f2937;
      line-height: 1.45;
      font-size: 11pt;
      margin: 0;
    }
    h1, h2, h3, h4 {
      color: #0f172a;
      margin-top: 1.2em;
      margin-bottom: 0.45em;
      page-break-after: avoid;
    }
    h1 {
      font-size: 22pt;
      border-bottom: 2px solid #cbd5e1;
      padding-bottom: 6px;
      margin-top: 0;
    }
    h2 { font-size: 16pt; }
    h3 { font-size: 13pt; }
    p, li { orphans: 3; widows: 3; }
    blockquote {
      border-left: 4px solid #94a3b8;
      margin: 1em 0;
      padding: 0.2em 1em;
      color: #334155;
      background: #f8fafc;
    }
    code, pre {
      font-family: "Cascadia Code", Consolas, monospace;
    }
    code {
      background: #f1f5f9;
      padding: 0.08em 0.28em;
      border-radius: 4px;
      font-size: 0.95em;
    }
    pre {
      background: #0f172a;
      color: #e2e8f0;
      padding: 12px;
      border-radius: 8px;
      overflow-x: auto;
      white-space: pre-wrap;
      page-break-inside: avoid;
    }
    pre code {
      background: transparent;
      color: inherit;
      padding: 0;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 1em 0 1.2em 0;
      font-size: 10pt;
    }
    th, td {
      border: 1px solid #cbd5e1;
      padding: 7px 8px;
      vertical-align: top;
    }
    th {
      background: #e2e8f0;
      color: #0f172a;
      text-align: left;
    }
    tr:nth-child(even) td {
      background: #f8fafc;
    }
    a {
      color: #0f766e;
      text-decoration: none;
    }
    hr {
      border: 0;
      border-top: 1px solid #cbd5e1;
      margin: 1.4em 0;
    }
    img {
      max-width: 100%;
    }
  </style>
</head>
<body>
$BodyHtml
</body>
</html>
"@
}

function Wait-ForFile {
  param(
    [Parameter(Mandatory)][string]$Path,
    [int]$TimeoutSeconds = 10
  )

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  do {
    if (Test-Path $Path) { return $true }
    Start-Sleep -Milliseconds 250
  } while ((Get-Date) -lt $deadline)

  return (Test-Path $Path)
}

$browser = Resolve-BrowserPath -PreferredPath $BrowserPath
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$guides = @(
  @{ Source = "docs\studieprogramma-md102.md"; Target = "studieprogramma-md102.pdf"; Title = "Studieprogramma MD-102 (NL)" },
  @{ Source = "docs\study-guide-md102.md";     Target = "study-guide-md102.pdf";     Title = "Study Guide MD-102 (EN)" },
  @{ Source = "docs\studieprogramma-ms102.md"; Target = "studieprogramma-ms102.pdf"; Title = "Studieprogramma MS-102 (NL)" },
  @{ Source = "docs\study-guide-ms102.md";     Target = "study-guide-ms102.pdf";     Title = "Study Guide MS-102 (EN)" },
  @{ Source = "docs\studieprogramma-sc300.md"; Target = "studieprogramma-sc300.pdf"; Title = "Studieprogramma SC-300 (NL)" },
  @{ Source = "docs\study-guide-sc300.md";     Target = "study-guide-sc300.pdf";     Title = "Study Guide SC-300 (EN)" },
  @{ Source = "docs\studieprogramma-az104.md"; Target = "studieprogramma-az104.pdf"; Title = "Studieprogramma AZ-104 (NL)" },
  @{ Source = "docs\study-guide-az104.md";     Target = "study-guide-az104.pdf";     Title = "Study Guide AZ-104 (EN)" }
)

$tempRoot = Join-Path $env:TEMP ("ssw-lab-pdf-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
  foreach ($guide in $guides) {
    $sourcePath = Join-Path $repoRoot $guide.Source
    if (-not (Test-Path $sourcePath)) {
      throw "Bronbestand niet gevonden: $sourcePath"
    }

    $markdown = Get-Content $sourcePath -Raw -Encoding UTF8
    $bodyHtml = ($markdown | ConvertFrom-Markdown).Html.Trim()
    $htmlDoc  = New-HtmlDocument -Title $guide.Title -BodyHtml $bodyHtml

    $htmlPath = Join-Path $tempRoot ([IO.Path]::GetFileNameWithoutExtension($guide.Target) + ".html")
    $pdfPath  = Join-Path $OutputDir $guide.Target

    Set-Content -Path $htmlPath -Value $htmlDoc -Encoding UTF8

    $url = "file:///" + ($htmlPath -replace "\\","/")
    & $browser `
      "--headless" `
      "--disable-gpu" `
      "--allow-file-access-from-files" `
      "--print-to-pdf-no-header" `
      "--print-to-pdf=$pdfPath" `
      $url | Out-Null

    if (-not (Wait-ForFile -Path $pdfPath -TimeoutSeconds 10)) {
      throw "PDF niet aangemaakt: $pdfPath"
    }

    Write-Host "OK  $($guide.Target)" -ForegroundColor Green
  }
}
finally {
  if (Test-Path $tempRoot) {
    Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}
