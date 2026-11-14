# 八宝粥的个人博客 (Jekyll Theme Chirpy)

本项目基于 [Jekyll Theme Chirpy](https://github.com/cotes2020/jekyll-theme-chirpy) 构建，托管于 GitHub Pages，绑定独立域名 [wangzzleo.top](https://www.wangzzleo.top)。

## 🌟 主题特性
- **右侧吸顶大纲（Sticky TOC）**：长文页面右侧提供实时高亮定位目录，滚动随行，无需翻回顶部。
- **现代化多栏布局**：左侧固定导航栏（归档、分类、标签、关于），中间高密度文章流，右侧标签云与目录。
- **暗黑模式（Dark Mode）**：支持浅色/深色主题一键无缝切换。
- **即时搜索（Search）**：毫秒级全站标题与全文模糊搜索。
- **代码高亮与复制**：语法高亮并自带一键复制代码块功能。
- **数学公式支持**：支持 KaTeX / MathJax 渲染。

## 🚀 本地运行

### 推荐：使用 Docker 一键启动（免配置本地 Ruby 环境）
```bash
docker compose up
```
启动后访问 `http://localhost:4000` 即可实时预览（支持热重载）。

### 本地原生运行（需要 Ruby >= 3.0）
```bash
bundle install
bundle exec jekyll serve
```

## ✍️ 写新文章指南
在 `_posts/` 目录下创建 `YYYY-MM-DD-title.md` 文件，头部设置：
```yaml
---
title: "文章标题"
date: 2026-11-14 10:00:00 +0800
categories: [主分类, 子分类]
tags: [标签1, 标签2]
toc: true
---
```

## 🚢 自动部署
通过 GitHub Actions 自动化流水线（`.github/workflows/pages-deploy.yml`），只需将代码 push 到 `master` 分支，云端即可自动完成构建与发布。
