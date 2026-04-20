---
title: Python 基础
published: 2026-04-20
description: Python 基础语法、变量与输入输出
tags:
  - Python
  - 基础
category: Python
draft: false
---

## 1. 基础语法、变量与输入输出

### 注释
- 单行注释：`# 注释内容`
- Python 中没有真正的多行注释，常见写法是连续多行 `#`。
- 三引号字符串 `'''内容'''` 或 `"""内容"""` 本质上是字符串，常用于文档说明。

### 变量
- 变量不需要先声明，直接赋值即可。
- 变量名规则：
  - 只能由字母、数字、下划线组成
  - 不能以数字开头
  - 不能使用关键字
  - 区分大小写

### 常见数据类型
- `int`：整数
- `float`：浮点数
- `str`：字符串
- `bool`：布尔值，只有 `True` 和 `False`

```python
print(type(10))       # <class 'int'>
print(type(3.14))     # <class 'float'>
print(type("hello"))  # <class 'str'>
print(type(True))     # <class 'bool'>
```

### 输入与类型转换
- `input()` 获取的结果永远是字符串。
- 需要计算时，通常要先转换类型。

```python
name = input("请输入姓名：")
age = int(input("请输入年龄："))
height = float(input("请输入身高："))
```

常用转换：
- `int(x)`：转整数
- `float(x)`：转浮点数
- `str(x)`：转字符串
- `bool(x)`：转布尔值

### 输出与格式化

```python
name = "Alice"
age = 20
score = 95.6

print(name, age, score)
print("姓名：%s，年龄：%d，成绩：%.1f" % (name, age, score))
print("姓名：{}，年龄：{}，成绩：{}".format(name, age, score))
print(f"姓名：{name}，年龄：{age}，成绩：{score}")
```

### 运算符

算术运算符：
- `**` 幂运算

逻辑运算符：
- `and` 与
- `or` 或
- `not` 非

### 真值规则
以下值通常为假：
- `False`
- `0`
- `0.0`
- `''`
- `[]`
- `()`
- `{}`
- `set()`
- `None`

## 2. 流程控制

### if 条件判断

多分支：

```python
score = 85

if score >= 90:
    print("优秀")
elif score >= 60:
    print("及格")
else:
    print("不及格")
```

条件表达式：

```python
max_num = a if a > b else b
```

### while 循环

```python
i = 1
while i <= 5:
    print(i)
    i += 1
else:
	print("while循环执行完毕")
```

### for 循环
- `for` 适合遍历序列、字符串、列表、字典、集合等可迭代对象。

```python
for ch in "python":
    print(ch)
else:
	print("for循环执行完毕")
```

### range()

```python
range(5)        # 0,1,2,3,4
range(1, 5)     # 1,2,3,4
range(1, 10, 2) # 1,3,5,7,9
```

### break、continue、pass
- `break`：结束整个循环
- `continue`：跳过本次循环，进入下一次
- `pass`：占位语句，什么都不做

```python
for i in range(5):
    if i == 2:
        continue
    if i == 4:
        break
    print(i)
```

## 3. 常用数据类型与序列操作

### 字符串 `str`
- 字符串是不可变类型。
- 支持索引、切片、遍历。

```python
s = "python"
print(s[0])      # p
print(s[-1])     # n
print(s[1:4])    # yth
print(s[::-1])   # nohtyp
```

常用方法：

```python
s = " hello python "
print(s.strip())          # 去两端空格
print(s.upper())          # 转大写
print(s.lower())          # 转小写
print(s.replace("python", "world"))
print(s.split())
print(",".join(["a", "b", "c"]))
```

### 列表 `list`
- 列表是有序、可重复、可修改的序列。

```python
nums = [1, 2, 3]
nums.append(4)
nums.insert(1, 100)
nums.remove(2)
last = nums.pop()
nums[0] = 999
```

常用操作：
- `append()` 末尾追加
- `insert()` 指定位置插入
- `extend()` 合并可迭代对象
- `remove()` 删除指定值
- `pop()` 删除并返回指定位置元素，默认最后一个
- `clear()` 清空列表
- `sort()` 原地排序
- `reverse()` 原地反转
- `enumerate(lsit)` 同时遍历索引和值

列表切片：

```python
nums = [10, 20, 30, 40, 50]
print(nums[1:4])   # [20, 30, 40]
print(nums[::-1])  # [50, 40, 30, 20, 10]
```

### 元组 `tuple`
- 元组是有序、可重复、不可修改的序列。
- 如果元组只有一个元素，必须加逗号。

```python
t1 = (1, 2, 3)
t2 = (10,)
```

### 字典 `dict`
- 字典是键值对结构，键不能重复。
- 键通常要求是不可变类型。

```python
student = {"name": "Tom", "age": 20}
student["score"] = 95
student["age"] = 21
print(student["name"])
print(student.get("gender"))   # 不存在返回 None
```

