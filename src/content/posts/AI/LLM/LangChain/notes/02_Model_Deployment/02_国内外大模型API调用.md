---
title: 国内外大模型 API 调用
published: 2026-04-24
description: 在 LangChain 中统一接入 OpenAI、Anthropic、通义千问、Deepseek 等主流大模型 API
tags: [LangChain, API, OpenAI, Anthropic, 通义千问, Deepseek]
category: LangChain
draft: false
---

# 国内外大模型 API 调用

> 上一篇 [[01_大模型选择与私有化部署]] 解决了"选什么模型、怎么本地跑"的问题。本篇聚焦 **云端 API 调用**——通过 LangChain 的统一抽象层，用几乎相同的代码接入 OpenAI、Anthropic、通义千问、Deepseek 等国内外主流大模型。

---

## 1 LangChain 的模型抽象层

### 1.1 通俗理解

> [!tip] 万能充电器类比
> LangChain 就像一个 **万能充电器**——不管你的手机是 iPhone（OpenAI）、三星（Anthropic）还是小米（通义千问），只要插上对应的转接头（Provider 类），充电接口（调用方式）都一样：`model.invoke("你好")`。

这意味着：

- **切换模型不改业务逻辑**：把 `ChatOpenAI` 换成 `ChatAnthropic`，上下游代码零修改。
- **链（Chain）和智能体（Agent）天然兼容**：LCEL 管道中的 Model 环节可以随时热插拔。
- **流式、批量、异步**全部开箱即用，不需要为每个模型单独写适配代码。

### 1.2 BaseChatModel 接口统一了什么

LangChain 通过 `BaseChatModel` 抽象基类定义了所有 Chat Model 的公共契约：

| 方法 | 说明 |
|---|---|
| `invoke(messages)` | 同步调用，返回 `AIMessage` |
| `ainvoke(messages)` | 异步调用 |
| `stream(messages)` | 同步流式输出，逐 token 返回 |
| `astream(messages)` | 异步流式输出 |
| `batch(messages_list)` | 批量调用 |
| `bind_tools(tools)` | 绑定工具（Function Calling） |

> [!info] 关键认知
> 不管底层是 GPT-4o、Claude 3.5 还是 Qwen-Max，上层代码只面向 `BaseChatModel` 的这几个方法编程。这就是 **依赖倒置** 在 LLM 应用中的体现。

### 1.3 继承关系一览

```
BaseChatModel（抽象基类）
├── ChatOpenAI          → OpenAI GPT 系列
├── ChatAnthropic       → Anthropic Claude 系列
├── ChatTongyi          → 阿里通义千问
├── ChatOllama          → 本地 Ollama 模型
├── ChatZhipuAI         → 智谱 GLM 系列
├── QianfanChatEndpoint → 百度文心一言
└── ...更多社区集成
```

每个子类只需实现 `_generate()` 或 `_stream()` 等底层方法，就自动获得上面表格中的全部能力。详见 [[01_LangChain概述与核心架构]]。

---

## 2 OpenAI 系列模型调用

### 2.1 API Key 获取与配置

