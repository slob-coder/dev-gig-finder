#!/bin/bash
# oschina_zb.sh — 开源众包（开源中国）数据源
# 抓取开源中国众包平台项目列表

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"

SOURCE_ID="oschina_zb"
SOURCE_NAME="开源众包"
BASE_URL="https://zb.oschina.net"
CHECK_URL="https://zb.oschina.net/projects/list"

fetch_oschina_zb() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  log_info "抓取 $SOURCE_NAME (关键词: $keywords, 限制: $limit)"

  if ! check_source_available "$CHECK_URL" "$SOURCE_NAME"; then
    echo "[]"
    return 0
  fi

  local html
  html=$(cn_curl -H "Referer: https://www.oschina.net/" \
    --max-time 10 \
    "$CHECK_URL" 2>/dev/null | ensure_utf8)

  if [ -z "$html" ] || has_captcha "$html"; then
    log_warn "$SOURCE_NAME 抓取失败"
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
    [[ "$url" == /* ]] && url="${BASE_URL}${url}"
    [[ "$url" != http* ]] && continue

    local budget
    budget=$(extract_budget "$line")

    local record
    record=$(build_json_record \
      "$title" "" "$SOURCE_ID" "$SOURCE_NAME" \
      "$url" "平台联系" "$budget" "" "" "$title")

    results=$(echo "$results" | jq --argjson rec "$record" '. + [$rec]')
    count=$((count + 1))
  done < <(echo "$html" | grep -iE '(project|项目|需求|众包)' | grep -i 'href' | head -"$((limit * 2))")

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_oschina_zb "$@"
fi
