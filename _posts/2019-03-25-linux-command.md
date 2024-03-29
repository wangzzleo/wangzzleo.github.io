---
layout: post
title:  "常用的Linux命令"
subtitle: ""
date:   2019-03-26
background: '/img/imac_bg.png'
---
&#8194;&#8194;&#8194;&#8194;刚刚参加工作那会儿，对Linux很不熟悉，工作看日志时候被人一顿diss，后来下决心买了书，看着视频一点点学起。到现在用了也有好几年，可是最近几个月现在的公司运营出现问题，工作安排各种混乱，我已经被“闲置”了许久，之前常用的命令居然忘记了许多。所以这篇文章我用来记录下之前常用的Linux命令，自己有个记录的作用，也希望可以偶尔看到的读者有所收获。

1. 生命短暂，我用**快捷键**：
    - ```Ctrl + Alt + t ```             
	打开新终端如何记忆：t是terminal首字母）
    - ```Ctrl + →``` 或者 ```Ctrl + ←```               
	跳过一个单词 （适用于很多IDE，如idea，eclipse等）
    - ```ctrl + k```               
	剪切光标后边的内容；
    - ```ctrl + u```              
	剪切光标之前的内容；
    - ```ctrl + y```             
	在光标处粘贴剪切的命令（Ctrl+u、Ctrl+k剪切命令）；
    - ```ctrl + c```             
	中断正在运行的程序或命令；
    - ```ctrl + d```            
	结束当前命令窗口；
    - ```ctrl + r```       
	输入关键字可弹出曾经用过的指令；
    - ```ctrl + l```       
	clear命令
    - ```ctrl + a```  
	光标切换到行开头；
    - ```ctrl + e```  
	光标切换到行尾。
    - 可以将常用长命令添加到```~/.bashrc``` 中，起个别名。这样就可以使用别名来运行。

2. **find命令**
格式：find [目录] [参数] [匹配模型] [参数] [匹配模型]  
    - ```find . -name "*.sh"```  
