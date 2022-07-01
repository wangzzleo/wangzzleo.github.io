---
layout: post
title:  "Mybatis-Plus进行分页查询时，进程直接退出"
subtitle: ""
date:   2022-06-30
background: '/img/imac_bg.png'
---

# 现象描述

- 项目使用Spring Boot + mybatis-plus，当在Idea里启动服务，使用mybatis-plus的分页插件进行分页查询时候，服务就崩溃了。此现象只有在idea才会出现。使用gradle打包运行不会有此问题。

# 问题复现

项目地址：https://github.com/wangzzleo/test-mybatis-plus-crash

1. git clone [https://github.com/wangzzleo/test-mybatis-plus-crash.git](https://github.com/wangzzleo/test-mybatis-plus-crash.git)
2. 项目导入idea
3. 启动项目
4. 打开浏览器访问：[http://127.0.0.1:8080/test](http://127.0.0.1:8080/testerr)，正常返回。
5. 打开浏览器访问：[http://127.0.0.1:8080/testerr](http://127.0.0.1:8080/testerr)，crash。
6. 使用gradle构建项目，找到jar包启动。正常启动，访问上述链接，正常。

# 问题分析

进入源码发现：`mybatis-plus`的分页插件`PaginationInterceptor`，在进行分页查询时，运行到`PaginationInterceptor#queryTotal` 方法就会出错。

`Mybatis-plus` 在项目里相关的依赖如下：

![1.png](https://s2.loli.net/2022/06/30/HSNW5VCgqvzZscM.png)

![2.png](https://s2.loli.net/2022/06/30/dPkSv8r3BnRQNiZ.png)

因为项目组小伙伴需要用`mybatis-plus:3.4.1` 的新特性，所以单独引入了`implementation ('com.baomidou:mybatis-plus-core:3.4.1')` ，而另一个相关的包：`com.baomidou:mybatis-plus-extension:3.3.0` 仍使用旧3.3.0。而分页插件`PaginationInterceptor` 在`com.baomidou:mybatis-plus-extension` 包里，分页查询的方法`PaginationInterceptor#queryTotal` 里使用到了`com.baomidou:mybatis-plus-core` 的相关类：`MybatisDefaultParameterHandler` 。如下：

![3.png](https://s2.loli.net/2022/06/30/2cD6ymxnRHeIuGj.png)

这里已经出现了编译错误，根据错误提示可以看到，`MybatisDefaultParameterHandler` 类非`DefaultParameterHandler` 的子类。为什么会这样？因为`MybatisDefaultParameterHandler` 在3.4.1发生了变动，不再是`DefaultParameterHandler` 的子类。

`mybatis-plus-core:3.3.0` ：

![4.png](https://s2.loli.net/2022/06/30/rm1UWG69SVMaCpt.png)

`mybatis-plus-core:3.4.1` ：

![5.png](https://s2.loli.net/2022/06/30/gasvOMATENLmRli.png)

将`com.baomidou:mybatis-plus-extension` 升级到3.4.1即解决。

这个错误很容易定位，但是这个错误为什么只在Idea会出现？

这是因为，使用idea启动SpringBoot，是将依赖的jar使用 -classpath 加入启动参数。因为项目依赖mybatis-plus-boot-starter:3.3.0，因此间接引入依赖com.baomidou:mybatis-plus-extension:3.3.0 。而子项目依赖mybatis-plus-generator:3.4.1，间接引入com.baomidou:mybatis-plus-extension:3.4.1。Idea会将两个版本的包都加到项目的Libraries里，启动时候两个包都会加到classpath中。而具体执行时候jvm会加载哪个jar里的类？类加载器会按照顺序来加载查找到的第一个类（此处有疑问，可能会依赖类加载器的实现。出处：java - How does JVM deal with duplicate JARs of different versions - Stack Overflow）。而因为按照文件排名的顺序，3.3.0会排在3.4.1前面，这样加载的就是3.3.0的jar里的类。这样就导致启动报错。你可以试下，自己把启动参数复制出来，把3.4.1放在前面，就不会出现错误类。另外还有个问题，为什么Idea启动时候jvm没有报错，只在访问到相关的问题字节码才会出错？这是因为Idea启动Spring Boot时，会默认选中Enable launch optimization（如下图）。如果选中Enable launch optimization，则会加java启动参数：

`-noverify`，这样启动时不会校验字节码（实际此时的字节码是有问题的）。这样启动正常，但在运行到问题字节码就会出错。如果关掉该选项，启动时候则会出现字节码校验失败，无法启动。

![6.png](https://s2.loli.net/2022/06/30/yqD2vYS8WzlOtdi.png)

那为什么gradle打包完的代码，`java -jar xxx.jar` 执行时候，并没有`-noverify`此环境变量，为什么启动不会报错呢？

使用`gradle build`，打包到jar包里的，相关版本是正确的。因为gradle打包时候，如果发生依赖冲突，`gradle`会依照一定的处理原则进行处理，选择某一个依赖。（具体原则参考：[https://docs.gradle.org/current/userguide/dependency_resolution.html#sec:conflict-resolution](https://docs.gradle.org/current/userguide/dependency_resolution.html#sec:conflict-resolution)）

拓展：

1. [gradle.build](http://gradle.build) 做依赖管理的配置其实是错误的，但是为什么Idea启动时候有问题，而gradle build，打包后的jar里，相关的依赖包没有问题？ 
2. 为什么Idea启动时候要加`-noverify` 启动参数？`-noverify` 有什么作用？
3. 为什么加`-noverify` 启动参数后，运行到该代码时候进程会直接crash？
