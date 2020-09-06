---
layout: post
title:  "疑似MySQL Java驱动的bug"
subtitle: ""
date:   2020-09-07
background: '/img/imac_bg.png'
---



# 背景
项目组最近遇到了一个问题，各应用执行SQL偶尔会变慢，而且无规律可循。因为一些原因，最近数据库环境进行了迁移，访问数据库中间多了一层硬件防火墙，应用服务器也安装了一些杀毒软件。

# 描述
## 项目环境
JDK：1.8
数据库：MySQL 5.5
数据库连接池：alibaba Druid 1.1.5/1.1.23
MySQL驱动版本：mysql-connector-java 5.1.38/8.0.21
ps：上面列出两个版本是想说明最新版本有同样的问题。

## 数据库连接池配置

```xml
<bean id="dataSource" class="com.alibaba.druid.pool.DruidDataSource"
      init-method="init" destroy-method="close">
    <property name="driverClassName" value="com.mysql.jdbc.Driver"/>
    <!--或者使用～>8.0.0版本的下面这个驱动类-->
    <!--<property name="driverClassName" value="com.mysql.jdbc.Driver"/>-->
    <property name="url" value="${jdbc.url}"/>
    <property name="username" value="${jdbc.username}"/>
    <property name="password" value="${jdbc.password}"/>

    <!-- 配置初始化大小、最小、最大 -->
    <property name="initialSize" value="10"/>
    <property name="minIdle" value="10"/>
    <property name="maxActive" value="50"/>

    <property name="timeBetweenEvictionRunsMillis" value="60000"/>
    <property name="minEvictableIdleTimeMillis" value="300000"/>

    <property name="testWhileIdle" value="true"/>
    <property name="testOnBorrow" value="false"/>
    <property name="testOnReturn" value="false"/>

    <property name="poolPreparedStatements" value="true"/>
    <property name="maxOpenPreparedStatements" value="20"/>

    <!-- 配置监控统计拦截的filters，wall用于防止sql注入，stat用于统计分析 -->
    <property name="filters" value="wall,stat"/>
</bean>
```

