---
title: Python 高级
published: 2026-04-20
description: Python 高级特性与进阶用法
tags:
  - Python
  - 高级
category: Python
draft: false
---

## 1. Python 中的时间处理

Python 中常用 `datetime` 模块处理日期和时间。

### 获取当前时间

```python
from datetime import datetime, date, time

now = datetime.now()
today = date.today()

print(now)    # 2026-04-10 11:30:00.123456
print(today)  # 2026-04-10
```

### 构造时间对象

```python
from datetime import datetime, date, time

dt = datetime(2026, 4, 10, 11, 30, 0)
d = date(2026, 4, 10)
t = time(11, 30, 0)
```

### 时间格式化与解析

```python
from datetime import datetime

now = datetime.now()

print(now.strftime("%Y-%m-%d %H:%M:%S"))

text = "2026-04-10 11:30:00"
dt = datetime.strptime(text, "%Y-%m-%d %H:%M:%S")
print(dt)
```

常见格式符：
- `%Y`：四位年份
- `%m`：月份
- `%d`：日
- `%H`：24 小时制小时
- `%M`：分钟
- `%S`：秒

### 时间差计算

```python
from datetime import datetime, timedelta

dt1 = datetime(2026, 4, 10, 8, 0, 0)
dt2 = datetime(2026, 4, 12, 10, 30, 0)

delta = dt2 - dt1
print(delta.days)         # 2
print(delta.seconds)      # 9000
print(delta.total_seconds())

print(dt1 + timedelta(days=7))
print(dt1 - timedelta(hours=2))
```

### 时间戳

```python
from datetime import datetime

now = datetime.now()
ts = now.timestamp()
print(ts)

dt = datetime.fromtimestamp(ts)
print(dt)
```

## 2. 迭代器和生成器

### 可迭代对象与迭代器

可迭代对象：
- 能被 `for` 遍历
- 一般实现了 `__iter__()`

迭代器：
- 可以被 `next()` 不断取值
- 实现了 `__iter__()` 和 `__next__()`

```python
nums = [1, 2, 3] # 可迭代对象
it = iter(nums) # 迭代器

print(next(it))  # 1
print(next(it))  # 2
print(next(it))  # 3
```

### 自定义迭代器

```python
class Counter:
    def __init__(self, limit):
        self.limit = limit
        self.current = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self.current >= self.limit:
            raise StopIteration
        self.current += 1
        return self.current

for x in Counter(3):
    print(x)
```

### 生成器

只要函数中出现 `yield`，这个函数就不是普通函数，而是生成器函数。

```python
def gen():
    yield 1
    yield 2
    yield 3

g = gen()
print(next(g))
print(next(g))
print(next(g))
```

特点：
- 按需产出数据，节省内存
- 非常适合处理大数据、流式数据

#### 生成器与普通列表的区别

```python
lst = [x * 2 for x in range(5)]
gen = (x * 2 for x in range(5))

print(lst)  # [0, 2, 4, 6, 8]
print(gen)  # generator object
```

- 列表会一次性把结果全部放入内存
- 生成器是边迭代边计算

#### `yield from`

用于把一个生成器的产出委托给另一个可迭代对象。

```python
def sub():
    yield 1
    yield 2

def main():
    yield 0
    yield from sub()
    yield 3

print(list(main()))  # [0, 1, 2, 3]
```

#### 转换为列表 `list()`、元组 `tuple()` 
```Python
def my_generator():
    print("开始生产第一颗糖")
    yield 1
    print("开始生产第二颗糖")
    yield 2
    print("机器空了")

gen = my_generator()
print(list(gen))  
# 输出:
# 开始生产第一颗糖
# 开始生产第二颗糖
# 机器空了
# [1, 2]
```
`list()`：当它接收到一个生成器时，它为了把列表构建完整，会在内部疯狂调用 `next()`，一口气把生成器彻底**榨干**。
**为了构建一个完整的数据结构**（通常是容器类型）而调用的内置类/函数，几乎都会一口气榨干生成器，常见的有：
- `list(gen)`
- `tuple(gen)`
- `dict(gen)`
- `set(gen)`
- `sum(gen)` （求和也需要把所有数字都掏出来）
- `max(gen)` / `min(gen)`
## 3. 闭包和装饰器