前往 [OpenAI Platform](https://platform.openai.com/) 注册并创建 API Key，通过环境变量配置：

```bash
export OPENAI_API_KEY="sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

> [!warning] 安全提醒
> 永远不要将 API Key 提交到 Git 仓库。建议使用 `.env` + `python-dotenv` 管理。

### 2.2 ChatOpenAI 核心参数

```bash
pip install langchain-openai
```

| 参数 | 类型 | 说明 |
|---|---|---|
| `model` | str | 模型标识，如 `"gpt-4o"`、`"gpt-4o-mini"` |
| `temperature` | float | 取值 0-2，越高输出越随机；事实类任务建议 0，创意类 0.7-1.0 |
| `max_tokens` | int | 限制输出长度，防止模型"话太多"消耗额度 |
| `streaming` | bool | 设为 `True` 配合 `stream()` 方法使用 |
| `timeout` | int | 请求超时秒数 |
| `max_retries` | int | API 调用失败时自动重试次数 |

### 2.3 代码示例

#### 基础调用

```python
# pip install langchain-openai

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatOpenAI(model="gpt-4o", temperature=0)

messages = [
    SystemMessage(content="你是一位资深 Python 工程师。"),
    HumanMessage(content="用三句话解释什么是装饰器。"),
]

response = llm.invoke(messages)
print(response.content)
```

#### 流式输出

```python
# pip install langchain-openai

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-4o", temperature=0.7, streaming=True)

for chunk in llm.stream([HumanMessage(content="给我讲一个关于 AI 的短故事")]):
    print(chunk.content, end="", flush=True)
```

> [!tip] 流式输出的价值
> 在 Web 应用中，流式输出让用户"边生成边看"，显著提升体验。`stream()` 返回的每个 `chunk` 是 `AIMessageChunk` 对象。

---

## 3 Anthropic Claude 模型调用

前往 [Anthropic Console](https://console.anthropic.com/) 创建 API Key 并设置环境变量 `ANTHROPIC_API_KEY`。

```python
# pip install langchain-anthropic

from langchain_anthropic import ChatAnthropic
from langchain_core.messages import HumanMessage, SystemMessage

llm = ChatAnthropic(
    model="claude-sonnet-4-20250514",
    temperature=0,
    max_tokens=1024,
)

messages = [
    SystemMessage(content="你是一位数据分析专家，回答简洁准确。"),
    HumanMessage(content="解释什么是 p-value，给一个实际例子。"),
]

response = llm.invoke(messages)
print(response.content)
```

> [!info] Claude 的特点
> - 上下文窗口大（Claude 3.5 Sonnet 支持 200K tokens），适合长文档分析。
> - System Prompt 遵从性强，适合角色扮演和格式化输出场景。
> - `temperature` 范围为 0-1（与 OpenAI 的 0-2 不同）。

---

## 4 国内模型调用

### 4.1 通义千问（Qwen）

通义千问是阿里云推出的大语言模型，通过 **DashScope** 平台提供 API。前往 [阿里云 DashScope](https://dashscope.aliyun.com/) 获取 API Key 并设置环境变量 `DASHSCOPE_API_KEY`。

#### 方式一：使用 ChatTongyi

```python
# pip install langchain-community dashscope

from langchain_community.chat_models.tongyi import ChatTongyi
from langchain_core.messages import HumanMessage

llm = ChatTongyi(model="qwen-max", temperature=0.7, max_tokens=1024)

response = llm.invoke([HumanMessage(content="简述唐朝的科举制度。")])
print(response.content)
```

#### 方式二：OpenAI 兼容接口（推荐）

```python
# pip install langchain-openai

from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="qwen-max",
    base_url="https://dashscope.aliyuncs.com/compatible-mode/v1",
    api_key="sk-xxxxxxxx",
    temperature=0.7,
)

response = llm.invoke("用一句话介绍量子计算。")
print(response.content)
```

### 4.2 Deepseek

Deepseek 提供高性价比的大模型 API，原生支持 OpenAI 兼容格式。前往 [Deepseek Platform](https://platform.deepseek.com/) 获取 API Key。

```python
# pip install langchain-openai

from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="deepseek-chat",    # deepseek-chat 或 deepseek-reasoner
    base_url="https://api.deepseek.com",
    api_key="sk-xxxxxxxx",
    temperature=0,
    max_tokens=2048,
)

response = llm.invoke("解释梯度下降算法的直觉理解。")
print(response.content)
```

> [!tip] Deepseek-Reasoner
> `deepseek-reasoner`（即 DeepSeek-R1）擅长数学推理和复杂逻辑任务，使用方式完全一致，只需改 `model` 参数。

### 4.3 百度文心一言（ERNIE Bot）

文心一言通过 **千帆平台** 提供 API。设置环境变量 `QIANFAN_AK` 和 `QIANFAN_SK`。

```python
# pip install langchain-community qianfan

from langchain_community.chat_models import QianfanChatEndpoint
from langchain_core.messages import HumanMessage

llm = QianfanChatEndpoint(
    model="ERNIE-4.0-8K",
    temperature=0.7,
)

response = llm.invoke([HumanMessage(content="介绍一下深度学习的发展历程。")])
print(response.content)
```

> [!info] 千帆平台
> 百度千帆需要在控制台创建应用并获取 Access Key + Secret Key，与 OpenAI 单 Key 模式不同。

### 4.4 智谱 GLM（ChatGLM）

智谱 AI 推出的 GLM 系列模型。前往 [智谱 AI 开放平台](https://open.bigmodel.cn/) 获取 API Key。

#### 方式一：使用 ChatZhipuAI

```python
# pip install langchain-community zhipuai

import os
os.environ["ZHIPUAI_API_KEY"] = "your_api_key"

from langchain_community.chat_models import ChatZhipuAI
from langchain_core.messages import HumanMessage

llm = ChatZhipuAI(model="glm-4-plus", temperature=0.7)

response = llm.invoke([HumanMessage(content="什么是 Transformer 架构？")])
print(response.content)
```

#### 方式二：OpenAI 兼容接口

```python
# pip install langchain-openai

