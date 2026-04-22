param(
    [string]$Source = "D:\Knowledge\AI\LLM\Machine-learning\notes",
    [string]$Destination = "D:\Tools\Media\Fuwari\OopsYanxi\src\content\posts\AI\LLM\Machine-learning\notes"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$sharedScript = Join-Path $PSScriptRoot "sync-note-tree.ps1"
& $sharedScript -Source $Source -Destination $Destination
