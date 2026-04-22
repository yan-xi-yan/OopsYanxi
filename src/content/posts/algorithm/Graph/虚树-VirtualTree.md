---
title: 虚树（Virtual Tree / Auxiliary Tree）
published: 2026-04-18       # 笔记的发布或创建日期 (格式: YYYY-MM-DD)
description: 虚树的相关笔记 # (可选) 摘要
tags: [图论]        # 文章的标签，注意用英文方括号和逗号
category: Algorithm          # 文章的所属分类
draft: false                # 是否作为草稿隐藏（设为 true 则网站上不可见）
---

# 虚树（Virtual Tree / Auxiliary Tree）

## 1. 定义

虚树用于处理“树上多次查询，每次只关心少量关键点”的问题。

给定原树上的一组关键点 `key_nodes`，虚树会：

- 保留所有关键点
- 补上必要的 LCA
- 只保留这些点之间的祖先关系

最终得到一棵规模远小于原树的“浓缩树”。

它的意义是：

- 原来一次查询可能要扫整棵树，复杂度接近 `O(N)`
- 用虚树后，只需要在与关键点相关的极少数节点上做 DP / 统计

## 2. 适用场景

典型特征：

- 原图是一棵树
- 有很多组询问
- 每次询问只给出 `K` 个关键点
- 需要在这些关键点之间做路径、覆盖、DP、贡献统计

常见题型：

- 树上关键点最短连通子图
- 树上路径覆盖 / 染色 / 切断类 DP
- 一组点之间的距离和、边权贡献
- 每次只对少量特殊点做转移的树形 DP

## 3. 核心性质

### 3.1 虚树只保留“必要节点”

虚树中的点只包含两类：

- 原询问给出的关键点
- 为了保持树结构而补上的 LCA

因此虚树规模通常很小。

### 3.2 点数上界是 `2K - 1`

设去重后的关键点数量为 `K`，则虚树中的节点总数不超过：

```text
2K - 1
```

原因：

- 每加入一个新的关键点，最多只会额外引入一个新的分叉 LCA
- 所以补点数量不会超过 `K - 1`

### 3.3 虚树保留祖先关系

虚树上的父子关系，就是原树中的祖先关系压缩后得到的关系。

因此：

- 可以直接在虚树上做树形 DP
- 如果需要边权或路径长度，可以用原树信息补回来

例如原树有 `dist[u]` 表示根到 `u` 的距离，那么虚树边 `(fa, son)` 的真实长度就是：

```cpp
dist[son] - dist[fa]
```

## 4. 预处理前提

构建虚树前，原树必须先支持以下信息：

- `dfn[u]`：DFS 序
- `depth[u]`：节点深度
- `get_lca(u, v)`：能快速查询 LCA

常见 LCA 实现：

- 倍增 LCA
- Euler Tour + RMQ
- 树剖求 LCA

## 5. 这份模板做了什么

模板接口：

```cpp
int build(std::vector<int> key_nodes,
          const std::vector<int>& dfn,
          const std::vector<int>& depth,
          const std::function<int(int, int)>& get_lca)
```

返回值：

- 返回虚树根节点编号

结果存储：

- `graph[u]`：虚树中 `u` 向下连到哪些儿子
- `used_nodes`：本次构建用到的所有节点，便于下次 `O(K)` 清空

注意这份实现的一个细节：

- 函数参数是 `std::vector<int> key_nodes`
- 这是按值传参
- 所以函数内部确实会排序、去重
- 但不会修改调用者手里的原数组

也就是说，代码行为比注释更安全。

## 6. 为什么按 DFN 排序

虚树构造的核心前提是：

```cpp
std::sort(key_nodes.begin(), key_nodes.end(),
          [&](int u, int v) { return dfn[u] < dfn[v]; });
```

原因：

- 按 DFS 序排序后，关键点在原树上的出现顺序与“子树区间”一致
- 相邻关键点之间的 LCA 足以恢复整棵虚树结构
- 配合单调栈，可以只维护一条“当前右链”

这是整套做法成立的基础。

## 7. 单调栈在维护什么

栈中维护的是：

- 当前已经处理过的点
- 在虚树中尚未完成连边的那条祖先链

可以把它理解成：

- 栈底更高
- 栈顶更深
- 栈里节点的 `dfn` 单调递增
- 同时它们在原树上形成一条“右边界链”

每来一个新点 `u`：

1. 求 `lca = LCA(u, stk.back())`
2. 如果 `lca` 在栈顶上方，说明要把一些点先退栈并连边
3. 必要时把 `lca` 作为新的分叉点插入栈
4. 再把 `u` 入栈

## 8. 模板流程拆解

### 8.1 清空上一次查询的残留

```cpp
for (int u : used_nodes) {
    graph[u].clear();
}
used_nodes.clear();
```

这是虚树模板里非常重要的优化。

不能每次都把整张 `graph` 全清空，因为：

- 原树有 `N` 个点
- 单次查询只会用到 `O(K)` 个点
- 全清空会退化成每次 `O(N)`

所以要靠 `used_nodes` 精准回收。

### 8.2 排序 + 去重

```cpp
std::sort(key_nodes.begin(), key_nodes.end(),
          [&](int u, int v) { return dfn[u] < dfn[v]; });

key_nodes.erase(std::unique(key_nodes.begin(), key_nodes.end()), key_nodes.end());
```

作用：

- 保证构造顺序正确
- 防止输入中重复关键点导致虚树出现脏结构

### 8.3 初始化栈

