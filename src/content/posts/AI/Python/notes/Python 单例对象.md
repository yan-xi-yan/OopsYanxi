---
title: Python 单例对象
published: 2026-04-20
description: Python 单例设计模式的原理与实现
tags:
  - Python
  - 设计模式
category: Python
draft: false
---

单例（Singleton）是一种常见设计模式，核心目标只有一句话：

- 一个类只创建一个实例
- 后续再次调用这个类时，拿到的还是同一个对象

比如日志器、配置对象、数据库连接管理器，这些场景通常都希望“全局只有一份”。

---

## 1. 先理解：`类名()` 到底做了什么

很多人一看到单例，就急着背代码。但单例的关键，其实是先搞清楚：

```python
obj = MyClass()
```

这行代码背后，Python 到底做了哪些事。

### 1.1 普通类视角：`__new__` 和 `__init__`

当执行 `MyClass()` 时，通常会经历两步：

1. `__new__`：先创建对象
2. `__init__`：再初始化对象

可以把它理解成：
``
- `__new__` 负责“把人生出来”
- `__init__` 负责“给这个人穿衣服、填属性”

示例：

```python
class Person:
    def __new__(cls, *args, **kwargs):
        print("1. 执行 __new__：创建对象")
        obj = super().__new__(cls)
        return obj

    def __init__(self, name):
        print("2. 执行 __init__：初始化对象")
        self.name = name


p = Person("Tom")
```

输出顺序是：

```python
1. 执行 __new__：创建对象
2. 执行 __init__：初始化对象
```

结论：

- `__new__` 先执行
- `__new__` 必须返回一个实例对象，后面的 `__init__` 才能继续执行
- `__init__` 不负责创建对象，它只负责初始化已经创建好的对象

---

### 1.2 元类视角：真正触发创建流程的是 `type.__call__`

表面上看，我们写的是 `MyClass()`，像是在“调用类”。

实际上：

- `MyClass` 本身也是一个对象
- `MyClass` 的类型通常是 `type`
- 当你写 `MyClass()` 时，本质上调用的是元类 `type` 的 `__call__`

可以粗略理解成下面这段伪代码：

```python
def type_call(cls, *args, **kwargs):
    obj = cls.__new__(cls, *args, **kwargs)
    if isinstance(obj, cls):
        cls.__init__(obj, *args, **kwargs)
    return obj
```

也就是说，`类名()` 背后大致是这样的链路：

```python
类名() 
-> type.__call__()
-> 类.__new__()
-> 类.__init__()
-> 返回实例对象
```

这就是单例设计的切入点：

- 如果你想控制“对象怎么创建”，就改 `__new__`
- 如果你想控制“类被调用时怎么返回实例”，就改元类的 `__call__`

---

### 1.3 一个必须记住的规则：括号会触发“所属类”的 `__call__`

这个点非常关键，也是很多人第一次学元类时最容易绕晕的地方。

在 Python 里，给谁加括号，本质上就是在请求“调用”谁。但真正被查找的，不是这个对象自己内部的某个普通方法，而是它的“所属类”里的 `__call__`。

先看普通对象：

```python
class Person:
    def __call__(self):
        print("实例被调用了")


p = Person()
p()
```

这里为什么 `p()` 能执行？

- 因为 `p` 是 `Person` 的实例
- 所以 `p()` 会去找 `Person.__call__`

再看类对象：

```python
class Person:
    pass


p = Person()
```

这里为什么 `Person()` 能创建实例？

- 因为 `Person` 本身也是一个对象
- `Person` 的所属类是 `type`
- 所以 `Person()` 本质上触发的是 `type.__call__`

一句话记忆：

- `p()` 这种写法，找的是 `Person.__call__`
- `Person()` 这种写法，找的是 `type.__call__`

---

### 1.4 两条链不要混：实例链和继承链

很多人会继续追问：

- 既然 `Person` 继承自 `object`
- 那么执行 `Person()` 时，为什么不是先去 `object` 那里找 `__call__`？

答案是：因为这里走的是两条完全不同的链。

#### 第一条链：实例链

实例链回答的是：

