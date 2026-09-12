#!/usr/bin/env bash
#
# 一键发布博客
#
#   ./publish.sh              自动生成提交信息
#   ./publish.sh "修复错别字"   使用自定义提交信息
#
# 流程：检查改动 → 提交 → 推送 → 等待自动部署 → 打开线上页面
#
set -uo pipefail

# ── 配置 ──────────────────────────────────────────────────────────────

PROJECT_DIR="/Users/w/Documents/code/2026/blog-easy"
SITE_URL="https://w52mc.github.io/"
AUTHOR="碳水化合物"
DEPLOY_TIMEOUT=420   # 等待部署的最长秒数
SKIP_WAIT="${SKIP_WAIT:-0}"
NO_OPEN="${NO_OPEN:-0}"

# ── 输出样式 ──────────────────────────────────────────────────────────

if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'
  GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

info()  { printf '%s\n' "  $*"; }
ok()    { printf '%s\n' "  ${GREEN}✓${RESET} $*"; }
warn()  { printf '%s\n' "  ${YELLOW}!${RESET} $*"; }
fail()  { printf '%s\n' "  ${RED}✗${RESET} $*"; }
step()  { printf '\n%s\n' "${BOLD}${BLUE}▸ $*${RESET}"; }
die()   { fail "$*"; exit 1; }

printf '\n%s\n' "${BOLD}📝 博客发布${RESET}"

# ── 1. 进入项目 ───────────────────────────────────────────────────────

step "检查项目"

[ -d "$PROJECT_DIR" ] || die "找不到项目目录：$PROJECT_DIR"
cd "$PROJECT_DIR" || die "无法进入项目目录"

git rev-parse --git-dir >/dev/null 2>&1 || die "这不是一个 Git 仓库"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
[ "$BRANCH" = "main" ] || warn "当前分支是 $BRANCH（部署只监听 main）"

ok "项目：$(basename "$PROJECT_DIR")　分支：$BRANCH"

# ── 2. 检查改动 ───────────────────────────────────────────────────────

step "检查改动"

if [ -z "$(git status --porcelain)" ]; then
  warn "没有任何改动，无需发布"
  printf '\n%s\n\n' "${DIM}提示：文章写完保存后，再运行这个脚本。${RESET}"
  exit 0
fi

CHANGED=$(git status --porcelain | wc -l | tr -d ' ')
info "共 $CHANGED 个文件有改动："
git status --short | head -15 | sed 's/^/    /'
[ "$CHANGED" -gt 15 ] && info "    ${DIM}…还有 $((CHANGED - 15)) 个${RESET}"

# ── 自动补全 frontmatter ──────────────────────────────────────────────
# 你只写正文，标题/日期/作者等字段自动生成

FILLED=$(git status --porcelain \
  | awk '{print $NF}' \
  | grep -E '^src/content/posts/.*\.(md|mdx)$' 2>/dev/null \
  | while read -r f; do
      [ -f "$f" ] || continue
      python3 - "$f" "$AUTHOR" <<'PYEOF'
import re, sys, datetime, pathlib

path, author = sys.argv[1], sys.argv[2]
p = pathlib.Path(path)
raw = p.read_text(encoding="utf-8")

# 从文件名生成标题：去掉扩展名，连字符/下划线转空格，英文单词首字母大写
stem = re.sub(r"\.(md|mdx)$", "", p.name)
title = re.sub(r"[-_]+", " ", stem).strip()
if not re.search(r"[\u4e00-\u9fff]", title):
    title = " ".join(w.capitalize() for w in title.split())

now = datetime.datetime.now().astimezone()
now_str = now.strftime("%Y-%m-%dT%H:%M:%S%z")
now_str = re.sub(r"([+-]\d{2})(\d{2})$", r"\1:\2", now_str)

defaults = {
    "title": title,
    "author": author,
    "pubDatetime": now_str,
    "draft": "false",
    "tags": "[]",
    "description": "",
}

changed = False

if raw.startswith("---"):
    # 已有 frontmatter：补齐缺失字段
    end = raw.find("\n---", 3)
    if end == -1:
        sys.exit(0)
    fm = raw[3:end]
    had_keys = set(re.findall(r"^([A-Za-z_][A-Za-z0-9_]*):", fm, re.M))
    missing = {k: v for k, v in defaults.items() if k not in had_keys}
    if missing:
        extra = "".join(f"\n{k}: {v if v else '\"\"'}" for k, v in missing.items())
        raw = raw[:end] + extra + raw[end:]
        changed = True
else:
    # 完全没有 frontmatter：补一整块
    body = raw.lstrip("\n")
    fm_block = (
        "---\n"
        f"title: {defaults['title']}\n"
        f"author: {defaults['author']}\n"
        f"pubDatetime: {defaults['pubDatetime']}\n"
        f"draft: {defaults['draft']}\n"
        f"tags: {defaults['tags']}\n"
        'description: ""\n'
        "---\n\n"
    )
    raw = fm_block + body
    changed = True

if changed:
    p.write_text(raw, encoding="utf-8")
    print(path)
PYEOF
    done) || true

