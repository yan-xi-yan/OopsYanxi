---
title: Python 网络编程
published: 2026-04-20
description: Python 多任务与网络编程核心知识
tags:
  - Python
  - 网络编程
  - 多任务
category: Python
draft: false
---

## 1. 多任务的概念

在程序运行过程中，**多任务** 指的是同一时间段内让程序同时处理多个任务。  
在操作系统层面，这种“同时”很多时候并不是真正完全并行，而是通过 **任务切换** 让用户感觉多个任务在一起执行。

> 对网络程序来说，多任务尤其重要。  
> 因为服务端通常需要同时处理多个客户端请求，如果只能一次处理一个连接，性能和体验都会很差。

常见的多任务实现方式有：

1. **多进程**
2. **多线程**
3. **协程**

---

### 进程和线程

**进程** 和 **线程** 都是实现多任务的手段，但它们的资源管理方式和使用场景并不相同。

#### 进程

**进程** 是操作系统分配资源的基本单位。  
每启动一个程序，操作系统通常都会为它创建一个进程。

进程的特点：

1. 每个进程都有自己独立的内存空间。
2. 进程之间默认互不影响，彼此隔离。
3. 一个进程崩溃后，通常不会直接影响其他进程。
4. 进程切换开销相对较大。

可以把进程理解成一个“正在运行的程序实例”。

例如：

1. 打开的浏览器是一个进程。
2. 运行中的 Python 脚本也是一个进程。
3. 聊天软件、音乐播放器、编辑器都可能各自对应不同进程。

#### 线程

**线程** 是 CPU 调度的基本单位，也可以理解为进程内部真正执行代码的执行流。  
一个进程中至少有一个线程，这个线程通常称为 **主线程**。

线程的特点：

1. 线程依附于进程存在，不能单独存在。
2. 同一个进程中的多个线程共享进程资源。
3. 线程切换开销比进程更小。
4. 线程之间通信更方便，但也更容易发生资源竞争。

例如，一个下载工具可以：

1. 一个线程负责界面刷新。
2. 一个线程负责网络下载。
3. 一个线程负责写入文件。

> 在 CPython 中，由于 **GIL（全局解释器锁）** 的存在，多线程更适合 **IO 密集型任务**，而不适合纯 CPU 密集型并行计算。

##### GIL：全局解释器锁

**GIL** 的全称是 *Global Interpreter Lock*，即 **全局解释器锁**。  
它是 CPython 解释器中的一个机制，用来保证同一时刻只有一个线程在执行 Python 字节码。

它带来的影响主要有：

1. 多线程执行 Python 代码时，并不能真正做到多个线程同时并行计算。
2. 对于 **CPU 密集型任务**，多线程通常不能充分利用多核 CPU。
3. 对于 **IO 密集型任务**，线程在等待网络、磁盘等 IO 时会释放执行机会，因此依然很有价值。

简单理解：

1. **GIL 不是线程锁**
2. **它是 CPython 解释器层面的执行限制**
3. **它限制了 Python 多线程的计算并行能力**

#### 协程

**协程** 可以理解为一种比线程更轻量的并发方式。  
它通常运行在单线程内，通过在合适的时机主动让出执行权，实现多个任务“交替执行”。

协程的特点：

1. 创建开销很小。
2. 切换开销远低于线程。
3. 适合大量 **IO 密集型** 并发任务。
4. 通常需要配合事件循环运行。

在 Python 中，协程通常和 `asyncio` 一起使用。

##### 定义协程（异步函数）

在 Python 中，使用 `async def` 定义的函数就是 **协程函数**，调用后会得到一个协程对象。

基本示例：

```python
import asyncio


async def hello():
    print("hello")
    await asyncio.sleep(1)
    print("world")
```

说明：

1. `async def` 用来定义异步函数。
2. `await` 表示等待一个可等待对象执行完成。
3. 常见可等待对象包括协程对象、`Task`、`Future` 等。

> 协程函数仅仅“被调用”时并不会立刻执行，通常还需要交给事件循环调度。

