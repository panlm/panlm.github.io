---
title: AWS Well-Architected 相关 GitHub 仓库全景调研
description: 调研 9 个 AWS 官方 GitHub 组织全部 12061 个公开仓库，比较 Well-Architected 相关工具的迭代活跃度与能力差异
created: 2026-09-01
last_modified: 2026-09-01
tags:
- aws/well-architected
- github
permalink: git-mkdocs/others/aws-well-architected-repo-landscape
---

# AWS Well-Architected 相关 GitHub 仓库全景调研

> 调研日期：2026-09-01
> 范围：9 个 AWS 官方 GitHub 组织的全部公开仓库，以及组织外的第三方实现
> 方法：全量枚举 12,061 个公开仓库按名称/描述正则筛选，叠加 90 组「组织 × 关键词」搜索、17 轮命名模式扫描，以及针对 `SKILL.md` / MCP / WA Tool API 调用的代码搜索
> 所有指标取自 GitHub API，可复现（见文末「如何复现」）

---

## TL;DR

在**「教 AI agent 执行 Well-Architected 评审」**这个类别里，`aws-samples/sample-well-architected-skills-and-steering` <mark style="background: #FFB86CA6;">是目前最好的</mark>，且没有可比的第二名。

但如果只按 star 数或总提交数排，它排第 5 —— 前面四个数字更大的仓库都**不是同类工具**（教学语料、lens 模板、配置扫描器、IaC 打分器）。它在**近 90 天活跃度**上排第一，领先第二名近 2 倍。

调研中最值得记录的一个发现：**在所有碰过 Well-Architected Tool API 的仓库里，没有任何一个使用 AWS 官方发布的 per-best-practice 风险等级来定级** —— 全部由大模型自行判断严重度。

---

## 一、整体排名

| 仓库 | 类别 | Star | 提交数 | 贡献者 | 近 90 天提交 | 最后推送 |
|---|---|---|---|---|---|---|
| `awslabs/aws-well-architected-labs` | 教学内容语料 | 2,131 | 3,219 | 226 | 0 | 2026-01-14 |
| `aws-samples/custom-lens-wa-hub` | 自定义 lens 模板 | 2,041 | 210 | 29 | 10 | 2026-08-21 |
| `aws-samples/service-screener-v2` | 配置扫描器（自带 MCP） | 569 | 952 | 34 | 76 | 2026-08-10 |
| `aws-samples/well-architected-iac-analyzer` | IaC / 架构图打分 | 501 | 358 | 9 | 47 | 2026-09-01 |
| **`aws-samples/sample-well-architected-skills-and-steering`** | **Agent skill** | **255** | **203** | **9** | **141** | **2026-08-27** |

### 为什么前四名不算竞品

**`awslabs/aws-well-architected-labs`** —— 数字碾压一切（3,219 提交 / 226 贡献者，2018 年至今），但它是 wellarchitectedlabs.com 背后的**教学实验内容库**，给人读的教程，不是可执行工具。且**已停更 8 个月**。

**`aws-samples/custom-lens-wa-hub`** —— 2022 年建库，是一批**给人手工上传到 WA Tool 控制台的自定义 lens JSON 模板**。不含任何评审执行逻辑。

**`aws-samples/service-screener-v2`** —— 最成熟的**配置扫描器**：扫账号资源配置是否符合最佳实践并出报告。自带 MCP server，所以 agent 可调用。但它不走 57 问的评审流程，定位是「自动查配置」而非「做评审」。

**`aws-samples/well-architected-iac-analyzer`** —— Bedrock 网页应用，上传 IaC 代码或架构图后打分，自带一套 WA 分析 prompt library。同为打分工具，无 agent skill 接口。

---

## 二、Agent-native 类别：唯一的参考实现

`aws-samples/sample-well-architected-skills-and-steering`（MIT-0）

它的工程质量明显高于典型的 `aws-samples` demo：

- 3.5 个月 **203 次提交**，**30 个 release / 53 个 tag**，语义化版本至 v6.4.0
- **CI 有 4 个任务**：pytest、`drift-guard`（用 `diff -rq` 防止 Kiro 副本与主副本漂移）、`link-check`（lychee，失败即阻断）、`secret-scan`（gitleaks）
- **`evals/` 测试集并公布 F1 分数** —— 在 prompt / skill 类项目里罕见，说明作者在量化 skill 效果
- **14 种 agent 工具适配器**（Claude Code、Cursor、Kiro、Codex、Windsurf、Gemini CLI 等）
- 参考语料：**27 个 lens、951 个文件**，另有 6 个 pillar 文件（2.2 MB）
- 治理完备：CONTRIBUTING、SECURITY、CoC、PR 模板（含 eval 结果栏）、3 类 issue 模板、`plugin.json`

