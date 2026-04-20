---
title: Docker 速查表
published: 2026-04-20
description: Docker 常用命令速查参考
tags:
  - Docker
  - 速查表
category: Docker & K8s
draft: false
---

## 1. 基础信息

### 查看版本
```bash
docker --version
docker version
```

### 查看系统信息
```bash
docker info
```

---

## 2. 镜像命令

### 搜索镜像
```bash
docker search nginx
```

### 拉取镜像
```bash
docker pull nginx
docker pull nginx:1.25
```

### 查看本地镜像
```bash
docker images
```

### 删除镜像
```bash
docker rmi nginx
docker rmi IMAGE_ID
```

### 构建镜像
```bash
docker build -t myapp:1.0 .
```

---

## 3. 容器命令

### 创建并运行容器
```bash
docker run nginx
```

### 后台运行
```bash
docker run -d nginx
```

### 指定容器名称
```bash
docker run -d --name mynginx nginx
```

### 端口映射
```bash
docker run -d -p 8080:80 nginx
```

### 挂载目录
```bash
docker run -d -v /host/data:/container/data nginx
```

### 交互式运行
```bash
docker run -it ubuntu bash
```

### 查看运行中的容器
```bash
docker ps
```

### 查看所有容器
```bash
docker ps -a
```

### 启动 / 停止 / 重启
```bash
docker start 容器名
docker stop 容器名
docker restart 容器名
```

### 强制停止
```bash
docker kill 容器名
```

### 删除容器
```bash
docker rm 容器名
docker rm -f 容器名
```

---

## 4. 日志与状态

### 查看日志
```bash
docker logs 容器名
docker logs -f 容器名
docker logs --tail 100 容器名
```

### 查看详情
```bash
docker inspect 容器名
```

### 查看资源占用
```bash
docker stats
```

---

## 5. 进入容器

### 进入容器 Shell
```bash
docker exec -it 容器名 /bin/bash
docker exec -it 容器名 /bin/sh
```

### 执行单条命令
```bash
docker exec 容器名 ls /app
```

---

## 6. 文件拷贝

### 宿主机复制到容器
```bash
docker cp ./test.txt 容器名:/tmp/
```

### 容器复制到宿主机
```bash
docker cp 容器名:/var/log/nginx/access.log ./
```

---

## 7. 镜像导入导出

### 保存镜像
```bash
docker save -o nginx.tar nginx:latest
```

### 加载镜像
```bash
docker load -i nginx.tar
```

### 导出容器
```bash
docker export 容器名 > mycontainer.tar
```

### 导入为镜像
```bash
cat mycontainer.tar | docker import - myimage:latest
```

### 提交容器为镜像
```bash
docker commit 容器名 myimage:1.0
```

---

## 8. 网络命令

### 查看网络
```bash
docker network ls
```

### 创建网络
```bash
docker network create mynet
```

### 查看网络详情
```bash
docker network inspect mynet
```

### 指定网络运行容器
```bash
docker run -d --name app1 --network mynet nginx
```

### 删除网络
```bash
docker network rm mynet
```

---

## 9. 数据卷命令

### 查看数据卷
```bash
docker volume ls
```

### 创建数据卷
```bash
docker volume create mydata
```

### 挂载数据卷
```bash
docker run -d -v mydata:/data nginx
```

### 查看数据卷详情
```bash
docker volume inspect mydata
```

### 删除数据卷
```bash
docker volume rm mydata
```

---

## 10. Docker Compose

### 启动服务
```bash
docker compose up
docker compose up -d
```

### 停止并删除服务
```bash
docker compose down
```

### 查看服务状态
```bash
docker compose ps
```

### 查看日志
```bash
docker compose logs
docker compose logs -f
```

### 重新构建并启动
```bash
docker compose up -d --build
```

---

## 11. 清理命令

### 删除停止的容器
```bash
docker container prune
```

### 删除未使用的镜像
```bash
docker image prune
```

### 删除未使用的网络
```bash
docker network prune
```

### 删除未使用的数据卷
```bash
docker volume prune
```

### 一键清理无用资源
```bash
docker system prune
docker system prune -a
```

---

## 12. `docker run` 常用参数

```bash
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
```

- `-d`：后台运行
- `-it`：交互式运行
- `--name`：指定容器名
- `-p`：端口映射
- `-v`：挂载目录或数据卷
- `--rm`：退出后自动删除
- `-e`：设置环境变量
- `--network`：指定网络
- `--restart`：设置重启策略

示例：
```bash
docker run -d \
  --name web \
  -p 8080:80 \
  -v /data/html:/usr/share/nginx/html \
  --restart always \
  nginx
```

---

## 13. 常用实战示例

### 启动一个 Nginx
```bash
docker run -d --name nginx1 -p 8080:80 nginx
```

### 启动一个 MySQL
```bash
docker run -d \
  --name mysql1 \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=123456 \
  mysql:8.0
```

### 进入 MySQL 容器
```bash
docker exec -it mysql1 bash
```

### 查看 MySQL 日志
```bash
docker logs -f mysql1
```

---

## 14. 建议优先掌握

1. `docker pull`
2. `docker images`
3. `docker run`
4. `docker ps`
5. `docker logs`
6. `docker exec`
7. `docker stop`
8. `docker start`
9. `docker rm`
10. `docker build`
11. `docker compose up`
12. `docker compose down`