from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    model="glm-4-plus",
    base_url="https://open.bigmodel.cn/api/paas/v4",
    api_key="your_api_key",
)

response = llm.invoke("Transformer 中的自注意力机制是如何工作的？")
print(response.content)
```

---

## 5 通过 OpenAI 兼容接口统一调用

### 5.1 为什么可以统一？

OpenAI 的 Chat Completions API 已成为事实标准。Deepseek、通义千问、智谱 GLM、月之暗面 Kimi 等国内厂商均实现了兼容端点。

> [!tip] 核心优势
> 只需 `langchain-openai` 一个包，通过修改 `base_url` 和 `model` 参数，就能接入几乎所有主流大模型，无需为每个厂商安装单独的 SDK。

### 5.2 工厂函数：统一调用模式

```python
# pip install langchain-openai

from langchain_openai import ChatOpenAI

def create_llm(provider: str) -> ChatOpenAI:
    """工厂函数：根据 provider 创建对应的 LLM 实例"""
    configs = {
        "openai": {
            "model": "gpt-4o",
            "base_url": "https://api.openai.com/v1",
            "api_key": "sk-xxx",
        },
        "deepseek": {
            "model": "deepseek-chat",
            "base_url": "https://api.deepseek.com",
            "api_key": "sk-xxx",
        },
        "qwen": {
            "model": "qwen-max",
            "base_url": "https://dashscope.aliyuncs.com/compatible-mode/v1",
            "api_key": "sk-xxx",
        },
        "glm": {
            "model": "glm-4-plus",
            "base_url": "https://open.bigmodel.cn/api/paas/v4",
            "api_key": "xxx",
        },
    }
    cfg = configs[provider]
    return ChatOpenAI(
        model=cfg["model"],
        base_url=cfg["base_url"],
        api_key=cfg["api_key"],
        temperature=0,
        max_tokens=1024,
    )

# 切换模型只需改一个字符串
llm = create_llm("deepseek")
response = llm.invoke("什么是向量数据库？")
print(response.content)
```

### 5.3 兼容端点汇总

| 模型厂商 | `base_url` | 常用 `model` |
|---|---|---|
| OpenAI | `https://api.openai.com/v1` | `gpt-4o`、`gpt-4o-mini` |
| Deepseek | `https://api.deepseek.com` | `deepseek-chat`、`deepseek-reasoner` |
| 通义千问 | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-max`、`qwen-plus` |
| 智谱 GLM | `https://open.bigmodel.cn/api/paas/v4` | `glm-4-plus`、`glm-4-flash` |
| 月之暗面 | `https://api.moonshot.cn/v1` | `moonshot-v1-8k`、`moonshot-v1-128k` |
| 零一万物 | `https://api.lingyiwanwu.com/v1` | `yi-large`、`yi-medium` |

> [!warning] 兼容性注意
> "OpenAI 兼容"不代表 100% 功能对齐。部分高级特性（如 **Structured Output**、**Parallel Function Calling**）在某些厂商的实现中可能不完整，生产环境需充分测试。

### 5.4 配合 LCEL 实现模型热切换

结合 [[01_LangChain概述与核心架构]] 中介绍的 LCEL，可以在 Chain 中灵活切换模型：

```python
# pip install langchain-openai langchain-core

from langchain_core.prompts import ChatPromptTemplate
from langchain_core.output_parsers import StrOutputParser

prompt = ChatPromptTemplate.from_messages([
    ("system", "你是一位{role}。"),
    ("human", "{question}"),
])

# 构建 Chain —— 模型部分可随时替换
chain = prompt | create_llm("deepseek") | StrOutputParser()
result = chain.invoke({"role": "物理学家", "question": "为什么天空是蓝色的？"})
print(result)

# 切换到 Qwen，Chain 结构完全不变
chain_qwen = prompt | create_llm("qwen") | StrOutputParser()
result_qwen = chain_qwen.invoke({"role": "物理学家", "question": "为什么天空是蓝色的？"})
```

---

## 6 模型调用最佳实践

### 6.1 错误处理与重试策略

LangChain 内置了重试机制，也可用 `tenacity` 做更精细的控制：

```python
# pip install langchain-openai tenacity

from langchain_openai import ChatOpenAI
from langchain_core.messages import HumanMessage
from tenacity import retry, stop_after_attempt, wait_exponential

# 方式一：内置参数
llm = ChatOpenAI(model="gpt-4o", max_retries=3, timeout=30)

# 方式二：手动指数退避
@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=30),
)
def safe_invoke(llm, messages):
    return llm.invoke(messages)

response = safe_invoke(llm, [HumanMessage(content="Hello")])
```

