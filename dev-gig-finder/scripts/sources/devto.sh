#!/bin/bash
# devto.sh — dev.to 数据源
# 使用 dev.to API 搜索 listings 和文章

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

fetch_devto() {
  local keywords="${1:-freelance developer}"
  local limit="${2:-10}"

  log_info "抓取 dev.to (关键词: $keywords, 限制: $limit)"

  local results="[]"

  # 1. 抓取 listings (collabs 和 forhire 分类)
  local categories=("collabs" "forhire")
  for cat in "${categories[@]}"; do
    local response
    response=$(curl -s --max-time 15 \
      "https://dev.to/api/listings?category=${cat}&per_page=${limit}" \
      2>/dev/null)

    if echo "$response" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
      local items
      items=$(echo "$response" | jq --arg cat "$cat" '
        [.[] | {
          title: .title,
          summary: "",
          source: "devto",
          source_name: ("dev.to/" + $cat),
          url: ("https://dev.to/listings/" + (.slug // (.id | tostring))),
          contact: (.user.username // ""),
          budget: "",
          tags: (.tags // []),
          posted_at: (.published_at // ""),
          safety_flags: [],
          raw_snippet: ((.body_markdown // "")[:500])
        }]
      ' 2>/dev/null || echo "[]")

      if echo "$items" | jq -e 'length > 0' >/dev/null 2>&1; then
        results=$(echo "$results" | jq --argjson new "$items" '. + $new')
      fi
    fi
  done

  # 2. 搜索文章（备用）
  local encoded_keywords
  encoded_keywords=$(echo "$keywords" | sed 's/ /%20/g')
  local articles
  articles=$(curl -s --max-time 15 \
    "https://dev.to/api/articles?tag=hiring&per_page=${limit}" \
    2>/dev/null)

  if echo "$articles" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
    local art_items
    art_items=$(echo "$articles" | jq '
      [.[] | select(.title | test("hiring|freelance|contract|developer|wanted"; "i")) | {
        title: .title,
        summary: "",
        source: "devto",
        source_name: "dev.to",
        url: .url,
        contact: (.user.username // ""),
        budget: "",
        tags: (.tag_list // []),
        posted_at: (.published_at // ""),
        safety_flags: [],
        raw_snippet: ((.description // "")[:500])
      }]
    ' 2>/dev/null || echo "[]")

    if echo "$art_items" | jq -e 'length > 0' >/dev/null 2>&1; then
      results=$(echo "$results" | jq --argjson new "$art_items" '. + $new')
    fi
  fi

  # 去重并限制数量
  results=$(echo "$results" | jq --argjson limit "$limit" '[group_by(.url)[] | .[0]] | .[:$limit]')

  echo "$results"
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_devto "$@"
fi