- “这个对象是谁造出来的？”
- “调用它时，应该去谁那里找 `__call__`？”

对于 `Person` 来说：

```python
Person -> type
```

所以 `Person()` 查找的是 `type.__call__`。

#### 第二条链：继承链

继承链回答的是：

- “这个类没有某个方法时，应该沿着哪个父类继续找？”

对于普通类 `Person` 来说：

```python
Person -> object
```

所以当 `type.__call__` 内部去执行：

```python
obj = cls.__new__(cls, *args, **kwargs)
```

如果 `Person` 自己没有写 `__new__`，这时才会沿着继承链找到 `object.__new__`。

可以把整个过程记成一句口诀：

- 加括号调用时，先找元类的 `__call__`
- 真正分配内存时，再沿继承链找父类的 `__new__`

---

## 2. `__new__`、`__init__`、`__call__` 分别是什么

这三个魔法方法很容易混在一起，必须区分清楚。

### 2.1 `__new__`

作用：

- 创建实例对象
- 是实例化流程中最早执行的方法

特点：

- 第一个参数是 `cls`
- 通常要返回一个对象
- 常用于不可变类型定制、对象创建控制、单例等场景

示例：

```python
class Demo:
    def __new__(cls, *args, **kwargs):
        print("__new__")
        return super().__new__(cls)
```

---

### 2.2 `__init__`

作用：

- 初始化对象属性

特点：

- 第一个参数是 `self`
- 不负责返回对象
- 如果写了 `return` 非 `None`，会报错

示例：

```python
class Demo:
    def __init__(self, name):
        print("__init__")
        self.name = name
```

---

### 2.3 `__call__`

作用：

- 让“对象”像函数一样被调用

示例：

```python
class Dog:
    def __call__(self):
        print("汪汪汪")


d = Dog()
d()
```

这里触发的是实例对象 `d` 的 `__call__`，不是创建对象。

---

### 2.4 `__call__` 和 `__new__` 的区别

最容易混淆的点在这里：

- `__new__` 关心的是“对象怎么被创建出来”
- `__call__` 关心的是“对象或类被调用时怎么执行”

分两种情况理解：

1. 在普通实例对象中

- `obj()` 会触发实例的 `__call__`
- 这是“对象像函数一样被调用”

2. 在元类中

- `ClassName()` 会先触发元类的 `__call__`
- 这是“类对象被调用”
- 元类的 `__call__` 内部通常再去调用类的 `__new__` 和 `__init__`

一句话总结：

- `__new__` 是“造对象”
- `__init__` 是“初始化对象”
- `__call__` 是“处理调用动作”

---

## 3. 方式一：通过类属性控制单例

这是最常见、最容易理解的写法。核心思路是：

- 类中保存一个 `_instance`
- 第一次创建时，真正生成对象
- 后续再创建时，直接返回第一次创建的对象

### 3.1 基础写法

```python
class SingletonPerson:
    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            print("第一次创建对象")
            cls._instance = super().__new__(cls)
        else:
            print("对象已存在，直接返回旧对象")
        return cls._instance


p1 = SingletonPerson()
p2 = SingletonPerson()

print(p1 is p2)   # True
print(id(p1))
print(id(p2))
```

这段代码已经实现了“只创建一个对象”。

---

### 3.2 一个很重要的坑：`__init__` 可能会重复执行

很多人以为对象只有一个，`__init__` 就只会执行一次。其实不一定。

看下面的例子：

```python
class SingletonPerson:
    _instance = None

    def __new__(cls, name):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, name):
        print("__init__ 执行了")
        self.name = name


p1 = SingletonPerson("Tom")
p2 = SingletonPerson("Jack")

print(p1 is p2)        # True
print(p1.name)         # Jack
print(p2.name)         # Jack
```

原因是：

- `__new__` 的确只创建了一次对象
- 但每次写 `SingletonPerson(...)` 时，类还是会被调用
- 元类的 `__call__` 在拿到对象后，仍然可能继续执行 `__init__`

所以：

- “实例只有一个”
- 不代表“初始化只执行一次”

---

### 3.3 更稳妥的写法：增加初始化保护

