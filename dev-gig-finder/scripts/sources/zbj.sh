#!/bin/bash
# zbj.sh — 猪八戒网数据源
# 抓取猪八戒网软件开发分类任务

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"

SOURCE_ID="zbj"
SOURCE_NAME="猪八戒网"
BASE_URL="https://task.zbj.com"
CHECK_URL="https://task.zbj.com/t-sjkf/p1.html"

fetch_zbj() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  log_info "抓取 $SOURCE_NAME (关键词: $keywords, 限制: $limit)"

  # 连通性检测
  if ! check_source_available "$CHECK_URL" "$SOURCE_NAME"; then
    echo "[]"
    return 0
  fi

  # 抓取任务列表页
  local html
  html=$(cn_curl -H "Referer: https://www.zbj.com/" "$CHECK_URL" 2>/dev/null | ensure_utf8)

  if [ -z "$html" ]; then
    log_warn "$SOURCE_NAME 返回空响应"
    echo "[]"
    return 0
  fi

  # 检测验证码
  if has_captcha "$html"; then
    log_warn "$SOURCE_NAME 触发验证码，跳过"
    echo "[]"
    return 0
  fi

  # 解析任务列表
  # 猪八戒任务页面结构：包含任务卡片，每个有标题、预算、链接
  local results="[]"
  local count=0

  # 提取任务项：标题和链接
  while IFS='|' read -r url title; do
    [ -z "$url" ] || [ -z "$title" ] && continue
    [ "$count" -ge "$limit" ] && break

    local budget
    budget=$(extract_budget "$title")
    local contact
    contact=$(extract_contacts "$title")

    local record
    record=$(build_json_record \
      "$title" "" "$SOURCE_ID" "$SOURCE_NAME" \
      "$url" "$contact" "$budget" "" "" "$title")

    results=$(echo "$results" | jq --argjson rec "$record" '. + [$rec]')
    count=$((count + 1))
  done < <(echo "$html" | grep -oE '<a[^>]*href="(https?://task\.zbj\.com/[^"]*)"[^>]*>[^<]*</a>' | \
    sed 's/<a[^>]*href="\([^"]*\)"[^>]*>\([^<]*\)<\/a>/\1|\2/' | head -"$limit")

  # 如果正则未匹配，尝试备用方式
  if echo "$results" | jq -e 'length == 0' >/dev/null 2>&1; then
    # 使用更宽松的匹配
    while IFS= read -r line; do
      [ "$count" -ge "$limit" ] && break
      local url title
      url=$(echo "$line" | grep -oE 'https?://task\.zbj\.com/[0-9]+[^"]*' | head -1)
      title=$(html_to_text "$line")
      title=$(truncate_text "$title" 100)

      [ -z "$url" ] || [ -z "$title" ] && continue

      local record
      record=$(build_json_record \
        "$title" "" "$SOURCE_ID" "$SOURCE_NAME" \
        "$url" "平台联系" "" "" "" "$title")

      results=$(echo "$results" | jq --argjson rec "$record" '. + [$rec]')
      count=$((count + 1))
    done < <(echo "$html" | grep -i 'task\.zbj\.com' | head -"$limit")
  fi

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_zbj "$@"
fi
