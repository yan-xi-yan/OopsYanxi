param(
    [string]$Source = "D:\Knowledge\AI\LLM\Machine-learning\notes",
    [string]$Destination = "D:\Tools\Media\Fuwari\OopsYanxi\src\content\posts\AI\LLM\Machine-learning\notes"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-FrontmatterFile {
    param(
        [string]$Path
    )

    $content = Get-Content -Path $Path -Encoding UTF8 -Raw
    return $content -match '(?s)\A---\r?\n.*?\r?\n---\r?\n'
}

if (-not (Test-Path -LiteralPath $Source)) {
    throw "Source directory not found: $Source"
}

if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$copiedFiles = New-Object System.Collections.Generic.List[string]
$skippedFiles = New-Object System.Collections.Generic.List[string]

Get-ChildItem -LiteralPath $Source -Recurse -File -Filter *.md | ForEach-Object {
    $relativePath = $_.FullName.Substring($Source.Length).TrimStart('\')
    $targetPath = Join-Path $Destination $relativePath

    if (-not (Test-FrontmatterFile -Path $_.FullName)) {
        $skippedFiles.Add($relativePath)
        return
    }

    $targetDir = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    Copy-Item -LiteralPath $_.FullName -Destination $targetPath -Force
    $copiedFiles.Add($relativePath)
}

Write-Host "Copied $($copiedFiles.Count) markdown files:"
$copiedFiles | Sort-Object | ForEach-Object { Write-Host "  $_" }

if ($skippedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipped $($skippedFiles.Count) files without frontmatter:"
    $skippedFiles | Sort-Object | ForEach-Object { Write-Host "  $_" }
}
