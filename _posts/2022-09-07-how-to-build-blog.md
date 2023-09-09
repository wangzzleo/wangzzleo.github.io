---
layout: post
title:  "构建一个你自己的博客"
subtitle: "使用Github创建你的博客"
date:   2022-09-07
background: '/img/imac_bg.png'
---

# 使用Github创建你的博客

# 为什么你需要一个博客？

- 总结你的所思所想

  总结 → 进步

- 纯当作笔记
- 自己的博客不怕和谐

  简介都没法修改？逢敏感时期，头像、ID都没法改？

- 发布文章自己说了算，不担心审核
  ![Untitled.png](https://s2.loli.net/2023/09/09/nhFvRsf3TBa2UEm.png)

- 不怕账号封禁导致文章丢失

    ![Untitled.png](https://s2.loli.net/2023/09/09/9prg6fnbQGyENJM.png)

# 建设博客，有哪些方式？

1. 国内的博客网站（审查）

   掘金、简书、博客园、微信公众号、思否….

2. 国外的博客网站（墙）

   [blogger.com](https://link.zhihu.com/?target=http%3A//1.blogger.com) 、
   [wordpress.com](https://link.zhihu.com/?target=http%3A//2.wordpress.com) 、Tumblr（汤博乐、汤不热）等

3. 自己建站（复杂+付费+备案）

   买云服务、搭建服务、部署前后端

4. 网站托管

   付费：各种云厂商（付费）

   免费：Github pages


# GitHub pages

### 什么是**Github pages**

- **GitHub Pages** 是一种静态站点托管服务，它直接从 GitHub 上的仓库获取 HTML、CSS 和 JavaScript 文件，可选择通过构建过程运行文件，然后发布网站。

**点击连接了解Github Pages：**

https://docs.github.com/en/pages/getting-started-with-github-pages/about-github-pages

**点击连接查看Github Pages 示例：**

https://github.com/collections/github-pages-examples

### 使用Github pages有什么好处

1. 免费
2. 方便

### 使用Github pages创建一个博客

1. 注册一个Github账号，比如：oneuss
2. 创建一个仓库，名为：{username}.github.io，例如：oneuss.github.io
3. 在你新建仓库下面新建个文件：README.md，随便写点内容
4. 点击**Settings（设置）**，单击左侧**Pages**

    ![Untitled.png](https://s2.loli.net/2023/09/09/Pou8mnsiv9ZNV6c.png)

5. 然后等待片刻，便可以从：[oneuss.github.io](https://oneuss.github.io) 访问你的博客

### 修改博客名称

1. 添加文件：`_config.yml`
2. 文件中添加：

    ```
    title: oneuss的博客
    description: 这是我的博客
    ```


看到如下效果：

   ![Untitled.png](https://s2.loli.net/2023/09/09/NZyjLcKdWo7VzYB.png)

### 修改博客主题

1. 修改`_config.yml`，添加属性：`theme`

    ```jsx
    title: oneuss的博客
    description: 这是我的博客
    theme: minima
    ```

   修改之后：

   ![Untitled.png](https://s2.loli.net/2023/09/09/k6e8PEaVMpshc47.png)

2. Github pages支持的主题（https://pages.github.com/themes/），更换主题时点进去根据教程更换即可：

    ![Untitled.png](https://s2.loli.net/2023/09/09/2powxiMAuIrWmVN.png)

1. 如果需要更换到其他托管在Github上的主题，增加配置：`remote_theme: THEME-NAME`
2. 还想要其他主题？
    - [GitHub.com #jekyll-theme repos](https://github.com/topics/jekyll-theme)
    - [jamstackthemes.dev](https://jamstackthemes.dev/ssg/jekyll/)
    - [jekyllthemes.org](http://jekyllthemes.org/)
    - [jekyllthemes.io](https://jekyllthemes.io/)
    - [jekyll-themes.com](https://jekyll-themes.com/)
3. 自定义主题的
4. 新增文章
    1. 新建目录`_posts`
    2. 建一个名为*`YYYY-MM-DD-NAME-OF-POST.md`*的新文件，将*YYYY-MM-DD*替换为您的文章日期，将*NAME-OF-POST*替换为您的文章名称
    3. 将以下 `YAML frontmatter` 添加到文件顶部，将*`POST TITLE`*替换为帖子的标题，将*`YYYY-MM-DD hh:mm:ss`*替换为帖子的日期和时间，后面跟文章内容，使用markdown语法。

        ```
        ---
        layout: post
        title: "POST TITLE"
        date: YYYY-MM-DD hh:mm:ss -0000
        ---
        ```

    4. 提交之后，使用 [https://oneuss.github.io/YYYY/MM/DD/TITLE.html](https://octocat.github.io/YYYY/MM/DD/TITLE.html) 访问
5. 为你的博客增加文章的自定义索引
    1. Jekyll使用模板引擎Liquid，所以可以使用Liquid标签创建索引，在首页增加如下代码：

       ![code.png](https://s2.loli.net/2023/09/09/ExzFsAWVyldMP48.png)


最终效果如下：

![Untitled.png](https://s2.loli.net/2023/09/09/kmgiVrSae4CUPQo.png)

![Untitled.png](https://s2.loli.net/2023/09/09/MCg4vuOlQ9KdpqG.png)

如果觉得还是不好看，可以自定义主题的**CSS**、自定义****HTML 布局。****

- 查看官方教程：

[GitHub Pages 快速入门 - GitHub Docs](https://docs.github.com/cn/pages/quickstart)

### 更简单的方式

1. fork你想要主题的项目
2. 修改项目名称，设置域名等
3. 删掉原来的文章，直接在_post里加你自己的文章

## 限制

1. 仓库大小不超过1GB
2. 带宽限制为每月 100 GB
3. 每小时 10 次构建

# 使用Jekyll

### 什么是Jekyll
   
![Untitled.png](https://s2.loli.net/2023/09/09/TU4AlkiXfFHwsrP.png)

Jekyll 是一个静态站点生成器，内置对 GitHub Pages 的支持和简化的构建过程。Jekyll 采用 Markdown 和 HTML 文件，并根据选择的布局创建一个完整的静态网站。Jekyll 支持 Markdown 和 Liquid，这是一种在您的网站上加载动态内容的模板语言。

[Jekyll * Simple, blog-aware, static sites](https://jekyllrb.com/)

[Jekyll * 简单静态博客网站生成器](http://jekyllcn.com/)

# 推广你的博客

1. 购买域名，并创建`CNAME`记录，指向指向`oneuss.github.io`

   ![Untitled.png](https://s2.loli.net/2023/09/09/T4o5pEL7HkUxQIt.png)

2. 给到一些人维护的独立博客列表，比如：https://github.com/timqian/chinese-independent-blogs ，提交PR
3. 在国内博客网站上写文章链接到你的博客
4. 友链，比如赵琦的博客：https://www.ingernotes.cn/
5. 为你的博客增加百度统计、谷歌统计，查看访问数据

# 收益

1. 直接收益，比如广告：**Google Ads**
2. 个人品牌效应
3. 存储你的文章，不怕被封，不怕被检测关键字（当然也别乱写）
4. 反过来影响你进步，比如给自己定目标定期更新

# 注意：网络不是法外之地

![Untitled.png](https://s2.loli.net/2023/09/09/uLWvTfemQ1PcnZI.png)

# 拓展实践

如何在本地调试自己的博客？

另：oneuss-demo地址 https://github.com/oneuss/oneuss.github.io
