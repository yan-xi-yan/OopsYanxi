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

function Get-PublishedDateFromFile {
    param(
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $content = Get-Content -LiteralPath $Path -Encoding UTF8 -Raw
    $match = [regex]::Match($content, '(?m)^published:\s*(?<date>[^\r\n]+)\s*$')
    if (-not $match.Success) {
        return $null
    }

    try {
        return [datetime]::Parse($match.Groups['date'].Value.Trim())
    }
    catch {
        return $null
    }
}

function Get-FallbackPublishedDate {
    param(
        [string]$Path
    )

    $currentFileName = Split-Path -Leaf $Path
    $siblingDates = @(Get-ChildItem -LiteralPath (Split-Path -Parent $Path) -File -Filter *.md |
        Where-Object { $_.Name -ne $currentFileName } |
        ForEach-Object { Get-PublishedDateFromFile -Path $_.FullName } |
        Where-Object { $null -ne $_ })

    if ($siblingDates.Count -gt 0) {
        return ($siblingDates | Sort-Object | Select-Object -Last 1).ToString("yyyy-MM-dd")
    }

    return (Get-Item -LiteralPath $Path).LastWriteTime.ToString("yyyy-MM-dd")
}

function Repair-MarkdownFrontmatter {
    param(
        [string]$Path
    )

    $content = Get-Content -LiteralPath $Path -Encoding UTF8 -Raw
    $match = [regex]::Match($content, '(?s)\A---\r?\n(?<frontmatter>.*?)\r?\n---(?:\r?\n)?')
    if (-not $match.Success) {
        return
    }

    $frontmatter = $match.Groups['frontmatter'].Value
    $body = $content.Substring($match.Length)
    $knownKeysPattern = '(?:published|updated|draft|description|image|tags|category|lang|prevTitle|prevSlug|nextTitle|nextSlug):\s'
    $normalizedFrontmatter = [regex]::Replace(
        $frontmatter,
        "([^\r\n])(?=$knownKeysPattern)",
        { param($m) $m.Groups[1].Value + [Environment]::NewLine }
    )

    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($line in ($normalizedFrontmatter -split '\r?\n')) {
        $trimmedLine = $line.TrimEnd()
        if ($trimmedLine.Length -eq 0) {
            continue
        }

        $lines.Add($trimmedLine)
    }

    $hasPublished = $false
    foreach ($line in $lines) {
        if ($line -match '^published:\s+') {
            $hasPublished = $true
            break
        }
    }

    if (-not $hasPublished) {
        $published = Get-FallbackPublishedDate -Path $Path
        $insertIndex = 0
        if ($lines.Count -gt 0 -and $lines[0] -match '^title:\s+') {
            $insertIndex = 1
        }

        $lines.Insert($insertIndex, "published: $published")
    }

    $rewrittenFrontmatter = ($lines -join "`r`n").TrimEnd()
    $rewrittenContent = "---`r`n$rewrittenFrontmatter`r`n---`r`n$body"
    if ($rewrittenContent -ne $content) {
        Set-Content -LiteralPath $Path -Encoding UTF8 -Value $rewrittenContent
    }
}

function Resolve-ExistingRelativeMarkdownLink {
    param(
        [string]$BasePath,
        [string]$Link
    )

    $baseDir = Split-Path -Parent $BasePath
    $directTarget = [System.IO.Path]::GetFullPath((Join-Path $baseDir $Link))
    if (Test-Path -LiteralPath $directTarget) {
        return $Link
    }

    $candidateLinks = @(
        ($Link -replace ' ', '_'),
        ($Link -replace '%20', '_')
    ) | Select-Object -Unique

    foreach ($candidateLink in $candidateLinks) {
        if ($candidateLink -eq $Link) {
            continue
        }

        $candidateTarget = [System.IO.Path]::GetFullPath((Join-Path $baseDir $candidateLink))
        if (Test-Path -LiteralPath $candidateTarget) {
            return $candidateLink
        }
    }

    return $Link
}

function Repair-MarkdownRelativeLinks {
    param(
        [string]$Path
    )

    $content = Get-Content -LiteralPath $Path -Encoding UTF8 -Raw
    $rewrittenContent = [regex]::Replace(
        $content,
        '\[(?<text>[^\]]+)\]\((?<link>(?:\./|\.\./)[^)]+?\.md)\)',
        {
            param($match)

            $originalLink = $match.Groups['link'].Value
            $resolvedLink = Resolve-ExistingRelativeMarkdownLink -BasePath $Path -Link $originalLink
            if ($resolvedLink -eq $originalLink) {
                return $match.Value
            }

            return $match.Value.Replace($originalLink, $resolvedLink)
        }
    )

    if ($rewrittenContent -ne $content) {
        Set-Content -LiteralPath $Path -Encoding UTF8 -Value $rewrittenContent
    }
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
    Repair-MarkdownFrontmatter -Path $targetPath
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

Get-ChildItem -LiteralPath $Destination -Recurse -File -Filter *.md | ForEach-Object {
    Repair-MarkdownRelativeLinks -Path $_.FullName
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
