# 碳水化合物的博客

个人博客，记录 AI 大模型、前端与全栈开发的实践和思考。

线上地址：**https://w52mc.github.io/**

## 技术栈

- [Astro](https://astro.build/) — 静态站点框架
- [AstroPaper](https://github.com/satnaing/astro-paper) — 博客主题
- [Tailwind CSS](https://tailwindcss.com/) — 样式
- [Pagefind](https://pagefind.app/) — 静态搜索
- GitHub Pages + GitHub Actions — 托管与自动部署

## 本地开发

```sh
pnpm install     # 安装依赖
pnpm dev         # 启动开发服务器 → http://localhost:4321
pnpm build       # 构建到 dist/
pnpm preview     # 预览构建结果
```

## 写新文章

在 `src/content/posts/` 新建 `.md` 文件：

```markdown
---
title: 文章标题
author: 碳水化合物
pubDatetime: 2026-09-12T15:30:00+08:00
draft: false
tags:
  - 标签一
  - 标签二
description: 一句话摘要，会显示在列表页和搜索结果里。
---

正文从这里开始。
```

`draft: true` 的文章只在本地可见，不会被发布。

## 配置

站点信息集中在 `astro-paper.config.ts`：

| 字段 | 说明 |
| --- | --- |
| `site.url` | 站点地址 |
| `site.title` / `description` / `author` | 站名、简介、作者 |
| `posts.perPage` | 列表页每页文章数 |
| `posts.perIndex` | 首页显示文章数 |
| `features.search` | 搜索（`"pagefind"` 或 `false`） |
| `features.editPost` | 文章底部「编辑此页」链接 |
| `socials` | 页脚社交图标 |
| `shareLinks` | 文章底部分享按钮（留空数组即隐藏） |

界面文案在 `src/i18n/lang/zh.ts`。

## 部署

推送到 `main` 分支后，GitHub Actions 会自动构建并发布（见 `.github/workflows/deploy.yml`）。

## 参考

`reference/theme-docs/` 保留了 AstroPaper 主题自带的英文文档，说明如何配置主题、修改配色、添加评论等。这些文件不参与构建。

## 主题许可

基于 [AstroPaper](https://github.com/satnaing/astro-paper)，遵循 MIT 许可，详见 [LICENSE](LICENSE)。
