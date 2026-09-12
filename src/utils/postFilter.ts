import type { CollectionEntry } from "astro:content";
import config from "@/config";

/**
 * Determines whether a post is eligible to be listed/rendered.
 *
 * - 草稿（draft: true）只在本地开发时显示，方便预览排版；生产构建绝不包含
 * - 定时发布：pubDatetime 未到（扣除配置的容差）的文章在生产构建中不显示
 * - 本地开发时所有非草稿文章都显示，方便写作
 */
export function postFilter({ data }: CollectionEntry<"posts">) {
  const isPublishTimePassed =
    Date.now() >
    new Date(data.pubDatetime).getTime() - config.posts.scheduledPostMargin;
  // 本地：草稿也渲染出来；生产：排除草稿
  return import.meta.env.DEV || (!data.draft && isPublishTimePassed);
}