#### 区别

| 对比项  | 进程              | 线程              | 协程                 |
| ---- | --------------- | --------------- | ------------------ |
| 资源分配 | 操作系统分配资源的基本单位   | CPU 调度的基本单位     | 用户态轻量级任务           |
| 内存空间 | 相互独立            | 共享所属进程的内存       | 共享所属线程的资源          |
| 创建开销 | 较大              | 较小              | 很小                 |
| 切换开销 | 较大              | 较小              | 很小                 |
| 通信方式 | 较复杂，需要 IPC      | 较方便，可直接共享数据     | 共享变量方便，但要注意状态管理    |
| 稳定性  | 一个进程崩溃通常不影响其他进程 | 一个线程异常可能影响整个进程  | 协程异常通常影响当前事件循环中的任务 |
| 适用场景 | 需要隔离、稳定性高的任务    | 需要频繁协作、IO 较多的任务 | 高并发 IO、网络请求、异步服务   |

简单理解：

1. **进程像一个独立的工厂**
2. **线程像工厂里的工人**
3. **协程像工人手里的任务清单，谁空闲就先处理谁**

---

## 2. Python 网络编程

在 Python 网络编程中，服务端程序通常需要同时处理多个客户端连接，因此常会结合 **多进程** 或 **多线程** 来提升并发能力。  
本节先从 Python 中的 **进程创建** 和 **进程通信** 入手，因为这些内容是后续构建并发网络服务的重要基础。

### 多进程

#### 创建一个进程

Python 中创建进程通常使用 `multiprocessing` 模块。  
它的接口风格和 `threading` 模块比较接近，使用起来相对统一。

常见导入方式：

```python
from multiprocessing import Process
```

##### 1、Process 类的说明

`Process` 类用于创建一个子进程，常见构造方式如下：

```python
Process(group=None, target=None, name=None, args=(), kwargs={}, daemon=None)
```

常用参数说明：

| 参数       | 说明                 |
| -------- | ------------------ |
| `group`  | 指定进程组，目前只能使用None   |
| `target` | 子进程要执行的目标函数        |
| `args`   | 以元组形式传递给目标函数的位置参数  |
| `kwargs` | 以字典形式传递给目标函数的关键字参数 |
| `name`   | 进程名称               |
| `daemon` | 是否设置为守护进程          |


常用方法：

| 方法            | 说明         |
| ------------- | ---------- |
| `start()`     | 启动进程       |
| `run()`       | 进程启动后执行的方法 |
| `join()`      | 阻塞等待子进程结束  |
| `is_alive()`  | 判断进程是否还在运行 |
| `terminate()` | 强制结束进程     |

> 使用多进程时，几乎都要写 `if __name__ == "__main__":`，否则在某些平台上可能出现重复创建子进程的问题。

##### 2、直接使用Process创建进程

直接传入一个函数作为 `target`，是最常见的写法。

```python
from multiprocessing import Process
import time


def work(name, count):
    for i in range(count):
        print(f"{name} 正在执行第 {i + 1} 次任务")
        time.sleep(1)


if __name__ == "__main__":
    p = Process(target=work, args=("worker-1", 3))
    p.start()
    p.join()
    print("主进程执行结束")
```

执行流程：

1. 主进程创建 `Process` 对象。
2. 调用 `start()` 启动子进程。
3. 子进程执行 `target` 对应的函数。
4. 主进程可以继续执行，也可以通过 `join()` 等待子进程结束。

##### 3、继承Process类创建进程

如果进程逻辑比较复杂，也可以通过 **继承 `Process` 类** 的方式创建进程。  
这种写法更适合封装一类任务。

```python
from multiprocessing import Process
import time


class MyProcess(Process):
    def __init__(self, name):
        super().__init__()
        self.task_name = name

    def run(self):
        for i in range(3):
            print(f"{self.task_name} 正在执行第 {i + 1} 次任务")
            time.sleep(1)


if __name__ == "__main__":
    p = MyProcess("下载任务")
    p.start()
    p.join()
```

