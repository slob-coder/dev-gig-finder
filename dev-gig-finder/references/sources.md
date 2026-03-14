# 数据源配置与说明

> dev-gig-finder Skill 全部 13 个数据源的详细文档

## 数据源概览

| # | 来源 ID | 中文名 | 类型 | API/方式 | 可靠性 | 分类 |
|---|---------|--------|------|---------|--------|------|
| 1 | github | GitHub | Issues 搜索 | `gh` CLI | ⭐⭐⭐⭐⭐ | 国际 |
| 2 | hackernews | Hacker News | 文章搜索 | Algolia API | ⭐⭐⭐⭐⭐ | 国际 |
| 3 | reddit | Reddit | Subreddit 搜索 | JSON API | ⭐⭐⭐⭐ | 国际 |
| 4 | devto | dev.to | Listings/文章 | REST API | ⭐⭐⭐⭐ | 国际 |
| 5 | zbj | 猪八戒网 | 威客任务 | Web Scraping | ⭐⭐⭐ | 中文 |
| 6 | epwk | 一品威客 | 威客任务 | Web Scraping | ⭐⭐⭐⭐ | 中文 |
| 7 | smartcity | 智城外包网 | 外包项目 | Web Scraping | ⭐⭐ | 中文 |
| 8 | codingmart | 码市 | 软件众包 | Web Scraping | ⭐⭐ | 中文 |
| 9 | proginn | 程序员客栈 | 开发者接单 | Web Scraping | ⭐⭐⭐ | 中文 |
| 10 | yuanjisong | 猿急送 | 技术人员服务 | Web Scraping | ⭐⭐ | 中文 |
| 11 | oschina_zb | 开源众包 | 开源项目众包 | Web Scraping | ⭐⭐⭐ | 中文 |
| 12 | kuaimacode | 快码 | 软件研发众包 | Web Scraping | ⭐⭐ | 中文 |
| 13 | yingxuan | 英选 | 软件定制外包 | Web Scraping | ⭐ | 中文 |

### 来源分类

- **核心来源**（高可靠，推荐日常使用）：GitHub, HN, Reddit, dev.to, 一品威客, 程序员客栈
- **扩展来源**（可能不稳定，建议按需启用）：猪八戒, 智城, 码市, 猿急送, 开源众包, 快码, 英选

---

## 国际来源详细说明

### 1. GitHub Issues

| 项目 | 说明 |
|------|------|
| 来源 ID | `github` |
| 抓取方式 | `gh search issues` CLI 命令 |
| 搜索标签 | `help-wanted`, `bounty`, `freelance`, `hiring`, `paid` |
| 认证要求 | 需要 `gh` CLI 已登录 |
| Rate Limit | 已认证：30 次/分钟（搜索 API） |
| 输出字段 | title, url, body, labels, author, updatedAt |
| 可靠性 | ⭐⭐⭐⭐⭐ |
| 故障排查 | 检查 `gh auth status`；rate limit 错误等待 60s 重试 |

### 2. Hacker News

| 项目 | 说明 |
|------|------|
| 来源 ID | `hackernews` / `hn` |
| 抓取方式 | Algolia HN Search API |
| API URL | `https://hn.algolia.com/api/v1/search` |
| 认证要求 | 无（公开 API） |
| Rate Limit | 10,000 次/小时 |
| 典型搜索 | `freelance developer`, `hiring`, `who is hiring` |
| 可靠性 | ⭐⭐⭐⭐⭐ |
| 故障排查 | 极少故障；检查网络连接即可 |

### 3. Reddit

| 项目 | 说明 |
|------|------|
| 来源 ID | `reddit` |
| 抓取方式 | Reddit JSON API（`.json` 后缀） |
| 搜索 Subreddit | r/forhire, r/freelance, r/remotejs, r/jobbit |
| User-Agent | `OpenClaw/1.0 (dev-gig-finder)` — 必须设置合规 UA |
| 认证要求 | 无 |
| Rate Limit | ~60 次/分钟（无认证） |
| 可靠性 | ⭐⭐⭐⭐ |
| 故障排查 | 429 限流→等待 60s；确保 User-Agent 格式合规 |

### 4. dev.to