```python
class SingletonPerson:
    _instance = None
    _initialized = False

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def __init__(self, name, age):
        if self.__class__._initialized:
            return

        self.name = name
        self.age = age
        self.__class__._initialized = True


p1 = SingletonPerson("Tom", 20)
p2 = SingletonPerson("Jack", 30)

print(p1 is p2)        # True
print(p1.name, p1.age) # Tom 20
print(p2.name, p2.age) # Tom 20
```

这才是更符合预期的“单例”效果：

- 对象只创建一次
- 初始化逻辑也只执行一次

---

## 4. `super(SingletonPerson, cls).__new__(cls)` 到底在做什么

这是单例代码里最容易卡住的一行。

先看经典写法：

```python
cls._instance = super(SingletonPerson, cls).__new__(cls)
```

它的作用可以拆成两部分理解。

### 4.1 为什么要调用 `super().__new__(cls)`

因为你虽然重写了 `__new__`，但你自己并不会“真正制造对象”。

你写的 `__new__` 更多是在做“流程控制”：

- 要不要创建
- 创建几次
- 返回哪个对象

真正负责从底层分配内存、构造实例对象的，通常还是父类的 `__new__`，也就是最终走到 `object.__new__`。

所以这句代码的意思是：

- “我决定现在要创建对象了”
- “具体怎么创建，交给父类去做”

---

### 4.2 `super(SingletonPerson, cls)` 这两个参数是什么意思

这是一种完整写法：

- `SingletonPerson`：从这个类开始找父类
- `cls`：把当前类对象绑定进去

在 Python 3 中，更常见、更简洁的写法是：

```python
cls._instance = super().__new__(cls)
```

通常推荐直接写这一种。

---

### 4.3 为什么一般不要写成 `super().__new__(cls, *args, **kwargs)`

因为最顶层的 `object.__new__()` 通常只需要类本身，不接受业务参数。

也就是说，下面这种写法在很多场景中并不合适：

```python
super().__new__(cls, *args, **kwargs)
```

更稳妥的写法是：

```python
super().__new__(cls)
```

业务参数交给 `__init__` 去处理更合理。

---

## 5. 方式二：通过元类实现单例

如果你希望“多个类都能复用单例逻辑”，那么元类方式更合适。

核心思路是：

- 拦截“类被调用”这件事
- 第一次调用时真正创建实例
- 以后直接返回缓存对象

### 5.1 元类版本代码

```python
class SingletonMeta(type):
    _instances = {}

    def __call__(cls, *args, **kwargs):
        if cls not in cls._instances:
            print(f"为 {cls.__name__} 创建新对象")
            cls._instances[cls] = super().__call__(*args, **kwargs)
        else:
            print(f"{cls.__name__} 已存在，直接返回旧对象")
        return cls._instances[cls]


class Config(metaclass=SingletonMeta):
    def __init__(self, env):
        print("执行 Config.__init__")
        self.env = env


c1 = Config("dev")
c2 = Config("prod")

print(c1 is c2)   # True
print(c1.env)     # dev
print(c2.env)     # dev
```

---

### 5.2 元类里的 `__init__` 在初始化谁

除了重写元类的 `__call__`，还可以顺手看看元类的 `__init__`。

很多人第一次看到这段代码会疑惑：

- 元类 `__init__` 里的 `self` 到底是谁？

答案是：

- 在普通类中，`__init__(self)` 里的 `self` 是实例对象
- 在元类中，`__init__(self, name, bases, attrs)` 里的 `self` 是“刚创建出来的类对象本身”

也就是说，下面代码里的 `self` 不是某个实例，而是 `Person` 这个类：

```python
class SingletonMeta(type):
    def __init__(self, name, bases, attrs):
        super().__init__(name, bases, attrs)
        self._instance = None


class Person(metaclass=SingletonMeta):
    pass


print(Person._instance)  # None
```

这段代码本质上相当于在类创建完成时，动态给类绑定了一个属性：

```python
Person._instance = None
```

这也是为什么有些元类单例实现，会把缓存实例的属性挂在类对象本身上。

---

### 5.3 为什么元类写法更自然

