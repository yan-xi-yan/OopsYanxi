---
title: 注意力机制
published: 2026-04-22
description: Self Attention 从直觉到数学推导再到多头扩展
tags: [Transformer, Self Attention, 多头注意力, 索引]
---

# 03 - 注意力机制

## 本章内容

| 笔记                                            | 要点                                       |
| --------------------------------------------- | ---------------------------------------- |
| [理解 Self Attention](./01_理解Self_Attention.md) | Q/K/V 直觉类比，与 RNN/CNN 的对比，为什么能捕捉长程依赖      |
| [Self Attention 计算](./02_Self_Attention计算.md) | Scaled Dot-Product 公式推导，数值实例，代码实现        |
| [多头注意力](./03_多头注意力.md)                        | 多表示子空间，Split→Attend→Concat→Project，参数量分析 |

## 前置依赖
- [Transformer 整体架构](../01_Foundation/02_Transformer整体架构.md) — 知道注意力在全局中的位置

