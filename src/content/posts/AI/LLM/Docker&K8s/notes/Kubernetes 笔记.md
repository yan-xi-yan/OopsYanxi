---
title: Kubernetes 笔记
published: 2026-04-20
description: Kubernetes 核心概念与容器编排实践
tags:
  - Kubernetes
  - K8s
  - 容器编排
category: Docker & K8s
draft: false
---

## 前言

`Kubernetes` 是一个用于容器编排的平台。其核心职责是**接收期望状态**、**做出调度决策**，并在实际状态与目标状态不一致时持续进行**自动对齐**。

## 整体架构

`Kubernetes` 的架构可以大致分为两部分：

- **控制平面（Control Plane）**
- **工作节点（Worker Node）**

其中，`Pod` 是 `Kubernetes` 中**最小的调度单元**。

## 控制平面

控制平面负责管理整个集群，主要职责包括：

- 接收需求
- 做出调度决策
- 持续对齐目标状态与实际状态
- 如果实际状态与目标不一致，系统会自动补齐或修复

### 核心组件

1. `kube-apiserver`
   - API 服务器
   - 集群的统一入口
   - 负责接收请求并下发信息

2. `etcd`
   - 用于存储集群的关键数据

3. `kube-scheduler`
   - 负责调度 `Pod` 到合适的节点上

4. `kube-controller-manager`
   - 负责运行各类控制器，确保集群状态持续符合预期

5. `cloud-controller-manager`
   - 负责与云厂商相关的资源进行集成和管理

## Node 节点

`Node` 是运行工作负载的节点，主要负责承载容器和执行控制平面下发的任务。

### 核心组件

1. `kubelet`
   - 负责和控制平面通信
   - 确保节点上的 `Pod` 按照预期运行

2. `Container Runtime`
   - 负责容器的实际运行
   - 例如 `containerd`、`CRI-O`

3. `kube-proxy`
   - 负责网络转发与服务访问相关能力

## 常见资源对象

以下是 `Kubernetes` 中常见的资源对象：

- `Pod`
- `Deployment`
- `Service (SVC)`
- `Ingress (Ing)`
- `ConfigMap`
- `Secret`
- `Volume`
- `StatefulSet`
- `Namespace`

### Pod

`Pod` 是 `Kubernetes` 中**最小的调度单元**，一个 `Pod` 里可以包含一个或多个容器。

- `Pod` 中的容器共享网络和存储
- 通常一个应用实例对应一个 `Pod`
- `Pod` 本身是临时资源，故障后通常不会直接手动修，而是由上层控制器重新创建

### Deployment

`Deployment` 用来管理无状态应用，是日常使用最频繁的控制器之一。

- 负责创建和管理 `Pod`
- 支持副本数量控制
- 支持滚动更新和回滚
- 适合部署 Web 服务、接口服务等**无状态应用**

可以简单理解为：**`Deployment` 负责管 `Pod` 应该有多少个、怎么更新。**

### Service

`Service` 用来给一组 `Pod` 提供一个**稳定的访问入口**。

- `Pod` 的 IP 可能会变化
- `Service` 会提供一个稳定的虚拟 IP 或域名
- 可以把流量转发到后端多个 `Pod`

常见作用：

- 做服务发现
- 做负载均衡
- 屏蔽后端 `Pod` 的变化

### Ingress

`Ingress` 主要用于管理集群外部访问到集群内部服务的规则，通常用于 `HTTP` 和 `HTTPS` 流量。

- 可以根据域名或路径转发请求
- 可以统一管理多个服务的访问入口
- 常与 `Ingress Controller` 搭配使用

可以简单理解为：**`Service` 解决服务内部暴露，`Ingress` 解决服务对外暴露。**

### ConfigMap

`ConfigMap` 用来保存**普通配置数据**。

- 例如环境变量
- 配置文件内容
- 启动参数

适合存放**非敏感信息**，并注入到容器中使用。

### Secret

`Secret` 用来保存**敏感数据**。

- 例如密码
- Token
- API Key
- 证书

它和 `ConfigMap` 的作用类似，但语义上更适合存放敏感信息。

### Volume

`Volume` 用来给 `Pod` 提供存储能力。

- 容器本身是临时的
- 如果数据只存在容器里，容器重建后数据可能丢失
- `Volume` 可以把数据独立出来

常见用途：

- 挂载配置文件
- 持久化应用数据
- 在多个容器之间共享文件

### StatefulSet

`StatefulSet` 用来管理**有状态应用**。

它和 `Deployment` 的区别在于，`StatefulSet` 更关注实例的**固定身份**和**稳定存储**。

- 每个 `Pod` 都有固定名称
- 每个 `Pod` 都可以绑定独立存储
- 适合数据库、中间件、消息队列等场景

例如：

- `MySQL`
- `Redis`
- `Kafka`

### Namespace

`Namespace` 用来对集群资源做逻辑隔离。

- 可以把不同项目放到不同命名空间
- 可以把开发、测试、生产环境区分开
- 方便做资源管理和访问控制

可以简单理解为：**`Namespace` 是集群内部的资源分组机制。**

## 调度过程

在整体运行过程中，可以理解为：

1. 用户将需求提交给控制平面
2. 控制平面根据当前集群状态做出调度决策
3. 工作节点执行调度结果并运行对应的容器
4. 控制平面持续监控实际状态
5. 如果实际状态偏离目标状态，系统会自动进行修正

## 总结

`Kubernetes` 的核心可以概括为两点：

- **`Pod` 是最小调度单元**
- **控制平面负责决策，工作节点负责执行**

从架构视角看，理解 `Control Plane`、`Node`、常见资源对象，以及基本调度过程，是学习 `Kubernetes` 的第一步。
