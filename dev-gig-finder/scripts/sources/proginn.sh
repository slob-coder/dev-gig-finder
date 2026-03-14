#!/bin/bash
# proginn.sh — 程序员客栈数据源
# 抓取程序员客栈外包项目列表

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"

SOURCE_ID="proginn"
SOURCE_NAME="程序员客栈"
BASE_URL="https://www.proginn.com"
CHECK_URL="https://www.proginn.com/outsource"

fetch_proginn() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  log_info "抓取 $SOURCE_NAME (关键词: $keywords, 限制: $limit)"

  if ! check_source_available "$CHECK_URL" "$SOURCE_NAME"; then
    echo "[]"
    return 0
  fi

  # 尝试外包项目列表
  local html
  html=$(cn_curl -H "Referer: https://www.proginn.com/" "$CHECK_URL" 2>/dev/null | ensure_utf8)

  if [ -z "$html" ] || has_captcha "$html"; then
    # 尝试备用 URL
    html=$(cn_curl -H "Referer: https://www.proginn.com/" \
      "https://www.proginn.com/wo/" 2>/dev/null | ensure_utf8)
  fi

  if [ -z "$html" ]; then
    log_warn "$SOURCE_NAME 返回空响应"
    echo "[]"
    return 0
  fi

  local results="[]"
  local count=0

  # 解析项目列表
  while IFS= read -r line; do
    [ "$count" -ge "$limit" ] && break

    local url title
    url=$(echo "$line" | grep -oE 'href="[^"]*"' | head -1 | sed 's/href="//; s/"$//')
    title=$(html_to_text "$line")
    title=$(truncate_text "$title" 100)

    [ -z "$url" ] || [ -z "$title" ] && continue
    [[ "$url" == /* ]] && url="${BASE_URL}${url}"
    [[ "$url" != http* ]] && continue

    local budget
    budget=$(extract_budget "$line")
    local contact
    contact=$(extract_contacts "$line")

    local record
    record=$(build_json_record \
      "$title" "" "$SOURCE_ID" "$SOURCE_NAME" \
      "$url" "$contact" "$budget" "" "" "$title")

    results=$(echo "$results" | jq --argjson rec "$record" '. + [$rec]')
    count=$((count + 1))
  done < <(echo "$html" | grep -iE '(outsource|外包|项目|需求|开发)' | grep -i 'href' | head -"$((limit * 2))")

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_proginn "$@"
fi