这种方式的关键点是：

1. 继承 `Process`
2. 重写 `run()` 方法
3. 调用 `start()` 时会自动执行 `run()`

##### 4、join函数

`join()` 的作用是：**让主进程等待子进程执行结束**。

如果不使用 `join()`，主进程和子进程会并发执行；  
如果使用 `join()`，主进程会阻塞，直到对应子进程完成。

示例：

```python
from multiprocessing import Process
import time


def task():
    print("子进程开始执行")
    time.sleep(2)
    print("子进程执行结束")


if __name__ == "__main__":
    p = Process(target=task)
    p.start()

    print("主进程等待子进程...")
    p.join()
    print("主进程继续执行")
```

还可以设置超时时间：

```python
p.join(1)
```

这表示最多等待 `1` 秒，时间到了就继续往后执行。

##### 5、进程池（Pool）

当需要创建大量子进程时，如果每次都手动创建和销毁进程，开销会比较大。  
这时可以使用 **进程池 `Pool`** 来统一管理进程。

常见特点：

1. 可以限制同时运行的进程数量。
2. 避免频繁创建和销毁进程。
3. 适合批量任务处理。

基本示例：

```python
from multiprocessing import Pool
import os
import time


def worker(i):
    print(f"任务 {i} 由进程 {os.getpid()} 执行")
    time.sleep(1)
    return i * i


if __name__ == "__main__":
    pool = Pool(3)

    for i in range(5):
        pool.apply_async(worker, args=(i,))

    pool.close()
    pool.join()
    print("所有任务执行完毕")
```

常用方法：

| 方法              | 说明            |
| --------------- | ------------- |
| `apply()`       | 同步执行任务，提交后会阻塞 |
| `apply_async()` | 异步执行任务，常用     |
| `close()`       | 不再接收新任务       |
| `join()`        | 等待进程池中的任务全部完成 |
| `terminate()`   | 立即结束进程池       |


> 一般顺序是：先 `close()`，再 `join()`。  
> 如果不先关闭进程池，`join()` 通常不会正常结束等待。

---

#### 进程之间的通信

多个进程虽然相互独立，但实际开发中常常需要交换数据。  
这时就要使用 **进程间通信（IPC，Inter-Process Communication）**。

Python 中常见的进程通信方式有：

1. **队列（Queue）**
2. **管道（Pipe）**

##### 1、进程队列（Queue）通信

`Queue` 是多进程中最常用的通信方式之一。  
它的特点是 **先进先出（FIFO）**，适合生产者-消费者模型。

常见方法：

| 方法          | 说明       |
| ----------- | -------- |
| `put(data)` | 向队列中放入数据 |
| `get()`     | 从队列中取出数据 |
| `empty()`   | 判断队列是否为空 |
| `full()`    | 判断队列是否已满 |

示例：

```python
from multiprocessing import Process, Queue


def producer(q):
    for item in ["Python", "TCP", "UDP"]:
        q.put(item)
        print(f"生产数据: {item}")


def consumer(q):
    while not q.empty():
        data = q.get()
        print(f"消费数据: {data}")


if __name__ == "__main__":
    q = Queue()

    p1 = Process(target=producer, args=(q,))
    p2 = Process(target=consumer, args=(q,))

    p1.start()
    p1.join()

    p2.start()
    p2.join()
```

使用场景：

1. 主进程向子进程分发任务
2. 子进程把处理结果回传给主进程
3. 多个进程之间解耦数据流转

> `Queue` 更适合一对多、多对多的通信场景，写法也更直观。

##### 2、管道（Pipe）

`Pipe` 也可以实现进程之间通信。  
它通常返回两个连接对象，分别代表管道两端。

常见导入方式：

```python
from multiprocessing import Pipe
```

示例：

