#!/bin/bash
# epwk.sh — 一品威客数据源
# 抓取一品威客任务大厅

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"

SOURCE_ID="epwk"
SOURCE_NAME="一品威客"
BASE_URL="https://task.epwk.com"
CHECK_URL="https://task.epwk.com/"

fetch_epwk() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  log_info "抓取 $SOURCE_NAME (关键词: $keywords, 限制: $limit)"

  if ! check_source_available "$CHECK_URL" "$SOURCE_NAME"; then
    echo "[]"
    return 0
  fi

  # 尝试软件开发分类页面
  local html
  html=$(cn_curl -H "Referer: https://www.epwk.com/" \
    "https://task.epwk.com/portal/task/tasklist.html?categoryId=1" 2>/dev/null | ensure_utf8)

  if [ -z "$html" ]; then
    # 退回到主页
    html=$(cn_curl -H "Referer: https://www.epwk.com/" "$CHECK_URL" 2>/dev/null | ensure_utf8)
  fi

  if [ -z "$html" ] || has_captcha "$html"; then
    log_warn "$SOURCE_NAME 抓取失败或触发验证码"
    echo "[]"
    return 0
  fi

  local results="[]"
  local count=0

  # 提取任务列表项
  while IFS= read -r line; do
    [ "$count" -ge "$limit" ] && break

    local url title budget
    url=$(echo "$line" | grep -oE 'https?://task\.epwk\.com/[^"'"'"' ]*' | head -1)
    [ -z "$url" ] && url=$(echo "$line" | grep -oE '/portal/task/[^"'"'"' ]*' | head -1)
    [ -z "$url" ] && continue

    # 补全相对路径
    [[ "$url" == /* ]] && url="https://task.epwk.com${url}"

    title=$(html_to_text "$line")
    title=$(truncate_text "$title" 100)
    [ -z "$title" ] && continue

    budget=$(extract_budget "$line")
    local contact
    contact=$(extract_contacts "$line")

    local record
    record=$(build_json_record \
      "$title" "" "$SOURCE_ID" "$SOURCE_NAME" \
      "$url" "$contact" "$budget" "" "" "$title")

    results=$(echo "$results" | jq --argjson rec "$record" '. + [$rec]')
    count=$((count + 1))
  done < <(echo "$html" | grep -iE '(task|任务|需求|项目)' | grep -i 'href' | head -"$((limit * 2))")

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_epwk "$@"
fi