### 闭包

闭包的核心：
- 函数嵌套函数
- 内部函数引用了外部函数的变量
- 外部函数返回内部函数

```python
def outer():
    num = 10

    def inner():
        print(num)

    return inner

f = outer()
f()
```

闭包的作用：
- 让函数“记住”创建时的环境
- 可以封装状态，而不必写成类

### `nonlocal`

内部函数如果要修改外层局部变量，需要使用 `nonlocal`。

```python
def counter():
    count = 0

    def inc():
        nonlocal count
        count += 1
        return count

    return inc

fn = counter()
print(fn())  # 1
print(fn())  # 2
```

### 装饰器

装饰器本质上是：
- 接收一个函数
- 返回一个新函数
- 在不修改原函数源码的情况下扩展功能

```python
def log_decorator(func):
    def wrapper(*args, **kwargs):
        print(f"调用函数：{func.__name__}")
        result = func(*args, **kwargs)
        print("调用结束")
        return result
    return wrapper

@log_decorator
def add(a, b):
    return a + b

print(add(3, 5))
```

等价写法：

```python
def add(a, b):
    return a + b

add = log_decorator(add)
```

### 带参数的装饰器

```python
def repeat(n):
    def decorator(func):
        def wrapper(*args, **kwargs):
            for _ in range(n):
                func(*args, **kwargs)
        return wrapper
    return decorator

@repeat(3)
def hello():
    print("hello")
```

> **注意**:使用带参数的Python装饰器时, 写在装饰器外的内容, 会在装饰器绑定到函数时（也就是代码刚被 Python 解释器加载，还没开始调用时）执行一次
```Python
 def simple_decorator(func):
    print("【加载时执行】装饰器正在绑定到函数上...")
    
    def wrapper(*args, **kwargs):
        print("【调用时执行】真正执行了！")
        return func(*args, **kwargs)
        
    return wrapper

@simple_decorator
def my_func():
    pass

# 即使你在这里不运行 my_func()，控制台依然会打印出“【加载时执行】...”
```
### 使用 `functools.wraps`

不使用 `wraps` 时，原函数名、文档字符串等信息会丢失。

```python
from functools import wraps

def log_decorator(func):
     # @wraps(func)
     #为了让装饰器通用, 这里用(*args, **kwargs)
    def wrapper(*args, **kwargs): 
		 # 我是装饰器
        print("before")
        return func(*args, **kwargs)
    return wrapper
```
```Python
# 假设没有使用 @wraps(func)
print(hello.__name__)  
# 输出结果会变成：'wrapper'  （它忘记自己叫 hello 了！）

print(hello.__doc__)   
# 输出结果会变成：'我是装饰器' （它把 wrapper 函数的注释当成自己的了！）
```

### 装饰器类

如果一个类实现了 `__call__()`，它的实例也可以当作装饰器使用。

```python
class CheckLogin:
    def __init__(self, func):
        self.func = func

    def __call__(self, *args, **kwargs):
        print("先检查登录状态")
        return self.func(*args, **kwargs)

@CheckLogin
def pay():
    print("付款成功")

pay()
```

这种写法适合在装饰器中保存状态，或者需要在初始化时接收额外参数的场景。

### property装饰器

`property` 可以把方法伪装成属性，让外部通过“对象.属性”的方式访问。

```python
class Student:
    def __init__(self, score):
        self._score = score

    @property
    def score(self):
        return self._score

    @score.setter
    def score(self, value):
        if not 0 <= value <= 100:
            raise ValueError("score must be between 0 and 100")
        self._score = value

stu = Student(80)
print(stu.score)
stu.score = 95
```

常见用途：
- 对属性读取和赋值做校验
- 隐藏内部实现细节
- 保持调用方式简洁 

