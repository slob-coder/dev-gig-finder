#!/bin/bash
# github.sh — GitHub Issues 数据源
# 搜索带有 help-wanted, bounty, freelance 等标签的 issues

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

fetch_github() {
  local keywords="${1:-software development}"
  local limit="${2:-10}"

  # 检查 gh CLI 是否可用
  if ! command -v gh >/dev/null 2>&1; then
    log_warn "gh CLI 未安装，跳过 GitHub 来源"
    echo "[]"
    return 0
  fi

  log_info "抓取 GitHub Issues (关键词: $keywords, 限制: $limit)"

  local results="[]"

  # 搜索多个标签组合
  # 注意：关键词和标签分开搜索，避免过于严格的过滤
  local search_labels=("help-wanted" "bounty" "freelance" "hiring" "paid")
  local all_items="[]"

  for label in "${search_labels[@]}"; do
    local items
    items=$(gh search issues "label:$label" \
      --sort updated \
      --limit "$limit" \
      --json title,url,body,labels,author,updatedAt 2>/dev/null || echo "[]")

    if echo "$items" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
      all_items=$(echo "$all_items" | jq --argjson new "$items" '. + $new')
    fi
  done

  # 去重并转换为统一格式
  results=$(echo "$all_items" | jq -r --argjson limit "$limit" '
    [group_by(.url)[] | .[0]] |
    .[:$limit] |
    [.[] | {
      title: .title,
      summary: "",
      source: "github",
      source_name: "GitHub",
      url: .url,
      contact: (if .author.login then ("@" + .author.login) else "" end),
      budget: "",
      tags: [.labels[]?.name // empty],
      posted_at: (.updatedAt // ""),
      safety_flags: [],
      raw_snippet: ((.body // "")[:500])
    }]
  ' 2>/dev/null || echo "[]")

  echo "$results"
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_github "$@"
fi