```python
from multiprocessing import Process, Pipe


def send_msg(conn):
    conn.send("你好，子进程发送了一条消息")
    conn.close()


def recv_msg(conn):
    msg = conn.recv()
    print(f"接收到消息: {msg}")
    conn.close()


if __name__ == "__main__":
    conn1, conn2 = Pipe()

    p1 = Process(target=send_msg, args=(conn1,))
    p2 = Process(target=recv_msg, args=(conn2,))

    p1.start()
    p2.start()

    p1.join()
    p2.join()
```

`Pipe` 的特点：

1. 适合两个进程之间点对点通信。
2. 使用上比 `Queue` 更底层。
3. 如果通信关系复杂，通常不如 `Queue` 方便。

### 多线程

在 Python 中，多线程通常使用 `threading` 模块实现。  
相比多进程，线程创建和切换开销更小，更适合处理 **网络请求、文件读写、数据库访问** 这类 **IO 密集型任务**。

常见导入方式：

```python
from threading import Thread
```

#### 创建线程

##### 1、直接使用 `Thread` 类

最常见的方式是直接创建 `Thread` 对象，并通过 `target` 指定线程任务。

```python
from threading import Thread
import time


def task(name):
    for i in range(3):
        print(f"{name} 正在执行第 {i + 1} 次任务")
        time.sleep(1)


if __name__ == "__main__":
    t = Thread(target=task, args=("thread-1",))
    t.start()
    t.join()
    print("主线程执行结束")
```

常用方法：

| 方法           | 说明         |
| ------------ | ---------- |
| `start()`    | 启动线程       |
| `run()`      | 线程启动后执行的方法 |
| `join()`     | 等待线程结束     |
| `is_alive()` | 判断线程是否仍在运行 |

##### 2、设置守护线程

**守护线程** 会随着主线程结束而结束。  
适合那些“辅助型任务”，例如日志监听、后台心跳检测、状态轮询等。

```python
from threading import Thread
import time


def daemon_task():
    while True:
        print("守护线程运行中...")
        time.sleep(1)


if __name__ == "__main__":
    t = Thread(target=daemon_task)
    t.daemon = True
    t.start()

    time.sleep(3)
    print("主线程结束")
```

注意：

1. 守护线程要在线程启动前设置。
2. 主线程结束后，守护线程通常不会继续单独存活。
3. 不适合用于必须完整执行完的关键任务。

##### 3、继承 `Thread` 类

如果线程逻辑较复杂，也可以通过继承 `Thread` 类并重写 `run()` 方法来实现。

```python
from threading import Thread
import time


class MyThread(Thread):
    def __init__(self, name):
        super().__init__()
        self.task_name = name

    def run(self):
        for i in range(3):
            print(f"{self.task_name} 正在执行第 {i + 1} 次任务")
            time.sleep(1)


if __name__ == "__main__":
    t = MyThread("下载线程")
    t.start()
    t.join()
```

这种方式适合：

1. 封装线程任务逻辑
2. 给线程对象增加属性
3. 让代码结构更面向对象

#### 线程安全

多个线程共享同一份数据时，如果没有同步控制，就可能出现 **线程安全问题**。  
线程安全问题的本质是：**多个线程对共享资源的访问顺序不可控**。

例如下面的代码中，两个线程同时对同一个变量做修改，就可能得到不符合预期的结果：

```python
from threading import Thread


count = 0


def add():
    global count
    for _ in range(100000):
        count += 1


if __name__ == "__main__":
    t1 = Thread(target=add)
    t2 = Thread(target=add)

    t1.start()
    t2.start()
    t1.join()
    t2.join()

    print(count)
```

线程不安全常见表现：

1. 数据丢失
2. 结果不稳定
3. 同一段代码每次运行结果不同

> 只要出现“多个线程共享同一资源并且至少有一个线程会修改该资源”的情况，就要考虑线程安全问题。

#### 互斥锁

为了解决多个线程同时访问共享资源的问题，可以使用 **互斥锁**。  
互斥锁可以保证同一时刻只有一个线程进入临界区执行代码。

##### 1、同步锁和互斥锁

在 Python 中，常说的 **同步锁**、**互斥锁**，通常指的就是 `threading.Lock()`。