## 4. Python的正则表达式

Python 中通常使用 `re` 模块处理正则表达式，用于字符串匹配、查找、替换和切分。

常用函数：
- `re.match()`：从字符串开头开始匹配
	- _通过span()提取匹配到的字符下标_
	- _通过group()提取匹配到的内容_
- `re.search()`：搜索第一个匹配项
- `re.findall()`：返回所有匹配结果
- `re.sub()`：把匹配到的内容替换掉

常见元字符：
1. 表示字符的元字符
	- `.`：匹配任意单个字符
	- `[]`：匹配字符集合中的任意一个
	- `\d`：匹配数字
	- `\D`：匹配非数字
	- `\w`：匹配字母、数字、下划线
	- `\W`：匹配非字母、数字、下划线
	- `\s`：匹配空白字符
	- `\S`：匹配非空白字符
2. 表示数量的元字符
	- `*`：前一个字符重复 0 次或多次
	- `+`：前一个字符重复 1 次或多次
	- `?`：前一个字符重复 0 次或 1 次
	- `{m}`：匹配前一个字符出现 m 次
	- `{m,}`：匹配前一个字符至少出现 m 次
	- `{m,n}`：匹配前一个字符出现 m 到 n 
3. 表示边界的元字符
	- `^`：匹配字符串开头
	- `$`：匹配字符串结尾
	- `\b`：匹配一个单词的边界
	- `\B`：匹配非单词的边界
4. 表示分组的元字符
	- `|`：匹配左右任意一个表达式
	- `(ab)`：将括号中字符作为一个分组
	- `\number`：匹配和前面索引为number的分组捕获到的内容一样的字符串

```python
import re

text = "联系电话：13812345678，备用电话：13900001111"

result = re.findall(r"1[3-9]\d{9}", text)
print(result)  # ['13812345678', '13900001111']

email = "test@example.com"
print(re.match(r"^\w+@\w+\.\w+$", email))

new_text = re.sub(r"\d", "*", "abc123")
print(new_text)  # abc***
```

正则表达式建议配合原始字符串使用，也就是在模式前加 `r`，这样可以减少反斜杠转义带来的混乱。

## 5. Python面对对象进阶

### 一切皆对象

1. `__class__` : 表示这个对象是谁创建的
    
2. `__bases__` ： 表示这个类的**父类**是哪个类？

```Python
class Person(object):
    pass


if __name__ == '__main__':
    print(Person.__class__)
    p = Person()
    print(p.__class__)
    print(Person.__bases__)

    print(int.__class__)
    print(int.__bases__)
```

- **type**为对象的顶点，所有对象都创建自type。
    
- **object**为类继承的顶点，所有类都继承自object。