**两个健康度隐忧：**

- **Bus factor = 1**。主维护者贡献 171/203 次提交（84%），其余除一人外均为单次提交。
- **提交频率递减**：5 月 62 → 6 月 59 → 7 月 53 → **8 月 29**。2026-08-27 后无提交，维护者自己的两个 PR 自 8 月中旬起未合并。

**42 个 fork 中没有一个领先于上游**（抽查最近推送的 11 个，全部 `ahead_by=0`），且全部 0 star。无人改进过它。

---

## 三、其余 Agent-native 实现

搜索发现的其他 agent 可调用实现，均不构成竞品，但各有专门用途：

| 仓库 / 路径 | Star | 定位 |
|---|---|---|
| `awslabs/mcp` → `src/well-architected-security-mcp-server` | 9,648（monorepo） | MCP server，6 工具。**仅安全支柱**，无题库，扫 GuardDuty / Security Hub / Inspector / Access Analyzer + 存储与网络加密 |
| `aws-samples/sample-aws-resilience-skill` | 9 | 9 个 Claude skill，含 `aws-well-architected-review`，映射到 Resilience Lifecycle |
| `aws-samples/sample-cloudops-multi-agent-system` | 12 | 分层 agent 系统，5 个 `SKILL.md`，含 `resilience-report`、`finops-analysis` |
| `aws-samples/sample-aws-network-architecture-review-mcp-server` | 26 | MCP，13 工具：DX 冗余评分、TGW 拓扑、Cloud WAN 发现（仅网络域） |
| `aws-samples/sample-network-resilience-agent` | 23 | Direct Connect 拓扑发现/可视化/建议，含 `skills/resilience-report/SKILL.md` |
| `aws-samples/sample-well-architected-generative-ai-solutions` | 29 | Bedrock Agents + MCP action group 执行 WA 安全评估 |
| `aws-samples/sample-architecture-review-agent` | 0 | AgentCore agent：89 条 WA 规则 + 10 条组织规则，作用于 CloudFormation |
| `aws-samples/sample-rds-agentic-well-architected-review` | 3 | RDS/Aurora 专用多 agent MCP 评审，每支柱一个 prompt 文件 |
| `aws-samples/sample-ftr-self-assessment-mcp` | 0 | MCP + CLI，把**已完成的 WAFR 报告 PDF** 对照 6 条 FTR 门槛打分（如「12 个月内」「SEC/OPS/REL 无活跃 HRI」） |
| `aws-samples/sample-q-architecture-reviewer` | 3 | 「ArchiQ」—— Amazon Q prompt pack，封装 service-screener |
| `aws-samples/sample-ai-agent-skills` → `wellarchitected-troubleshooting` | 低 | 排查 **WA Tool 本身**（lens 配置、milestone、共享）的诊断 runbook |
| `github/awesome-copilot` → `skills/aws-well-architected-review` | 46k+（monorepo） | 扫 IaC，约 50 条 checkbox，经 GitHub MCP 建 issue |
| `YoshiiRyo1/document-templates-for-aws` → `.claude/skills/wa-review` | 357（repo） | 审**日文 AWS 设计文档 / 需求确认表**，每支柱参考文件 |
| `sandeepdas0407/cloud-waf-review-plugin` | 0 | 审 **.pptx 演示稿 / 架构图 / IaC**，支持 AWS 6 支柱与 Azure 5 支柱 |
| `harshgoyal1/cloud-architect-skills` | 1 | 97 行 prompt，Strong/Adequate/Weak 评级 + 权衡登记表 |

**已知损坏，建议避开**：`mcpnexus-registry/mcp-well-architected` —— 输出硬编码，完全忽略输入。

---

## 四、核心发现：三项能力，无人达成两项

对每一个碰过 Well-Architected Tool API 的仓库，检查三件事：

