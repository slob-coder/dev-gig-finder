#!/bin/bash
# fetch_gigs.sh — 多源软件开发任务抓取（v2.0）
# 输出 JSON 格式的任务列表到 stdout，来源状态到 stderr
#
# 用法:
#   bash fetch_gigs.sh [--sources github,hn,reddit,zbj,...] [--keywords "python,react"] [--limit 20]
#   bash fetch_gigs.sh --sources cn    # 仅中文来源
#   bash fetch_gigs.sh --sources intl  # 仅国际来源
#   bash fetch_gigs.sh --sources all   # 全部来源（默认）

set -o pipefail

MAIN_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载公共库
source "$MAIN_SCRIPT_DIR/lib/common.sh"
source "$MAIN_SCRIPT_DIR/lib/cn_fetch.sh"

# 来源分组定义
INTL_SOURCES="github,hackernews,reddit,devto"
CN_SOURCES="zbj,epwk,smartcity,codingmart,proginn,yuanjisong,oschina_zb,kuaimacode,yingxuan"
ALL_SOURCES="${INTL_SOURCES},${CN_SOURCES}"

# 来源到脚本文件名的映射（bash 3 兼容，无关联数组）
get_source_script() {
  local source_id="$1"
  case "$source_id" in
    github)      echo "github.sh" ;;
    hackernews|hn) echo "hackernews.sh" ;;
    reddit)      echo "reddit.sh" ;;
    devto)       echo "devto.sh" ;;
    zbj)         echo "zbj.sh" ;;
    epwk)        echo "epwk.sh" ;;
    smartcity)   echo "smartcity.sh" ;;
    codingmart)  echo "codingmart.sh" ;;
    proginn)     echo "proginn.sh" ;;
    yuanjisong)  echo "yuanjisong.sh" ;;
    oschina_zb)  echo "oschina_zb.sh" ;;
    kuaimacode)  echo "kuaimacode.sh" ;;
    yingxuan)    echo "yingxuan.sh" ;;
    *)           echo "" ;;
  esac
}

# 来源到函数名的映射
get_fetch_function() {
  local source_id="$1"
  case "$source_id" in
    github)      echo "fetch_github" ;;
    hackernews|hn) echo "fetch_hackernews" ;;
    reddit)      echo "fetch_reddit" ;;
    devto)       echo "fetch_devto" ;;
    zbj)         echo "fetch_zbj" ;;
    epwk)        echo "fetch_epwk" ;;
    smartcity)   echo "fetch_smartcity" ;;
    codingmart)  echo "fetch_codingmart" ;;
    proginn)     echo "fetch_proginn" ;;
    yuanjisong)  echo "fetch_yuanjisong" ;;
    oschina_zb)  echo "fetch_oschina_zb" ;;
    kuaimacode)  echo "fetch_kuaimacode" ;;
    yingxuan)    echo "fetch_yingxuan" ;;
    *)           echo "" ;;
  esac
}

# 来源中文名映射
get_source_display_name() {
  local source_id="$1"
  case "$source_id" in
    github)      echo "GitHub" ;;
    hackernews|hn) echo "HN" ;;
    reddit)      echo "Reddit" ;;
    devto)       echo "dev.to" ;;
    zbj)         echo "猪八戒" ;;
    epwk)        echo "一品威客" ;;
    smartcity)   echo "智城" ;;
    codingmart)  echo "码市" ;;
    proginn)     echo "程序员客栈" ;;
    yuanjisong)  echo "猿急送" ;;
    oschina_zb)  echo "开源众包" ;;
    kuaimacode)  echo "快码" ;;
    yingxuan)    echo "英选" ;;
    *)           echo "$source_id" ;;
  esac
}

# 默认参数
SOURCES="all"
KEYWORDS="software development,freelance developer"
LIMIT=10

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sources)
      SOURCES="$2"
      shift 2
      ;;
    --keywords)
      KEYWORDS="$2"
      shift 2
      ;;
    --limit)
      LIMIT="$2"
      shift 2
      ;;
    --help)
      echo "用法: bash fetch_gigs.sh [--sources all|cn|intl|<逗号分隔>] [--keywords \"关键词\"] [--limit N]"
      echo ""
      echo "来源分组:"
      echo "  all   - 全部 13 个来源（默认）"
      echo "  intl  - 国际来源: GitHub, HN, Reddit, dev.to"
      echo "  cn    - 中文来源: 猪八戒, 一品威客, 智城, 码市, 程序员客栈, 猿急送, 开源众包, 快码, 英选"
      echo "  自定义 - 逗号分隔，如: github,zbj,proginn"
      exit 0
      ;;
    *)
      log_error "未知参数: $1"
      shift
      ;;
  esac
