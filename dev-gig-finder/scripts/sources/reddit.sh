#!/bin/bash
# reddit.sh — Reddit 数据源
# 搜索 r/forhire, r/freelance 等相关 subreddit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

fetch_reddit() {
  local keywords="${1:-hiring developer}"
  local limit="${2:-10}"

  log_info "抓取 Reddit (关键词: $keywords, 限制: $limit)"

  local encoded_keywords
  encoded_keywords=$(echo "$keywords" | sed 's/ /+/g')

  local results="[]"
  local subreddits=("forhire" "freelance" "remotejs" "jobbit")

  for sub in "${subreddits[@]}"; do
    local response
    response=$(curl -s --max-time 15 \
      -H "User-Agent: OpenClaw/1.0 (dev-gig-finder)" \
      "https://www.reddit.com/r/${sub}/search.json?q=${encoded_keywords}&sort=new&limit=${limit}&restrict_sr=on&t=month" \
      2>/dev/null)

    if [ -z "$response" ] || ! echo "$response" | jq -e '.data.children' >/dev/null 2>&1; then
      log_warn "Reddit r/$sub 返回无效响应"
      continue
    fi

    local items
    items=$(echo "$response" | jq --arg sub "$sub" '
      [.data.children[]?.data | select(.title) | {
        title: .title,
        summary: "",
        source: "reddit",
        source_name: ("Reddit r/" + $sub),
        url: ("https://www.reddit.com" + .permalink),
        contact: (.author // ""),
        budget: "",
        tags: [],
        posted_at: (.created_utc | todate? // ""),
        safety_flags: [],
        raw_snippet: ((.selftext // "")[:500])
      }]
    ' 2>/dev/null || echo "[]")

    if echo "$items" | jq -e 'length > 0' >/dev/null 2>&1; then
      results=$(echo "$results" | jq --argjson new "$items" '. + $new')
    fi

    # 避免 Reddit 限流，间隔请求
    sleep 1
  done

  # 限制总数并去重
  results=$(echo "$results" | jq --argjson limit "$limit" '[group_by(.url)[] | .[0]] | .[:$limit]')

  echo "$results"
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_reddit "$@"
fi
