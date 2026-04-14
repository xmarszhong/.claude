---
name: cnb-pr
description: Create CNB pull requests safely, following repository git checks and CNB URL conventions.
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

- 不执行 destructive git 操作。
- 不自动 amend、rebase、reset。
- 不自动提交未提交改动。
- 不跳过 hooks 或检查。
- 工作区不干净时先停止并询问用户。
- 不从 `master`、`main` 或其他基准分支直接创建 PR。
- 未经用户明确要求，不执行 force push。

## 工作流程

### 1. 先检查仓库状态

先用只读命令检查：

- `git status --short --branch`
- `git branch --show-current`
- `git remote get-url origin`
- `git log --oneline -20`

如果能识别出 CNB 仓库路径，则记录 `repo`。对于当前 Tars 仓库，通常应是 `apifox/tarslib`，但应以当前 remote 为准。

### 2. 检查工作区是否干净

如果存在未提交或已暂存但未提交的改动：

- 不要自动纳入 PR
- 先问用户如何处理
- 仅在用户明确要求后再继续提交或推送

### 3. 确定目标分支

目标分支按以下优先级决定：

1. 如果用户明确给了 base branch，使用用户指定值。
2. 仅当当前分支符合 `feature/rYYYYwN-<owner-or-suffix>` 时，目标分支使用去掉最后 suffix 后的 `feature/rYYYYwN`。
   - 示例：`feature/r202604w3-mars` -> `feature/r202604w3`
   - 示例：`feature/r202604w2-zayne` -> `feature/r202604w2`
3. 其他任何分支格式都不要推断目标分支，必须询问用户。

确定目标分支后，先确认远端存在该分支；如果远端不存在，停止并询问用户，不要自动创建目标分支。

### 4. 检查 PR 范围

检查：

- `git log <base>...HEAD --oneline`
- `git diff --stat <base>...HEAD`
- `git diff <base>...HEAD`

如果当前仓库有提交规范要求，要一并检查。对于 `tarslib`：

- `feat:` / `fix:` 提交通常需要 `#AP-<number>`
- 不要自动改写历史提交，发现问题先告知用户

### 5. 运行必要校验

优先遵守仓库内 `CLAUDE.md` 要求。对于 `tarslib`：

- 提交前/PR 前优先运行 `pnpm run check`

如果检查失败：

- 停止创建 PR
- 简要汇总失败原因
- 让用户决定是否先修复或带说明继续

### 6. 确认分支是否已推到远端

先检查当前分支是否已有 upstream。

如果没有 upstream：

- 先告诉用户将执行 push
- 得到确认后再执行：`git push -u origin <branch>`

默认不要 force push。

### 7. 生成 PR 标题和描述

标题要求：

- 简洁
- 与当前分支改动一致
- 如仓库/任务要求，保留 JIRA ID，例如 `#AP-15449`

描述建议使用模板：

```md
## Summary
- <改动点 1>
- <改动点 2>

## Test plan
- <已运行的检查>
- <未运行项及原因>
```

如果检查没有跑，必须明确说明原因，不要假装已验证。

### 8. 使用 CNB MCP 创建 Pull Request

优先使用 CNB MCP：

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

返回 PR 链接时，使用 CNB 正确链接格式：

- `https://cnb.cool/<group>/<repo>/-/pulls/<number>`

不要只返回 GitHub 风格 `owner/repo#123`，也不要漏掉 `/-/pulls/`。

## 示例

- `/cnb-pr create PR to feature/r202604w3`
- `/cnb-pr 为当前分支创建 CNB PR，目标分支是 master`
- `/cnb-pr 检查当前分支是否已经可以提 PR，但先不要真正创建`
