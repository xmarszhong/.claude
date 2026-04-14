---
name: jira-to-test
description: Move Jira issues or tasks to testing by setting status and fixVersion from the current branch.
---

# Jira 转测试

用于把 Jira 单据转到测试阶段。

开始时先说明：

> 我正在使用 jira-to-test skill 来转测试 Jira 单据。

## 何时使用

当用户要求以下事情时使用：

- 转测试
- 把 issue 转验证
- 把 task 转待测试
- 设置 Jira fixVersion 并流转状态

## 安全规则

- 这是会修改 Jira 的操作，执行前必须明确知道目标 Jira key。
- 如果用户没有提供 Jira key，先从当前分支、最近提交或 PR 标题中尝试识别 `AP-<number>`；识别不到必须询问用户。
- 不要猜测 Jira key。
- 不要修改 summary、description、assignee、priority、labels 等无关字段。
- 不要自动评论，除非用户明确要求。
- 如果状态流转或 fixVersion 更新失败，停止并报告失败原因。

## 工作流程

### 1. 确定 Jira key

按以下优先级确定 Jira key：

1. 用户明确给出 `AP-<number>` 时使用用户指定值。
2. 否则只读检查当前上下文：
   - `git branch --show-current`
   - `git log --oneline -20`
3. 如果能唯一识别一个 `AP-<number>`，使用该 key。
4. 如果识别不到或识别到多个，必须询问用户。

### 2. 获取 Jira 单据信息

使用 Jira MCP：

- `mcp__jira__jira_get_issue`

读取：

- issue key
- issue type
- current status
- current fixVersions

### 3. 确定目标状态

根据 issue type 决定目标状态：

- 如果类型是 `Issue` 或名称中包含 `Issue`，目标状态为 `待验证`。
- 如果类型是 `Task` 或名称中包含 `Task`，目标状态为 `待测试`。
- 如果类型无法判断，必须询问用户，不要猜。

### 4. 从当前分支推断 fixVersion

只在当前分支符合以下格式时推断：

- `feature/rYYYYwN-<owner-or-suffix>`

推断规则：

- 去掉最后 suffix 得到团队分支：`feature/rYYYYwN`
- 版本名为：`API-rYYYYwN`

示例：

- `feature/r202604w3-mars` -> `API-r202604w3`
- `feature/r202604w2-zayne` -> `API-r202604w2`

其他任何分支格式都不要推断 fixVersion，必须询问用户。

### 5. 更新 Jira

先使用 Jira MCP 更新状态：

- `mcp__jira__jira_update_issue`
- 参数：`issueKey`、`status`

对于 fixVersion：

- 如果 Jira MCP 支持直接更新 fixVersion，优先使用 MCP。
- 如果当前 MCP 不支持 fixVersion 字段，可以使用 Jira REST API 更新，但不要输出或泄露 token。
- 更新前通过 Jira 项目版本列表确认目标版本存在。
- 目标版本不存在时停止并询问用户，不要自动创建版本。

### 6. 验证结果

更新后再次读取 Jira 单据，确认：

- status 已是目标状态
- fixVersions 包含目标版本

如果任一字段未生效，报告实际状态，不要假装成功。

## 输出格式

成功后简短输出：

```md
已转测试：
- Jira：AP-xxxxx
- status：<目标状态>
- fixVersion：<目标版本>
```

如果缺少信息，直接问用户需要的字段。

## 示例

- `/jira-to-test AP-15449`
- `/jira-to-test 转测试 AP-15449`
- `/jira-to-test 当前分支对应的 issue 转测试`
