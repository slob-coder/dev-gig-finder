#!/bin/bash
# codingmart.sh — 码市 (Coding Mart) 数据源
# 抓取码市/Coding Mart 项目列表

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"

SOURCE_ID="codingmart"
SOURCE_NAME="码市"
CHECK_URLS=("https://codemart.com/projects" "https://mart.coding.net/")

fetch_codingmart() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  log_info "抓取 $SOURCE_NAME (关键词: $keywords, 限制: $limit)"

  local base_url=""
  local html=""

  for url in "${CHECK_URLS[@]}"; do
    if check_source_available "$url" "$SOURCE_NAME"; then
      html=$(cn_curl "$url" 2>/dev/null | ensure_utf8)
      if [ -n "$html" ] && ! has_captcha "$html"; then
        base_url="$url"
        break
      fi
    fi
  done

  if [ -z "$base_url" ] || [ -z "$html" ]; then
    log_warn "$SOURCE_NAME 不可达，跳过"
    echo "[]"
    return 0
  fi

  local results="[]"
  local count=0

  while IFS= read -r line; do
    [ "$count" -ge "$limit" ] && break

    local url title
    url=$(echo "$line" | grep -oE 'href="[^"]*"' | head -1 | sed 's/href="//; s/"$//')
    title=$(html_to_text "$line")
    title=$(truncate_text "$title" 100)

    [ -z "$url" ] || [ -z "$title" ] && continue
    [[ "$url" == /* ]] && url="${base_url%/}${url}"
    [[ "$url" != http* ]] && continue

    local budget
    budget=$(extract_budget "$line")

    local record
    record=$(build_json_record \
      "$title" "" "$SOURCE_ID" "$SOURCE_NAME" \
      "$url" "平台联系" "$budget" "" "" "$title")

    results=$(echo "$results" | jq --argjson rec "$record" '. + [$rec]')
    count=$((count + 1))
  done < <(echo "$html" | grep -iE '(项目|project|需求)' | grep -i 'href' | head -"$((limit * 2))")

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_codingmart "$@"
fi
