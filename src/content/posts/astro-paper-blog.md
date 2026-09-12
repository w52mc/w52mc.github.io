---
title: 用 AstroPaper 搭一个静态博客
author: 碳水化合物
pubDatetime: 2026-09-08T20:00:00+08:00
draft: false
tags:
  - Astro
  - 建站
description: 从手写极简模板改用成熟主题，以及部署到 GitHub Pages 的关键配置。
---

我想要一个博客，条件很明确：写得舒服、加载够快、样式干净。

## 先是自己写

最开始我手写了一个极简模板：一个布局文件、一个样式表、三个页面。首页只有日期和标题，没有侧边栏，没有评论区，构建出来连一个 JavaScript 文件都没有。

```text
src/
├── layouts/BaseLayout.astro
├── pages/index.astro
├── pages/posts/[slug].astro
└── styles/global.css
```

这确实够轻，但很快就发现少了些东西：标签、分页、归档、搜索，每一样都得自己写。于是换成了 [AstroPaper](https://github.com/satnaing/astro-paper)。

## 换主题得到了什么

AstroPaper 是一个成熟的 Astro 博客主题，开箱就有：

- 标签页与归档页
- 文章分页
- 静态搜索（Pagefind）
- 亮色 / 暗色主题切换
- RSS 与 sitemap
- MDX 支持
- 自动生成社交分享图

代价是项目结构复杂了不少，依赖也多了。**极简和功能之间总是要取舍的。**

## GitHub Pages 子路径的关键配置

这是部署时最容易踩的坑。如果仓库不是 `用户名.github.io` 这种根仓库，站点会挂在子路径下，比如 `/blog-easy/`。

这时候有两件事必须做对。

**第一，配置 `site` 和 `base`：**

```ts
export default defineConfig({
  site: "https://w52mc.github.io/",
  base: process.env.NODE_ENV === "production" ? "/blog-easy" : "",
});
```

本地开发用根路径，构建时自动加前缀，这样两边都能正常预览。

**第二，站内链接不能用绝对路径。**

写成 `/posts/hello/` 会跳到 `域名/posts/hello/`，正确地址其实是 `域名/blog-easy/posts/hello/`。主题里用 `withBase()` 这类工具统一处理：

```ts
const base = import.meta.env.BASE_URL.replace(/\/+$/, "");
const baseRoot = base === "" ? "/" : `${base}/`;
```

## 部署方式

用 GitHub Actions 自动构建部署，只需要在仓库设置里把 Pages 的来源指定为 Actions。之后每次 `git push`，站点会自动更新。

## 小结

自己写模板能完全掌控样式，但功能要一点点补。用成熟主题则相反——功能是现成的，但要花时间理解它的结构。

如果目标是**尽快开始写文章**，成熟主题通常是更划算的选择。