```cpp
std::vector<int> stk;
stk.push_back(key_nodes[0]);
used_nodes.push_back(key_nodes[0]);
```

第一个关键点先作为当前链的起点。

### 8.4 处理新关键点

核心代码：

```cpp
int u = key_nodes[i];
int lca = get_lca(u, stk.back());
```

若 `lca != stk.back()`，说明当前点 `u` 不在栈顶节点的子树内部最深位置，需要调整结构。

#### 情况 1：持续退栈

```cpp
while (stk.size() > 1 && depth[stk[stk.size() - 2]] >= depth[lca]) {
    graph[stk[stk.size() - 2]].push_back(stk.back());
    stk.pop_back();
}
```

含义：

- 只要次栈顶仍然不低于 `lca`
- 栈顶节点就已经确定应该挂到次栈顶下面
- 可以直接连边并弹出

#### 情况 2：补入 LCA 分叉点

```cpp
if (depth[stk.back()] > depth[lca]) {
    graph[lca].push_back(stk.back());
    stk.pop_back();

    if (stk.empty() || stk.back() != lca) {
        stk.push_back(lca);
        used_nodes.push_back(lca);
    }
}
```

这一步表示：

- 栈顶节点仍然在 `lca` 下方
- 但更高层已经不属于它这一支了
- 所以 `lca` 必须显式出现，作为一个新分叉点

然后再把当前节点 `u` 入栈：

```cpp
stk.push_back(u);
used_nodes.push_back(u);
```

### 8.5 收尾

```cpp
while (stk.size() > 1) {
    graph[stk[stk.size() - 2]].push_back(stk.back());
    stk.pop_back();
}
```

最终栈中剩下的一条链，依次连起来即可。

最后：

```cpp
return stk[0];
```

栈底就是虚树根。

## 9. 为什么这棵树是“有向树”

模板里建边方式是：

```cpp
graph[parent].push_back(child);
```

也就是说方向固定为：

- 父节点指向子节点

这样做的好处是：

- 直接适配树形 DP
- 不需要再带父节点参数防止走回头路
- 单次查询构出的图天然就是一棵 rooted tree

## 10. 复杂度要说准确

这份模板常被口头写成 `O(K log K)`，但严格来说应分开看：

- 排序：`O(K log K)`
- 去重：`O(K)`
- 单调栈建树：`O(K)`
- LCA 查询：一共 `O(K)` 次，每次代价取决于你的 LCA

因此总复杂度更准确地写成：

```text
O(K log K + K * T_lca)
```

若：

- `LCA = O(1)`，则整体是 `O(K log K)`
- `LCA = O(log N)`，则整体是 `O(K log K + K log N)`

## 11. 使用方式

假设你已经对原树完成了 DFS 和 LCA 预处理：

```cpp
int n = ...;
VirtualTree vt(n);

std::vector<int> key_nodes = {5, 9, 13, 20};

int root = vt.build(
    key_nodes,
    dfn,
    depth,
    [&](int u, int v) {
        return lca(u, v);
    }
);

// 在虚树上做 DP
std::function<void(int)> dfs = [&](int u) {
    for (int v : vt.graph[u]) {
        dfs(v);
    }
};

dfs(root);
```

如果题目需要知道“哪些点是原始关键点”，通常会额外维护：

```cpp
is_key[u] = true / false
```

然后在虚树 DP 时区分：

- 原始关键点
- 补出来的 LCA 点

## 12. 例子理解

设原树中查询关键点是：

```text
{4, 5, 8, 9}
```

它们在原树上的结构大致是：

```text
        1
      /   \
     2     3
    / \   / \
   4   5 8   9
```

那么虚树中需要保留的点是：

```text
{4, 5, 8, 9, 2, 3, 1}
```

虚树结构就是：

```text
        1
      /   \
     2     3
    / \   / \
   4   5 8   9
```

如果一组关键点本来几乎都落在同一条链上，虚树会更小。

比如关键点是：

```text
{10, 15, 18}
```

而这三个点祖先链很接近，那么虚树可能只包含少量补点。

## 13. 常见坑

### 13.1 没按 `dfn` 排序

不排序，整套单调栈逻辑都不成立。

### 13.2 忘记去重

重复关键点可能导致：

- 无意义重复入栈
- 虚树结构异常
- DP 统计重复

### 13.3 每次查询都整图清空

错误做法会把单次复杂度拖回 `O(N)`。

虚树模板必须利用 `used_nodes` 做局部清空。

### 13.4 把虚树边当成原树边长为 `1`

虚树中的一条边，代表原树中的一整段祖先路径。

如果题目涉及距离、边权、路径贡献，必须用原树信息恢复真实代价。

### 13.5 忘记标记关键点和补点的区别

很多题的转移只对原始关键点生效。

LCA 补点只是结构点，不一定有题意贡献。

### 13.6 节点编号体系混乱

这份模板 `graph.assign(max_nodes + 1, ...)` 默认更偏向：

- 节点编号从 `1` 开始

如果你题里是 `0` 下标，也能用，但需要整套保持一致。

## 14. 记忆版总结

- 虚树 = 关键点 + 必要 LCA 的浓缩树
- 构造顺序：`dfn` 排序 -> 去重 -> 单调栈建树
- 栈维护的是当前未完成连边的祖先链
- 虚树规模最多 `2K - 1`
- 单次构造复杂度是 `O(K log K + K * T_lca)`
- 模板中的边是“父 -> 子”的有向边，适合直接做树形 DP