done

# 展开来源分组
case "$SOURCES" in
  all)  SOURCES="$ALL_SOURCES" ;;
  intl) SOURCES="$INTL_SOURCES" ;;
  cn)   SOURCES="$CN_SOURCES" ;;
esac

# 将来源列表转为数组
IFS=',' read -ra SOURCE_LIST <<< "$SOURCES"

log_info "启动抓取: 来源=${#SOURCE_LIST[@]}个, 关键词=$KEYWORDS, 限制=$LIMIT"

# 创建临时目录
TMPDIR_GIGS=$(mktemp -d)
trap "rm -rf $TMPDIR_GIGS" EXIT

# 来源状态跟踪
declare -a SOURCE_STATUS_LIST

# 逐个执行各来源
for source_id in "${SOURCE_LIST[@]}"; do
  source_id=$(echo "$source_id" | tr -d ' ')
  local_script=$(get_source_script "$source_id")
  local_func=$(get_fetch_function "$source_id")
  display_name=$(get_source_display_name "$source_id")

  if [ -z "$local_script" ]; then
    log_warn "未知来源: $source_id，跳过"
    SOURCE_STATUS_LIST+=("⏭️ ${display_name}(未知)")
    continue
  fi

  script_path="$MAIN_SCRIPT_DIR/sources/$local_script"
  if [ ! -f "$script_path" ]; then
    log_warn "脚本不存在: $script_path，跳过"
    SOURCE_STATUS_LIST+=("⏭️ ${display_name}(缺失)")
    continue
  fi

  # 加载来源脚本
  source "$script_path"

  # 执行抓取
  result_file="$TMPDIR_GIGS/${source_id}.json"
  log_info "正在抓取: $display_name..."

  if $local_func "$KEYWORDS" "$LIMIT" > "$result_file" 2>/dev/null; then
    # 验证输出是否为合法 JSON 数组
    if [ -s "$result_file" ] && jq -e 'type == "array"' "$result_file" >/dev/null 2>&1; then
      local_count=$(jq 'length' "$result_file")
      if [ "$local_count" -gt 0 ]; then
        SOURCE_STATUS_LIST+=("✅ ${display_name}(${local_count}条)")
        log_info "$display_name: 获取 $local_count 条结果"
      else
        SOURCE_STATUS_LIST+=("⏭️ ${display_name}(0条)")
        log_info "$display_name: 无结果"
      fi
    else
      echo "[]" > "$result_file"
      SOURCE_STATUS_LIST+=("❌ ${display_name}(解析失败)")
      log_warn "$display_name: 输出格式无效"
    fi
  else
    echo "[]" > "$result_file"
    SOURCE_STATUS_LIST+=("❌ ${display_name}(执行失败)")
    log_warn "$display_name: 脚本执行失败"
  fi
done

# 合并所有结果
log_info "合并结果..."
MERGED="[]"
for f in "$TMPDIR_GIGS"/*.json; do
  [ -f "$f" ] || continue
  content=$(cat "$f")
  if echo "$content" | jq -e 'type == "array" and length > 0' >/dev/null 2>&1; then
    MERGED=$(echo "$MERGED" | jq --argjson new "$content" '. + $new')
  fi
done

# URL 去重
MERGED=$(echo "$MERGED" | jq '[group_by(.url)[] | .[0]]')

# 总条数
TOTAL=$(echo "$MERGED" | jq 'length')
log_info "合并完成: 共 $TOTAL 条（去重后）"

# 输出 JSON 结果到 stdout
echo "$MERGED"

# 输出来源状态摘要到 stderr
echo "" >&2
echo "---SOURCE_STATUS---" >&2
echo "来源状态：$(IFS=' | '; echo "${SOURCE_STATUS_LIST[*]}")" >&2
echo "共 $TOTAL 条结果" >&2