- **(a) 题库实时拉取，且按 `LensVersion` 失效** —— AWS 修订 lens 时能自动感知
- **(b) 使用 AWS 官方发布的 per-best-practice 风险等级定级** —— 即文档里的 "Level of risk exposed if this best practice is not established"
- **(c) 通过 `UpdateAnswer` 携带真实 choice ID 写回 WA Tool**

| 仓库 | (a) | (b) | (c) |
|---|---|---|---|
| `aws-samples/sample-well-architected-acceleration-with-generative-ai` | ✗ | ✗ | **✓** |
| `kd03-dev/keel-wafr-engine` | ✗ | ✗ | ✗ |
| `aws-samples/sample-ai-agent-skills` | ✗ | ✗ | ✗ |
| `awslabs/aws-well-architected-labs`（watool utilities） | ✗ | ✗ | ✗ |
| `awslabs/mcp`（well-architected-security） | ✗ | ✗ | ✗ |
| `chrishuffman5/awscliskills` | ✗ | ✗ | ✗ |

**没有任何仓库达成两项。(b) 由零个仓库实现。**

### (b) 项零实现，尤其值得注意

AWS 为每一条最佳实践都公开发布了风险等级（High / Medium / Low）。这个字段可以让「这条是 High 风险」从一句主观判断变成一句可审计的引用。

目前所有实现都让大模型自行判断严重度。

最能说明问题的是 `sample-well-architected-acceleration-with-generative-ai`：它**已经在运行时调用 `GetAnswer`**，官方风险数据就在它解析的那个响应里 —— 但它仍然让 Bedrock 生成一个 severity 字符串，再用正则从模型输出里抠出来（`generate_pillar_question_response.py:138`）。

而参考实现 `sample-well-architected-skills-and-steering` 的情况更微妙：**它的爬虫已经把官方风险等级抓进语料了**，以正文加粗文字的形式存在（`**Level of risk exposed if this best practice is not established:** High`，见 `references/pillars/*.md`）。但：

- 它不是字段，没有 frontmatter key、表格列或 JSON 属性
- 输出 schema `schemas/aws-well-architected-framework-review-v1.schema.json` 里没有对应属性
- **`references/manifest.md`（agent 每次都会加载的索引文件）完全省略了它**

**数据在仓库里，但结构上不可达。** 这是一个用现有数据即可修复的缺口。

---

## 五、参考实现的三个具体缺口

以下均基于对仓库文件的直接核查，标注了可验证的文件路径。三者都属于**用仓库已有数据即可修复**的类型。

### 缺口 1：题库是转述后的静态快照，且无法确定新旧

- 57 道题以**改写后的转述**形式存于 `references/wa-questions.md`，非 API 原文
- 语料由 `scripts/crawl-wa-framework.py`（1,283 行）抓取 `docs.aws.amazon.com/.../toc-contents.json` 生成 —— **抓文档网站，而非 API**
- 爬虫**手工触发**，无定时刷新 workflow
- **语料内无抓取日期**。每条 BP 有 `*Source: <url>*` 脚注但不含日期；grep 全部 6 个 pillar 文件查 `crawled|generated on|snapshot date` 返回 0
- 目标 URL 形如 `.../latest/...`，不锁版本，因此重跑爬虫会静默改变内容，**且无 diff 门禁**
- 全仓库对 `ExportLens` / `ListAnswers` / `GetAnswer` / `LensVersion` / `boto3.client("wellarchitected"` 的搜索：**各 0 命中**

**需要指出：这是刻意的设计目标，不是疏漏。** `README.md:26` 明确写「Requires no AWS credentials, no API calls — everything runs locally」，`README.md:730` 也诚实声明「a snapshot of the AWS Well-Architected public docs at the time of the last crawl. **You are responsible for checking whether the data needs updating before use**」。

这个取舍换来了真实的好处：**可在 CI 中运行，可审计你无 AWS 访问权限的代码库。** API 方案做不到这两点。

代价是使用者无法在不查 git 历史的情况下知道快照有多旧。

### 缺口 2：官方风险等级不可达

见上一节。数据已在语料中，但未结构化，且被 agent 唯一必加载的索引文件省略。

### 缺口 3：采集了业务关键度，却在定级前丢弃

