---
title: EBCC（边双连通分量） 
published: 2026-04-18       # 笔记的发布或创建日期 (格式: YYYY-MM-DD)
description: EBCC的相关笔记 # (可选) 摘要
tags: [图论]        # 文章的标签，注意用英文方括号和逗号
category: Algorithm          # 文章的所属分类
draft: false                # 是否作为草稿隐藏（设为 true 则网站上不可见）
---

# EBCC（边双连通分量） 

## 1. 定义

边双连通分量（Edge Biconnected Component, e-BCC）是无向图中的一个极大子图，满足：

- 删掉子图内任意一条边后，这个子图仍然连通。
- 等价地说，子图内不存在桥。

常见等价结论：

- 两个点属于同一个 e-BCC，当且仅当它们之间存在至少两条边不相交路径。
- 把整张图里的所有桥删掉，剩下的每个连通块就是一个 e-BCC。

## 2. 这个模板能做什么

这份模板完成了 3 件事：

1. 求无向图中的所有桥。
2. 求所有边双连通分量。
3. 把每个 e-BCC 缩成一个点，得到一棵树或森林。

复杂度：

- 时间复杂度：`O(V + E)`
- 空间复杂度：`O(V + E)`

## 3. 核心性质

### 3.1 桥的判定

设 `dfn[u]` 表示 `u` 被 DFS 首次访问的时间戳，`low[u]` 表示：

- 从 `u` 出发，
- 只走 DFS 树边向下，
- 最多经过一条返祖边，
- 能回到的最早祖先时间戳。

若 DFS 树边 `u -> v` 满足：

```cpp
low[v] > dfn[u]
```

则这条边是桥。

含义是：`v` 这棵子树无论怎么绕，都回不到 `u` 或 `u` 的祖先，所以 `u-v` 一断，图就被分开了。

### 3.2 缩点后的图一定无环

把每个 e-BCC 缩成一个点后：

- 原图中的桥，变成新图中的边。
- 新图一定是一棵树或森林。

原因很直接：

- 如果缩点图里还有环，那么环上的边都不是桥。
- 这和“缩点图中的边全部来自原图桥”矛盾。

## 4. 为什么无向图找桥必须用边编号

这是这类题最容易写错的地方。

在无向图里，一条无向边会拆成两条方向相反的邻接记录。如果你只用“父节点编号”判断回边：

```cpp
if (v == parent) continue;
```

那么遇到重边时会直接出错。

### 反例：两个点之间有两条边

```text
1 == 2
```

如果从 `1` 走到 `2` 用的是第一条边，那么从 `2` 回看 `1` 时：

- 第一条边确实是“原路返回”，应该跳过。
- 第二条边其实是一条合法返祖边，必须参与更新 `low`。

但如果你写的是 `if (v == parent) continue;`，这两条边都会被跳过，结果会把本来不是桥的边误判成桥。

所以正确做法是：

- 给每条无向边一个唯一的 `edge_id`
- DFS 时记录“进入当前点所使用的那条边编号”
- 只跳过这同一条边，而不是跳过父节点

模板里的关键写法：

```cpp
if (id == in_edge_id) continue;
```

这是支持重边的标准写法。

## 5. 模板字段说明

### 5.1 边结构

```cpp
struct Edge {
    int to;
    int id;
};
```

- `to`：边的终点
- `id`：无向边编号，同一条无向边的两个方向共用同一个 `id`

### 5.2 关键数组

- `graph[u]`：邻接表
- `dfn[u]`：DFS 访问序
- `low[u]`：追溯值
- `stk`：当前 DFS 栈中尚未归属分量的点
- `is_bridge[id]`：第 `id` 条无向边是否为桥
- `edccs`：每个 e-BCC 内包含哪些点
- `edcc_id[u]`：点 `u` 属于哪个 e-BCC

## 6. 模板流程

### 6.1 建图

```cpp
void addEdge(int u, int v) {
    graph[u].push_back({v, edge_counter});
    graph[v].push_back({u, edge_counter});
    is_bridge.push_back(0);
    edge_counter++;
}
```

无向边 `(u, v)` 会被拆成两条邻接边，但共享同一个 `edge_id`。

### 6.2 主过程

```cpp
void build() {
    for (int i = 0; i < n; i++) {
        if (!dfn[i]) {
            tarjan(i, -1);
        }
    }
}
```

因为原图可能不连通，所以要从每个未访问点出发。

### 6.3 Tarjan 过程

核心逻辑：

