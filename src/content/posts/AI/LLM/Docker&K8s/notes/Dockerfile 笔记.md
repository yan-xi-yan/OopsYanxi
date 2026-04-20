---
title: Dockerfile 笔记
published: 2026-04-20
description: Dockerfile 编写规范与镜像构建实践
tags:
  - Docker
  - Dockerfile
  - 容器
category: Docker & K8s
draft: false
---

## 相关笔记

- `Docker` 总体概念见 [[Docker 笔记]]。

## 概述

`Dockerfile` 是用于**构建镜像**的文本文件，其中定义了镜像的基础环境、依赖安装、文件复制、启动命令等内容。

可以把它理解为：

- 镜像的构建说明书
- 自动化的镜像打包脚本
- 应用运行环境的标准化描述

它的目标是让镜像构建过程**可重复**、**可维护**、**可交付**。

## 为什么需要 `Dockerfile`

如果只靠手动运行容器、进入容器、再手动安装软件，虽然也能得到一个“能跑的环境”，但会有明显问题：

- 操作不可复现
- 难以协作
- 难以版本化
- 不利于持续集成和部署

而 `Dockerfile` 的价值就在于：

- 把构建步骤写成代码
- 任何人都可以按同样方式重新构建镜像
- 修改历史可以纳入版本控制

## 镜像构建的基本流程

一个典型的镜像构建过程通常是：

1. 选择基础镜像。
2. 安装应用运行所需依赖。
3. 复制项目文件到镜像中。
4. 配置工作目录、环境变量、端口。
5. 指定容器启动命令。
6. 使用 `docker build` 构建镜像。

## 常见指令

### `FROM`

指定基础镜像。

```dockerfile
FROM python:3.12-slim
```

表示当前镜像基于 `python:3.12-slim` 继续构建。

### `WORKDIR`

设置工作目录。

```dockerfile
WORKDIR /app
```

后续命令默认在 `/app` 目录下执行。

### `COPY`

将宿主机文件复制到镜像中。

```dockerfile
COPY . /app
```

### `RUN`

在构建镜像时执行命令，常用于安装依赖。

```dockerfile
RUN pip install -r requirements.txt
```

### `EXPOSE`

声明容器可能会使用的端口。

```dockerfile
EXPOSE 8000
```

它主要用于文档说明，不等于自动开放端口。

### `CMD`

指定容器启动时默认执行的命令。

```dockerfile
CMD ["python", "app.py"]
```

## 一个最小可运行示例

下面是一个简单的 `Python` 应用镜像构建示例：

```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt /app/
RUN pip install -r requirements.txt

COPY . /app

EXPOSE 8000

CMD ["python", "app.py"]
```

这个文件表达的意思是：

1. 使用 `python:3.12-slim` 作为基础镜像。
2. 将工作目录设置为 `/app`。
3. 先复制 `requirements.txt` 并安装依赖。
4. 再复制项目代码。
5. 声明应用使用 `8000` 端口。
6. 容器启动后执行 `python app.py`。

## 落地构建说明

假设项目目录如下：

```text
project/
├─ app.py
├─ requirements.txt
└─ Dockerfile
```

### 第一步：编写 `Dockerfile`

把镜像构建规则写入项目根目录下的 `Dockerfile`。

### 第二步：构建镜像

在项目根目录执行：

```bash
docker build -t my-python-app:1.0 .
```

这条命令的含义是：

- `docker build`：开始构建镜像
- `-t my-python-app:1.0`：给镜像起名字并打标签
- `.`：当前目录作为构建上下文

**构建上下文** 指的是构建时会发送给 `Docker daemon` 的文件范围，因此：

- 不要把无关的大文件放进项目根目录
- 应结合 `.dockerignore` 排除不需要的内容

### 第三步：查看镜像

```bash
docker images
```

如果构建成功，就能看到 `my-python-app:1.0`。

### 第四步：运行容器

```bash
docker run -d --name myapp -p 8000:8000 my-python-app:1.0
```

表示：

- 后台运行容器
- 容器名为 `myapp`
- 宿主机 `8000` 映射到容器 `8000`

### 第五步：查看运行结果

```bash
docker ps
docker logs myapp
```

如果服务启动正常，就说明镜像构建和容器运行流程已经打通。

## 为什么通常先复制依赖文件

很多项目会这样写：

```dockerfile
COPY requirements.txt /app/
RUN pip install -r requirements.txt
COPY . /app
```

这样做的好处是利用镜像分层缓存。

如果只是业务代码变化，而 `requirements.txt` 没变，那么依赖安装这一层通常可以复用缓存，构建速度会更快。

## `.dockerignore` 的作用

`.dockerignore` 用于排除不需要参与构建的文件，例如：

```text
__pycache__
*.pyc
.git
.venv
node_modules
```

它的作用是：

- 减少构建上下文体积
- 加快构建速度
- 避免把无关文件打进镜像

## `CMD` 和 `RUN` 的区别

这是初学者最容易混淆的地方之一。

### `RUN`

`RUN` 发生在**镜像构建阶段**，常用于：

- 安装软件
- 安装依赖
- 执行构建步骤

### `CMD`

`CMD` 发生在**容器启动阶段**，用于指定默认启动命令。

**简单记忆：**

- `RUN` 是“构建时执行”
- `CMD` 是“启动时执行”

## 常见落地问题

### 容器一启动就退出

常见原因：

- `CMD` 写错
- 主进程执行完立即结束
- 应用实际启动失败

排查方式：

```bash
docker logs <container_name>
```

### 端口映射后仍无法访问

常见原因：

- 应用没有监听正确端口
- 容器内部端口和 `-p` 映射不一致
- 服务只监听了 `127.0.0.1`

### 镜像体积太大

常见原因：

- 基础镜像过大
- 把无关文件复制进镜像
- 安装缓存未清理

优化方向：

- 优先使用更轻量的基础镜像
- 配置 `.dockerignore`
- 合理安排构建层

## 实战理解

你可以这样理解整个过程：

- `Dockerfile`：定义“怎么打包”
- `docker build`：执行打包过程
- `Image`：打包后的产物
- `docker run`：基于产物启动容器

所以，`Dockerfile` 并不是用来运行容器的，而是用来**稳定地产生镜像**的。

## 总结

`Dockerfile` 的核心价值在于把镜像构建过程标准化、自动化、可复现。

掌握它之后，你就能把“手动搭环境”升级为：

- 写构建规则
- 构建镜像
- 启动容器
- 统一交付

这也是 `Docker` 真正落地到开发和部署流程中的关键一步。

如果需要先回到 `Docker` 的整体概念、核心对象和运行流程，可以返回 [[Docker 笔记]]。