因为它直接拦截了最外层的 `ClassName()` 调用。

回忆前面的流程：

```python
ClassName()
-> 元类.__call__()
-> Class.__new__()
-> Class.__init__()
```

元类版单例直接改写了第一层入口：

- 如果实例不存在，才执行 `super().__call__()`
- 而 `super().__call__()` 才会继续触发 `__new__` 和 `__init__`
- 如果实例已经存在，就直接返回缓存对象

因此它天然避免了“每次都重新走一次 `__init__`”的问题。

---

### 5.4 另一种元类单例写法

如果你想把“缓存实例”直接挂到每个类自己身上，也可以这样写：

```python
class SingletonMeta(type):
    def __init__(self, name, bases, attrs):
        super().__init__(name, bases, attrs)
        self._instance = None

    def __call__(self, *args, **kwargs):
        if self._instance is None:
            self._instance = super().__call__(*args, **kwargs)
        return self._instance


class Person(metaclass=SingletonMeta):
    def __init__(self, name):
        self.name = name


p1 = Person("Tom")
p2 = Person("Jack")

print(p1 is p2)   # True
print(p1.name)    # Tom
```

这里的关键理解是：

- `self` 在元类的 `__call__` 中，指的不是实例 `p1`
- `self` 指的是类对象 `Person`
- 所以 `self._instance` 本质上就是 `Person._instance`

---

## 6. 两种单例写法对比

### 6.1 类属性版

优点：

- 简单直接
- 适合入门理解
- 单个类使用时足够方便

缺点：

- 每个类都要重复写一套逻辑
- 如果处理不当，`__init__` 可能重复执行

---

### 6.2 元类版

优点：

- 复用性更强
- 更接近“从实例化入口统一控制”
- 多个类都能直接复用

缺点：

- 理解门槛更高
- 需要先明白元类和 `__call__` 的关系

---

## 7. 一个完整的理解链路

现在把整个过程串起来：

当你写下：

```python
obj = MyClass()
```

Python 大致会这样处理：

1. 先调用元类的 `__call__`
2. 元类的 `__call__` 再调用类的 `__new__`
3. `__new__` 负责创建并返回实例
4. 元类的 `__call__` 再调用类的 `__init__`
5. 返回最终对象

如果使用元类单例，还可以继续细化为：

1. 解释器执行 `class Person(metaclass=SingletonMeta): ...`
2. 先创建出类对象 `Person`
3. 执行 `SingletonMeta.__init__`，此时 `self` 就是类对象 `Person`
4. 给 `Person` 挂上 `_instance` 等类级别属性
5. 第一次执行 `Person()` 时，进入 `SingletonMeta.__call__`
6. 发现 `Person._instance` 为空，于是调用 `super().__call__()` 真正创建实例
7. 第二次执行 `Person()` 时，直接返回 `Person._instance`

所以单例有两种典型切入位置：

- 在 `__new__` 中拦截：控制“对象只能被创建一次”
- 在元类 `__call__` 中拦截：控制“类只能真正实例化一次”

---

## 8. 使用单例时的注意点

### 8.1 单例不等于全局变量

单例是“某个类只有一个实例”。

它仍然是对象，仍然有方法、属性、封装，不是简单地拿一个全局变量替代。

---

### 8.2 单例容易隐藏状态共享问题

因为所有地方拿到的都是同一个对象，所以一个地方改了属性，其他地方都会看到变化。

这很方便，但也可能让程序变得难以排查。

---

### 8.3 多线程场景要额外小心

本文的两种写法都只是基础版。

如果在多线程环境下同时创建对象，可能会出现竞争问题，导致创建出多个实例。那时还需要加锁处理。

---

## 9. 小结

记住下面这几句话就够了：

- `__new__` 负责创建对象
- `__init__` 负责初始化对象
- `__call__` 负责处理“调用”这件事
- `类名()` 背后真正先触发的，是元类的 `__call__`
- 单例的本质，是控制“实例只能产生一次”

如果只是写一个类的单例，用重写 `__new__` 就够了。

如果要让多个类复用这套机制，用元类更合适。
