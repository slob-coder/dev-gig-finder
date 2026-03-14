# dev-gig-finder

> OpenClaw Skill: 自动抓取网络中的软件开发任务/外包需求

## 功能

从 13 个数据源自动抓取软件开发商机和外包任务，输出结构化表格。

### 支持的数据源

**国际来源（4 个）：**
- GitHub Issues (help-wanted, bounty 标签)
- Hacker News (freelance/hiring 帖子)
- Reddit (r/forhire, r/freelance 等)
- dev.to (listings & articles)

**中文来源（9 个）：**
- 猪八戒网、一品威客、智城外包网、码市
- 程序员客栈、猿急送、开源众包、快码、英选

## 安装

将 `dev-gig-finder/` 目录复制到 `~/.openclaw/skills/`：

```bash
cp -r dev-gig-finder ~/.openclaw/skills/
```

## 前置依赖

- `curl` — HTTP 请求
- `jq` — JSON 处理（`brew install jq`）
- `gh` — GitHub CLI，已登录（`gh auth login`）
- `iconv`（可选）— 中文编码转换（macOS 自带）

## 使用方式

### 通过 OpenClaw

对 agent 说：
- "帮我找软件开发任务"
- "抓取外包需求"
- `/dev-gig-finder`

### 直接运行脚本

```bash
# 全部来源
bash dev-gig-finder/scripts/fetch_gigs.sh --sources all --limit 10

# 仅国际来源
bash dev-gig-finder/scripts/fetch_gigs.sh --sources intl

# 仅中文来源
bash dev-gig-finder/scripts/fetch_gigs.sh --sources cn

# 自定义来源组合
bash dev-gig-finder/scripts/fetch_gigs.sh --sources github,zbj,proginn --keywords "React,Python" --limit 5
```

## 输出格式

脚本输出 JSON 数组到 stdout，agent 会将其转换为 Markdown 表格，按国际/国内分组展示。

## 自定义数据源

参见 [references/sources.md](dev-gig-finder/references/sources.md) 了解如何添加新的数据源。

## 许可

MIT