![image.png](https://cdn.jsdelivr.net/gh/yan-xi-yan/tomato-images/img/20260410141321608.png)
### 元类:metaclass
![image.png](https://cdn.jsdelivr.net/gh/yan-xi-yan/tomato-images/img/20260410141347177.png)
#### type

在 Python 中，“一切皆对象”，类本身也是一个对象。

- **普通类**：定义了如何创建“实例对象”。
    
- **元类**：定义了如何创建“类对象”。
    
- **默认元类**：Python 中所有类的默认元类都是 `type`。

> **类本身不过是一个名为type类的实例** 


`type` 是 Python 的内置函数，但它有两种完全不同的用法：

1. **检查类型**：`type(obj)` 返回对象的类型。
    
2. **动态创建类**：`type(name, bases, dict)`
    
    - `name`: 类名（字符串）。
        
    - `bases`: 父类元组（如 `(object,)`）。
        
    - `dict`: 类的属性和方法字典。

### 元类的核心工作流

当你定义 `class MyClass(metaclass=MyMeta):` 时，Python 的创建顺序如下：

1. **拦截**：Python 解释器看到 `metaclass` 关键字，停止使用默认的 `type` 创建类。
    
2. **触发 `__new__`**：调用元类的 `__new__` 方法。这是**创建类对象**的阶段，你可以在这里修改类名、父类或属性字典（如将属性名变大写）。
    
3. **触发 `__init__`**：类对象创建完成后，进行初始化设置。
    
4. **返回类对象**：最终生成你在代码中使用的那个类。

### 元类常用方法说明

- `__new__(cls, name, bases, attrs)`:
    
    - `cls`: 元类本身。
        
    - 必须返回一个创建好的类对象（通常通过 `super().__new__`）。
        
    - **用途**：最常用的钩子，用于**修改**类的定义。
        
- `__call__(cls, *args, **kwargs)`:
    
    - 当你执行 `obj = MyClass()` 时触发。
        
    - **用途**：控制**实例化的过程**（例如实现单例模式，即无论调用多少次类都只返回同一个实例）。

```Python
class UpperMeta(type):
    def __new__(mcs, name, bases, attrs):
        # 过滤掉系统内置的双下划线属性
        new_attrs = {}
        for k, v in attrs.items():
            if not k.startswith("__"):
                new_attrs[k.upper()] = v
            else:
                new_attrs[k] = v
        return super().__new__(mcs, name, bases, new_attrs)

class User(metaclass=UpperMeta):
    role = "admin"

# 测试结果
# print(User.ROLE) -> "admin"
# print(User.role) -> AttributeError
```
## 6. 匿名函数

### `lambda`

`lambda` 用于定义简单的匿名函数。

```python
add = lambda a, b: a + b
print(add(2, 3))
```

适合：
- 临时传入一个简单函数
- 作为排序、映射、过滤的参数
## 7. 推导式与生成式

### 列表推导式

```python
nums = [x * x for x in range(1, 6)]
print(nums)  # [1, 4, 9, 16, 25]
```

带条件：

```python
evens = [x for x in range(10) if x % 2 == 0]
```

### 字典推导式

```python
dic = {x: x * x for x in range(1, 6)}
print(dic)
```

### 集合推导式

```python
s = {x % 3 for x in range(10)}
print(s)
```

### 生成器表达式

```python
g = (x * x for x in range(5))
print(next(g))
print(next(g))
```

说明：
- 语法和列表推导式很像
- 只是把 `[]` 换成 `()`
- 返回的不是列表，而是生成器


## 8. 魔术方法

魔术方法也叫双下方法，形如 `__xxx__`。

### 常见魔术方法

```python
class Student:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def __str__(self):
        return f"Student(name={self.name}, age={self.age})"

    def __len__(self):
        return self.age

s = Student("Tom", 18)
print(s)
print(len(s))
```

常见方法：
- `__init__`：初始化对象
- `__new__(cls, ...)`：向内存申请空间，真正把这个对象“无中生有”地造出来，并返回这个对象。
- `__str__`：面向用户的字符串表示。 被 `print()`、`str()` 或 `f-string` 触发。如果没定义，会退化调用 `__repr__`。
- `__repr__`：更偏向开发者视角的对象表示, 被 `repr()` 触发，或者在交互式终端（REPL）中直接回车触发。
- `__len__`：支持 `len()`
- `__call__`：让对象像函数一样调用, 执行 `obj()` 时触发。非常适合用来实现带有“记忆”或“状态”的函数（比如装饰器类）。
- `__iter__`：让对象可迭代, 被 `for` 循环或 `iter()` 触发。必须返回一个**迭代器对象**（通常就是 `self`，或者通过 `yield` 生成的生成器）。
- `__next__`：定义迭代器下一个值

### `__call__`

```python
class Adder:
    def __call__(self, a, b):
        return a + b

add = Adder()
print(add(3, 4))
```

### 特殊属性
`__dict__`：它存储了该对象所有动态绑定的实例属性。
```Python
class Point:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        
    def __iter__(self):
        # 只要 yield 产出包含两个元素的元组，dict() 就能识别
        yield 'x', self.x
        yield 'y', self.y

pt = Point(10, 20)
print(dict(pt))  # 输出: {'x': 10, 'y': 20}
```