# 写作指南

## 文章放在哪里

```
blog-easy/src/content/posts/
```

**一个 `.md` 文件 = 一篇文章。** 文件名会成为网址的一部分：

| 文件 | 网址 |
| --- | --- |
| `src/content/posts/hello-world.md` | `https://w52mc.github.io/posts/hello-world/` |
| `src/content/posts/my-setup.md` | `https://w52mc.github.io/posts/my-setup/` |

> 文件名建议用小写英文加连字符（如 `my-first-post.md`）。用中文做文件名也能用，但网址里会出现一串编码字符，不好看。

## 一篇文章的完整格式

在 `src/content/posts/` 新建 `.md` 文件，开头必须有这段「frontmatter」（两条 `---` 之间的部分）：

```markdown
---
title: 我的第一篇正式文章
author: 碳水化合物
pubDatetime: 2026-09-12T20:00:00+08:00
draft: false
featured: false
tags:
  - AI
  - 前端
description: 一句话摘要，会显示在文章列表和搜索结果里。
---

正文从这里开始。

## 二级标题

普通段落。

- 列表项
- 列表项

> 引用

`行内代码`，以及代码块：

```sh
echo "hello"
```
```

### 每个字段的作用

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `title` | ✅ | 文章标题 |
| `pubDatetime` | ✅ | 发布日期，格式 `年-月-日T时:分:秒+08:00` |
| `description` | ✅ | 摘要，出现在列表页、搜索结果、分享卡片上 |
| `draft` | | `true` = 草稿（不发布）；`false` 或不写 = 正常发布 |
| `tags` | | 标签数组，会生成标签页 |
| `featured` | | `true` = 首页「精选」区块显示 |
| `author` | | 作者名，不写则用配置里的默认值 |
| `modDatetime` | | 修改时间，可选 |
| `ogImage` | | 自定义分享图，可选（不写会自动生成） |

## 完整操作流程

### 1. 启动本地预览（写文章时一直开着）

```sh
cd ~/Documents/code/2026/blog-easy
pnpm dev
```

然后浏览器打开 **http://localhost:4321** —— 保存文件后页面会自动刷新。

### 2. 新建文章

```sh
cd ~/Documents/code/2026/blog-easy
hx src/content/posts/my-new-post.md
```

把上面的模板粘进去，改标题和内容。

### 3. 写的时候用草稿模式

**刚开始写的时候，把 `draft` 设为 `true`：**

```yaml
draft: true
```

这样：
- ✅ 本地能正常预览（列表页、文章页都能看到）
- ✅ **不会发布到线上**
- ✅ **不会被提交到 GitHub**（推不上去，别人看不到）

### 4. 写完了，发布

**第一步：把 `draft: true` 改成 `draft: false`**

```yaml
draft: false
```

**第二步：一键发布**

```sh
publish
```

脚本会自动：提交 → 推送 → 等部署完成 → 打开你的网站。大约 50 秒。

### 5. 确认

浏览器会自动打开 https://w52mc.github.io/ ，按 `Cmd+Shift+R` 强制刷新就能看到新文章。

## 关于草稿的三个要点

**① 草稿只能放在本地**

只要文件里有 `draft: true`，`publish` 脚本就会把它排除在提交之外。所以草稿**永远不会出现在 GitHub 上**，只有你自己电脑上有。

⚠️ **这意味着草稿没有备份**。如果硬盘坏了，草稿会丢。重要的草稿建议另外复制一份（比如放到 iCloud、或者用 Obsidian 管理）。

**② 草稿本地可预览，线上绝不出现**

|  | 本地 (`pnpm dev`) | 线上 (GitHub Pages) |
| --- | --- | --- |
| `draft: true` | ✅ 可见，可预览 | ❌ 完全不显示 |
| `draft: false` | ✅ 可见 | ✅ 发布 |

**③ 想发布时只改一个字**

把 `draft: true` 改成 `draft: false`，然后运行 `publish`。

## 常用操作

| 我想… | 怎么做 |
| --- | --- |
| 写新文章 | `hx src/content/posts/新文件名.md` |
| 本地预览 | `pnpm dev` → http://localhost:4321 |
| 发布所有改动 | `publish` |
| 发布并自定义说明 | `publish "修复错别字"` |
| 不等部署结果就关掉 | `SKIP_WAIT=1 publish` |
| 进入博客目录 | `blog` |
| 看部署进度 | https://github.com/w52mc/w52mc.github.io/actions |
| 改站点配置 | `hx astro-paper.config.ts` |
| 改界面文字 | `hx src/i18n/lang/zh.ts` |
| 改配色 | `hx src/styles/theme.css` |

> `publish` 和 `blog` 是给你配的快捷命令（在 `~/dotfiles/zsh/zshrc` 里定义）。如果提示找不到命令，先执行 `source ~/.zshrc` 或重开终端。

## 修改已有文章

直接编辑文件，改完运行 `publish` 就行。

如果想让文章顶部显示「更新于」时间，在 frontmatter 里加：

```yaml
modDatetime: 2026-09-13T10:00:00+08:00
```

## 删除文章

```sh
rm src/content/posts/要删的文章.md
publish
```

线上会在部署完成后同步移除。

## 写在什么地方

| 内容 | 位置 |
| --- | --- |
| 博客文章 | `src/content/posts/*.md` |
| 「关于」页面 | `src/content/pages/about.md` |
| 站点配置（站名、作者、社交链接） | `astro-paper.config.ts` |
| 界面文案（导航、按钮文字） | `src/i18n/lang/zh.ts` |
| 配色主题 | `src/styles/theme.css` |
| 文章模板参考 | `reference/theme-docs/`（主题官方文档，不参与构建） |

## 遇到问题

**推送失败**
```sh
gh auth refresh -s workflow   # 补权限
publish
```

**本地页面报错或显示异常**
```sh
# 停掉服务，清缓存，重启
pkill -f "astro dev"
rm -rf .astro dist
pnpm dev
```

**线上还是旧内容**
按 `Cmd+Shift+R` 强制刷新（浏览器缓存）。如果仍然不对，去 [Actions 页面](https://github.com/w52mc/w52mc.github.io/actions) 看部署是否成功。