查找当前目录（及子目录）下以sh结尾的文件。
    - ```find . -perm 755```           
	查找当前目录（及子目录）下属性为755的文件。
    - ```find -user root```
    查找当前目录（及子目录）下属主为root的文件。
    - ```find /var -mtime -5```           
     查找/var下更改时间在5天**以内**的文件。
    - ```find /var -mtime +3```          
     查找/var下更改时间在3天**以前**的文件。
    - ```find /etc -type l```                
     查找/etc下文件类型为l（这是英文l，链接文件）的链接文件。
    - ```find . -size +1000000c```    
      查找当前目录（及子目录）下文件大小大于1M的文件。
    - ```find . -perm 700 |xargs chmod 777```           
      查找当前目录（及子目录）下所有权限为700的文件，并把其权限重设为777。
    - ```find . -type f |xargs ls -l```  
      查找文件并查看其详细信息
    - ```find [路径]  [参数] -exec [others command] {} \;```  
      ```{}``` 花括号代表前面find查找出来的文件，以```;```为终止字符。因为各个系统中分号可能有不同的意义，所以加了反斜杠```\```。  

		参考：[[shell之find命令详解](https://www.cnblogs.com/lanchang/p/6597372.html)
](http://www.cnblogs.com/lanchang/p/6597372.html)

3. **grep 命令**
	1. grep全称是Global Regular Expression Print，表示全局正则表达式版本，它的使用权限是所有用户。
	2. 命令格式：```grep [option] pattern file```

4. **man 命令**
	1. 命令代码代表的意义：命令代号的意义：
	    -  1：用户在shell环境中可以操作的命令和可执行文件
    	-  5：配置文件或某些文件的格式
    	-  8：系统管理员可用的管理命令
    2. info page按键说明：
   		- [space]：向下翻一页
  		- [Page Down]：向下翻一页
  		- [Page Up]：向上翻一页
  		- [Tab]：在节点之间移动，有节点的地方，通常会以“ * ”显示
  		- [Enter]：当光标在节点上面时，按下Enter进入该节点
		- ```-b```：移动光标到该Info界面当中的开始处（原文是：该Info界面当中的第一个节点处）
		- ```-e```：移动光标到该Info界面结束处（原文是：该INfo界面当中的最后一个节点处）
		- ```-n```：前往下一个节点处
		- ```-p```：前往上一个节点处
		- ```-u```：向上移动一层
		- ```-/```：在info page当中进行查询
		- ```-h```：显示求助菜单
		- ```-?```：命令一览表
		- ```-q```：结束此次的info page
5. **shutdown命令：**
	1. 除非你是以tty7图形化界面来登录的，否则只有root用户拥有使用shutdown命令的权限。
	2. /sbin/shutdown [-t 秒] [-arkhncfF] 时间 [警告信息]
		- ```-t sec``` ：-t 加秒，即多少秒后关机
  		- ```-k``` ：不会关机，只是发送警告消息
  		- ```-r``` ：在将系统的服务停掉之后就重新启动（比较常用）
  		- ```-h``` ：将系统的服务停掉之后立即关机（常用）
  		- ```-n``` ：不经过初始化程序，直接以shutdown的功能来关机
  		- ```-f``` ：关机并开机后，强制略过fsck的磁盘检查
  		- ```-F``` ：系统重启之后，强制进行fsck的磁盘检查
  		- ```-c``` ：取消已经在进行的shutdown命令内容
  	3. 例子：```/sbin/shutdon -h10 "shutdown in 10 mins"(十分钟后关机，并且会显示在屏幕下方)```
 	4. 注意：时间是一定要加入的参数，指定关机的时间。(注意一定要加时间参数，否则会跳到run-level1)
6. **忘记root密码？**
	1. 启动机器，在读秒的时候按下任意键；
  	2. 按下 e键，选择kernel /。。。。。。 这一行；
  	3. 按下e键进入kernel编辑界面，在最后输入 single；
  	4. 按下Enter确定，再按下b就能进入单用户维护模式，之后进行passwd修改密码。

9. ls命令：
	- ```a``` ：全部的文件，连同隐藏文件一同列出；
  	- ```A``` ：列出全部文件，不包括.与.. ；
  	- ```d``` ：仅列出目录；
	- ```h```：将文件大小表示位 KB，MB,GB的形式
	- ```l``` ：列出长数据串，包含文件的属性与权限等。
	- ```S```：以文件容量大小排序；
	- ```t``` ：依时间排序，而不是文件名。
 	- ```--color=never```：不依据文件特性显示不同颜色；
 	- ```--color=always```：显示颜色；
 	- ```--color=auto```：系统依据设置来自行判断颜色；
 	- ```--full- time``` ：以完整时间模式输出；

10. cp复制命令：
	- ```-a``` ：相当于-pdr 的意思；
	- ```-d``` ：若源文件为连接文件的属性（link file），则复制连接文件属性而非文件本身；
	- ```-f```  ：为强制的意思，若目标文件已经存在且无法开启，则删除后再尝试一次；
	- ```-i```  ：若目标文件已经存在时，在覆盖时会先询问操作的进行；
	- ```-l```  ：进行硬连接的连接文件创建，而非复制文件本身；
	- ```-p``` ：连同文件属性一起复制过去，而非使用默认属性（备份常用）；
	- ```-r```  ：递归持续复制，用于目录的复制行为；
	- ```-s```  ：复制成为符号链接文件，即“快捷方式”文件；
	- ```-u```  ：若destination比source旧才更新destination。


参考：[1] [Linux爱好者：每天一个 Linux 命令](https://mp.weixin.qq.com/s/G3Los9__bmhwBy-1L8glXA)
&#8194;&#8194;&#8194;&#8194;&#8194;&#8194;
