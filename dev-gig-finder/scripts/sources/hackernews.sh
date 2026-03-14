#!/bin/bash
# hackernews.sh — Hacker News 数据源
# 使用 HN Algolia API 搜索 freelance/hiring 相关帖子

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

fetch_hackernews() {
  local keywords="${1:-freelance developer}"
  local limit="${2:-10}"

  log_info "抓取 Hacker News (关键词: $keywords, 限制: $limit)"

  # URL 编码关键词
  local encoded_keywords
  encoded_keywords=$(echo "$keywords" | sed 's/ /+/g')

  # 搜索 HN stories
  local response
  response=$(curl -s --max-time 15 \
    "https://hn.algolia.com/api/v1/search?query=${encoded_keywords}&tags=story&hitsPerPage=${limit}" \
    2>/dev/null)

  if [ -z "$response" ] || ! echo "$response" | jq -e '.hits' >/dev/null 2>&1; then
    log_warn "Hacker News API 返回无效响应"
    echo "[]"
    return 0
  fi

  # 转换为统一格式
  local results
  results=$(echo "$response" | jq --argjson limit "$limit" '
    [.hits[:$limit][] | {
      title: .title,
      summary: "",
      source: "hn",
      source_name: "Hacker News",
      url: (if .url and .url != "" then .url else ("https://news.ycombinator.com/item?id=" + (.objectID // "")) end),
      contact: (.author // ""),
      budget: "",
      tags: [],
      posted_at: (.created_at // ""),
      safety_flags: [],
      raw_snippet: ((.title // "") + " " + (.story_text // ""))[:500]
    }]
  ' 2>/dev/null || echo "[]")

  echo "$results"
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_hackernews "$@"
fi
