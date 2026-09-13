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

# ── 部署查询（检查改动、等待部署都要用）───────────────────────────────

RUN_REPO="w52mc/w52mc.github.io"

# 找某个 commit 对应的 workflow run，成功则打印 run id
find_run_id() {
  local sha="$1" rid=""
  for _ in $(seq 1 12); do
    rid=$(gh run list --repo "$RUN_REPO" --limit 8 \
      --json databaseId,headSha,status,createdAt \
      --jq "[.[] | select(.headSha == \"$sha\")] | .[0].databaseId" 2>/dev/null)
    if [ -n "$rid" ] && [ "$rid" != "null" ]; then printf '%s' "$rid"; return 0; fi
    sleep 5
  done
  return 1
}

# 查询 run 状态，输出 "status|conclusion"
run_state() {
  gh api "repos/$RUN_REPO/actions/runs/$1" \
    --jq '.status + "|" + (.conclusion // "")' 2>/dev/null
}

# 等待 run 结束：部署成功返回 0，失败返回 1
wait_deploy() {
  local run_id="$1" elapsed=0 status="" conclusion="" state=""
  while [ "$elapsed" -lt "$DEPLOY_TIMEOUT" ]; do
    state=$(run_state "$run_id")
    status="${state%%|*}"
    conclusion="${state##*|}"
    [ "$status" = "completed" ] && break
    printf '\r    %s 已等待 %ss…' "$(printf '%s' '⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏' | cut -c$(( (elapsed / 2) % 10 + 1 )))" "$elapsed"
    sleep 5
    elapsed=$((elapsed + 5))
  done
  printf '\r\033[K'

  if [ "$status" = "completed" ] && [ "$conclusion" = "success" ]; then
    ok "部署完成（用时约 ${elapsed}s）"
    return 0
  elif [ "$status" = "completed" ]; then
    fail "部署失败：$conclusion"
    info "日志：https://github.com/$RUN_REPO/actions/runs/$run_id"
    return 1
  else
    warn "等待超时（${DEPLOY_TIMEOUT}s），部署可能仍在进行"
    info "进度：https://github.com/$RUN_REPO/actions"
    return 0
  fi
}

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

# 上次 push 失败会把提交留在本地：工作区是干净的，但它们还没上去
UNPUSHED=$(git rev-list --count HEAD --not --remotes 2>/dev/null || echo 0)
[ -n "$UNPUSHED" ] || UNPUSHED=0

if [ -z "$(git status --porcelain)" ] && [ "$UNPUSHED" -eq 0 ]; then
  # 没有新内容。如果上次是部署失败，允许直接重跑，不用再提交一次。
  if command -v gh >/dev/null 2>&1; then
    LAST=$(gh run list --repo "$RUN_REPO" --limit 8 \
      --json databaseId,headSha,status,conclusion \
      --jq "[.[] | select(.headSha == \"$(git rev-parse HEAD)\")] | .[0] // empty | \"\(.databaseId)|\(.status)|\(.conclusion // \"\")\"" 2>/dev/null)
    if [ -n "$LAST" ]; then
      LAST_ID="${LAST%%|*}"
      REST="${LAST#*|}"
      LAST_STATUS="${REST%%|*}"
      LAST_CONCL="${REST##*|}"
      if [ "$LAST_STATUS" = "completed" ] && [ "$LAST_CONCL" = "failure" ]; then
        printf '\n'
        warn "没有新改动，但上次部署失败了，正在重新部署…"
        step "重跑部署"
        if gh run rerun "$LAST_ID" --repo "$RUN_REPO" >/dev/null 2>&1; then
          ok "已重新触发（run $LAST_ID）"
          wait_deploy "$LAST_ID" || exit 1
          printf '\n%s\n\n' "  ${BOLD}${GREEN}🎉 部署完成${RESET}"
          exit 0
        fi
        fail "重新触发失败，请手动打开："
        info "https://github.com/$RUN_REPO/actions/runs/$LAST_ID"
        exit 1
      elif [ "$LAST_STATUS" != "completed" ]; then
        warn "没有新改动，上次的部署还在进行中"
        info "https://github.com/$RUN_REPO/actions/runs/$LAST_ID"
        exit 0
      else
        ok "没有新改动，当前版本已部署成功"
        info "线上地址：${SITE_URL}"
        printf '\n%s\n\n' "${DIM}若显示旧内容，按 Cmd+Shift+R 强制刷新${RESET}"
        exit 0
      fi
    fi
  fi
  warn "没有任何改动，也没有待推送的提交，无需发布"
  printf '\n%s\n\n' "${DIM}提示：文章写完保存后，再运行这个脚本。${RESET}"
  exit 0
fi

if [ "$UNPUSHED" -gt 0 ]; then
  printf '\n'
  ok "发现 $UNPUSHED 个还没推送成功的提交，这次会一起推上去"
fi

CHANGED=$(git status --porcelain | wc -l | tr -d ' ')
if [ "$CHANGED" -gt 0 ]; then
  info "共 $CHANGED 个文件有改动："
  git status --short | head -15 | sed 's/^/    /'
  [ "$CHANGED" -gt 15 ] && info "    ${DIM}…还有 $((CHANGED - 15)) 个${RESET}"
fi

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

# 标题优先取正文里的一级标题（`# 标题`）；没有才用文件名兜底
# 文件名：去掉扩展名，连字符/下划线转空格，英文单词首字母大写
stem = re.sub(r"\.(md|mdx)$", "", p.name)
title = re.sub(r"[-_]+", " ", stem).strip()
if not re.search(r"[\u4e00-\u9fff]", title):
    title = " ".join(w.capitalize() for w in title.split())

