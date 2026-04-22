param(
    [string]$Source = "",
    [Parameter(Mandatory = $true)]
    [string]$Destination,
    [switch]$RepairOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Write-Utf8NoBomFile {
    param(
        [string]$Path,
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

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

function Get-FrontmatterValue {
    param(
        [string]$Frontmatter,
        [string]$Key
    )

    $match = [regex]::Match(
        $Frontmatter,
        "(?m)^{0}:\s*(?<value>[^\r\n]+)\s*$" -f [regex]::Escape($Key)
    )
    if ($match.Success) {
        return $match.Groups['value'].Value.Trim()
    }

    return ""
}

function Set-FrontmatterScalarValue {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Key,
        [string]$Value
    )

    $pattern = "^{0}:\s*(?<value>.*)$" -f [regex]::Escape($Key)
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match $pattern) {
            $existingValue = [string]$Matches['value']
            $existingValue = $existingValue.Trim()
            if ([string]::IsNullOrWhiteSpace($existingValue) -or $existingValue -eq "null") {
                $Lines[$i] = "${Key}: $Value"
            }

            return
        }
    }

    $Lines.Add("${Key}: $Value")
}

function Get-IndexMetadata {
    param(
        [string]$Path,
        [string]$RootPath,
        [string]$Title
    )

    if ((Split-Path -Leaf $Path) -ine "00_Index.md") {
        return $null
    }

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $rootFullPath = [System.IO.Path]::GetFullPath($RootPath).TrimEnd('\')
    $relativePath = $fullPath.Substring($rootFullPath.Length).TrimStart('\')
    $relativeDirectory = Split-Path -Parent $relativePath
    $folderName = if ([string]::IsNullOrWhiteSpace($relativeDirectory)) {
        ""
    }
    else {
        Split-Path -Leaf $relativeDirectory
    }

    $order = 0
    if ($folderName -match '^(?<number>\d+)_') {
        $order = [int]$Matches['number']
    }

    $series = ""
    $category = ""

    if ($rootFullPath -match '(?i)\\Machine-learning\\notes$') {
        $series = "Machine Learning"
        if ($relativePath -ieq "00_Index.md") {
            $category = "Machine Learning"
        }
        elseif ($order -ge 7 -and $order -le 10) {
            $category = "Deep Learning"
        }
        else {
            $category = "Machine Learning"
        }
    }
    elseif ($rootFullPath -match '(?i)\\Transformer\\notes$') {
        $series = "Transformer"
        $category = "Transformer"
    }
    elseif ($rootFullPath -match '(?i)\\Python\\notes$') {
        $series = "Python"
        $category = "Python"
    }
    elseif ($rootFullPath -match '(?i)\\Docker&K8s\\notes$') {
        $series = "Docker & K8s"
        $category = "Docker & K8s"
    }

    return [ordered]@{
        category = $category
        draft = "false"
        series = $series
        section = $Title
        kind = "index"
        order = $order.ToString()
    }
}

function Repair-MarkdownFrontmatter {
    param(
        [string]$Path,
        [string]$RootPath
    )

    $content = Get-Content -LiteralPath $Path -Encoding UTF8 -Raw
    $match = [regex]::Match($content, '(?s)\A---\r?\n(?<frontmatter>.*?)\r?\n---(?:\r?\n)?')
    if (-not $match.Success) {
        return
    }

    $frontmatter = $match.Groups['frontmatter'].Value
    $body = $content.Substring($match.Length)
    $knownKeysPattern = '(?:published|updated|draft|description|image|tags|category|lang|series|section|kind|order|prevTitle|prevSlug|nextTitle|nextSlug):\s'
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

    $title = Get-FrontmatterValue -Frontmatter $normalizedFrontmatter -Key "title"
    $indexMetadata = Get-IndexMetadata -Path $Path -RootPath $RootPath -Title $title
    if ($null -ne $indexMetadata) {
        foreach ($key in $indexMetadata.Keys) {
            $value = [string]$indexMetadata[$key]
            if (-not [string]::IsNullOrWhiteSpace($value)) {
                Set-FrontmatterScalarValue -Lines $lines -Key $key -Value $value
            }
        }
    }

    $rewrittenFrontmatter = ($lines -join "`r`n").TrimEnd()
    $rewrittenContent = "---`r`n$rewrittenFrontmatter`r`n---`r`n$body"
    if ($rewrittenContent -ne $content) {
        Write-Utf8NoBomFile -Path $Path -Content $rewrittenContent
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
        Write-Utf8NoBomFile -Path $Path -Content $rewrittenContent
    }
}

if (-not (Test-Path -LiteralPath $Destination)) {
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$copiedFiles = New-Object System.Collections.Generic.List[string]
$skippedFiles = New-Object System.Collections.Generic.List[string]
$deletedFiles = New-Object System.Collections.Generic.List[string]
$failedRepairs = New-Object System.Collections.Generic.List[string]
$sourceRelativePaths = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)

if (-not $RepairOnly) {
    if (-not $Source) {
        throw "Source directory is required unless -RepairOnly is specified."
    }

    if (-not (Test-Path -LiteralPath $Source)) {
        throw "Source directory not found: $Source"
    }

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
}

Get-ChildItem -LiteralPath $Destination -Recurse -File -Filter *.md | ForEach-Object {
    $filePath = $_.FullName
    try {
        Repair-MarkdownFrontmatter -Path $filePath -RootPath $Destination
        Repair-MarkdownRelativeLinks -Path $filePath
    }
    catch {
        $failedRepairs.Add($filePath)
        Write-Warning ("Failed to repair {0}: {1}" -f $filePath, $_.Exception.Message)
    }
}

if ($RepairOnly) {
    Write-Host "Repaired markdown metadata and links under $Destination"
}
else {
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
}

if ($failedRepairs.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed to repair $($failedRepairs.Count) markdown files:"
    $failedRepairs | Sort-Object | ForEach-Object { Write-Host "  $_" }
}