- `business_criticality` 在 `SKILL.md:17` 采集，并序列化进输出 JSON
- 但它**未传入任何一个 pillar 子 agent 的 prompt**（`SKILL.md:233–255`）—— 而这些子 agent 才是给每一条发现定严重度的地方
- 它**不是** Impact × Likelihood 矩阵（`SKILL.md:372–382`）的输入轴
- grep `sandbox` / `non-production` / `nonprod` / `staging` / `downgrade`：**各 0 命中**，无升降级机制
- 唯一的环境分层语句（三处重复）：「When business criticality is 'low'/'standard', accept simpler architectures (single-region is fine for internal tools)」—— 但它只到达汇总环节，**对真正定级的子 agent 不可见**

**实测影响**：对一个内部 LLM 代理网关（单实例 + ALB，内部沙箱账号，无客户数据，无 SLA，单人运维）执行完整 57 问评审：

| | High 数量 |
|---|---|
| AWS 标准原始评级 | **44** |
| 按语境校准后 | **22** |

差异来自 28 处校准（26 处下调、2 处上调），每处下调均记录理由与「何种情况下重新升为 High」的触发条件。

对无客户数据的内部沙箱直接返回 44 条 High，是典型的「评审结论被使用者整体忽略」的成因 —— 使用者会认为评审方不了解系统实况。

两处**上调**同样重要，说明校准不是单向放水：

- 事件检测题：AWS 标准 Medium → High。理由是 ALB access log 与 VPC Flow Log 双双关闭，事后无法还原调用来源，取证能力为零
- 支持就绪题：AWS 标准 Low → Medium。AWS 只把「无 support plan」计为 Low，但实际缺口是 0 告警 + 0 SNS topic + 容器健康检查已失效 = 无任何呼叫路径

---

## 六、一处历史考证

参考实现有一个 release 名为 **v6.0.0 — wa-review renamed to aws-well-architected-framework-review**，容易让人以为上游曾实现过 API 版本后放弃。

核查结论：**并非如此。**

- 改名前的 `skills/wa-review/SKILL.md`（tag `v5.12.1`，改名前最后一个 tag）为 640 行，frontmatter `version: 2.3.0`，description 与今日**字节相同**
- 该旧文件对 `ExportLens` / `ListAnswers` / `GetAnswer` / `UpdateAnswer` / `LensVersion` / `SelectedChoices` / `boto3` 的搜索：**各 0 命中**
- 它已在 9 处引用静态语料，加载顺序（manifest → pillar → playbook）与 6 路并行子 agent 派发方式与今日一致
- 新旧 diff 约 70/690 行，全部是 `name:` 行、v6.2.0 的 "Fix blocks" 特性、以及输出文件名重命名

**上游从未尝试 API 支撑的评审路径。**

---

## 七、值得借鉴的两个设计

调研中遇到两个想法，值得任何做 WA 评审工具的人参考：

**1. 用 API 快照替代手写转述** —— `kd03-dev/keel-wafr-engine` 调用 `list_answers` 抓出 167 KB 快照（6 支柱 / 57 问 / 307 最佳实践，AWS 原文标题与描述），落盘为 `wellarchitected_raw.json`，运行时读本地文件、不需 AWS 权限。其 `docs/adr/0007-real-lens-content.md` 明确记录了**从手写转述迁移到 API 原文**的决策。

这是「credential-free」与「用原文而非转述」的一个折中方案：抓取时需要一次性权限，运行时不需要。

> 注：该仓库**无 license 文件**，作为依赖使用存在法律障碍。此处仅参考其设计思路。

**2. 把「查不出来」作为一等公民** —— 同一仓库的 finding 有四态：`PASSED` / `FAILED` / `SUPPRESSED` / `ERROR`，且答案是由「检查 → 最佳实践 → 问题 → 支柱 → 风险」逐层上卷**推导**出来的，从不直接存储答案。

这比二元的通过/不通过更诚实。任何评审工具都会遇到「权限不足查不到」「证据不充分」的情况，把它算作「通过」会掩盖真实缺口，算作「不通过」则是冤枉。

---

## 八、结论与建议

### 结论

1. **Agent-native 类别里，`aws-samples/sample-well-architected-skills-and-steering` 是最佳选择，且无可比的第二名。** 工程质量（evals + F1、CI 四检、30 个 release、14 种工具适配）显著高于同类。
2. star 数与总提交数更高的四个仓库都不是同类工具。该仓库在**近 90 天活跃度**上排名第一。
3. 它的两个健康度风险是真实的：**bus factor = 1**，且**提交频率连续四个月递减**。
4. **没有任何现存实现同时做到「API 实时题库 + 官方风险等级 + 写回 WA Tool」中的两项。** 官方风险等级由**零个**仓库使用。
5. bundled 语料方案与 API 方案是**互补而非竞争**：前者用于上线前的代码 / IaC 审查（可在 CI 运行、无需凭证），后者用于线上活账号审计（可写回、可与下次评审做 diff）。

