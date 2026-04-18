---
title: Markdown 扩展功能
published: 2024-05-01
updated: 2024-11-29
description: 进一步了解 OopsYanxi 中的 Markdown 扩展能力。
image: ''
tags: [自定义]
category: 指南
draft: true
---

## GitHub 仓库卡片

你可以添加会跳转到 GitHub 仓库的动态卡片。页面加载时，仓库信息会通过 GitHub API 拉取。

::github{repo="Fabrizz/MMM-OnSpotify"}

使用 `::github{repo="<owner>/<repo>"}` 这段代码即可创建 GitHub 仓库卡片。

```markdown
::github{repo="yan-xi-yan/OopsYanxi"}
```

## 提示块

支持以下类型的提示块：`note` `tip` `important` `warning` `caution`

:::note
即使只是快速浏览，用户也应该注意这类信息。
:::

:::tip
这类可选信息能帮助用户更顺利地完成操作。
:::

:::important
这是用户成功完成操作所必需的关键信息。
:::

:::warning
这是带有潜在风险、需要用户立即注意的重要内容。
:::

:::caution
说明某个操作可能带来的负面后果。
:::

### 基本语法

```markdown
:::note
即使只是快速浏览，用户也应该注意这类信息。
:::

:::tip
这类可选信息能帮助用户更顺利地完成操作。
:::
```

### 自定义标题

提示块的标题可以自定义。

:::note[我的自定义标题]
这是一条带有自定义标题的提示。
:::

```markdown
:::note[我的自定义标题]
这是一条带有自定义标题的提示。
:::
```

### GitHub 语法

> [!TIP]
> 也支持 [GitHub 的提示块语法](https://github.com/orgs/community/discussions/16925)。

```
> [!NOTE]
> 也支持 GitHub 的提示块语法。

> [!TIP]
> 也支持 GitHub 的提示块语法。
```

### 剧透内容

你可以在文本中加入剧透内容，里面同样支持 **Markdown** 语法。

内容 :spoiler[被隐藏起来了 **ayyy**]！

```markdown
内容 :spoiler[被隐藏起来了 **ayyy**]！
```