> [!tip] 指数退避
> 遇到 429（Rate Limit）错误时，使用 **指数退避**（Exponential Backoff）而非固定间隔重试，可以更优雅地应对限流。

### 6.2 超时配置

```python
# 简单问答：短超时
llm_fast = ChatOpenAI(model="gpt-4o-mini", timeout=15)

# 长文档生成：长超时
llm_slow = ChatOpenAI(model="gpt-4o", timeout=120, max_tokens=4096)
```

### 6.3 Token 用量控制

Token 是 API 计费的基本单位，控制手段：

1. **限制 `max_tokens`**：防止输出过长。
2. **精简 System Prompt**：冗长的系统提示词消耗大量输入 token。
3. **使用回调监控用量**：

```python
# pip install langchain-openai langchain-community

from langchain_openai import ChatOpenAI
from langchain_community.callbacks import get_openai_callback
from langchain_core.messages import HumanMessage

llm = ChatOpenAI(model="gpt-4o", temperature=0)

with get_openai_callback() as cb:
    response = llm.invoke([HumanMessage(content="什么是 LangChain？")])
    print(f"输入 Tokens:  {cb.prompt_tokens}")
    print(f"输出 Tokens:  {cb.completion_tokens}")
    print(f"总 Tokens:    {cb.total_tokens}")
    print(f"总费用 (USD): ${cb.total_cost:.6f}")
```

> [!warning] 回调兼容性
> `get_openai_callback` 仅适用于 `ChatOpenAI`，其他模型需查看 `response.response_metadata` 获取用量信息。

### 6.4 费用估算

```python
# pip install tiktoken

import tiktoken

def estimate_tokens(text: str, model: str = "gpt-4o") -> int:
    """估算文本的 token 数量（仅适用于 OpenAI 模型）"""
    encoding = tiktoken.encoding_for_model(model)
    return len(encoding.encode(text))

tokens = estimate_tokens("这是一段需要估算 token 的文本。")
print(f"预估 token 数: {tokens}")
```

### 6.5 各模型 API 对比

> [!info] 价格信息
> 以下价格为截至 2025 年初的参考值，实际价格请以各厂商官网为准。1M = 100 万 tokens。

| 模型 | 输入价格（/1M tokens） | 输出价格（/1M tokens） | 最大上下文 | 速度 |
|---|---|---|---|---|
| GPT-4o | $2.50 | $10.00 | 128K | 中等 |
| GPT-4o-mini | $0.15 | $0.60 | 128K | 快 |
| Claude 3.5 Sonnet | $3.00 | $15.00 | 200K | 中等 |
| Claude 3.5 Haiku | $0.80 | $4.00 | 200K | 快 |
| Qwen-Max | ~￥0.02/千tokens | ~￥0.06/千tokens | 32K | 中等 |
| Qwen-Plus | ~￥0.004/千tokens | ~￥0.012/千tokens | 128K | 快 |
| Deepseek-Chat（V3） | ￥1.00/1M | ￥2.00/1M | 64K | 快 |
| GLM-4-Plus | ￥0.05/千tokens | ￥0.05/千tokens | 128K | 中等 |

> [!tip] 性价比策略
> - **开发调试阶段**：优先使用 `gpt-4o-mini`、`deepseek-chat`、`qwen-plus` 等低价模型。
> - **生产环境**：根据任务复杂度选择模型档次，简单任务无需顶配模型。
> - **批量处理**：部分厂商提供 Batch API（如 OpenAI），价格可低至一半。

---

## 7 总结与下一步

本篇覆盖了通过 LangChain 调用国内外主流大模型 API 的完整流程：

1. **抽象层设计**：`BaseChatModel` 统一了所有模型的调用接口。
2. **国外模型**：OpenAI（`ChatOpenAI`）和 Anthropic（`ChatAnthropic`）的标准调用。
3. **国内模型**：通义千问、Deepseek、文心一言、智谱 GLM 各自的接入方式。
4. **统一调用**：利用 OpenAI 兼容接口 + `base_url` 参数，一套代码接入多个模型。
5. **最佳实践**：错误处理、Token 控制、费用优化。

> [!tip] 下一步
> 模型调用只是起点。下一章 [[01_输出解析与结构化|输出解析与结构化]] 将介绍如何把大模型返回的自由文本转换为程序可用的结构化数据（JSON、Pydantic 对象等），让 LLM 真正融入你的应用流程。

