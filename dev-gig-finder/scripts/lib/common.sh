#!/bin/bash
# common.sh — 公共函数库
# 提供 JSON 构建、联系方式提取、去重等通用功能

# 构建标准 JSON 记录
# 用法: build_json_record "title" "summary" "source" "source_name" "url" "contact" "budget" "tags" "posted_at" "raw_snippet"
build_json_record() {
  local title="$1"
  local summary="$2"
  local source="$3"
  local source_name="$4"
  local url="$5"
  local contact="$6"
  local budget="$7"
  local tags="$8"
  local posted_at="$9"
  local raw_snippet="${10}"

  # 截断 raw_snippet 到 500 字符
  if [ ${#raw_snippet} -gt 500 ]; then
    raw_snippet="${raw_snippet:0:500}"
  fi

  # 使用 jq 安全构建 JSON（处理特殊字符）
  jq -n \
    --arg title "$title" \
    --arg summary "$summary" \
    --arg source "$source" \
    --arg source_name "$source_name" \
    --arg url "$url" \
    --arg contact "$contact" \
    --arg budget "$budget" \
    --arg tags "$tags" \
    --arg posted_at "$posted_at" \
    --arg raw_snippet "$raw_snippet" \
    '{
      title: $title,
      summary: $summary,
      source: $source,
      source_name: $source_name,
      url: $url,
      contact: $contact,
      budget: $budget,
      tags: ($tags | split(",")),
      posted_at: $posted_at,
      safety_flags: [],
      raw_snippet: $raw_snippet
    }'
}

# 从文本中提取 email 地址
# 用法: extract_email "text"
extract_email() {
  echo "$1" | grep -oiE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' | head -1
}

# 从文本中提取手机号（中国大陆）
# 用法: extract_phone "text"
extract_phone() {
  echo "$1" | grep -oE '1[3-9][0-9]{9}' | head -1
}

# 从文本中提取 QQ 号
# 用法: extract_qq "text"
extract_qq() {
  echo "$1" | grep -oiE '(QQ|qq)[：: ]*[0-9]{5,12}' | head -1 | grep -oE '[0-9]{5,12}'
}

# 从文本中提取微信号
# 用法: extract_wechat "text"
extract_wechat() {
  echo "$1" | grep -oiE '(微信|WeChat|wx)[：: ]*[a-zA-Z0-9_-]{5,20}' | head -1 | sed 's/^[^:：]*[：: ]*//'
}

# 从文本中提取预算信息
# 用法: extract_budget "text"
extract_budget() {
  local text="$1"
  # 匹配中文预算格式：¥1000, 1000元, 1-5万, 5000-10000, $500-$1000
  local budget=""

  # 尝试匹配各种格式
  budget=$(echo "$text" | grep -oE '[¥￥$][0-9,]+([.-][0-9,]+)?' | head -1)
  if [ -z "$budget" ]; then
    budget=$(echo "$text" | grep -oE '[0-9]+-[0-9]+万?' | head -1)
  fi
  if [ -z "$budget" ]; then
    budget=$(echo "$text" | grep -oE '[0-9]+(\.[0-9]+)?万' | head -1)
  fi
  if [ -z "$budget" ]; then
    budget=$(echo "$text" | grep -oE '[0-9,]+元' | head -1)
  fi
  if [ -z "$budget" ]; then
    budget=$(echo "$text" | grep -oiE '(budget|预算)[：: ]*[^ ，,]*' | head -1 | sed 's/^[^:：]*[：: ]*//')
  fi

  echo "$budget"
}

# 从文本中提取所有联系方式（合并）
# 用法: extract_contacts "text"
extract_contacts() {
  local text="$1"
  local contacts=""

  local email=$(extract_email "$text")
  local phone=$(extract_phone "$text")
  local qq=$(extract_qq "$text")
  local wechat=$(extract_wechat "$text")

  [ -n "$email" ] && contacts="$email"
  [ -n "$phone" ] && contacts="${contacts:+$contacts, }$phone"
  [ -n "$qq" ] && contacts="${contacts:+$contacts, }QQ:$qq"
  [ -n "$wechat" ] && contacts="${contacts:+$contacts, }微信:$wechat"

  echo "${contacts:-平台联系}"
}

# 合并多个 JSON 数组
# 用法: merge_json_arrays file1.json file2.json ...
merge_json_arrays() {
  if [ $# -eq 0 ]; then
    echo "[]"
    return
  fi

  local result="[]"
  for f in "$@"; do
    if [ -f "$f" ] && [ -s "$f" ]; then
      local content
      content=$(cat "$f")
      # 验证是合法 JSON 数组
      if echo "$content" | jq -e 'type == "array"' >/dev/null 2>&1; then
        result=$(echo "$result" | jq --argjson new "$content" '. + $new')
      fi
    fi
  done
  echo "$result"
}

# URL 去重
# 用法: dedup_by_url < json_array
dedup_by_url() {
  jq '[group_by(.url)[] | .[0]]'
}

# 清理 HTML 标签（简易版）
# 用法: strip_html "text"
strip_html() {
  echo "$1" | sed 's/<[^>]*>//g' | sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g; s/&#39;/'"'"'/g; s/&nbsp;/ /g'
}

# 截断文本到指定长度
# 用法: truncate_text "text" max_len
truncate_text() {
  local text="$1"
  local max_len="${2:-200}"
  if [ ${#text} -gt "$max_len" ]; then
    echo "${text:0:$max_len}..."
  else
    echo "$text"
  fi
}

# 日志函数
log_info() {
  echo "[INFO] $*" >&2
}

log_warn() {
  echo "[WARN] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}
