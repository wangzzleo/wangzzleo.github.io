---
layout: post
title:  "项目中使用了哪些技术？"
subtitle: "常被问到"
date:   2020-04-22
background: '/img/imac_bg.png'
---
# Spring
1. 为什么使用Spring？
    这里引用Spring官网的描述：
    > Spring使Java编程变得更快、更简单、更安全。Spring对速度、简单性和效率的关注使其成为世界上最受欢迎的Java框架。
    > Spring makes programming Java quicker, easier, and safer for everybody. Spring’s focus on speed, simplicity, and productivity has made it the [world's most popular](https://snyk.io/blog/jvm-ecosystem-report-2018-platform-application/) Java framework.
    > "我们使用了很多Spring框架自带的工具，并收获了很多**开箱即用的解决方案，而且不用担心编写大量的额外代码**--所以这确实为我们节省了一些时间和精力。"
    > 西恩-格雷厄姆，应用转型领导，迪克体育用品公司的应用转型负责人
    > “We use a lot of the tools that come with the Spring framework and reap the benefits of having a lot of the out of the box solutions, and not having to worry about writing a ton of additional code—so that really saves us some time and energy.”
    >SEAN GRAHAM, APPLICATION TRANSFORMATION LEAD, DICK’S SPORTING GOODS

    > 1. Spring is everywhere
    >     Spring 框架无处不在，全世界的开发人员，各种公司都在使用Spring，这从侧面反映了Spring框架的稳定性。另外，广泛的使用也使得这个框架可以更早地发现其中隐藏的bug，促进了框架的安全性。同时也使得Spring开发社区十分活跃，使用过程中发现问题可以更及时、高效地解决，入门也更迅速。
    > 2. Spring is flexible
    >     Spring 是灵活的。Spring拥有众多的扩展，以及可以灵活地使用第三方库。
![官网截图](https://upload-images.jianshu.io/upload_images/13572633-692d7b9175682fb2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
    > 3. Spring is productive
    >    微服务相关的描述，我并没有使用到。
    > 4. Spring is fast
    >    速度很快。包括几个方面，首先是性能方面，速度快，其次是开发效率快，上手快。最后是可以快速构建项目（使用Spring Boot）。
    > 5. Spring is secure
    >    Spring是安全的。这也包括两方面。一是安全漏洞的修补和版本更新迭代。二是Spring的安全框架。
    > 6. Spring is supportive
    >    社区完善，这点第一点里面提到过。社区也很重要，以前我使用过IBM的产品，出问题在互联网上很难找到合适的解决方案。
2. Spring MVC
3. IOC
    这个不用说了，IOC是Spring的基础。
4. [AOP、spring-aspects](https://docs.spring.io/spring/docs/4.1.2.RELEASE/spring-framework-reference/html/aop.html#aop-introduction)
    1. 针对API：进行入参、返回结果的打印，对异常的返回结果进行进行封装。
    2. 集群环境下，为避免定时任务重复执行，针对定时任务执行前后进行加锁，解锁操作。（使用针对函数的自定义注解，参数1：缓存的key，参数２：过期时间）
5. Spring-Data-Redis
    这个不用多说了，RedisTemplate。
6. Spring-TX
    事务隔离级别
# MyBatis

# MySQL
1. 如何优化SQL
2. MySQL调优做过哪些
3. Explain的结果一定是最优的吗
4. 有没有做主从之类的

# Redis
1. 使用它做什么？
2. 分布式锁如何实现的？
3. 遇到过什么问题？锁过期时间设置了吗？如果设置了过期还未执行完怎么办？（看门狗）可重入是怎么做的？
4. 有没有用过本地缓存
5. 二八定律、热数据与冷数据、缓存学霸、缓存击穿、缓存预热、缓存更新、缓存降级。
6. Redis数据结构、如何做持久化？
7. Redis单线程为什么这么快？
8. 有没有做高可用
9. 缓存读写，数据库和缓存如何协同工作

# 使用了什么高并发技术？
1. CountDownLatch
2. 使用了什么高并发集合？
3. 使用的什么类型的线程池？用什么拒绝策略？
    Spring的ThreadPoolTaskExecutor，本质是ThreadPoolExecutor
4. 用过什么锁，有什么区别
5. 锁升级过程
# 用到了哪些设计模式？
1. 工厂模式，单例模式，建造者，代理模式之类
2. 简单实用了适配器模式：使用JAXB转换进行Bean和xml格式转换时候，一些日期格式或者别的与默认的转换格式不一致时候，使用实现了XmlAdapter 接口的自定义的适配器进行类型转换。
# Dubbo
1. 调用超时怎么办
2. 怎么做负载均衡的
3. 集群容错怎么做的
4. SPI
5. 是用Zookeeper做注册中心的注册，发现过程,以`barService`为例
    1. 服务提供者启动时: 向 /dubbo/com.foo.BarService/providers 目录下写入自己的 URL 地址
    2.  服务消费者启动时: 订阅 /dubbo/com.foo.BarService/providers 目录下的提供者 URL 地址。并向 /dubbo/com.foo.BarService/consumers 目录下写入自己的 URL 地址
    3. 监控中心启动时: 订阅 /dubbo/com.foo.BarService 目录下的所有提供者和消费者 URL 地址。
    4. 我们来验证以下：
        1. 是用zkclient连接zookeeper:`./zkCli.sh -server 127.0.0.1:2181`
        2. 查看`dubbo`节点的所有子节点：`ls /dubbo`，结果如下：  
      ![image.png](https://upload-images.jianshu.io/upload_images/13572633-d1b4e93f7225b6ee.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
        3. 随便查看一个service路径下的内容，可以看到提供者消费者都在下面。
![image.png](https://upload-images.jianshu.io/upload_images/13572633-56fbeb787177f0c4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


# Zookeeper
1. 用它做什么？（dubbo的注册中心，服务注册发现）
2. 为什么选择它？dubbo还有其他选择吗？
3. 有没有做高可用？做了，三台机器
4. zookeeper的数据结构？应用场景，如何实现分布式一致性


# 领域驱动设计
[https://kb.cnblogs.com/page/522125/](https://kb.cnblogs.com/page/522125/)

# 数据结构
1. 项目中使用过哪些数据结构
2. 对每个数据结构的了解，每个数据结构的特点，Java对他们是如何实现的
3. HashMap 数据结构，JDK8之后的改变，为什么线程不安全，并发会有什么问题
# 项目难点

# 哪里使用到了反射
1. 项目里不同的场景需要使用不同的第三方支付渠道，我将支付渠道实现类bean name写到枚举类里面，里面有支付渠道ID和bean name，再在创建场景时候，将资金与支付渠道在数据库里关联起来，这样不同的场景支付时候，先查询到支付渠道的ID，再通过id找到bean name，反射执行支付方法。

# Nginx
1. 负载均衡算法
2. 有没有做限流？怎么做的
3. Nginx有没有做高可用？用什么模型
# FastDFS

# 网络
1. 三次握手与四次挥手的原因

# 对项目对详细介绍
1. 项目如何避免超放？

# 算法
