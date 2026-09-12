#!/usr/bin/env bash
#
# 新建文章
#
#   newpost 我的文章标题
#   newpost                    → 使用当天日期作为标题
#
# 会用 Helix 打开新文件，写完保存退出，然后运行 publish 即可发布。
#
set -uo pipefail

PROJECT_DIR="/Users/w/Documents/code/2026/blog-easy"
POSTS_DIR="$PROJECT_DIR/src/content/posts"

if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; RED=$'\033[31m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; GREEN=""; YELLOW=""; RED=""; RESET=""
fi

die() { printf '  %s✗%s %s\n' "$RED" "$RESET" "$*"; exit 1; }

[ -d "$POSTS_DIR" ] || die "找不到文章目录：$POSTS_DIR"

# ── 标题与文件名 ──────────────────────────────────────────────────────

TITLE="${*:-}"
if [ -z "$TITLE" ]; then
  TITLE=$(date '+%Y-%m-%d')
fi

# 由标题生成文件名：保留中英文与数字，其余转为连字符
FILENAME=$(printf '%s' "$TITLE" | python3 -c "
import re, sys
s = sys.stdin.read().strip().lower()
s = re.sub(r'[^\w\s-]', '', s, flags=re.UNICODE)   # 去掉标点
s = re.sub(r'[\s_]+', '-', s)                       # 空格转连字符
s = re.sub(r'-+', '-', s).strip('-')
print(s)
")

[ -n "$FILENAME" ] || die "无法生成文件名，请换一个标题"

FILE="$POSTS_DIR/$FILENAME.md"

if [ -e "$FILE" ]; then
  printf '  %s!%s 文件已存在，直接打开：%s\n' "$YELLOW" "$RESET" "$FILENAME.md"
else
  NOW=$(date '+%Y-%m-%dT%H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/')

  cat > "$FILE" <<EOF
---
title: $TITLE
author: 碳水化合物
pubDatetime: $NOW
draft: false
tags: []
description: ""
---

在这里写正文。

EOF

  printf '  %s✓%s 已创建 %s%s%s\n' "$GREEN" "$RESET" "$BOLD" "$FILENAME.md" "$RESET"
fi

printf '  %s文件位置：%s%s\n\n' "$DIM" "$FILE" "$RESET"

# ── 打开编辑器 ────────────────────────────────────────────────────────

EDITOR_CMD="${EDITOR:-hx}"
if command -v "$EDITOR_CMD" >/dev/null 2>&1; then
  "$EDITOR_CMD" "$FILE"
  printf '\n  %s写完保存退出后，运行 %spublish%s 发布%s\n\n' \
    "$DIM" "$BOLD$GREEN" "$RESET$DIM" "$RESET"
else
  printf '  %s未找到编辑器 %s，请手动编辑：%s%s\n\n' \
    "$YELLOW" "$EDITOR_CMD" "$FILE" "$RESET"
fi
