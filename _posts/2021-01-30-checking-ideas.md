---
layout: post
title:  "问题排查"
subtitle: "总结常见问题的排查思路"
date:   2021-01-30
background: '/img/imac_bg.png'
---

# 问题分类

一般问题分类：

1. CPU
2. 磁盘
3. 内存
4. 网络
5. 数据库问题
6. 其他问题

# 1. CPU问题

1. top
2. top -Hp pid
3. jstack
4. 可以使用在线网站例如：[https://fastthread.io/、perfma（https://thread.console.perfma.com/）](https://fastthread.io/%E3%80%81perfma%EF%BC%88https://thread.console.perfma.com/%EF%BC%89)

## 频繁GC

1. jstat 查看gc情况
2. `XX:+PrintGC -XX:+PrintGCDateStamps -XX:+PrintGCDetails -XX:+PrintGCTimeStamps`
3. jcmd

## 上下文切换

1. vmstat 通过`cs`这一列代表上下文切换的次数
2. pidstat -w pid 对特定pid进行监控，cswch，nvcswch分别表示自愿和非自愿切换

# 2. 磁盘

1. df -hl 查看文件系统情况
2. iostat -d -k -x io情况
3. lsof -p pid 查看pid使用的文件情况

```
lsof  filename 显示打开指定文件的所有进程
lsof -a 表示两个参数都必须满足时才显示结果
lsof -c string   显示COMMAND列中包含指定字符的进程所有打开的文件
lsof -u username  显示所属user进程打开的文件
lsof -g gid 显示归属gid的进程情况
lsof +d /DIR/ 显示目录下被进程打开的文件
lsof +D /DIR/ 同上，但是会搜索目录下的所有目录，时间相对较长
lsof -d FD 显示指定文件描述符的进程
lsof -n 不将IP转换为hostname，缺省是不加上-n参数
lsof -i 用以显示符合条件的进程情况
lsof -i[46] [protocol][@hostname|hostaddr][:service|port]
            46 --> IPv4 or IPv6
            protocol --> TCP or UDP
            hostname --> Internet host name
            hostaddr --> IPv4地址
            service --> /etc/service中的 service name (可以不只一个)
            port --> 端口号 (可以不只一个)

```

1. du 查看文件大小，如果显示的层级过深，可以使用`d`（depth）制定深度。

```
df -hl：查看磁盘剩余空间
df -h：查看每个根路径的分区大小
du -sh [目录名]：返回该目录的大小
du -sm [文件夹]：返回该文件夹总M数
du -h [目录名]：查看指定文件夹下的所有文件大小（包含子文件夹）

```

# 内存

1. free 查看内存使用情况

```
total - 这个数字表示应用程序可以使用的内存总量。
used - 已使用的内存。它的计算方法是： used = total - free - buffers - cache。
free - 空闲/未使用的内存。
shared - 这一列可以忽略，因为它没有任何意义。它在这里只是为了向后兼容。
buff/cache - 内核缓冲区、页面缓存和板块使用的内存组合。如果应用程序需要，这个内存可以在任何时候被回收。如果你想让缓冲区和缓存显示在两列中，使用-w选项。
available - 估计可用于启动新应用程序的内存量，不需要交换。

```

# 3. 网络问题

[https://cloud.tencent.com/developer/article/1630364](https://cloud.tencent.com/developer/article/1630364)

- 汇总：
    - 网络配置相关：ifconfig、ip
    - 路由相关：route、netstat、ip
    - 查看端口工具：netstat、lsof、ss、nc、telnet
    - 下载工具：curl、wget、axel
    - 防火墙：iptables、ipset
    - 流量相关：iftop、nethogs
    - 连通性及响应速度：ping、traceroute、mtr、tracepath
    - 域名相关：nslookup、dig、whois
    - web服务器：python、nginx
    - 抓包相关：tcpdump
    - 网桥相关：ip、brctl、ifconfig、ovs

### ping

判断网络的连通性以及网速，偶尔还顺带当做域名解析使用

`ping google.com`

### netstat

查看**当前建立的网络连接**。最经典的案例就是查看本地系统打开了哪些端口

netstat能够查看所有的网络连接，包括unix socket连接

### lsof

查看打开的文件(list open files)，由于在Linux中一切皆文件，那socket、pipe等也是文件，因此能够查看网络连接以及网络设备

### iftop

**查看网络流量的工具**

### nc

常常作为网络应用的Debug分析器，可以根据需要创建各种不同类型的网络连接

**一个经典的用法是端口扫描**
。比如我要扫描**`192.168.56.2`主机`1~100`端口，探测哪些端口开放的:**

```markdown
~$ nc -zv 192.168.56.2 1-100 |& grep 'succeeded!'
Connection to 192.168.56.2 22 port [tcp/ssh] succeeded!
Connection to 192.168.56.2 80 port [tcp/http] succeeded!
```

### tcpdump

**命令行抓包工具**

### telnet

并不仅仅限于telnet协议，有时也**用来探测端口**

### ifconfig

网卡配置工具(configure a network interface)，我们经常使用它来查看网卡信息（比如IP地址、发送包的个数、接收包的个数、丢包个数等）以及配置网卡（开启关闭网卡、修改网络mtu、修改ip地址等）

### nslookup && dig

nslookup用于**交互式域名解析**

dig命令也是域名解析工具(DNS lookup utility)，不过提供的信息更全面

### whois

**查看域名所有者的信息**

### route

route命令用于查看和修改路由表

### ip

它完全可以替换`ifconfig`、`netstat`、`route`、`arp`等命令

### brcctl

`brctl`是linux网桥管理工具，可用于查看网桥、创建网桥、把网卡加入网桥等。

### traceroute

ping命令用于**探测两个主机间连通性以及响应速度**，而**traceroute会统计到目标主机的每一跳的网络状态**（print the route packets trace to network host），这个命令常常用于判断网络故障，**比如本地不通，可使用该命令探测出是哪个路由出问题了**

### mtr

**mtr是常用的网络诊断工具**(a network diagnostic tool)，它**把ping和traceroute并入一个程序的网络诊断工具中**并实时刷新。

### ss

ss命令也是一个查看网络连接的工具(another utility to investigate sockets),**用来显示处于活动状态的套接字信息**。

### curl

curl是强大的URL传输工具，支持FILE, FTP, HTTP, HTTPS, IMAP, LDAP, POP3,RTMP, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET以及TFTP等协议。

### wget

wget是一个强大的非交互网络下载工具（The non-interactive network downloader），虽然curl也支持文件下载，不过wget更强大，比如支持断点下载等。

### axel

axel是一个多线程下载工具（A light download accelerator for Linux），通过建立多连接，能够大幅度提高下载速度

### nethogs

我们前面介绍的iftop工具能够根据主机查看流量(by host)，而nethogs则可以根据进程查看流量信息

### iptables

**强大的包过滤工具**
，Docker、Neutron都网络配置都离不开iptables。**iptables通过一系列规则来实现数据包过滤、处理，能够实现防火墙、NAT等功能**

### ipset

以上我们通过iptables封IP，如果IP地址非常多，我们就需要加入很多的规则，这些规则需要一一判断，性能会下降（线性的）。ipset能够把多个主机放入一个集合，iptables能够针对这个集合设置规则，既方便操作，又提高了执行效率。注意**ipset并不是只能把ip放入集合，还能把网络地址、mac地址、端口等也放入到集合中**。

## OOM问题

1. 使用jmap进行堆转储`jmap -dump:format=b,file=filename pid`
2. `XX:+HeapDumpOnOutOfMemoryError`
3. 使用jcmd也可以进行堆转储

# 4. 数据库问题

## 查看锁超时时间

show variables like 'innodb_lock_wait_timeout';

## 查看锁情况

使用information_schema数据库中的表查看

## 正在执行的事务，事务的状态

select * from information_schema.innodb_trx\G

## 查看锁信息

### mysql8.0.1之前

select * from information_schema.innodb_locks\G

### mysql8.0.1之后

SELECT * FROM performance_schema.data_locks;

## 查看哪个事务因为获取不到锁而阻塞

### mysql8之前版本

select * from information_schema.innodb_locks\G

### 8之后版本

SELECT * FROM performance_schema.data_lock_waits\G

## 借助引擎状态查询事务情况

show engine innodb status\G

## 表空间id查询表

select * from information_schema.INNODB_SYS_DATAFILES where space=3431;

## 使用information_schema数据库下与事务相关的几个系统表关联查询

参考文章：[https://www.cnblogs.com/kerrycode/p/8948335.html](https://www.cnblogs.com/kerrycode/p/8948335.html)

```
SELECT b.trx_mysql_thread_id             AS 'blocked_thread_id'
      ,b.trx_query                      AS 'blocked_sql_text'
      ,c.trx_mysql_thread_id             AS 'blocker_thread_id'
      ,c.trx_query                       AS 'blocker_sql_text'
      ,( Unix_timestamp() - Unix_timestamp(c.trx_started) )
                              AS 'blocked_time'
FROM   information_schema.innodb_lock_waits a
    INNER JOIN information_schema.innodb_trx b
         ON a.requesting_trx_id = b.trx_id
    INNER JOIN information_schema.innodb_trx c
         ON a.blocking_trx_id = c.trx_id
WHERE  ( Unix_timestamp() - Unix_timestamp(c.trx_started) ) > 4;

```

```
SELECT a.sql_text,
       c.id,
       d.trx_started
FROM   performance_schema.events_statements_current a
       join performance_schema.threads b
         ON a.thread_id = b.thread_id
       join information_schema.processlist c
         ON b.processlist_id = c.id
       join information_schema.innodb_trx d
         ON c.id = d.trx_mysql_thread_id
where c.id=17
ORDER  BY d.trx_started\\G;

```

## 慢查询日志

是否开启慢查询日志

`show variables like 'slow_query_log%';`

默认的超时时间

`show variables like 'long_query_time%';`

# 5. 进程crash

> 参考文章：[https://www.cnblogs.com/rjzheng/p/11317889.html](https://www.cnblogs.com/rjzheng/p/11317889.html)