基本使用流程：

1. 获取锁：`lock.acquire()`
2. 执行临界区代码
3. 释放锁：`lock.release()`

示例：

```python
from threading import Thread, Lock


count = 0
lock = Lock()


def add():
    global count
    for _ in range(100000):
        with lock:
            count += 1


if __name__ == "__main__":
    t1 = Thread(target=add)
    t2 = Thread(target=add)

    t1.start()
    t2.start()
    t1.join()
    t2.join()

    print(count)
```

互斥锁的优点：

1. 保证共享数据访问安全
2. 防止多个线程同时修改同一份数据

互斥锁的缺点：

1. 会让线程串行执行一部分代码
2. 使用不当可能降低程序效率
3. 还可能引发死锁问题

##### 2、死锁的问题

**死锁** 指的是两个或多个线程互相等待对方释放资源，结果谁也无法继续执行。

典型场景：

1. 线程 A 持有锁 1，等待锁 2
2. 线程 B 持有锁 2，等待锁 1
3. 两个线程彼此等待，程序卡住

简单示意：

```python
# 线程 A: 先拿 lock1，再等 lock2
# 线程 B: 先拿 lock2，再等 lock1
```

避免死锁的常见做法：

1. 尽量只使用一把锁
2. 多把锁时，保证加锁顺序一致
3. 获取锁后尽快释放，不要长时间持有
4. 必要时使用带超时的锁机制

### 多协程

多协程通常依赖 `asyncio` 模块来统一调度。  
它非常适合需要同时处理大量网络请求、接口调用、爬虫抓取等场景。

#### 启动多协程任务

##### 1、单个协程的启动

最基础的方式是使用 `asyncio.run()` 启动一个协程。

```python
import asyncio


async def main():
    print("协程开始")
    await asyncio.sleep(1)
    print("协程结束")


asyncio.run(main())
```

执行流程：

1. 创建事件循环。
2. 把协程交给事件循环。
3. 运行直到协程执行结束。

##### 2、多协程同步

如果按顺序 `await` 多个协程，那么它们会表现为“一个等一个”，整体是串行的。

```python
import asyncio


async def task(name):
    print(f"{name} 开始")
    await asyncio.sleep(1)
    print(f"{name} 结束")


async def main():
    await task("任务1")
    await task("任务2")


asyncio.run(main())
```

这种写法的特点是：

1. 代码简单
2. 执行顺序清晰
3. 并发能力有限

##### 3、多协程异步

如果希望多个协程并发执行，可以使用 `asyncio.gather()` 或 `asyncio.create_task()`。

使用 `gather()`：

```python
import asyncio


async def task(name):
    print(f"{name} 开始")
    await asyncio.sleep(1)
    print(f"{name} 结束")


async def main():
    await asyncio.gather(
        task("任务1"),
        task("任务2"),
        task("任务3"),
    )


asyncio.run(main())
```

这种方式适合把多个协程一次性交给事件循环统一调度。

**`gather` 是一个“并发任务收集器与同步屏障”。**
- **并发执行：** 接收多个协程时，会自动将它们转为后台并发任务。
- **同步屏障：** 强制主程序在此处停顿，直到所有任务全部执行完毕。
- **统一收集：** 将所有任务的返回值，严格按照传入的顺序打包成列表返回。
- **异常处理：** 集中处理并发过程中出现的错误。

##### 4、多任务异步

还可以先把协程包装成任务对象 `Task`，再统一等待结果。

```python
import asyncio


async def download(name):
    print(f"{name} 开始下载")
    await asyncio.sleep(1)
    print(f"{name} 下载完成")


async def main():
    task1 = asyncio.create_task(download("文件A"))
    task2 = asyncio.create_task(download("文件B"))

    await task1
    await task2


asyncio.run(main())
```

