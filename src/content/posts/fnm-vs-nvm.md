---
title: fnm 和 nvm 该怎么选
author: 碳水化合物
pubDatetime: 2026-09-10T10:00:00+08:00
draft: false
tags:
  - Node.js
  - 工具
description: 两个 Node 版本管理器的差别，以及我为什么最终留下了 fnm。
---

管理 Node 版本的工具不少，最常被提到的是 nvm 和 fnm。两个都能用，但体验差别不小。

## 最直观的差别：速度

nvm 是 Shell 脚本写的，每次打开终端都要先执行一遍它的代码。fnm 是编译好的程序，启动几乎瞬间完成。

打开的终端窗口越多，这个差距越明显。

## 自动切换

这是 fnm 最让人满意的地方。在项目里放一个 `.node-version` 文件：

```sh
echo "20.11.0" > .node-version
```

之后只要 `cd` 进这个目录，版本就自动切好了。nvm 需要每次手动敲 `nvm use`。

## 它们其实可以互换

两个工具读同样的版本文件：

- `.nvmrc`
- `.node-version`

所以从一个换到另一个没有任何迁移成本。

## 命令对照

| nvm                  | fnm             |
| -------------------- | --------------- |
| `nvm install 20`     | `fnm install 20`|
| `nvm use 20`         | `fnm use 20`    |
| `nvm ls`             | `fnm list`      |
| `nvm alias default 20` | `fnm default 20` |

规律很简单：把 `nvm` 换成 `fnm`，参数基本照抄。

## 一个容易困惑的地方

装了新版本并设为默认之后，**当前已经打开的终端窗口不会自动切换**。每个终端会话在启动时就绑定了当时的版本。

```sh
fnm default 24    # 改了默认版本
node -v           # 旧窗口里还是老版本
exec zsh          # 重启当前 Shell 才会生效
```

记住这个区别就不容易被绕进去：`fnm use` 立即生效，`fnm default` 只影响以后新开的窗口。

## 什么时候选 nvm

如果你的 shell 是 bash，而且不介意启动速度，nvm 完全够用。它的生态更成熟，网上教程也更多。

但如果追求终端响应速度，或者用 zsh / fish，fnm 是更舒服的选择。
