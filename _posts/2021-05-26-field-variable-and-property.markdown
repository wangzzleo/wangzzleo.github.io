---
layout: post
title:  "field、variable和property有什么区别"
subtitle: "简单学"
date:   2021-05-26
background: '/img/imac_bg.png'
---

这看起来是个无聊的文字游戏，但其实Java术语表里是有关于每一项的说明的。

参考Java的术语表  
[https://docs.oracle.com/javase/tutorial/information/glossary.html](https://docs.oracle.com/javase/tutorial/information/glossary.html)

>field  
> - A data member of a class. Unless specified otherwise, a field is not static.
> - 一个类的数据成员。除非另有规定，否则一个字段不是静态的。
>
>property
> - Characteristics of an object that users can set, such as the color of a window.
> - 用户可以设置对象的特征，如窗口的颜色。
>
>variable
> - An item of data named by an identifier. Each variable has a type, such as int or Object, and a scope. See also class variable, instance variable, local variable.
> - 由一个标识符命名的数据项。每个变量都有一个类型，如int或Object，以及一个范围。参见类变量、实例变量、局部变量。

其实`variable`还好，主要是其他两个容易混淆。

以`Thread`类为例，看下`IntelliJ IDEA`里，它是怎么区分`field`和`property`的：
打开`Structure`界面之后，菜单栏有两个功能按钮，可以分别打开`field`和`property`：

[![sSUlad.jpg](https://img-blog.csdnimg.cn/img_convert/6d72f626a68dcdcd113a9c72229d7739.png)](https://imgchr.com/i/sSUlad)

`field`和`property`前面的图标分别用`f`或`p`表示。而`property`有个小尖头可以点开，点开发现该项下面是一系列方法或者字段。基本上都是`get`、`set`这些方法。

可以看到标记为`property`的并不一定都是用户可以修改的，比如`#alive`、`#getThreads`等都是`#native`方法，并不支持用户设置。
而`#getStackTrace`则是返回`StackTraceElement`数组。

再看`Thread`类的UML类图：

[![sSaI0g.png](https://img-blog.csdnimg.cn/img_convert/acea6d7e8d0e2e40ffeb0b27cf7fe287.png)](https://imgchr.com/i/sSaI0g)

有很多其实是重合的。

不过`idea`里仅作为参考。但是我也感觉这个没必要死扣，叫哪个名字还是根据上下文语境。不过在看官方文档时候，心里还是有个关于这两者区别的概念，此时以官方描述为准。
