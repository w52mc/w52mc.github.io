#!/usr/bin/env python3
"""publish 时的标签输入。

用法：tag_prompt.py <文章.md> [更多文章...]

对每篇"还没有标签"的文章，在终端上问一次标签，写回 frontmatter 的 tags 字段。
已经有标签的文章直接跳过，不动它。

- 输入用逗号分隔，例如：python, 爬虫
- 直接回车 = 跳过这篇（保持原样，不写 tags 字段）
- 输入 others = 用系统默认标签

输入从 stdin 读（shell 里用 < /dev/tty 把它接到终端），
提示写到 stderr —— 不依赖打开 /dev/tty 设备。
"""
import os
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
    """读标题、现有 tags、是否草稿。"""
    raw = open(path, encoding="utf-8").read()
    fm, _ = split_frontmatter(raw)
    m = re.search(r"^title:[ \t]*(.*)$", fm, re.M)
    title = m.group(1).strip().strip("\"'") if m else ""
    t = re.search(r"^tags:[ \t]*(.*)$", fm, re.M)
    tags = t.group(1).strip() if t else ""
    draft = bool(re.search(r"^draft:[ \t]*true[ \t]*$", fm, re.M | re.I))
    return raw, title or path, tags, draft


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


def main(argv):
    paths = argv[1:]
    if not paths:
        return 0

    stdin, out = pick_io()
    if stdin is None:
        out.write("  ! 读不到终端输入，跳过标签（可手动编辑 frontmatter 的 tags）\n")
        return 0

    targets = []
    for path in paths:
        try:
            raw, title, tags, draft = read_info(path)
        except OSError:
            continue
        if draft:                       # 草稿不打扰
            continue
        if not has_tags(tags):
            targets.append((path, title))

    if not targets:
        return 0

    out.write("  \033[2m标签：逗号分隔；直接回车跳过；输入 others 用系统默认标签\033[0m\n")
    saved = 0
    for path, title in targets:
        answer = ask("\n  %s\n  标签: " % title, stdin, out)
        if answer is None:
            continue
        tags = parse_input(answer)
        if not tags:
            continue
        # 先把新内容算出来，再打开文件写入。
        # 不能写成 f.write(write_tags(path, tags))：open(path, "w") 会先把文件截断，
        # 那样 write_tags 读到的是空文件，正文会被整段丢掉。
        result = write_tags(path, tags)

        # 保险：写入前对比大小。正常只是改一行 tags，不可能让文件缩水一大截；
        # 真出现了就说明读到的内容不完整，宁可不动这个文件。
        try:
            old_size = os.path.getsize(path)
        except OSError:
            old_size = 0
        if old_size and len(result.encode("utf-8")) < old_size * 0.5:
            out.write("    ! 跳过 %s：写入前检查发现内容会异常变短，已保持原文件不动\n" % path)
            continue

        with open(path, "w", encoding="utf-8") as f:
            f.write(result)
        out.write("    ✓ " + ", ".join(tags) + "\n")
        saved += 1

    if saved:
        out.write("  \033[2m已写入 %d 篇文章；想改就直接编辑文件\033[0m\n" % saved)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
