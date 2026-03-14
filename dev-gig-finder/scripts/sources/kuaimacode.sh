#!/bin/bash
# kuaimacode.sh — 快码数据源
# 抓取快码软件研发众包平台

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"

SOURCE_ID="kuaimacode"
SOURCE_NAME="快码"
BASE_URL="https://www.kuaimacode.com"
CHECK_URL="https://www.kuaimacode.com/"

fetch_kuaimacode() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  log_info "抓取 $SOURCE_NAME (关键词: $keywords, 限制: $limit)"

  if ! check_source_available "$CHECK_URL" "$SOURCE_NAME"; then
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

  # 快码可能偏服务公司型，未必有公开任务列表
  # 尝试寻找项目/需求相关内容
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
  done < <(echo "$html" | grep -iE '(项目|需求|开发|案例)' | grep -i 'href' | head -"$((limit * 2))")

  # 如果没有找到结构化任务数据，记录日志并返回空
  if echo "$results" | jq -e 'length == 0' >/dev/null 2>&1; then
    log_info "$SOURCE_NAME 未找到结构化任务列表（平台可能偏服务型）"
  fi

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_kuaimacode "$@"
fi
