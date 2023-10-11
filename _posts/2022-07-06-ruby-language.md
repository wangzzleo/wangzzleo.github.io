---
layout: post
title:  "ruby language"
subtitle: "ruby language"
date:   2022-07-06
background: '/img/imac_bg.png'
---


# ruby language

2022-07-06

是真的方便

1. 循环？
    
    ```ruby
    5.times do
    
    	print 'hello world!'
    
    end
    ```
    
2. 数学计算？
    
    `2 + 3`
    
3. 打印？*put something on the screen*
    
    `puts xxx`
    
4. 重复多个字符串？
    
    `"ruby" * 5`
    
5. 类型抓换？
    
    `to_s` 转换为字符串
    
    `to_a` 转换为数组
    
    `to_i` 转换为整数
    
6. 定义数组？
    
    `arr = [1,2,3]`
    
7. 数组长度？最大值？最小值？反转？排序？
    
    `[12, 47, 35].length`
    
    `[12, 47, 35].max`
    
    `[12, 47, 35].min`
    
    `[12, 47, 35].reverse`
    
    `[12, 47, 35].sort!`
    
    `…`
    
8. 数组排序是否修改原数组？
    
    `arr = [1,2,3]`
    
    `arr.sort!` 加`!` 标记在原数组上排序
    
9. 读取、存放数组
    
    `puts arr[1]`
    
    `arr[1] = 4`
    
10. 一些字符串操作方法
    
    `name = "ruby is nice"`
    
    `name.gsub("nice", "so nice")`
    
    `name.reverse`
    
    `name.lines`
    
11. 方法链式调用？
    
    `str = "Hello world!\n I am Ruby!"`
    
    `str.lines.reverse.join`
    
12. hash
    
    `books = {}`
    
    `books["The deep end"]  = :abysmal`
    
    `books["Living colors"] = :mediocre`
    
    `puts books`
    
    `puts books.length`
    
    `puts books["The deep end"]` ：取value
    
    `books.keys`
    
    `books.values`
    
13. `:` 的含义？
    
    单词前加`:`, 会让这个单词在内存里只存一份。这样节省内存。
    
    但是加上`:` 就不再是简单的字符串了。
    
14. 分支？
    
    ```ruby
    if 1 < 2
      puts "It is true: 1 is less than 2"
    end
    
    puts "It is true: 1 is less than 2" if 1 < 0
    ```
    
15. What does the question mark at the end of a method name mean?
    - It is a code style convention; it indicates that a method returns a boolean value (true or false) or an object to indicate a true value (or “truthy” value).
        
        The question mark is a valid character at the end of a method name.
        
        https://docs.ruby-lang.org/en/2.0.0/syntax/methods_rdoc.html#label-Method+Names
        
        From : [https://stackoverflow.com/questions/1345843/what-does-the-question-mark-at-the-end-of-a-method-name-mean-in-ruby#:~:text=It is a code style,html%23label-Method%2BNames](https://stackoverflow.com/questions/1345843/what-does-the-question-mark-at-the-end-of-a-method-name-mean-in-ruby#:~:text=It%20is%20a%20code%20style,html%23label%2DMethod%2BNames)
        
16. 打印替换
    
    **`#{}`** 里面放变量，比如 `#{name}`
    
17. 面向对象：定义类
    
    ```ruby
    class Blurb
    	attr_accessor :content, :time, :mood
    	def initialize(mood, content="")
    		@time    = Time.now
    		@content = content[0..39]
    		@mood    = mood
    	end
    end
    ```
    
    这里的`@` ，和使用`.` 调用意思一样。在类里面调用对象的变量用`@` ，类外用`.`
