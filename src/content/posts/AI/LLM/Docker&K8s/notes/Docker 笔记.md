---
title: Docker 笔记
published: 2026-04-20
description: Docker 核心概念与常用操作笔记
tags:
  - Docker
  - 容器
category: Docker & K8s
draft: false
---

## 相关笔记

- 镜像构建落地说明见 [[Dockerfile 笔记]]。

## 概述

`Docker` 是一种容器化技术的实现方式，用于将应用及其运行环境一起封装、分发和运行。

**核心收益：**

- **交付更快**：构建、分发、部署流程更加统一。
- **环境一致**：开发、测试、生产环境更容易保持一致。
- **资源利用率更高**：在相同硬件上可以运行更多工作负载。
- **扩缩容更灵活**：更适合响应式部署和横向扩展。

![image.png](https://cdn.jsdelivr.net/gh/yan-xi-yan/tomato-images/img/20260401091150614.png)

## 核心组件

### `Docker Host`

`Docker Host` 指运行 `Docker` 的主机。
### `Docker daemon`

`Docker daemon` 是 `Docker` 的后台服务，负责管理：

- `Images`
- `Containers`
- 网络
- 存储
  
### `Registry`

`Registry` 是镜像仓库，用于存储和分发镜像。

## 核心对象之间的关系

理解 `Docker` 时，最重要的是分清 `Image`、`Container` 和 `Volume`。

### `Image`

`Image` 是静态模板，里面包含：

- 应用程序
- 依赖环境
- 启动命令

镜像本身不运行，它更像一个可复用的应用快照。

### `Container`

`Container` 是镜像启动后的运行实例。

可以理解为：

- `Image` 是类模板
- `Container` 是实际运行出来的对象

同一个镜像可以创建多个容器。

### `Volume`

`Volume` 是独立于容器生命周期之外的数据存储。

它的作用是：

- 保存需要长期保留的数据
- 避免容器删除后数据一起消失
- 支持多个容器共享数据

**一句话理解：**

- `Image` 负责封装应用
- `Container` 负责运行应用
- `Volume` 负责保存数据

## 执行流程

`Docker` 的典型执行流程如下：

1. 客户端通过命令向 `Docker daemon` 发送请求。
2. `Docker daemon` 在 `Docker Host` 上管理 `Images` 和 `Containers`。
3. 当本地不存在目标镜像时，`Docker daemon` 会从 `Registry` 拉取镜像。
4. 镜像下载完成后，基于镜像创建并运行容器。

**补充理解：**

- 镜像通常存储在磁盘中。
- 容器运行时主要使用内存和宿主机资源。
- 客户端本质上只是命令的发起者。

## 最小操作链路

下面是一组最基础的 `Docker` 操作链路：

```bash
docker pull nginx
docker run -d --name web -p 8080:80 nginx
docker ps
docker logs web
docker exec -it web sh
```

这组命令对应的含义是：

1. 拉取 `nginx` 镜像。
2. 基于镜像启动一个名为 `web` 的容器。
3. 将宿主机的 `8080` 端口映射到容器的 `80` 端口。
4. 查看当前正在运行的容器。
5. 查看容器日志。
6. 进入容器内部进行排查或查看文件。

## 网络与存储

### 数据卷

数据卷用于管理容器中的持久化数据，将业务数据从容器生命周期中分离出来。

### 网络模式

#### `bridge`

`bridge` 网络会为每一个容器分配一个私有 `IP`，这是默认且最常见的网络模式。

#### `host`

`host` 模式下，容器不会获得独立的 `IP`，而是直接使用宿主机网络栈。

#### `none`

`none` 模式下，容器默认不配置网络。

## 网络模式对比

| 模式       | 是否有独立 `IP` | 是否与宿主机网络隔离 | 典型场景                   |
| -------- | ---------- | ---------- | ---------------------- |
| `bridge` | 是          | 是          | 默认单机容器通信、常规应用部署        |
| `host`   | 否          | 否          | 对网络性能要求较高，或希望直接使用宿主机端口 |
| `none`   | 否          | 是          | 不需要网络，或需要自行配置网络环境      |

## 容器访问与 Shell

即使通过 `docker exec` 进入容器，也不一定存在 `bash`。

例如，`busybox` 镜像通常没有 `bash`，进入时应使用：

```bash
docker exec -it <container_name> sh
```

## 自定义网络的特性

`Docker` 在自定义网络中自带 `DNS` 服务，因此：

- 容器名通常就可以直接作为访问地址使用。

这也是多容器通信时推荐使用自定义网络的重要原因。

## `docker compose`

`docker compose` 通过一个 `.yml` 配置文件来定义多个服务，从而实现：

- 快速部署
- 统一启动
- 多容器协同管理

### 示例

下面是一个简单的双服务示例：

```yaml
services:
  web:
    image: nginx
    ports:
      - "8080:80"

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: 123456
```

它比手动执行多条 `docker run` 命令更适合管理多容器应用，因为服务关系、端口和配置都集中定义在同一个文件中。

## 镜像封装

`Docker` 的核心思想之一，就是将应用、依赖、运行环境一起封装为镜像，再基于镜像运行容器。

如果要继续深入“镜像是怎么一步步构建出来的”，应继续阅读 [[Dockerfile 笔记]]。
