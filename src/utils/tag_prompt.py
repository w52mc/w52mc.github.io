#!/usr/bin/env python3
"""publish 时问标签和简介。

用法：tag_prompt.py <文章.md> [更多文章...]

对每篇文章依次问两件事，答案写回 frontmatter：
1. tags —— 没有标签的文章才问；直接回车或输入无效 → 用 others
2. description —— 没有简介的文章才问；直接回车或输入无效 → 留空

输入从 stdin 读（shell 里用 < /dev/tty 把它接到终端），
提示写到 stderr —— 不依赖打开 /dev/tty 设备。
"""
import os
import re
import sys

EMPTY_ARRAY = re.compile(r'^\[[ \t]*("")?[ \t]*(,[ \t]*"")*[ \t]*\]$')
DEFAULT_TAG = "others"


def split_frontmatter(text):
    """返回 (frontmatter, 结束位置)。没有 frontmatter 时返回 ("", -1)。"""
    if not text.startswith("---"):
        return "", -1
    end = text.find("\n---", 3)
    if end == -1:
        return "", -1
    return text[3:end], end


def read_info(path):
    """读标题、现有 tags、现有 description、是否草稿。"""
    raw = open(path, encoding="utf-8").read()
    fm, _ = split_frontmatter(raw)

    def field(name):
        m = re.search(r"^%s:[ \t]*(.*)$" % name, fm, re.M)
        return m.group(1).strip() if m else ""

    title = field("title").strip("\"'")
    tags = field("tags")
    description = field("description")
    draft = bool(re.search(r"^draft:[ \t]*true[ \t]*$", fm, re.M | re.I))
    return raw, title or path, tags, description, draft


def has_description(description):
    """description: "" 这种空壳算没有简介。"""
    return bool(re.sub(r'["\' \t]', "", description))



def has_tags(tags):
    """空数组、空壳、没有 tags 行，都算没标签。"""
    if not tags:
        return False
    if EMPTY_ARRAY.match(tags):
        return False
    return bool(re.sub(r'["\'\[\] \t,]', "", tags))


def parse_input(raw):
    """把用户输入切成标签数组。去重按小写比较（Rust 和 rust 只留先出现的那个）。"""
    out, seen = [], set()
    for t in re.split(r"[,，、]+", raw):
        t = re.sub(r'["\'\[\]#]', "", t).strip()[:20]
        if t and t.lower() not in seen:
            seen.add(t.lower())
            out.append(t)
    return out


def write_field(path, name, value_repr):
    """把 frontmatter 里的某个字段写成 value_repr（已是 YAML 值形式）。"""
    text = open(path, encoding="utf-8").read()
    fm, end = split_frontmatter(text)

    if end == -1:
        return "---\n%s: %s\n---\n\n" % (name, value_repr) + text

    m = re.search(r"^%s:[ \t]*(.*)$" % name, fm, re.M)
    if m:
        return text[: 3 + m.start(1)] + value_repr + text[3 + m.end(1):]
    return text[:end] + "\n%s: %s" % (name, value_repr) + text[end:]


def yaml_string(s):
    """YAML 双引号字符串。"""
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_tags(path, tags):
    """把 tags 写进 frontmatter。"""
    return write_field(path, "tags", "[" + ", ".join(yaml_string(t) for t in tags) + "]")


def clean_description(raw):
    """清理简介文本；空或只剩引号/空白 → 返回空字符串。"""
    s = re.sub(r"[\r\n]+", " ", raw)
    s = re.sub(r'^[\s"\'“”‘’]+|[\s"\'“”‘’]+$', "", s)
    return s.strip()



def pick_io():
    """决定从哪里读输入、往哪里写提示。

    优先 stdin（shell 里通常已经 < /dev/tty 接好了）。只有 stdin 彻底读不到
    才返回 None（此时上层会跳过标签输入）。
    """
    stdin = sys.stdin
    if not stdin.isatty():
        try:
            stdin = open("/dev/tty", "r")
        except OSError:
            stdin = sys.stdin          # /dev/tty 打不开就退回 stdin，别放弃

    if stdin is None or not getattr(stdin, "readable", lambda: False)():
        stdin = None

    out = sys.stderr if sys.stderr.isatty() else sys.stdout
    return stdin, out


def ask(prompt, fh, out):
    """问一句并读一行。读不到输入就返回 None，表示跳过。"""
    out.write(prompt)
    out.flush()
    line = fh.readline()
    return line.rstrip("\n") if line else ""


def safe_write(path, result, out):
    """写入前做一次缩水检查，防止读到的内容不完整时把正文写没。"""
    try:
        old_size = os.path.getsize(path)
    except OSError:
        old_size = 0
    if old_size and len(result.encode("utf-8")) < old_size * 0.5:
        out.write("    ! 跳过 %s：写入前检查发现内容会异常变短，已保持原文件不动\n" % path)
        return False
    with open(path, "w", encoding="utf-8") as f:
        f.write(result)
    return True


def main(argv):
    paths = argv[1:]
    if not paths:
        return 0

    stdin, out = pick_io()
    if stdin is None:
        out.write("  ! 读不到终端输入，跳过标签与简介（可手动编辑 frontmatter）\n")
        return 0

    targets = []
    for path in paths:
        try:
            raw, title, tags, description, draft = read_info(path)
        except OSError:
            continue
        if draft:                       # 草稿不打扰
            continue
        targets.append((path, title, tags, description))

    if not targets:
        return 0

    out.write("  \033[2m标签：逗号分隔，空着回车 = 用 others\033[0m\n")
    out.write("  \033[2m简介：一句话摘要，空着回车 = 留空\033[0m\n")

    saved = 0
    for path, title, tags, description in targets:
        out.write("\n  %s\n" % title)
        changed = False

        # ── 1. 标签 ────────────────────────────────────────────────
        if not has_tags(tags):
            answer = ask("  标签: ", stdin, out)
            if answer is None:
                continue
            tags = parse_input(answer) or [DEFAULT_TAG]
            # 先把新内容算出来，再打开文件写入。
            # 不能写成 f.write(write_tags(...))：open(path, "w") 会先把文件截断，
            # 那样写函数读到的是空文件，正文会被整段丢掉。
            if safe_write(path, write_tags(path, tags), out):
                out.write("    ✓ tags: " + ", ".join(tags) + "\n")
                changed = True

        # ── 2. 简介 ────────────────────────────────────────────────
        if not has_description(description):
            answer = ask("  简介: ", stdin, out)
            if answer is None:
                continue
            desc = clean_description(answer)
            if safe_write(path, write_field(path, "description", yaml_string(desc)), out):
                out.write("    ✓ description: %s\n" % (desc if desc else "(空)"))
                changed = True

        if changed:
            saved += 1

    if saved:
        out.write("  \033[2m已更新 %d 篇文章；想改就直接编辑文件\033[0m\n" % saved)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