### 给参考实现的两个改进建议

两者都能用仓库**已有的数据**完成，无需新增数据源：

1. **把官方风险等级从正文 prose 提升为机器可读字段**，并纳入 `references/manifest.md` 与输出 schema。语料里已经抓到了这个值，目前只是未结构化。收益：风险评级从「模型判断」变为「引用 AWS 官方发布值」，可审计。
2. **把 `business_criticality` 传入那 6 个 pillar 子 agent 的 prompt**，或纳入 Impact × Likelihood 矩阵作为一个轴。值已采集，目前只是未向下传递。收益：内部工具 / 沙箱负载不再收到与生产环境相同的评级。

### 若要自行搭建，两个提速资源

- `aws-samples/sample-well-architected-custom-lens` —— 17 个官方 lens 的 JSON 集中在一处，比逐个 `ExportLens` 拉取更快
- `aws-samples/sample-rds-aurora-postgresql-stats-collection` —— 专为 WA 评审做证据采集（CloudWatch、Performance Insights、`pg_stat_statements`）

---

## 九、未验证项

以下一项未完成核查，**不应与上文已确认结论同等对待**：

> `aws-samples/well-architected-iac-analyzer`（501★，358 提交，2026-09-01 推送）与 `aws-samples/service-screener-v2`（569★，952 提交，自带 MCP）**是否调用 Well-Architected Tool API、是否使用官方发布的风险等级**，尚未核查。
>
> 从其描述判断大概率为否（前者自带 prompt library，后者是配置扫描器），但未经验证。
>
> **若其中任一使用了官方风险等级，则第四节「(b) 由零个仓库实现」与「无人达成两项」两句结论需要修正。**

其余结论不受此项影响。

---

## 如何复现

所有指标均来自 GitHub API，无需特殊权限：

```bash
# 组织内关键词搜索
gh search repos "well-architected" --owner aws-samples --limit 100 \
  --json fullName,description,stargazersCount,updatedAt,pushedAt,createdAt,isArchived

# 全量枚举某组织（本次对 9 个组织共 12,061 个仓库执行）
gh api --paginate "orgs/aws-samples/repos?per_page=100" \
  --jq '.[] | {full_name, description, pushed_at, stargazers_count}'

# 总提交数：读 link 头 rel="last" 的页码
gh api "repos/{owner}/{repo}/commits?per_page=1" --include | grep -i '^link:'

# 近 90 天提交数
gh api "repos/{owner}/{repo}/commits?since=2026-06-01" --jq 'length'

# 贡献者（含匿名）
gh api "repos/{owner}/{repo}/contributors?anon=1&per_page=100" --jq 'length'

# fork 是否领先上游
gh api "repos/{fork_owner}/{repo}/compare/{upstream}:main...{fork_owner}:main" \
  --jq '{ahead_by, behind_by}'

# 检查是否调用 WA Tool API
gh api "repos/{owner}/{repo}/git/trees/HEAD?recursive=1" --jq '.tree[].path'
gh search code "list_answers repo:{owner}/{repo}"
```

指标随时间变化，上表为 2026-09-01 的快照。

---

## 排除项说明

为避免误导，记录本次调研主动排除的内容：

- **约 40 个「多区域高可用参考架构」仓库**（如 `guidance-for-multi-region-*`、`sample-multi-region-resilient-microservice-on-aws`、`apprunner-multiregion`）—— 它们是**具备韧性的应用**，而非 WA 框架或评审/评估工具
- **韧性类仅保留评估工具与框架**，不含韧性实现范例
- **搜索词误命中**：`sample-compliance-lens`（Config 规则）、`infrastructure-assessment-iac-automation`（资源审计）、`sample-fragile-to-resilient`（Bedrock 教学套件），以及 WAF / wallet / wafer / DeepLens / contact-lens 等名称冲突

---

*本文为独立技术调研，不代表 AWS 或任何仓库维护方的立场。所有批评性结论均附可验证的文件路径，欢迎指正。*