if [ -n "${FILLED:-}" ]; then
  FILLED_COUNT=$(printf '%s\n' "$FILLED" | grep -c . || true)
  printf '\n'
  ok "自动补全了 $FILLED_COUNT 篇文章的信息："
  printf '%s\n' "$FILLED" | while read -r f; do
    [ -n "$f" ] || continue
    t=$(awk '/^title:/{sub(/^title:[[:space:]]*/, ""); gsub(/^["'"'"']|["'"'"']$/, ""); print; exit}' "$f")
    info "    ${DIM}·${RESET} ${t:-$(basename "$f")}"
  done
  info "  ${DIM}标题取自文件名，日期取当前时间。想改就直接编辑文件。${RESET}"
fi

# 草稿文件：draft: true —— 只在本地保留，绝不提交
DRAFTS=$(git status --porcelain \
  | awk '{print $NF}' \
  | grep -E '^src/content/posts/.*\.(md|mdx)$' 2>/dev/null \
  | while read -r f; do
      [ -f "$f" ] || continue
      grep -qiE '^draft:[[:space:]]*true' "$f" && printf '%s\n' "$f"
    done) || true

DRAFT_COUNT=0
if [ -n "${DRAFTS:-}" ]; then
  DRAFT_COUNT=$(printf '%s\n' "$DRAFTS" | grep -c . || true)
fi

if [ "$DRAFT_COUNT" -gt 0 ]; then
  printf '\n'
  warn "发现 $DRAFT_COUNT 篇草稿（draft: true），本次不会提交："
  printf '%s\n' "$DRAFTS" | while read -r f; do
    [ -n "$f" ] || continue
    t=$(awk '/^title:/{sub(/^title:[[:space:]]*/, ""); gsub(/^["'"'"']|["'"'"']$/, ""); print; exit}' "$f")
    info "    ${DIM}·${RESET} ${t:-$(basename "$f")}"
  done
  info "  ${DIM}要发布草稿：把文件里的 draft: true 改成 draft: false${RESET}"
fi

# ── 3. 生成提交信息 ───────────────────────────────────────────────────

step "生成提交信息"

if [ $# -ge 1 ] && [ -n "${1:-}" ]; then
  MSG="$1"
  info "使用你指定的信息"
else
  # 标题检测：先看本次改动的文章，没有再取最近的文章
  TITLES=$(git status --porcelain \
    | awk '{print $NF}' \
    | grep -E '^src/content/posts/.*\.(md|mdx)$' 2>/dev/null \
    | while read -r f; do
        [ -f "$f" ] || continue
        grep -qiE '^draft:[[:space:]]*true' "$f" && continue
        awk '/^title:/{sub(/^title:[[:space:]]*/, ""); gsub(/^["'"'"']|["'"'"']$/, ""); print; exit}' "$f"
      done \
    | head -3)

  POST_COUNT=0
  if [ -n "$TITLES" ]; then
    POST_COUNT=$(printf '%s\n' "$TITLES" | grep -c . || true)
  fi

  # 改动里没有文章（例如只删了一篇、或文章早已提交）：取最近修改的一篇标题
  if [ "$POST_COUNT" -eq 0 ]; then
    RECENT=$(ls -t src/content/posts/*.md src/content/posts/*.mdx 2>/dev/null | head -1)
    if [ -n "$RECENT" ]; then
      TITLES=$(awk '/^title:/{sub(/^title:[[:space:]]*/, ""); gsub(/^["'"'"']|["'"'"']$/, ""); print; exit}' "$RECENT")
      [ -n "$TITLES" ] && POST_COUNT=1
    fi
  fi

  if [ "$POST_COUNT" -gt 0 ]; then
    FIRST=$(printf '%s\n' "$TITLES" | head -1)
    if [ "$POST_COUNT" -eq 1 ]; then
      MSG="post: $FIRST"
    else
      MSG="post: $FIRST 等 $POST_COUNT 篇"
    fi
  elif git status --porcelain | grep -q '^.. src/content/pages/'; then
    MSG="chore: 更新页面"
  elif git status --porcelain | grep -qE '^.. (astro-paper\.config\.ts|astro\.config\.ts|src/i18n|src/styles)'; then
    MSG="chore: 调整站点配置"
  else
    MSG="chore: 更新 $(date '+%Y-%m-%d %H:%M')"
  fi
