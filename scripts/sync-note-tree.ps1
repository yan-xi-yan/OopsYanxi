param(
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$Destination
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-FrontmatterFile {
    param(
        [string]$Path
    )

    $content = Get-Content -LiteralPath $Path -Encoding UTF8 -Raw
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
$deletedFiles = New-Object System.Collections.Generic.List[string]
$sourceRelativePaths = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)

Get-ChildItem -LiteralPath $Source -Recurse -File -Filter *.md | ForEach-Object {
    $relativePath = $_.FullName.Substring($Source.Length).TrimStart('\')
    $sourceRelativePaths.Add($relativePath) | Out-Null
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

Get-ChildItem -LiteralPath $Destination -Recurse -File -Filter *.md | ForEach-Object {
    $relativePath = $_.FullName.Substring($Destination.Length).TrimStart('\')
    if (-not $sourceRelativePaths.Contains($relativePath)) {
        Remove-Item -LiteralPath $_.FullName -Force
        $deletedFiles.Add($relativePath)
    }
}

Get-ChildItem -LiteralPath $Destination -Recurse -Directory |
    Sort-Object FullName -Descending |
    ForEach-Object {
        if (-not (Get-ChildItem -LiteralPath $_.FullName -Force)) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }

Write-Host "Copied $($copiedFiles.Count) markdown files:"
$copiedFiles | Sort-Object | ForEach-Object { Write-Host "  $_" }

if ($skippedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipped $($skippedFiles.Count) files without frontmatter:"
    $skippedFiles | Sort-Object | ForEach-Object { Write-Host "  $_" }
}

if ($deletedFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "Deleted $($deletedFiles.Count) destination-only markdown files:"
    $deletedFiles | Sort-Object | ForEach-Object { Write-Host "  $_" }
}
