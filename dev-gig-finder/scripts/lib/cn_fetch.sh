#!/bin/bash
# cn_fetch.sh — 中文平台通用抓取辅助
# 提供 UA 设置、连通性检测、编码处理、HTML 简易解析

# 通用中文平台 curl 请求
# 用法: cn_curl [curl_options] url
cn_curl() {
  curl -s -L \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8" \
    -H "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8" \
    -H "Accept-Encoding: identity" \
    -H "Cache-Control: no-cache" \
    --max-time 15 \
    --retry 1 \
    --retry-delay 2 \
    "$@"
}

# 连通性检测
# 用法: check_source_available "url" "source_name"
# 返回 0=可达, 1=不可达
check_source_available() {
  local url="$1"
  local source_name="$2"

  local http_code
  http_code=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
    --max-time 10 \
    -L "$url" 2>/dev/null)

  if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 400 ] 2>/dev/null; then
    log_info "$source_name 可达 (HTTP $http_code)"
    return 0
  else
    log_warn "$source_name 不可达 (HTTP $http_code)"
    return 1
  fi
}

# 检测响应是否包含验证码/反爬标记
# 用法: has_captcha "html_content"
# 返回 0=有验证码, 1=无
has_captcha() {
  local content="$1"
  if echo "$content" | grep -qiE '(captcha|验证码|滑块|slider|challenge|recaptcha|人机验证)'; then
    return 0
  fi
  return 1
}

# 编码转换：确保 UTF-8
# 用法: ensure_utf8 < input
ensure_utf8() {
  # 尝试检测是否为 GBK/GB2312 并转换
  if command -v iconv >/dev/null 2>&1; then
    # 先尝试直接输出（已是 UTF-8）；如果有非法序列则尝试 GBK 转换
    local input
    input=$(cat)
    if echo "$input" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then
      echo "$input"
    else
      echo "$input" | iconv -f GBK -t UTF-8 2>/dev/null || echo "$input"
    fi
  else
    cat
  fi
}

# 从 HTML 提取文本内容（去标签、去多余空白）
# 用法: html_to_text "html"
html_to_text() {
  echo "$1" | sed 's/<[^>]*>//g' | sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g; s/&#39;/'"'"'/g; s/&nbsp;/ /g' | tr -s '[:space:]' ' ' | sed 's/^ //; s/ $//'
}

# 从 HTML 提取所有链接（href 属性值）
# 用法: extract_hrefs "html" "base_url"
extract_hrefs() {
  local html="$1"
  local base_url="$2"

  echo "$html" | grep -oE 'href="[^"]*"' | sed 's/href="//; s/"$//' | while read -r href; do
    # 处理相对路径
    if [[ "$href" == /* ]]; then
      # 绝对路径，需补全域名
      local domain
      domain=$(echo "$base_url" | grep -oE 'https?://[^/]+')
      echo "${domain}${href}"
    elif [[ "$href" == http* ]]; then
      echo "$href"
    fi
  done
}

# 从 HTML 列表页提取结构化数据（通用）
# 解析 <a> 标签中的标题和链接
# 用法: parse_list_items "html" "item_selector_pattern" "base_url"
parse_list_items() {
  local html="$1"
  local pattern="$2"
  local base_url="$3"

  echo "$html" | grep -oE "$pattern" | while read -r item; do
    local href
    href=$(echo "$item" | grep -oE 'href="[^"]*"' | head -1 | sed 's/href="//; s/"$//')
    local title
    title=$(html_to_text "$item")

    if [ -n "$href" ] && [ -n "$title" ]; then
      # 补全 URL
      if [[ "$href" == /* ]]; then
        local domain
        domain=$(echo "$base_url" | grep -oE 'https?://[^/]+')
        href="${domain}${href}"
      fi
      echo "$href|$title"
    fi
  done
}
