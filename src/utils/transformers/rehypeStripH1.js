/**
 * 正文里的一级标题不渲染。
 *
 * 页面标题由 frontmatter 的 `title` 渲染（`posts/[...slug]/index.astro`），
 * 正文再写 `# 标题` 会变成第二个 H1。这里直接丢掉正文里的 h1 节点，
 * 从 Typora / 网页粘过来的 Markdown 也就不用再手改。
 *
 * 只处理正文：frontmatter 标题、目录、锚点都不受影响。
 */
export function rehypeStripH1() {
  return tree => {
    const strip = node => {
      if (!Array.isArray(node.children)) return;

      for (let i = node.children.length - 1; i >= 0; i--) {
        if (node.children[i].tagName === "h1") node.children.splice(i, 1);
        else strip(node.children[i]);
      }
    };

    strip(tree);
  };
}
