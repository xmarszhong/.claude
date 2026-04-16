---
name: cnb-pr
description: Use when creating a CNB pull request for the current branch and you need to check branch state, compare against the correct remote base, and open the PR safely.
---

# CNB Pull Request

用于创建或准备 CNB Pull Request。

开始时先说明：

> 我正在使用 cnb-pr skill 来创建 CNB Pull Request。

## 何时使用

当用户要求以下事情时使用：

- 创建 CNB PR
- 打开 CNB 合并请求
- 把当前分支提到某个目标分支
- 为当前仓库创建 CNB Pull Request

## 安全规则

- 不执行 destructive git 操作
- 不自动 amend、rebase、reset
- 不自动提交未提交改动
- 不跳过 hooks 或检查
- 工作区不干净时先停止并询问用户
- 不从 `master`、`main` 或其他基准分支直接创建 PR
- 未经用户明确要求，不执行 force push

## 工作流程

### 1. 检查仓库状态

先用只读命令检查：

- `git status --short --branch`
- `git branch --show-current`
- `git remote get-url origin`
- `git log --oneline -20`

如果能识别出 CNB 仓库路径，则记录 `repo`。

### 2. 检查工作区是否干净

如果存在未提交或已暂存但未提交的改动：

- 不要自动纳入 PR
- 先问用户如何处理
- 仅在用户明确要求后再继续

### 3. 确定目标分支

目标分支按以下优先级决定：

1. 如果用户明确给了 base branch，使用用户指定值
2. 仅当当前分支符合 `feature/rYYYYwN-<suffix>` 时，目标分支使用去掉最后 suffix 后的 `feature/rYYYYwN`
3. 其他任何分支格式都不要推断目标分支，必须询问用户

确定目标分支后，先确认远端存在该分支；如果远端不存在，停止并询问用户。

### 4. 先 fetch，再检查 PR 范围

在检查 PR 范围前，固定先执行：

- `git fetch origin <base> <current-branch>`

然后统一基于远端最新目标分支检查：

- `git log origin/<base>...HEAD --oneline`
- `git diff --stat origin/<base>...HEAD`
- `git diff origin/<base>...HEAD`

不要直接拿本地 `<base>` 对比。

### 5. 运行必要校验

优先遵守仓库内 `CLAUDE.md` 要求。

如果 skill 里写的默认校验命令在仓库里不存在，不要硬跑，改为使用仓库实际存在且用户认可的校验命令。

如果检查失败：

- 停止创建 PR
- 简要汇总失败原因
- 让用户决定是否继续

### 6. 确认分支是否已推到远端

先检查当前分支是否已有 upstream。

如果没有 upstream：

- 先告诉用户将执行 push
- 得到确认后再执行：`git push -u origin <branch>`

### 7. 生成 PR 标题和描述

标题要求：

- 简洁
- 与当前分支改动一致
- 如仓库或任务要求，保留 JIRA ID，例如 `#AP-15449`

描述默认只写：

```md
## Summary
- <改动点 1>
- <改动点 2>
```

不要提不需要的内容，例如 `Test plan`，除非用户明确要求。

### 8. 使用 CNB MCP 创建 Pull Request

优先使用：

- `mcp__cnb__cnb_create_pull`

参数应包含：

- `repo`
- `base`
- `head_repo`
- `head`
- `title`
- `body`

如果 CNB MCP 失败，先报告失败原因，再决定是否重试。

## 输出链接格式

返回 PR 链接时，使用：

- `https://cnb.cool/<group>/<repo>/-/pulls/<number>`