| 项目 | 说明 |
|------|------|
| 来源 ID | `devto` |
| 抓取方式 | dev.to REST API |
| API URL | `https://dev.to/api/listings` (listings)、`https://dev.to/api/articles` (文章) |
| 搜索分类 | `collabs`, `forhire` |
| 认证要求 | 无（公开 API） |
| Rate Limit | 30 次/30s（无认证） |
| 可靠性 | ⭐⭐⭐⭐ |
| 故障排查 | 检查 API 状态：`curl https://dev.to/api/articles?per_page=1` |

---

## 中文来源详细说明

### 5. 猪八戒网 (zbj.com)

| 项目 | 说明 |
|------|------|
| 来源 ID | `zbj` |
| 网站 | https://www.zbj.com |
| 抓取 URL | `https://task.zbj.com/t-sjkf/p1.html`（软件开发分类） |
| 抓取方式 | curl + HTML 解析 |
| 反爬措施 | 滑块验证码、IP 频率限制 |
| 应对策略 | 设置浏览器 UA + Referer；首次可能触发验证 |
| 可提取字段 | 标题、预算范围、投标人数、URL |
| 可靠性 | ⭐⭐⭐ |
| 故障排查 | 验证码→更换 IP 或等待；检查页面结构是否变化 |

### 6. 一品威客 (epwk.com)

| 项目 | 说明 |
|------|------|
| 来源 ID | `epwk` |
| 网站 | https://www.epwk.com |
| 抓取 URL | `https://task.epwk.com/portal/task/tasklist.html?categoryId=1` |
| 抓取方式 | curl + HTML 解析 |
| 反爬措施 | 较弱 |
| 可提取字段 | 标题、预算、任务类型（招标/悬赏/雇佣）、投标人数、URL |
| 可靠性 | ⭐⭐⭐⭐ |
| 故障排查 | 检查分类 ID 是否变化 |

### 7. 智城外包网

| 项目 | 说明 |
|------|------|
| 来源 ID | `smartcity` |
| 网站 | taskcity.com 或 smartcity.com（域名可能变更） |
| 抓取方式 | curl + HTML 解析 |
| 降级策略 | 多域名轮询，不可达时自动跳过 |
| 可靠性 | ⭐⭐ |
| 故障排查 | 搜索引擎确认最新域名；检查网站是否仍在运营 |

### 8. 码市 Coding Mart

| 项目 | 说明 |
|------|------|
| 来源 ID | `codingmart` |
| 网站 | codemart.com 或 mart.coding.net |
| 说明 | 原开源中国旗下，可能已合并或转型 |
| 降级策略 | 多域名轮询，不可达时跳过 |
| 可靠性 | ⭐⭐ |
| 故障排查 | 确认平台当前状态 |

### 9. 程序员客栈 (proginn.com)

| 项目 | 说明 |
|------|------|
| 来源 ID | `proginn` |
| 网站 | https://www.proginn.com |
| 抓取 URL | `/outsource` 或 `/wo/` |
| 抓取方式 | curl + HTML 解析 |
| 可提取字段 | 项目名称、技术栈要求、预算、URL |
| 可靠性 | ⭐⭐⭐ |
| 故障排查 | 检查页面路径是否变化 |

### 10. 猿急送 (yuanjisong.com)

| 项目 | 说明 |
|------|------|
| 来源 ID | `yuanjisong` |
| 网站 | https://www.yuanjisong.com |
| 抓取 URL | `/job` |
| 反爬措施 | 严格的 403 拦截 |
| 应对策略 | 多种 User-Agent 轮询重试 |
| 可靠性 | ⭐⭐ |
| 故障排查 | 尝试不同 UA；检查是否需要 Cookie |

### 11. 开源众包 (zb.oschina.net)

| 项目 | 说明 |
|------|------|
| 来源 ID | `oschina_zb` |
| 网站 | https://zb.oschina.net |
| 抓取 URL | `/projects/list` |
| 所属生态 | 开源中国 (OSChina) |
| 可靠性 | ⭐⭐⭐ |
| 故障排查 | 设置超时 10s；检查开源中国主站状态 |

### 12. 快码 (kuaimacode.com)

| 项目 | 说明 |
|------|------|
| 来源 ID | `kuaimacode` |
| 网站 | https://www.kuaimacode.com |
| 说明 | 偏服务公司型，可能缺乏公开任务列表 |
| 降级策略 | 无结构化任务数据时输出空结果 |
| 可靠性 | ⭐⭐ |
| 故障排查 | 确认网站是否提供公开项目列表 |

### 13. 英选 (yingxuan.io)

