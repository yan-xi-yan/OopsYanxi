---
title: Expressive Code 示例
published: 2024-04-10
description: 展示 Expressive Code 在 Markdown 中的代码块效果。
tags: ["自定义"]
category: 指南
draft: true
---

这篇文章会演示 [Expressive Code](https://expressive-code.com/) 呈现代码块时的效果。下面的示例基于官方文档整理，如果你需要更完整的说明，可以直接参考官方文档。

## Expressive Code

### 语法高亮

[语法高亮](https://expressive-code.com/key-features/syntax-highlighting/)

#### 常规语法高亮

```js
console.log('这段代码已经应用了语法高亮！')
```

#### 渲染 ANSI 转义序列

```ansi
ANSI 颜色：
- 常规：  [31m红色[0m [32m绿色[0m [33m黄色[0m [34m蓝色[0m [35m洋红[0m [36m青色[0m
- 粗体：  [1;31m红色[0m [1;32m绿色[0m [1;33m黄色[0m [1;34m蓝色[0m [1;35m洋红[0m [1;36m青色[0m
- 暗化：  [2;31m红色[0m [2;32m绿色[0m [2;33m黄色[0m [2;34m蓝色[0m [2;35m洋红[0m [2;36m青色[0m

256 色（展示 160-177）：
[38;5;160m160 [38;5;161m161 [38;5;162m162 [38;5;163m163 [38;5;164m164 [38;5;165m165[0m
[38;5;166m166 [38;5;167m167 [38;5;168m168 [38;5;169m169 [38;5;170m170 [38;5;171m171[0m
[38;5;172m172 [38;5;173m173 [38;5;174m174 [38;5;175m175 [38;5;176m176 [38;5;177m177[0m

完整 RGB 颜色：
[38;2;34;139;34m森林绿 - RGB(34, 139, 34)[0m

文本样式：[1m粗体[0m [2m暗化[0m [3m斜体[0m [4m下划线[0m
```

### 编辑器和终端边框

[编辑器与终端边框](https://expressive-code.com/key-features/frames/)

#### 代码编辑器边框

```js title="my-test-file.js"
console.log('标题属性示例')
```

---

```html
<!-- src/content/index.html -->
<div>文件名注释示例</div>
```

#### 终端边框

```bash
echo "这个终端边框没有标题"
```

---

```powershell title="PowerShell terminal example"
Write-Output "这个边框带有标题！"
```

#### 覆盖边框类型

```sh frame="none"
echo "看，没有边框！"
```

---

```ps frame="code" title="PowerShell Profile.ps1"
# 如果不覆盖，这里本来会被当成终端边框
function Watch-Tail { Get-Content -Tail 20 -Wait $args }
New-Alias tail Watch-Tail
```

### 文本与行标记

[文本与行标记](https://expressive-code.com/key-features/text-markers/)

#### 标记整行与行区间

```js {1, 4, 7-8}
// 第 1 行，按行号标记
// 第 2 行
// 第 3 行
// 第 4 行，按行号标记
// 第 5 行
// 第 6 行
// 第 7 行，被区间 "7-8" 标记
// 第 8 行，被区间 "7-8" 标记
```

#### 选择行标记类型（mark、ins、del）

```js title="line-markers.js" del={2} ins={3-4} {6}
function demo() {
  console.log('这一行会被标记为删除')
  // 这一行和下一行会被标记为新增
  console.log('这是第二行新增内容')

  return '这一行使用默认的中性标记类型'
}
```

#### 为行标记添加标签

```jsx {"1":5} del={"2":7-8} ins={"3":10-12}
// labeled-line-markers.jsx
<button
  role="button"
  {...props}
  value={value}
  className={buttonClassName}
  disabled={disabled}
  active={active}
>
  {children &&
    !active &&
    (typeof children === 'string' ? <span>{children}</span> : children)}
</button>
```

#### 让长标签独占一行

```jsx {"1. 在这里提供 value 属性：":5-6} del={"2. 移除 disabled 和 active 状态：":8-10} ins={"3. 添加这段代码，在按钮内部渲染 children：":12-15}
// labeled-line-markers.jsx
<button
  role="button"
  {...props}

  value={value}
  className={buttonClassName}

  disabled={disabled}
  active={active}
>

  {children &&
    !active &&
    (typeof children === 'string' ? <span>{children}</span> : children)}
</button>
```

#### 使用类似 diff 的语法

```diff
+这一行会被标记为新增
-这一行会被标记为删除
这是一行普通内容
```

---

```diff
--- a/README.md
+++ b/README.md
@@ -1,3 +1,4 @@
+这是一份真实的 diff 文件
-所有内容都会保持原样
 no whitespace will be removed either
```

#### 将语法高亮与 diff 语法结合使用

```diff lang="js"
  function thisIsJavaScript() {
    // 这个代码块整体会按 JavaScript 高亮，
    // 同时我们仍然可以加入 diff 标记！
-   console.log('需要移除的旧代码')
+   console.log('全新的闪亮代码！')
  }
```

#### 标记行内的特定文本

```js "given text"
function demo() {
  // 标记每一行中的指定文本
  return '支持对指定文本的多次匹配';
}
```

#### 正则表达式

```ts /ye[sp]/
console.log('单词 yes 和 yep 会被标记出来。')
```

#### 转义正斜杠

```sh /\/ho.*\//
echo "Test" > /home/test.txt
```

#### 选择行内标记类型（mark、ins、del）

```js "return true;" ins="inserted" del="deleted"
function demo() {
  console.log('这里演示的是新增和删除这两种行内标记类型');
  // return 语句使用默认标记类型
  return true;
}
```

### 自动换行

[自动换行](https://expressive-code.com/key-features/word-wrap/)

#### 为单个代码块配置换行

```js wrap
// wrap 示例
function getLongString() {
  return '这是一段非常长的字符串，除非容器非常宽，否则它大概率放不进可用空间里'
}
```

---

```js wrap=false
// wrap=false 示例
function getLongString() {
  return '这是一段非常长的字符串，除非容器非常宽，否则它大概率放不进可用空间里'
}
```

#### 配置换行后续行的缩进

```js wrap preserveIndent
// preserveIndent 示例（默认启用）
function getLongString() {
  return '这是一段非常长的字符串，除非容器非常宽，否则它大概率放不进可用空间里'
}
```

---

```js wrap preserveIndent=false
// preserveIndent=false 示例
function getLongString() {
  return '这是一段非常长的字符串，除非容器非常宽，否则它大概率放不进可用空间里'
}
```

## 可折叠区域

[可折叠区域](https://expressive-code.com/plugins/collapsible-sections/)

```js collapse={1-5, 12-14, 21-24}
// 这些样板初始化代码会被折叠起来
import { someBoilerplateEngine } from '@example/some-boilerplate'
import { evenMoreBoilerplate } from '@example/even-more-boilerplate'

const engine = someBoilerplateEngine(evenMoreBoilerplate())

// 这一部分默认可见
engine.doSomething(1, 2, 3, calcFn)

function calcFn() {
  // 你可以拥有多个折叠区域
  const a = 1
  const b = 2
  const c = a + b

  // 这一行会保持可见
  console.log(`计算结果：${a} + ${b} = ${c}`)
  return c
}

// 从这里到代码块结尾都会再次被折叠
engine.closeConnection()
engine.freeMemory()
engine.shutdown({ reason: '示例样板代码结束' })
```

## 行号

[行号](https://expressive-code.com/plugins/line-numbers/)

### 为单个代码块显示行号

```js showLineNumbers
// 这个代码块会显示行号
console.log('来自第 2 行的问候！')
console.log('我现在位于第 3 行')
```

---

```js showLineNumbers=false
// 这个代码块禁用了行号
console.log('你好？')
console.log('抱歉，你知道我现在在哪一行吗？')
```

### 修改起始行号

```js showLineNumbers startLineNumber=5
console.log('来自第 5 行的问候！')
console.log('我现在位于第 6 行')
```

