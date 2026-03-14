#!/bin/bash
# yuanjisong.sh — 猿急送数据源
# 抓取猿急送需求列表，含 403 重试逻辑

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"

SOURCE_ID="yuanjisong"
SOURCE_NAME="猿急送"
BASE_URL="https://www.yuanjisong.com"
CHECK_URL="https://www.yuanjisong.com/job"

fetch_yuanjisong() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  log_info "抓取 $SOURCE_NAME (关键词: $keywords, 限制: $limit)"

  # 猿急送经常返回 403，使用多种 UA 重试
  local user_agents=(
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
  )

  local html=""
  for ua in "${user_agents[@]}"; do
    html=$(curl -s -L --max-time 15 \
      -H "User-Agent: $ua" \
      -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
      -H "Accept-Language: zh-CN,zh;q=0.9" \
      -H "Referer: https://www.yuanjisong.com/" \
      "$CHECK_URL" 2>/dev/null | ensure_utf8)

    if [ -n "$html" ] && ! has_captcha "$html"; then
      # 检查是否真的得到了内容（非 403 页面）
      if ! echo "$html" | grep -qiE '(403|forbidden|access denied)'; then
        log_info "$SOURCE_NAME 使用 UA 成功获取页面"
        break
      fi
    fi
    html=""
    sleep 1
  done

  if [ -z "$html" ]; then
    log_warn "$SOURCE_NAME 所有 UA 均返回 403，跳过"
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
  done < <(echo "$html" | grep -iE '(job|需求|项目|开发)' | grep -i 'href' | head -"$((limit * 2))")

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_yuanjisong "$@"
fi