常用操作：
- `keys()`
- `values()`
- `items()`
- `get()`
- `pop()`
- `update()`

遍历：

```python
for k, v in student.items():
    print(k, v)
```

### 集合 `set`
- 集合无序、元素唯一。
- 常用于去重和集合运算。

```python
s = {1, 2, 3, 3}
print(s)   # {1, 2, 3}
```

常用运算：

```python
a = {1, 2, 3}
b = {3, 4, 5}

print(a & b)  # 交集
print(a | b)  # 并集
print(a - b)  # 差集
print(a ^ b)  # 对称差集
```

### 序列通用操作

```python
data = [10, 20, 30, 40]

print(len(data))
print(20 in data)
print(100 not in data)
for item in data:
    print(item)
```

### 可变类型与不可变类型

不可变类型：
- `int`
- `float`
- `bool`
- `str`
- `tuple`

可变类型：
- `list`
- `dict`
- `set`

```python
a = [1, 2]
b = a
a.append(3)
print(b)   # [1, 2, 3]
```

## 4. 函数

### 函数定义与调用

```python
def add(x, y):
    return x + y

result = add(3, 5)
print(result)
```

### 参数

位置参数：

```python
def info(name, age):
    print(name, age)

info("Tom", 20)
```

关键字参数：

```python
info(age=20, name="Tom")
```

默认参数：

```python
def power(x, n=2):
    return x ** n
```

不定长参数：

```python
def func(*args, **kwargs):
    print(args)
    print(kwargs)
```

说明：
- `*args` 接收多余的位置参数，结果是元组。
- `**kwargs` 接收多余的关键字参数，结果是字典。2

### 返回值
- 函数默认返回 `None`。

```python
def test():
    return 1, 2

a, b = test()
```

### 变量作用域
- 局部变量：定义在函数内部，只在函数内部有效。
- 全局变量：定义在函数外部，整个文件中通常可用。

```python
num = 100

def func():
    local_num = 10
    print(local_num)
```

修改全局变量：

```python
count = 0

def inc():
    global count
    count += 1
```

### lambda 表达式
- 适合写简单、一次性的函数。

```python
add = lambda x, y: x + y
print(add(2, 3))
```

### 高阶函数
- 函数可以作为参数传递。
- 函数也可以作为返回值返回。

```python
def calc(x, y, fn):
    return fn(x, y)

print(calc(3, 4, lambda a, b: a + b))
```

常见内置高阶函数：

```python
nums = [1, 2, 3, 4]

print(list(map(lambda x: x * 2, nums)))
print(list(filter(lambda x: x % 2 == 0, nums)))
print(sorted(nums, reverse=True))
```


推荐：

```python
def add_item(item, data=None):
    if data is None:
        data = []
    data.append(item)
    return data
```

## 5. 文件操作

### 打开与关闭文件

基本语法：

```python
file = open("test.txt", "r", encoding="utf-8")
content = file.read()
file.close()
```

使用 `with`，可自动关闭文件：

```python
with open("test.txt", "r", encoding="utf-8") as f:
    content = f.read()
```

### 常见模式
- `r`：只读
- `w`：只写，文件不存在会创建，存在会清空
- `a`：追加写入
- `b`：二进制模式
- `r+`：读写

### 常见读取方法

```python
with open("test.txt", "r", encoding="utf-8") as f:
    print(f.read())       # 一次性读取全部

with open("test.txt", "r", encoding="utf-8") as f:
    print(f.readline())   # 读取一行

with open("test.txt", "r", encoding="utf-8") as f:
    print(f.readlines())  # 读取所有行，返回列表
```

### 写入文件

```python
with open("test.txt", "w", encoding="utf-8") as f:
    f.write("hello\n")
    f.write("python")
```

### 文件夹与路径
- 常用模块：`os`
- 常见操作：
  - 判断路径是否存在
  - 创建文件夹
  - 删除文件夹
  - 遍历目录

```python
import os

print(os.path.exists("test.txt"))
os.mkdir("demo")
print(os.listdir("."))
```

### OS模块

- `os` 模块常用于和操作系统交互，例如处理路径、创建目录、遍历文件夹等。
- 其中路径相关功能经常和 `os.path` 一起使用。

```python
import os
```

### 获取当前工作目录

```python
import os

print(os.getcwd())   # 获取当前工作目录
```

### 切换工作目录

```python
import os

os.chdir("demo")
print(os.getcwd())
```

### 创建与删除目录

```python
import os

os.mkdir("test_dir")                 # 创建单级目录
os.makedirs("a/b/c", exist_ok=True)  # 创建多级目录

os.rmdir("empty_dir")                # 删除空目录
```

说明：
- `mkdir()` 只能创建一级目录。
- `makedirs()` 可以递归创建多级目录。
- `rmdir()` 只能删除空目录。

### 列出目录内容

```python
import os

print(os.listdir("."))   # 列出当前目录下的文件和文件夹
```