需要注意的是，按照官方说明，这里的配置是有问题的，后面会说到。具体配置请看文档：[DruidDataSource配置属性列表](https://github.com/alibaba/druid/wiki/DruidDataSource%E9%85%8D%E7%BD%AE%E5%B1%9E%E6%80%A7%E5%88%97%E8%A1%A8)

## 异常描述
### 异常1
SQL执行时间变长前后的日志有如下的异常栈：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200902213813200.PNG?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
可以看到线程`Druid-ConnectionPool-Create-xxx`在执行`SocketInputStream#socketRead0`这个本地方法时超时，这里是在读取响应数据的时候超时的，也就是请求数据已经发送出去了，猜测是连接已经建立了，等待读取数据时候超时的？

### 异常2
后续又发现，应用服务启动时候会阻塞在某个地方导致启动失败，失败时候的线程堆栈dump如下（使用的是[perfma的在线分析工具](https://thread.console.perfma.com/)）：

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200902232551817.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)

通过结果可以看出启动线程同样卡在`SocketInputStream#socketRead0`方法里。

对于以上现象的分析：
上面两种情况都是卡在了读取数据时候，所以猜测是服务器返回的包在中间某个环节丢失了？（中间加了硬件防火墙和服务器的防火墙，所以肯定是这两个环节的问题）后来就将其中一个应用服务器节点上防火墙停掉了，结果情况并没有改善，所以排除了服务器防火墙的原因。而因为别的原因，硬件防火墙没办法查看分析，提议运维抓包又一直没抓，所以只能瞎猜原因。后面看到的现象是如果多启动几次应用服务会启动成功，所以猜测是某些端口的原因，这个问题没办法只能搁置了，不过总得解决，这个后续还要继续分析，等待更新。这个不是本文重点，重点是接下来的点。

### 异常3
在发现异常1的时候，开始时候分析是数据库连接池的连接已经中断，继续使用连接导致的（现在看来不是这个原因），而druid配置的检查连接是否有效的时间间隔太长甚至是配置可能未生效导致的，所以通过查看Druid的文档，发现我们的配置确实是有问题：

> validationQuery：用来检测连接是否有效的sql，要求是一个查询语句，常用select 'x'。如果validationQuery为null，testOnBorrow、testOnReturn、testWhileIdle都不会起作用。

从上面看到，需要加上`validationQuery`这个参数。加上之后debug发现`Destroy线程会检测连接`依然没有检查连接是否有效，所以决定查看源码，`Destroy线程`线程的核心方法是`shrink(boolean checkTime, boolean keepAlive)`方法，该方法中与检查连接有效性相关的代码片段如下（部分代码）：
```java

int keepAliveCount = 0;
for (int i = 0; i < poolingCount; ++i) {
    DruidConnectionHolder connection = connections[i];
    if ((onFatalError || fatalErrorIncrement > 0) && (lastFatalErrorTimeMillis > connection.connectTimeMillis))  {
         keepAliveConnections[keepAliveCount++] = connection;
         continue;
    }
    long idleMillis = currentTimeMillis - connection.lastActiveTimeMillis;
    if (idleMillis < minEvictableIdleTimeMillis
           & idleMillis < keepAliveBetweenTimeMillis
    ) {
        break;
    }
    if (keepAlive && idleMillis >= keepAliveBetweenTimeMillis) {
        keepAliveConnections[keepAliveCount++] = connection;
    }
}
if (keepAliveCount > 0) {
    // keep order
    for (int i = keepAliveCount - 1; i >= 0; --i) {
        DruidConnectionHolder holer = keepAliveConnections[i];
        Connection connection = holer.getConnection();
        holer.incrementKeepAliveCheckCount();

        boolean validate = false;
        try {
            this.validateConnection(connection);
            validate = true;
        } catch (Throwable error) {
            if (LOG.isDebugEnabled()) {
                LOG.debug("keepAliveErr", error);
            }
            // skip
        }

        boolean discard = !validate;
        if (validate) {
            holer.lastKeepTimeMillis = System.currentTimeMillis();
            boolean putOk = put(holer, 0L);
            if (!putOk) {
                discard = true;
            }
        }

        if (discard) {
            try {
                connection.close();
            } catch (Exception e) {
                // skip
            }

            lock.lock();
            try {
                discardCount++;

                if (activeCount + poolingCount <= minIdle) {
                    emptySignal();
                }
            } finally {
                lock.unlock();
            }
        }
    }
    this.getDataSourceStat().addKeepAliveCheckCount(keepAliveCount);
    Arrays.fill(keepAliveConnections, null);
}
```
很明显，需要配置合适的`minEvictableIdleTimeMillis`和`keepAliveBetweenTimeMillis`值，另外还需要配置`keepAlive = true`。通过上述配置，`Destroy`线程的确走到了检查连接有效性的代码部分，看起来问题似乎是解决的。

### 异常4
上面说到，检查连接有效性的配置生效了，我又连接本地数据库简单测试了一下，方法是在应用启动之后关闭MySQL数据库服务，测试结果却和预期不太一样。测试结果显示，数据库服务关闭之后，`Destroy`线程第一次检查完连接，连接依然有效。这是怎么回事？
点进去`this.validateConnection(connection);`方法查看一下，代码如下：
```java
    public void validateConnection(Connection conn) throws SQLException {
        String query = getValidationQuery();
        if (conn.isClosed()) {
            throw new SQLException("validateConnection: connection closed");
        }

        if (validConnectionChecker != null) {
            boolean result = true;
            Exception error = null;
            try {
                result = validConnectionChecker.isValidConnection(conn, validationQuery, validationQueryTimeout);

                if (result && onFatalError) {
                    lock.lock();
                    try {
                        if (onFatalError) {
                            onFatalError = false;
                        }
                    } finally {
                        lock.unlock();
                    }
                }
            } catch (SQLException ex) {
                throw ex;
            } catch (Exception ex) {
                error = ex;
            }

            if (!result) {
                SQLException sqlError = error != null ? //
                    new SQLException("validateConnection false", error) //
                    : new SQLException("validateConnection false");
                throw sqlError;
            }
            return;
        }

        if (null != query) {
            Statement stmt = null;
            ResultSet rs = null;
            try {
                stmt = conn.createStatement();
                if (getValidationQueryTimeout() > 0) {
                    stmt.setQueryTimeout(getValidationQueryTimeout());
                }
                rs = stmt.executeQuery(query);
                if (!rs.next()) {
                    throw new SQLException("validationQuery didn't return a row");
                }

                if (onFatalError) {
                    lock.lock();
                    try {
                        if (onFatalError) {
                            onFatalError = false;
                        }
                    }
                    finally {
                        lock.unlock();
                    }
                }
            } finally {
                JdbcUtils.close(rs);
                JdbcUtils.close(stmt);
            }
        }
    }
```
仔细看下代码，进去之后先获取参数里设置的`validationQuery`，似乎是按照文档描述那样在运行，但是继续往下看发现发现首先判断的却是`validConnectionChecker`，这个是什么东西？看名称是一个有效连接检查器，再看这个变量是在`DruidDataSource#initValidConnectionChecker`方法设置进去的，代码如下：
```java
private void initValidConnectionChecker() {
    if (this.validConnectionChecker != null) {
        return;
    }

    String realDriverClassName = driver.getClass().getName();
    if (JdbcUtils.isMySqlDriver(realDriverClassName)) {
        this.validConnectionChecker = new MySqlValidConnectionChecker();
    }
    // 其余省略
}
```
只要驱动是MySQL的驱动，这个变量就赋值为`MySqlValidConnectionChecker`对象，而这个方法是在`DruidDataSource#init`方法中调用的，也就是说这个变量几乎一定是指向`MySqlValidConnectionChecker`对象。这就是说无论你配置还是不配置`validationQuery`，如果不做特殊处理，几乎一定是走`validConnectionChecker#isValidConnection`方法来判断连接的有效性，也就是说在这儿，连接的检查没有使用`validationQuery`，配置不配置不影响（比较好奇别的地方会不会影响，为了不影响文章连贯性，这部分放在最后吧。）
那就到`validConnectionChecker`来看看。

![在这里插入图片描述](https://img-blog.csdnimg.cn/20200906174956613.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
我使用的是版本的MySQL驱动`ConnectionImpl`类的`pingInternal`方法是存在的（我看5.1.x版本这个方法就存在了），所以这里将反射执行`pingInternal`方法来进行连接的检查。后面省略的代码部分是该方法不存在时候使用`validationQuery`来进行检查。经过debug发现，问题就出在反射执行`pingInternal`这里。该方法会在MySQL服务刚刚关闭时候出现空指针异常，后续走`pingInternal`方法每次都会抛出NPE（因为对MySQL驱动并不了解，暂时不清楚抛出NPE是否有意为之，但是从代码看应该不是，这个地方咱们后面再谈）。如果这儿出现NPE会导致上面问题呢？咱们来看下这儿反射执行的代码：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200906180706587.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
显然这里会抛出`NPE`，再回到上层调用方法看下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200906192836440.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
可以看到这里对除`SQLException`的地方没有直接抛出，本意是在下面判断`result`为`false`时，包装成`SQLException`再抛出，却因为`result`默认值是`true`，而`validConnectionChecker#isValidConnection`却因为异常的抛出而没有将`result`的默认值进行修改，导致这个尴尬的结果。
但是你如果继续测试执行sql，你会发现并没有出现意外的情况，这是为什么？
来看一下获取连接的方法：
```java
    @Override
    public DruidPooledConnection getConnection() throws SQLException {
        return getConnection(maxWait);
    }

    public DruidPooledConnection getConnection(long maxWaitMillis) throws SQLException {
        init();

        if (filters.size() > 0) {
            FilterChainImpl filterChain = new FilterChainImpl(this);
            return filterChain.dataSource_connect(this, maxWaitMillis);
        } else {
            return getConnectionDirect(maxWaitMillis);
        }
    }
```
简单看下`getConnection`方法，这里是责任链模式的实际应用。点进去会发现最终还是会进入`getConnectionDirect`方法，直接看这个方法吧：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200906231918976.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
具体的配置我已经标出来了，`testOnBorrow`默认值是false，如果配置成true，和下面的代码走的一样的校验。而`testWhileIdle`建议是配置为`true`，那如果配置为true，并且满足空闲时间大于`timeBetweenEvictionRunsMillis`，来看下对应的代码：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200906233343510.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
同样抛出异常，这里直接返回来false，再到上层就丢弃这个连接了，所以这种情况下是不会有问题的。但是正如获取连接的方法注释的那样：
> ![if (idleMillis >= timeBetweenEvictionRunsMillis
                            || idleMillis < 0 // unexcepted branch
                            )](https://img-blog.csdnimg.cn/20200906233606623.png#pic_center)


因为`timeBetweenEvictionRunsMillis`同样是`Destroy`线程休眠的时间，理想情况下，`idleMillis`应该和`timeBetweenEvictionRunsMillis`差不多，但是如果连接长时间不用，这个值肯定还是略大于`idleMillis`，所以是会走到这个逻辑里的。如果刚好在这个时间间隙中获取连接呢？也就是说，`destroy`线程检查连接时候抛出了NPE，这个连接实际无效了，但是连接的`lastActiveTimeMillis`在上一次检查时更新了，这时候程序来拿连接了会怎么样？我们来试下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200907004002593.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
发现连接拿到了，`Statement`语句对象也创建了，直到执行sql时候报`CommunicationsException`，如图：
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200907004217727.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
虽然执行失败了，也算是没有再报NPE了。此时查看`DruidDataSource`对象，剩余的连接依然有效，`Destroy`线程依然在忙碌的进行无效的检查。
以上的测试代码都在我的GitHub仓库里，地址如下：https://github.com/wangzzleo/druid-bug-demo
### 异常5
以上的部分虽然是`Druid`的校验出了问题，虽然有代码默认值的问题，但是其实问题主要不在这儿，主要还是`MySQL-Connectot/J`以不期望的方式抛出了一个NPE，这个问题我提到了MySQL的bug系统里，链接如下：[https://bugs.mysql.com/bug.php?id=97824&thanks=3&notify=67](https://bugs.mysql.com/bug.php?id=97824&thanks=3&notify=67)，说实话，我其实不是很了解人家的代码，不知道是否有意为之，但是感觉NPE一般都不是有意为之的。这个bug并不是我提的，是另一个人提交的，我就是添加了一条评论告诉别人怎么复现。MySQL停机的问题应该不常见，但是在集群下有MySQL服务挂掉应该也是比较常模拟的故障，如果大家有这方面经验也可以告诉我下，战五渣的我其实这方面经验不是很多。后面我会给出我自己的理解，今天就先更新到这儿。另外，Druid是不是也可以提哥issue什么的，有读者看到可以帮忙提交一下，或者我改天提下。
### 异常6（这个可以不看，我还没细研究）
StatementImpl#executeQuery  1200行  抛出NPE
原因：

StatementImpl 类：
1186行，执行时将session设置为空，1220执行清空定时器时，抛出NPE。
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200903180801277.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)
![在这里插入图片描述](https://img-blog.csdnimg.cn/20200903180810966.png?x-oss-process=image/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L3NpbmF0XzM0ODc1MTA2,size_16,color_FFFFFF,t_70#pic_center)



# 推测（下面的内容等待整理，比较混乱）


Druid  DataSource 测试连接有效性问题

1. 测试连接有效性是在destroy线程里面测试的，usePingMethod 配置为true（暂时不清楚哪里配置的），则默认走的是MSSQLValidConnectionChecker#isValidConnection检查有效性

 问题是当连接关闭时，MySQL驱动的socket引用将被设置为null，继续走该方法就会报空指针异常，而空指针异常检测方法里面并未抛出，直接吞掉了。。。



 猜测- 是因为三个数据源是同一个库，检测到连接中断就会将socket设置为



 猜测：      NativeProtocol#checkErrorMessage 方法设置空socket



第一次验证连接，send(queryPacket, queryPacket.getPosition());抛出异常，不会走到销毁socket那步，则不报空指针，
相当于destroy验证连接无效，此时正常关闭连接，关闭连接之后不在走此函数，不用考虑空指针异常情况。






NativeProtocol#sendCommand出错的情况：
设置超时时间>0，send(queryPacket, queryPacket.getPosition()) 发包失败，但是没有报异常，因为skipCheck在这里固定是false，此时走到checkErrorMessage方法，将socket设置为null，再进入finally，#setSoTimeout报空指针异常
2020年9月2日15:47:15   复现成功：
步骤如下：
1. 关闭数据库，此时服务器TCP端口处于FIN_WAIT_2状态，可以接受数据但是不能返回响应；
2. 接下来，send(queryPacket, queryPacket.getPosition())发送数据，发送成功（可能是进入缓冲区，也可能是因为服务器此时还可以接受数据）
3. 此时进入checkErrorMessage(command)方法，该方法最终进入SimplePacketReader#readHeader方法，读取响应数据未读取到抛出异常，catch语句块捕获异常，并将this.mysqlSocket = null;this.mysqlInput = null;this.mysqlOutput = null;执行
4. 此时再回到NativeProtocol#sendCommand,进入finally语句块，该语句块不知为何重新设置了超时时间，this.socketConnection.getMysqlSocket().setSoTimeout(oldTimeout);，由3可知，此时socket为空，所以会抛出NPE。



这种情况出现的要点是：send(queryPacket, queryPacket.getPosition());函数不报错，调用checkErrorMessage#checkErrorMessage，内部调用readMessage(this.reusablePacket);，再调用this.packetReader.readHeader();，此时出现IOException或CJPacketTooBigException会关闭连接。



现在的状况是：1+n个连接，第一个连接send不会报错，checkErrorMessage报错（CJException）会将socket引用置为空，后续则send出错，进入正常状况

经过尝试，没有复现出来，两条都出问题了



发现：
抓包收到了两条回复，连接重置。 猜测：MySQL服务器刚刚听了不会马上断掉接口（确实不会马上断掉，而是进入FIN_WAIT_2状态）
验证1：
抓包
验证2：
第一次send发送包之后停留时间多一点，等server完全停止再继续发message那个（测试结果：还是能拿到数据，猜测是从buffer里面拿的，能拿到就不报错）




疑问：
那为什么在服务器关闭后，第一条访问的send不会报错？因为服务器处于FIN_WAIT_2状态还是可以接受数据


checkErrorMessage 为什么异常？ 因为没有读到数据？



后续：
这个方法在设置了超时时间的情况下，有可能报空指针异常。 当连接中断，服务器的tcp连接刚好处于 fin_wait 状态时候，服务器好像还能接受数据，但是没有相应写回去    后面有一个checkErrorMessage 方法，没有相应数据就抛异常了，然后把socket设置为null。  NativeProtoc#sendCommand方法的finally方法设置超时时间的时候会再再给socket设置一遍超时时间（不知道为这么干），这时候就抛空指针异常了

然后druid检查连接的方法里（DruidAbstractDataSource#validateConnection）里面把SQLException抛出了，但是没有抛别的异常，接着就把这个当做正常情况处理了，其实连接都失效了








【附1】：
来看看获取连接时候的代码，代码片段如下：
```java
	@Override
    public DruidPooledConnection getConnection() throws SQLException {
        return getConnection(maxWait);
    }

    public DruidPooledConnection getConnectionDirect(long maxWaitMillis) throws SQLException {
    int notFullTimeoutRetryCnt = 0;
    for (;;) {
        // handle notFullTimeoutRetry
        DruidPooledConnection poolableConnection;
        try {
            poolableConnection = getConnectionInternal(maxWaitMillis);
        } catch (GetConnectionTimeoutException ex) {
            if (notFullTimeoutRetryCnt <= this.notFullTimeoutRetryCount && !isFull()) {
                notFullTimeoutRetryCnt++;
                if (LOG.isWarnEnabled()) {
                    LOG.warn("get connection timeout retry : " + notFullTimeoutRetryCnt);
                }
                continue;
            }
            throw ex;
        }

        if (testOnBorrow) {
            boolean validate = testConnectionInternal(poolableConnection.holder, poolableConnection.conn);
            if (!validate) {
                if (LOG.isDebugEnabled()) {
                    LOG.debug("skip not validate connection.");
                }

                discardConnection(poolableConnection.holder);
                continue;
            }
        } else {
            if (poolableConnection.conn.isClosed()) {
                discardConnection(poolableConnection.holder); // 传入null，避免重复关闭
                continue;
            }
            if (testWhileIdle) {
                final DruidConnectionHolder holder = poolableConnection.holder;
                long currentTimeMillis             = System.currentTimeMillis();
                long lastActiveTimeMillis          = holder.lastActiveTimeMillis;
                long lastExecTimeMillis            = holder.lastExecTimeMillis;
                long lastKeepTimeMillis            = holder.lastKeepTimeMillis;
                if (checkExecuteTime
                        && lastExecTimeMillis != lastActiveTimeMillis) {
                    lastActiveTimeMillis = lastExecTimeMillis;
                }
                if (lastKeepTimeMillis > lastActiveTimeMillis) {
                    lastActiveTimeMillis = lastKeepTimeMillis;
                }
                long idleMillis                    = currentTimeMillis - lastActiveTimeMillis;
                long timeBetweenEvictionRunsMillis = this.timeBetweenEvictionRunsMillis;
                if (timeBetweenEvictionRunsMillis <= 0) {
                    timeBetweenEvictionRunsMillis = DEFAULT_TIME_BETWEEN_EVICTION_RUNS_MILLIS;
                }
                if (idleMillis >= timeBetweenEvictionRunsMillis
                        || idleMillis < 0 // unexcepted branch
                        ) {
                    boolean validate = testConnectionInternal(poolableConnection.holder, poolableConnection.conn);
                    if (!validate) {
                        if (LOG.isDebugEnabled()) {
                            LOG.debug("skip not validate connection.");
                        }

                        discardConnection(poolableConnection.holder);
                         continue;
                    }
                }
            }
        }
        // 省略后面代码
    }

    protected boolean testConnectionInternal(DruidConnectionHolder holder, Connection conn) {
        String sqlFile = JdbcSqlStat.getContextSqlFile();
        String sqlName = JdbcSqlStat.getContextSqlName();

        if (sqlFile != null) {
            JdbcSqlStat.setContextSqlFile(null);
        }
        if (sqlName != null) {
            JdbcSqlStat.setContextSqlName(null);
        }
        try {
            if (validConnectionChecker != null) {
                boolean valid = validConnectionChecker.isValidConnection(conn, validationQuery, validationQueryTimeout);
                long currentTimeMillis = System.currentTimeMillis();
               // ...
                return valid;
            }

            if (conn.isClosed()) {
                return false;
            }

            if (null == validationQuery) {
                return true;
            }

            Statement stmt = null;
            ResultSet rset = null;
            try {
                stmt = conn.createStatement();
                if (getValidationQueryTimeout() > 0) {
                    stmt.setQueryTimeout(validationQueryTimeout);
                }
                rset = stmt.executeQuery(validationQuery);
                if (!rset.next()) {
                    return false;
                }
            } finally {
                JdbcUtils.close(rset);
                JdbcUtils.close(stmt);
            }
			// ...
            return true;
        } catch (Throwable ex) {
            // skip
            return false;
        } finally {
            if (sqlFile != null) {
                JdbcSqlStat.setContextSqlFile(sqlFile);
            }
            if (sqlName != null) {
                JdbcSqlStat.setContextSqlName(sqlName);
            }
        }
    }
 ```
可以看到获取连接的逻辑和`Destroy`类似，`validConnectionChecker`不为空就和`validationQuery`没什么关系了。这个其实没啥，可能是文档没及时更新吧。
