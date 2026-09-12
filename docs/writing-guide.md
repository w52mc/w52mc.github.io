# 写作指南

## 最简单的用法（推荐）

```sh
newpost 我的文章标题     # ① 创建文章，自动打开编辑器
                        # ② 写正文，保存退出
publish                 # ③ 一键发布
```

**三条命令，完事。** 标题、日期、作者这些信息全部自动生成，你只需要写正文。

> 暂时没重开终端的话，用完整路径：`~/Documents/code/2026/blog-easy/newpost.sh`

## 更简单：直接建文件

你也可以完全跳过 `newpost`，**直接在 `src/content/posts/` 里手动创建 `.md` 文件**，随便写点内容，然后：

```sh
publish
```

脚本会**自动补全**缺少的文章信息：

| 自动生成 | 来源 |
| --- | --- |
| 标题 | 文件名（`my-first-post.md` → `My First Post`） |
| 日期 | 当前时间 |
| 作者 | 碳水化合物 |
| 其他 | 默认值 |

> 想在发布前预览效果，就再开一个终端运行 `blogdev`（或 `pnpm dev`），浏览器打开 http://localhost:4321

## 文章放在哪

```
blog-easy/src/content/posts/      ← 一个 .md 文件 = 一篇文章
```

文件名决定网址：

| 文件 | 网址 |
| --- | --- |
| `src/content/posts/hello-world.md` | `https://w52mc.github.io/posts/hello-world/` |
| `src/content/posts/如何理解大模型.md` | `https://w52mc.github.io/posts/如何理解大模型/` |

> 建议用英文文件名（如 `my-first-post.md`），网址更干净。`newpost` 会自动帮你转换。

## 完整格式（可选）

`publish` 会自动补全，所以**你完全可以不写 frontmatter**。如果想手动控制，格式如下：

```markdown
---
title: 我的文章标题
author: 碳水化合物
pubDatetime: 2026-09-12T20:00:00+08:00
draft: false
tags:
  - AI
  - 前端
description: 一句话摘要，显示在列表页和搜索结果里。
---

正文从这里开始。

## 二级标题

普通段落、列表、引用、代码块都支持 Markdown 语法。
```

| 字段 | 说明 |
| --- | --- |
| `title` | 不写则用文件名 |
| `pubDatetime` | 不写则用当前时间 |
| `description` | 摘要，不写则留空 |
| `draft` | `true` = 草稿（见下文），默认 `false` |
| `tags` | 标签数组，会生成标签页 |
| `featured` | `true` = 首页「精选」区块显示 |
| `modDatetime` | 修改时间，写了会显示「更新于」 |

## 草稿：不想发布怎么办

**把 `draft` 改成 `true`**：

```yaml
draft: true
```

这样：

|  | 本地预览 | 线上网站 | GitHub |
| --- | --- | --- | --- |
| `draft: true` | ✅ 可见 | ❌ 不显示 | ❌ **不会被提交** |
| `draft: false` | ✅ 可见 | ✅ 发布 | ✅ 提交 |

**想发布时，把 `draft: true` 改成 `draft: false`，再运行 `publish`。**

### ⚠️ 草稿没有备份

草稿不会提交到 GitHub，所以**只存在你电脑上**。硬盘坏了就会丢。

重要内容建议另外存一份（iCloud、Obsidian、备忘录都行）。

## 常用命令

| 我想… | 命令 |
| --- | --- |
| 新建文章 | `newpost 文章标题` |
| 发布所有改动 | `publish` |
| 发布并自定义说明 | `publish "修复错别字"` |
| 不等部署结果 | `SKIP_WAIT=1 publish` |
| 进入博客目录 | `blog` |
| 本地预览 | `blogdev` |
| 看部署进度 | https://github.com/w52mc/w52mc.github.io/actions |
| 改站点配置 | `hx ~/Documents/code/2026/blog-easy/astro-paper.config.ts` |
| 改界面文字 | `hx ~/Documents/code/2026/blog-easy/src/i18n/lang/zh.ts` |
| 改配色 | `hx ~/Documents/code/2026/blog-easy/src/styles/theme.css` |

> 如果提示命令不存在，执行 `source ~/.zshrc` 或重开终端。

## `publish` 做了哪些事

```
📝 博客发布

▸ 检查项目          确认位置和分支
▸ 检查改动          列出改了什么
▸ 自动补全          给缺信息的文章补上标题/日期/作者
▸ 生成提交信息      读取文章标题作为说明
▸ 提交并推送        自动完成（草稿自动排除）
▸ 等待自动部署      约 50 秒，实时显示进度
▸ 线上地址          自动打开浏览器
```

## 修改和删除文章

**修改**：直接编辑文件，运行 `publish`。

**删除**：

```sh
rm ~/Documents/code/2026/blog-easy/src/content/posts/要删的文章.md
publish
```

## 遇到问题

**推送失败**

```sh
gh auth refresh -s workflow
publish
```

**本地页面报错**

```sh
pkill -f "astro dev"
rm -rf ~/Documents/code/2026/blog-easy/.astro
blogdev
```

**线上还是旧内容**

按 `Cmd+Shift+R` 强制刷新。如果不对，去 [Actions 页面](https://github.com/w52mc/w52mc.github.io/actions) 看部署是否成功。

## 相关文件位置

| 内容 | 路径 |
| --- | --- |
| 博客文章 | `src/content/posts/*.md` |
| 「关于」页面 | `src/content/pages/about.md` |
| 站点配置 | `astro-paper.config.ts` |
| 界面文案 | `src/i18n/lang/zh.ts` |
| 配色主题 | `src/styles/theme.css` |
| 一键发布脚本 | `publish.sh` |
| 新建文章脚本 | `newpost.sh` |
| 主题官方文档 | `reference/theme-docs/`（不参与构建） |
