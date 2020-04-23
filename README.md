本博客使用[BlackrockDigital](https://github.com/BlackrockDigital)的`startbootstrap-clean-blog-jekyll`模板，[点击查看详细教程](https://github.com/BlackrockDigital/startbootstrap-clean-blog-jekyll)。
查看该模板[点击这里](http://blackrockdigital.github.io/startbootstrap-clean-blog-jekyll/)。
***
以下来自我的补充：  
1. 了解GitHub Pages，[戳这里](https://pages.github.com/)  
2. 了解Jekyll，[戳这里](http://jekyllcn.com/)  
3. 如果`bundle install`很卡，或者很慢，这个时候可以中断掉，将Gemfile文件的Ruby源修改为国内镜像：```
gem sources --remove https://rubygems.org/
gem source 'https://gems.ruby-china.com'``` 。之后进入目录中手动安装依赖的ruby包：`bundler show`，按照提示安装。  
4. 如果你是Windows用户，则需要[查看这里](http://jekyllcn.com/docs/windows/#installation)。经过我的实践，我对此指南补充以下：
	1. 最新文档可以查看[Jekyll国外官网](https://rubyinstaller.org/downloads/)，国内翻译官网因为翻译的延迟性等原因，可能会有误导，需要对照查看。
	2. 在国外官网可以得知，可以通过下载 `Ruby+Devkit`安装Ruby和Ruby development kit，[地址在此](https://rubyinstaller.org/downloads/)，这里需要注意的是，后续需要安装的`Nokogiri`这个软件包目前只支持`>ruby 2.2`、`<ruby 2.7.dev`，需要下载安装`2.7`之前的版本。
	3. `Nokogiri`这个包我也是通过`gem install Nokogiri`直接安装的，没有下载别的，各位可以试一试。


## Copyright and License

Copyright 2013-2019 Blackrock Digital LLC. Code released under the [MIT](https://github.com/BlackrockDigital/startbootstrap-clean-blog-jekyll/blob/gh-pages/LICENSE) license.
