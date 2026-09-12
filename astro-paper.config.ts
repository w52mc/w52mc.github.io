import { defineAstroPaperConfig } from "./src/types/config";

export default defineAstroPaperConfig({
  site: {
    url: "https://w52mc.github.io/",
    title: "碳水化合物的博客",
    description: "记录折腾、阅读与思考。",
    author: "碳水化合物",
    profile: "https://github.com/w52mc",
    ogImage: "default-og.jpg",
    lang: "zh",
    timezone: "Asia/Shanghai",
    dir: "ltr",
  },
  posts: {
    perPage: 6,
    perIndex: 5,
    scheduledPostMargin: 15 * 60 * 1000,
  },
  features: {
    lightAndDarkMode: true,
    dynamicOgImage: true,
    showArchives: true,
    showBackButton: true,
    editPost: {
      enabled: true,
      url: "https://github.com/w52mc/w52mc.github.io/edit/main/",
    },
    search: "pagefind",
  },
  socials: [
    {
      name: "github",
      url: "https://github.com/w52mc",
      linkTitle: "在 GitHub 上找到我",
    },
    {
      name: "mail",
      url: "mailto:liujunhang2013@163.com",
      linkTitle: "给我发邮件",
    },
  ],
  // 留空数组即可去掉文章底部的分享按钮
  shareLinks: [],
});
