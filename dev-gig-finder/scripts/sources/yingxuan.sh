#!/bin/bash
# yingxuan.sh — 英选数据源
# 抓取英选专业软件定制化外包平台

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"

SOURCE_ID="yingxuan"
SOURCE_NAME="英选"
BASE_URL="https://www.yingxuan.io"
CHECK_URL="https://www.yingxuan.io/"

fetch_yingxuan() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  log_info "抓取 $SOURCE_NAME (关键词: $keywords, 限制: $limit)"

  # 英选当前服务器可能宕机 (521)，连通性检测
  if ! check_source_available "$CHECK_URL" "$SOURCE_NAME"; then
    log_warn "$SOURCE_NAME 不可达（可能已停止运营），跳过"
    echo "[]"
    return 0
  fi

  local html
  html=$(cn_curl "$CHECK_URL" 2>/dev/null | ensure_utf8)

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
  done < <(echo "$html" | grep -iE '(项目|需求|外包|定制)' | grep -i 'href' | head -"$((limit * 2))")

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_yingxuan "$@"
fi
