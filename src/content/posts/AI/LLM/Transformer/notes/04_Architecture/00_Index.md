---
title: 架构组件
published: 2026-04-22
description: Encoder Block、Decoder 掩码与输出层
tags: [Transformer, Encoder, Decoder, 索引]
category: Transformer
draft: false
series: Transformer
section: 架构组件
kind: index
order: 4
---

# 04 - 架构组件

## 本章内容

| 笔记                                                     | 要点                                                |
| ------------------------------------------------------ | ------------------------------------------------- |
| [Encoder Block](./01_Encoder_Block.md)                 | MHA + FFN + 残差连接 + LayerNorm 完整结构                 |
| [Masked Self Attention](./02_Masked_Self_Attention.md) | 因果掩码原理，解码器自注意力与交叉注意力                              |
| [终端输出](./03_终端输出.md)                                   | Linear 投影 + Softmax，解码策略（Greedy/Beam/Top-k/Top-p） |

## 前置依赖
- [多头注意力](../03_Attention/03_多头注意力.md) — Encoder/Decoder Block 的核心子组件