| 项目 | 说明 |
|------|------|
| 来源 ID | `yingxuan` |
| 网站 | https://www.yingxuan.io |
| 当前状态 | 服务器 521 宕机，可能已停止运营 |
| 降级策略 | 连通性检测失败时自动跳过 |
| 可靠性 | ⭐ |
| 故障排查 | 检查域名是否仍有效 |

---

## 搜索关键词推荐

### 英文关键词（国际来源）
- `software development`, `web development`, `app development`
- `freelance developer`, `contract developer`, `remote developer`
- `help wanted`, `bounty`, `hiring`, `paid work`
- `React`, `Python`, `Node.js`, `TypeScript`, `Vue`, `Flutter`
- `full stack`, `frontend`, `backend`, `mobile app`

### 中文关键词（国内来源）
- `软件开发`, `网站开发`, `App开发`, `小程序开发`
- `系统开发`, `定制开发`, `二次开发`
- `前端开发`, `后端开发`, `全栈开发`
- `微信小程序`, `H5开发`, `移动端`
- `Python`, `Java`, `PHP`, `.NET`, `Go`
- `ERP系统`, `管理系统`, `电商平台`
- `爬虫开发`, `数据分析`, `自动化`

---

## 添加自定义数据源

### 步骤

1. **创建脚本**：在 `scripts/sources/` 下创建新的 `.sh` 文件

2. **实现标准接口**：

```bash
#!/bin/bash
# my_source.sh — 自定义来源

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/cn_fetch.sh"  # 如果是中文来源

SOURCE_ID="my_source"
SOURCE_NAME="我的来源"

fetch_my_source() {
  local keywords="${1:-软件开发}"
  local limit="${2:-10}"

  # 1. 连通性检测（推荐）
  if ! check_source_available "https://example.com" "$SOURCE_NAME"; then
    echo "[]"
    return 0
  fi

  # 2. 抓取数据
  local html
  html=$(cn_curl "https://example.com/projects" 2>/dev/null)

  # 3. 解析并构建 JSON
  local results="[]"
  # ... 解析逻辑 ...

  local record
  record=$(build_json_record \
    "标题" "" "$SOURCE_ID" "$SOURCE_NAME" \
    "https://url" "联系方式" "预算" "tag1,tag2" "2024-01-01" "摘要")
  results=$(echo "$results" | jq --argjson rec "$record" '. + [$rec]')

  echo "$results"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  fetch_my_source "$@"
fi
```

3. **注册来源**：在 `scripts/fetch_gigs.sh` 中添加映射：
   - `get_source_script()` 中添加 case
   - `get_fetch_function()` 中添加 case
   - `get_source_display_name()` 中添加 case
   - 将来源 ID 添加到 `CN_SOURCES` 或 `INTL_SOURCES`

4. **测试**：
```bash
bash scripts/sources/my_source.sh "关键词" 5
bash scripts/fetch_gigs.sh --sources my_source --limit 5
```

### 注意事项

- 每个脚本必须是独立的，可以单独运行
- 失败时必须输出 `[]` 并 `exit 0`，不能影响其他来源
- 使用 `build_json_record()` 确保输出格式统一
- 中文来源推荐使用 `cn_curl()` 和 `check_source_available()`
- 日志输出到 stderr（使用 `log_info`/`log_warn`/`log_error`）

---

## 故障排查指南

### 通用问题

| 症状 | 可能原因 | 解决方案 |
|------|---------|---------|
| 全部来源返回空 | 网络问题 | 检查 `curl https://httpbin.org/ip` |
| 单个来源失败 | 该平台不可达 | 查看 stderr 日志中的详细错误 |
| JSON 解析错误 | jq 未安装 | `brew install jq` 或 `apt install jq` |
| gh 命令失败 | 未认证 | 运行 `gh auth login` |

### 反爬相关

| 症状 | 可能原因 | 解决方案 |
|------|---------|---------|
| 返回验证码页面 | IP 被限制 | 等待一段时间或更换网络 |
| HTTP 403 | UA 被拒绝 | 脚本已内置多 UA 重试 |
| HTTP 429 | 请求过频 | 降低 --limit 或减少来源数量 |
| 返回空 HTML | 需要 JavaScript 渲染 | 当前架构限制，无法处理 |

### 编码相关

| 症状 | 可能原因 | 解决方案 |
|------|---------|---------|
| 中文乱码 | GBK 编码页面 | 安装 iconv（macOS 自带） |
| 特殊字符异常 | HTML 实体未转义 | `strip_html()` 应已处理 |
