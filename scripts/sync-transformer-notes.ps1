param(
    [string]$Source = "D:\Knowledge\AI\LLM\Transformer\notes",
    [string]$Destination = "D:\Tools\Media\Fuwari\OopsYanxi\src\content\posts\AI\LLM\Transformer\notes"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$sharedScript = Join-Path $PSScriptRoot "sync-note-tree.ps1"
& $sharedScript -Source $Source -Destination $Destination

function Apply-LiteralReplacements {
    param(
        [string]$FilePath,
        [string]$From,
        [string]$To
    )

    if (-not (Test-Path -LiteralPath $FilePath)) {
        return
    }

    $content = Get-Content -LiteralPath $FilePath -Encoding UTF8 -Raw
    $content = $content.Replace($From, $To)
    Set-Content -LiteralPath $FilePath -Encoding UTF8 -Value $content
}

$indexPath = Join-Path $Destination "00_Index.md"
Apply-LiteralReplacements -FilePath $indexPath -From "../Machine-learning/notes/" -To "../../Machine-learning/notes/"

$foundationPath = Join-Path $Destination "01_Foundation\01_什么是语言模型.md"
Apply-LiteralReplacements -FilePath $foundationPath -From "[[01_序列建模与循环神经网络]]" -To "[序列建模与循环神经网络](../../Machine-learning/notes/09_Sequence_Models/01_序列建模与循环神经网络.md)"
Apply-LiteralReplacements -FilePath $foundationPath -From "[[02_浅看Transformer架构]]" -To "[浅看 Transformer 架构](../../Machine-learning/notes/10_Attention_and_Transformer/02_浅看Transformer架构.md)"
Apply-LiteralReplacements -FilePath $foundationPath -From "[[02_梯度消失与长短时记忆网络|梯度消失]]" -To "[梯度消失](../../Machine-learning/notes/09_Sequence_Models/02_梯度消失与长短时记忆网络.md)"

$foundationOverviewPath = Join-Path $Destination "01_Foundation\02_Transformer整体架构.md"
Apply-LiteralReplacements -FilePath $foundationOverviewPath -From "[[02_浅看Transformer架构]]" -To "[浅看 Transformer 架构](../../Machine-learning/notes/10_Attention_and_Transformer/02_浅看Transformer架构.md)"

$selfAttentionPath = Join-Path $Destination "03_Attention\01_理解Self Attention.md"
Apply-LiteralReplacements -FilePath $selfAttentionPath -From "[[01_编码器解码器与注意力机制|ML 系列中的注意力机制]]" -To "[ML 系列中的注意力机制](../../Machine-learning/notes/10_Attention_and_Transformer/01_编码器解码器与注意力机制.md)"

$encoderBlockPath = Join-Path $Destination "04_Architecture\01_Encoder Block.md"
Apply-LiteralReplacements -FilePath $encoderBlockPath -From "[[01_梯度消失问题|梯度消失]]" -To "[梯度消失](../../Machine-learning/notes/07_Deep_Learning_Foundations/01_梯度消失问题.md)"

$outputPath = Join-Path $Destination "04_Architecture\03_终端输出.md"
Apply-LiteralReplacements -FilePath $outputPath -From "[[01_Token Embedding|Embedding 矩阵]]" -To "[Embedding 矩阵](../02_Input_Representation/01_Token Embedding.md)"