### 路径判断

```python
import os

path = "test.txt"

print(os.path.exists(path))   # 路径是否存在
print(os.path.isfile(path))   # 是否是文件
print(os.path.isdir(path))    # 是否是目录
```

### 路径拼接与拆分

```python
import os

path = os.path.join("Python", "notes", "test.txt")

print(path)
print(os.path.abspath(path))     # 绝对路径
print(os.path.basename(path))    # 文件名
print(os.path.dirname(path))     # 父目录
print(os.path.splitext(path))    # 分离文件名和扩展名
```

### 重命名与删除文件

```python
import os

os.rename("old.txt", "new.txt")   # 重命名
os.remove("new.txt")              # 删除文件
```

### 遍历目录

```python
import os

for root, dirs, files in os.walk("."):
    print("当前目录：", root)
    print("子目录：", dirs)
    print("文件：", files)
```

### 常见场景示例 

```python
import os

target_dir = "Python/notes"

if os.path.exists(target_dir):
    for name in os.listdir(target_dir):
        full_path = os.path.join(target_dir, name)
        if os.path.isfile(full_path):
            print("文件：", full_path)
```
## 6. 面向对象编程

### 类和对象
- 类是对象的模板。
- 对象是类创建出来的实例。

```python
class Person:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def speak(self):
        print(f"我是{self.name}")

p = Person("Tom", 20)
p.speak()
```

说明：
- `__init__` 是初始化方法。
- `self` 代表当前对象本身。

### 对象属性与类属性

```python
class Student:
    school = "Python学校"   # 类属性

    def __init__(self, name):
        self.name = name    # 对象属性
```

- 类属性属于类，多个对象共享。
- 对象属性属于对象，每个对象独立。

### 实例方法、类方法、静态方法

```python
class Demo:
    count = 0

    def instance_method(self):
        print("实例方法")

	 # 可以访问类属性, 不能访问对象属性
    @classmethod 
    def class_method(cls):
        print(cls.count)

	 # 无法得知自己属于哪个类, 不能访问类属性
    @staticmethod
    def static_method():
        print("静态方法")
```

### 继承

```python
class Animal:
    def eat(self):
        print("会吃")

class Dog(Animal):
    def bark(self):
        print("会叫")
```

- 子类会继承父类的属性和方法。

### 方法重写
- 子类中定义与父类同名的方法，会覆盖父类方法。

```python
class Animal:
    def speak(self):
        print("动物发声")

class Dog(Animal):
    def speak(self):
        print("汪汪汪")
```

### 多继承

```python
class A:
    pass

class B:
    pass

class C(A, B):
    pass
```

- Python 支持多继承。
- 方法查找顺序可通过 `类名.__mro__` 查看。

### 私有属性和私有方法
- 以双下划线开头：`__name`
- 本质是名称改写，不是绝对不能访问。

```python
class Test:
    def __init__(self):
        self.__age = 18
```

### 多态
- 关心对象能否完成某个行为，不强调对象具体类型。

```python
class Cat:
    def speak(self):
        print("喵喵")

class Dog:
    def speak(self):
        print("汪汪")

def make_sound(obj):
    obj.speak()
```

## 7. 模块、包与异常处理

### 模块导入

```python
import math
print(math.sqrt(16))
```

```python
from math import sqrt
print(sqrt(16))
```

```python
import math as m
print(m.pi)
```

### 自定义模块
- 一个 `.py` 文件就是一个模块。
- 模块中的变量、函数、类都可以被导入使用。

### `__name__`

```python
if __name__ == "__main__":
    print("当前文件被直接运行")
```

- 文件被直接运行时，`__name__` 的值是 `"__main__"`。
- 文件被导入时，`__name__` 的值是模块名。

### 包
- 包就是包含 `__init__.py` 的文件夹。
- 用于组织多个模块。

```python
from pkg1.module1 import func
```

### 异常处理

```python
try:
    num = int(input("请输入数字："))
    result = 10 / num
except ValueError:
    print("输入必须是整数")
except ZeroDivisionError:
    print("除数不能为0")
else:
    print(result)
finally:
    print("程序结束")
```

说明：
- `try`：可能出错的代码
- `except`：捕获异常
- `else`：没有异常时执行
- `finally`：无论是否异常都执行

### 抛出异常与自定义异常

```python
raise ValueError("参数错误")
```

```python
class MyError(Exception):
    pass

raise MyError("自定义异常")
```

## 8. 注意点

- `input()` 得到的是字符串
- `/` 和 `//` 的结果不同
- 列表是可变类型，字符串和元组是不可变类型
- 字典取值时，`dict[key]` 键不存在会报错，`dict.get(key)` 更安全
- 函数中修改全局变量要用 `global`
- 默认参数不要直接写可变对象
- `w` 模式会清空原文件
- 子类重写方法后，父类同名方法默认不会自动执行
