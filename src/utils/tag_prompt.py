#!/usr/bin/env python3
"""publish 时的标签输入。

用法：tag_prompt.py <文章.md> [更多文章...]

对每篇"还没有标签"的文章，在终端上问一次标签，写回 frontmatter 的 tags 字段。
已经有标签的文章直接跳过，不动它。

- 输入用逗号分隔，例如：python, 爬虫
- 直接回车 = 跳过这篇（保持原样，不写 tags 字段）
- 输入 others = 用系统默认标签

交互走 /dev/tty，所以无论这个脚本的 stdin 被重定向成什么都能正常读键盘。
"""
import re
import sys

EMPTY_ARRAY = re.compile(r'^\[[ \t]*("")?[ \t]*(,[ \t]*"")*[ \t]*\]$')


def split_frontmatter(text):
    """返回 (frontmatter, 结束位置)。没有 frontmatter 时返回 ("", -1)。"""
    if not text.startswith("---"):
        return "", -1
    end = text.find("\n---", 3)
    if end == -1:
        return "", -1
    return text[3:end], end


def read_info(path):
    """读标题和现有 tags。"""
    raw = open(path, encoding="utf-8").read()
    fm, _ = split_frontmatter(raw)
    m = re.search(r"^title:[ \t]*(.*)$", fm, re.M)
    title = m.group(1).strip().strip("\"'") if m else ""
    t = re.search(r"^tags:[ \t]*(.*)$", fm, re.M)
    tags = t.group(1).strip() if t else ""
    return raw, title or path, tags


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


def write_tags(path, tags):
    """把 tags 写进 frontmatter。"""
    value = "[" + ", ".join('"%s"' % t for t in tags) + "]"
    text = open(path, encoding="utf-8").read()
    fm, end = split_frontmatter(text)

    if end == -1:
        return "---\ntags: " + value + "\n---\n\n" + text

    m = re.search(r"^tags:[ \t]*(.*)$", fm, re.M)
    if m:
        return text[: 3 + m.start(1)] + value + text[3 + m.end(1):]
    return text[:end] + "\ntags: " + value + text[end:]


def ask(prompt, tty):
    """在终端上问一句。拿不到终端（非交互环境）就返回 None，表示跳过。"""
    if tty is None:
        return None
    tty.write(prompt)
    tty.flush()
    line = tty.readline()
    return line.rstrip("\n") if line else ""


def main(argv):
    paths = argv[1:]
    if not paths:
        return 0

    try:
        tty = open("/dev/tty", "r+")
    except OSError:
        tty = None

    if tty is None:
        print("  ! 没有可用终端，跳过标签输入")
        return 0

    targets = []
    for path in paths:
        try:
            raw, title, tags = read_info(path)
        except OSError:
            continue
        if not has_tags(tags):
            targets.append((path, title))

    if not targets:
        print("  没有需要填标签的文章")
        return 0

    print("  \033[2m标签：逗号分隔；直接回车跳过；输入 others 用系统默认标签\033[0m")
    saved = 0
    for path, title in targets:
        answer = ask("\n  %s\n  标签: " % title, tty)
        if answer is None:
            continue
        tags = parse_input(answer)
        if not tags:
            continue
        with open(path, "w", encoding="utf-8") as f:
            f.write(write_tags(path, tags))
        print("    ✓ " + ", ".join(tags))
        saved += 1

    if saved:
        print("  \033[2m已写入 %d 篇文章；想改就直接编辑文件\033[0m" % saved)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
