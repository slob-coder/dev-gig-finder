---
name: dev-gig-finder
description: >
  自动抓取网络中的软件开发任务/外包需求。支持 GitHub、Hacker News、Reddit、dev.to
  等国际平台，以及猪八戒、一品威客、程序员客栈等 9 个中文威客/众包平台，共 13 个数据源。
  输出结构化表格，含需求摘要、来源链接、预算和联系方式。
---

# dev-gig-finder

自动从互联网抓取软件开发商机/任务，输出结构化表格。

## 触发条件

当用户提到以下任何内容时激活此 Skill：
- "找软件开发任务"、"抓取外包需求"、"开发商机"
- "威客任务"、"众包项目"、"接单"、"freelance"
- "dev gig"、"find dev tasks"、"software bounty"
- `/dev-gig-finder`

## 前置依赖

- `curl` — HTTP 请求
- `jq` — JSON 处理
- `gh` — GitHub CLI（已认证，用于 GitHub Issues 搜索）
- `iconv`（可选）— 中文编码转换（GBK → UTF-8）

## 参数

用户可通过自然语言或命令行风格指定：

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `sources` | 数据源选择 | `all` |
| `keywords` | 搜索关键词 | 软件开发相关默认词 |
| `limit` | 每来源最大条数 | `10` |

### 来源分组

| 分组 | 包含来源 |
|------|---------|
| `all` | 全部 13 个来源 |
| `intl` | github, hn, reddit, devto |
| `cn` | zbj, epwk, smartcity, codingmart, proginn, yuanjisong, oschina_zb, kuaimacode, yingxuan |
| 自定义 | 逗号分隔，如 `github,zbj,proginn` |

## 工作流

### Step 1: 解析参数

从用户输入中提取：
- **sources**：来源分组或逗号分隔列表（默认 `all`）
- **keywords**：搜索关键词（默认：软件开发, 网站开发, App开发, 小程序, software development）
- **limit**：每来源条数（默认 10）

### Step 2: 执行抓取

```bash
exec: bash {baseDir}/scripts/fetch_gigs.sh --sources <sources> --keywords "<keywords>" --limit <limit>
```

脚本输出两部分（以 `---SOURCE_STATUS---` 分隔）：
1. JSON 数组（任务列表）
2. 来源状态摘要

### Step 3: AI 增强处理

读取 JSON 输出后，对每条记录：

1. **生成中文摘要**：基于 `title` 和 `raw_snippet`，生成 ≤50 字的中文简要描述
2. **安全风险检测**：扫描 `title` + `raw_snippet`，按以下规则标记 `safety_flags`：

| 风险类型 | 检测关键词/模式 | 标记 |
|---------|----------------|------|
| 要求 root/sudo 权限 | `sudo`, `root`, `chmod 777`, `rm -rf` | ⚠️ 需要高权限操作 |
| 涉及系统文件修改 | `/etc/`, `/sys/`, `registry`, `kernel` | ⚠️ 涉及系统级修改 |
| 网络嗅探/渗透 | `pentest`, `exploit`, `vulnerability scan`, `reverse shell` | 🚨 疑似安全攻击类任务 |
| 数据爬取法律风险 | `scrape personal data`, `bypass captcha`, `crack` | 🚨 可能涉及违规爬取 |
| 加密货币/金融风险 | `crypto wallet`, `smart contract exploit` | ⚠️ 加密货币相关 |
| 灰色产业（中文） | `刷单`, `刷量`, `破解`, `外挂`, `代付`, `洗钱` | 🚨 疑似灰色产业 |
| 个人信息收集（中文） | `身份证`, `银行卡`, `手机号采集`, `人脸` | 🚨 涉及个人隐私数据 |

3. **分组排序**：按来源分为国际/国内两组，组内按 `posted_at` 倒序

### Step 4: 格式化输出

生成 Markdown 表格：

```
📋 软件开发任务速报 | {日期}
━━━━━━━━━━━━━━━━━━━━
共发现 {n} 条开发需求（{m} 个来源）

🌐 国际来源
| # | 任务摘要 | 来源 | 技术栈 | 联系方式 | 安全 | 链接 |
|---|---------|------|--------|---------|------|------|
| 1 | 需要 React 前端重构... | GitHub | React, TS | @user | ✅ | [链接](url) |

🇨🇳 国内来源
| # | 任务摘要 | 来源 | 预算 | 联系方式 | 安全 | 链接 |
|---|---------|------|------|---------|------|------|
| 1 | 企业ERP系统开发... | 猪八戒 | 5-10万 | 平台联系 | ✅ | [链接](url) |

来源状态：✅ GitHub | ✅ HN | ❌ 猪八戒(验证码) | ✅ 一品威客 | ⏭️ 英选(宕机)

⚠️ 安全提醒：标记为 ⚠️ 或 🚨 的任务请仔细核实后再考虑
```

## 去重

- 使用 URL 作为唯一标识（脚本层已去重）
- agent 可通过 memory 存储已推送过的任务 URL hash，避免重复推送
- 格式：`gig_seen: {url_hash} | {title} | {date}`

## 定时运行（可选）

用户可要求定时抓取，建议使用 cron：
```
每天早上 9 点抓取一次：
cron(action=add, job={
  name: "dev-gig-finder-daily",
  schedule: { kind: "cron", expression: "0 9 * * *" },
  task: "运行 dev-gig-finder skill，抓取最新软件开发任务并推送结果"
})
```

## 安全约束

- 不存储用户凭据
- 所有 API 调用使用公开接口或已配置的 `gh` CLI
- 仅展示信息，不自动接受/投标任何任务
- 中文输出，方便阅读