1. `dfn[u] = low[u] = ++timer`
2. `u` 入栈
3. 枚举所有邻边
4. 遇到未访问点就递归
5. 回溯时更新 `low`
6. 若 `low[v] > dfn[u]`，则 `u-v` 是桥
7. 若 `dfn[u] == low[u]`，说明当前形成一个 e-BCC

对应代码里的关键部分：

```cpp
if (!dfn[v]) {
    tarjan(v, id);
    low[u] = std::min(low[u], low[v]);
    if (low[v] > dfn[u]) {
        is_bridge[id] = 1;
    }
} else {
    low[u] = std::min(low[u], dfn[v]);
}
```

注意这里返祖边更新必须是：

```cpp
low[u] = min(low[u], dfn[v]);
```

不能写成 `low[v]`。这是 Tarjan 的标准写法。

## 7. 为什么 `dfn[u] == low[u]` 时可以弹出一个 e-BCC

在这份模板里，栈中存的是“点”。

当 `dfn[u] == low[u]` 时，说明：

- 从 `u` 往下这一整段 DFS 子树，
- 已经无法通过返祖边再连到 `u` 上方的点，
- 所以从栈顶到 `u` 的这些点恰好构成一个完整的边双连通分量。

代码：

```cpp
if (dfn[u] == low[u]) {
    std::vector<int> current_edcc;
    int node;
    do {
        node = stk.back();
        stk.pop_back();
        current_edcc.push_back(node);
        edcc_id[node] = edccs.size();
    } while (node != u);
    edccs.push_back(current_edcc);
}
```

## 8. 缩点图怎么建

模板里的做法：

```cpp
if (edcc_id[u] != edcc_id[v]) {
    tree[edcc_id[u]].push_back(edcc_id[v]);
}
```

含义：

- 若原图一条边的两个端点属于不同 e-BCC
- 说明它必然是一条桥
- 那么它就在缩点图中连接这两个分量

注意：

- 这里得到的是无向图邻接表，所以一条桥会在两个方向各记录一次。
- 如果你统计缩点图边数，通常要记得除以 `2`。

## 9. 使用方式

```cpp
int n = 5;
EBCC solver(n);

solver.addEdge(0, 1);
solver.addEdge(1, 2);
solver.addEdge(2, 0);
solver.addEdge(1, 3);
solver.addEdge(3, 4);

solver.build();

// 1. 判断桥
for (int id = 0; id < solver.edge_counter; id++) {
    if (solver.is_bridge[id]) {
        // id 是桥
    }
}

// 2. 查看所有 e-BCC
for (auto &comp : solver.edccs) {
    // comp 是一个边双连通分量中的所有点
}

// 3. 查看点属于哪个 e-BCC
int cid = solver.edcc_id[3];

// 4. 建缩点图
auto tree = solver.buildShrunkenGraph();
```

## 10. 例子理解

### 10.1 图结构

```text
0 - 1 - 3 - 4
 \ /
  2
```

其中：

- `0-1-2-0` 构成一个环，不存在桥
- `1-3` 是桥
- `3-4` 是桥

因此 e-BCC 为：

- `{0, 1, 2}`
- `{3}`
- `{4}`

缩点后得到一条链：

```text
{0,1,2} - {3} - {4}
```

## 11. 常见坑

### 11.1 用父节点判回边

错误写法：

```cpp
if (v == parent) continue;
```

这会在重边图上出错。

### 11.2 返祖边用 `low[v]` 更新

错误写法：

```cpp
low[u] = min(low[u], low[v]);
```

返祖边必须用 `dfn[v]` 更新。

### 11.3 忘记处理非连通图

`build()` 必须从每个未访问点都启动一次 DFS。

### 11.4 把边双和点双混了

边双连通分量看的是“删边后是否断开”，核心对象是桥。  
点双连通分量看的是“删点后是否断开”，核心对象是割点。

两者不是一个东西，模板也不同。

## 12. 适用题型

这份模板常用于：

- 求桥的数量、桥的列表
- 求每个点属于哪个边双连通分量
- 缩点后在树上做 DP
- 统计删去某条边后的连通性变化
- 处理“至少两条边不相交路径”的判定类问题

## 13. 记忆版总结

- e-BCC = 删掉所有桥之后剩下的连通块
- 无向图找桥：`low[v] > dfn[u]`
- 重边防错：跳过的是 `in_edge_id`，不是父节点
- 缩点之后得到树 / 森林
- 这份模板一次 DFS 同时求桥、e-BCC、缩点映射