fi

info "提交信息：${BOLD}$MSG${RESET}"

# ── 4. 提交并推送 ─────────────────────────────────────────────────────

step "提交并推送"

git add -A || die "暂存失败"

# 把草稿从暂存区撤出，让它们只留在本地
if [ "$DRAFT_COUNT" -gt 0 ]; then
  printf '%s\n' "$DRAFTS" | while read -r f; do
    [ -n "$f" ] || continue
    git reset -q HEAD -- "$f" 2>/dev/null || true
  done
  ok "已排除 $DRAFT_COUNT 篇草稿（保留在本地）"
fi

if git diff --cached --quiet; then
  warn "排除草稿后没有可提交的内容"
  printf '\n%s\n\n' "  ${DIM}你的草稿还在本地。要发布它们，把 draft: true 改成 draft: false 再运行。${RESET}"
  exit 0
fi

if ! git commit -q -m "$MSG"; then
  die "提交失败"
fi
ok "已提交：$(git log --oneline -1 | cut -c1-60)"

printf '  %s' "推送到 GitHub…"
if ! git push 2>/tmp/blog_push_err.log; then
  printf '\r\033[K'
  fail "推送失败"
  sed 's/^/    /' /tmp/blog_push_err.log | head -8
  printf '\n%s\n' "${DIM}提示：如果是权限问题，运行 gh auth refresh -s workflow 后重试${RESET}"
  exit 1
fi
printf '\r\033[K'
ok "推送成功"

# ── 5. 等待部署 ───────────────────────────────────────────────────────

step "等待自动部署"

if [ "$SKIP_WAIT" = "1" ]; then
  warn "已跳过等待（SKIP_WAIT=1）"
elif ! command -v gh >/dev/null 2>&1; then
  warn "未安装 gh，无法查询部署进度"
  info "可在这里手动查看：https://github.com/w52mc/w52mc.github.io/actions"
else
  RUN_ID=""
  info "查找部署任务…"
  for _ in $(seq 1 12); do
    RUN_ID=$(gh run list --repo w52mc/w52mc.github.io --limit 8 \
      --json databaseId,headSha,status,createdAt \
      --jq "[.[] | select(.headSha == \"$(git rev-parse HEAD)\")] | .[0].databaseId" 2>/dev/null)
    [ -n "$RUN_ID" ] && [ "$RUN_ID" != "null" ] && break
    sleep 5
  done

  if [ -z "$RUN_ID" ] || [ "$RUN_ID" = "null" ]; then
    warn "没找到对应的部署任务，可能还在排队"
    info "进度：https://github.com/w52mc/w52mc.github.io/actions"
  else
    ELAPSED=0
    STATUS=""
    while [ "$ELAPSED" -lt "$DEPLOY_TIMEOUT" ]; do
      RESULT=$(gh api "repos/w52mc/w52mc.github.io/actions/runs/$RUN_ID" \
        --jq '.status + "|" + (.conclusion // "")' 2>/dev/null)
      STATUS="${RESULT%%|*}"
      CONCLUSION="${RESULT##*|}"
      if [ "$STATUS" = "completed" ]; then break; fi
      printf '\r    %s 已等待 %ss…' "$(printf '%s' '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' | cut -c$(( (ELAPSED / 2) % 10 + 1 )))" "$ELAPSED"
      sleep 5
      ELAPSED=$((ELAPSED + 5))
    done
    printf '\r\033[K'

    if [ "$STATUS" = "completed" ] && [ "$CONCLUSION" = "success" ]; then
      ok "部署完成（用时约 ${ELAPSED}s）"
    elif [ "$STATUS" = "completed" ]; then
      fail "部署失败：$CONCLUSION"
      info "日志：https://github.com/w52mc/w52mc.github.io/actions/runs/$RUN_ID"
      exit 1
    else
      warn "等待超时（${DEPLOY_TIMEOUT}s），部署可能仍在进行"
      info "进度：https://github.com/w52mc/w52mc.github.io/actions"
    fi
  fi
fi

# ── 6. 打开线上页面 ───────────────────────────────────────────────────

step "线上地址"

if [ "$NO_OPEN" != "1" ] && command -v open >/dev/null 2>&1; then
  open "$SITE_URL" 2>/dev/null && ok "已在浏览器打开"
fi

printf '\n%s\n' "  ${BOLD}${GREEN}🎉 发布完成${RESET}"
printf '%s\n\n' "  ${SITE_URL}"
printf '%s\n\n' "  ${DIM}若显示旧内容，按 Cmd+Shift+R 强制刷新${RESET}"