# 跳过 frontmatter 和围栏代码块，找第一个 `# 标题`
def heading_title(text):
    in_fm = text.startswith("---")
    fence = None
    for line in text.splitlines():
        s = line.strip()
        if in_fm:
            if s == "---":
                in_fm = False
            continue
        if fence:
            if s.startswith(fence):
                fence = None
            continue
        if s.startswith("```") or s.startswith("~~~"):
            fence = s[:3]
            continue
        if re.match(r"^#\s+\S", s):
            return s.lstrip("#").strip()
    return ""

body_title = heading_title(raw)
if body_title:
    title = body_title

now = datetime.datetime.now().astimezone()
now_str = now.strftime("%Y-%m-%dT%H:%M:%S%z")
now_str = re.sub(r"([+-]\d{2})(\d{2})$", r"\1:\2", now_str)

defaults = {
    "title": title,
    "author": author,
    "pubDatetime": now_str,
    "draft": "false",
    # 不写 tags：交给 schema 的默认值 ["others"]（src/content.config.ts:18）
    # 写 tags: [] 反而会让文章一个标签都没有
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

    # 已经有 title 时，让 frontmatter 跟正文一级标题保持一致
    if body_title:
        m = re.search(r"^title:[ \t]*(.*)$", fm, re.M)
        current = (m.group(1).strip() if m else "").strip("\"'").strip()
        if m and current != body_title:
            # fm 是 raw[3:end]，行内偏移要补上前面 3 个字符的 `---`
            start = 3 + m.start(1)
            end_at = 3 + m.end(1)
            raw = raw[:start] + body_title + raw[end_at:]
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

SKIP_TAGS=0
if [ "${1:-}" = "-t" ] || [ "${1:-}" = "--no-tags" ]; then
  SKIP_TAGS=1
  [ $# -ge 1 ] && shift
fi

# 给还没有标签的文章问一次标签（有标签的不动；草稿不问）
if [ "$SKIP_TAGS" = "0" ]; then
  TAG_FILES=$(git status --porcelain \
    | awk '{print $NF}' \
    | grep -E '^src/content/posts/.*\.(md|mdx)$' 2>/dev/null \
    | while read -r f; do
        [ -f "$f" ] || continue
        grep -qiE '^draft:[[:space:]]*true' "$f" && continue
        printf '%s\n' "$f"
      done) || true

  if [ -n "${TAG_FILES:-}" ]; then
    printf '\n'
    info "${BOLD}标签${RESET}"
    if [ -r /dev/tty ]; then
      # 把 stdin 直接接到终端，键盘输入不受调用方式影响
      python3 src/utils/tag_prompt.py $TAG_FILES < /dev/tty
    else
      warn "当前会话读不到终端（/dev/tty），跳过标签输入"
      info "  ${DIM}可手动编辑文章 frontmatter 的 tags 字段${RESET}"
    fi
  fi
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
  if [ "$UNPUSHED" -gt 0 ]; then
    ok "没有新的改动，跳过提交，直接补推那 $UNPUSHED 个提交"
  else
    warn "排除草稿后没有可提交的内容"
    printf '\n%s\n\n' "  ${DIM}你的草稿还在本地。要发布它们，把 draft: true 改成 draft: false 再运行。${RESET}"
    exit 0
  fi
else
  if ! git commit -q -m "$MSG"; then
    die "提交失败（改动还在工作区，处理完再运行本脚本即可）"
  fi
  ok "已提交：$(git log --oneline -1 | cut -c1-60)"
fi

printf '  %s' "推送到 GitHub…"
PUSHED=0
if git push 2>/tmp/blog_push_err.log; then
  PUSHED=1
elif grep -qiE "non-fast-forward|fetch first|\[rejected\]" /tmp/blog_push_err.log; then
  # 远端有新提交（例如在网页上改过），先同步再推一次
  printf '\r\033[K'
  warn "远端有新的提交，正在自动同步后重试…"
  if git pull --rebase --autostash -q && git push 2>/tmp/blog_push_err.log; then
    PUSHED=1
    info "已自动合并远端改动"
  fi
fi

printf '\r\033[K'
if [ "$PUSHED" = "1" ]; then
  ok "推送成功"
else
  fail "推送失败"
  sed 's/^/    /' /tmp/blog_push_err.log | head -8
  printf '\n'
  warn "提交已经存在本地了，不会丢"
  info "网络或权限恢复后，${BOLD}再运行一次本脚本${RESET}就会继续把它推上去"
  info "如果是权限问题：${BOLD}gh auth refresh -s workflow${RESET}"
  exit 1
fi

# ── 5. 等待部署 ───────────────────────────────────────────────────────

step "等待自动部署"

if [ "$SKIP_WAIT" = "1" ]; then
  warn "已跳过等待（SKIP_WAIT=1）"
elif ! command -v gh >/dev/null 2>&1; then
  warn "未安装 gh，无法查询部署进度"
  info "可在这里手动查看：https://github.com/$RUN_REPO/actions"
else
  info "查找部署任务…"
  if ! RUN_ID=$(find_run_id "$(git rev-parse HEAD)"); then
    warn "没找到对应的部署任务，可能还在排队"
    info "进度：https://github.com/$RUN_REPO/actions"
  else
    wait_deploy "$RUN_ID" || exit 1
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