```Python
import asyncio
import time

async def worker():
    print(f"[{time.strftime('%X')}] 员工：我终于拿到 CPU，开始干活了！")

async def main():
    print(f"[{time.strftime('%X')}] 老板：创建任务 (挂到白板上)")
    task = asyncio.create_task(worker())
    
    print(f"[{time.strftime('%X')}] 老板：我还在狂敲键盘，没有交出控制权")
    # time.sleep 是同步操作，它会霸占 CPU，不会把控制权还给事件循环
    time.sleep(3) 
    
    print(f"[{time.strftime('%X')}] 老板：敲完了，现在我喝口水 (遇到 await，交出 CPU)")
    # 这一句才是真正交出控制权的开关！
    await asyncio.sleep(0) 

asyncio.run(main())
```
`Task` 的好处在于：

1. 可以单独保存任务对象
2. 可以单独取消任务
3. 可以获取任务状态和返回值

> 调用 `create_task` 的那一刻，协程被封装成了任务对象，并被成功塞进了事件循环的‘就绪队列 (Ready Queue)’中。它做好了随时被执行的准备，但只要当前的主程序没有遇到 `await` 交出 CPU 控制权，这个任务连一行代码都不会真正执行
#### 协程的返回值和监控

##### 1、获取协程结束后的返回值

协程函数和普通函数一样，也可以返回结果。

```python
import asyncio


async def add(a, b):
    await asyncio.sleep(1)
    return a + b


async def main():
    result = await add(10, 20)
    print(result)


asyncio.run(main())
```

如果是 `Task` 对象，也可以在任务执行完成后通过 `result()` 获取结果。

##### 2、强制终止协程

如果某个协程任务不再需要执行，可以调用 `cancel()` 尝试取消。

```python
import asyncio


async def work():
    try:
        while True:
            print("任务运行中...")
            await asyncio.sleep(1)
    except asyncio.CancelledError:
        print("任务被取消")
        raise


async def main():
    task = asyncio.create_task(work())
    await asyncio.sleep(2)
    task.cancel()

    try:
        await task
    except asyncio.CancelledError:
        print("取消完成")


asyncio.run(main())
```

注意：

1. `cancel()` 是发出取消请求，不一定立刻终止。
2. 协程通常会在下一个 `await` 点响应取消。

##### 3、协程任务回调

可以给 `Task` 添加回调函数，在任务结束后自动执行。

```python
import asyncio


def on_done(task):
    print("任务结果:", task.result())


async def job():
    await asyncio.sleep(1)
    return "执行完成"


async def main():
    task = asyncio.create_task(job())
    task.add_done_callback(on_done)
    await task


asyncio.run(main())
```

适用场景：

1. 任务结束后统一记录日志
2. 自动处理结果
3. 做任务状态监控
---

## 3. 补充：计算密集型 vs. IO 密集型

在学习 Python 并发时，经常会看到 **计算密集型** 和 **IO 密集型** 这两个概念。

### 计算密集型

**计算密集型任务** 指的是程序大部分时间都花在 CPU 计算上，例如：

1. 大量数学运算
2. 图像处理
3. 视频编码
4. 数据加密解密

这类任务的瓶颈通常是 **CPU 性能**。

在 Python 中：

1. 多线程不一定能显著提升纯计算任务性能
2. 更适合考虑 **多进程**

### IO 密集型

**IO 密集型任务** 指的是程序大部分时间都在等待输入输出，例如：

1. 网络请求
2. 文件读写
3. 数据库操作
4. 爬虫抓取网页

这类任务的瓶颈通常不是 CPU，而是：

1. 网络延迟
2. 磁盘速度
3. 外部服务响应时间

在 Python 中：

1. 多线程通常对 IO 密集型任务效果较好
2. 协程在高并发 IO 场景中也非常常见

### 如何选择

| 场景         | 更常见的选择   |
| ---------- | -------- |
| 纯计算任务      | 多进程      |
| 网络请求、文件读写  | 多线程 / 协程 |
| 需要进程隔离和稳定性 | 多进程      |
| 需要大量等待 IO  | 多线程或协程   |

> 简单记忆：  
> **CPU 忙，优先考虑多进程；IO 等，优先考虑多线程或协程。**