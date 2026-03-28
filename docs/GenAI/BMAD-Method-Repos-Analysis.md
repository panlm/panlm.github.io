---
title: BMAD Method Repos Analysis
type: note
tags:
- bmad
- ai-agents
- agile
- claude-code
- product-discovery
- methodology
---

# BMAD Method 相关仓库分析

## 概述

BMAD (Breakthrough Method of Agile AI-Driven Development) 是一套面向 AI 驱动开发的敏捷方法论框架。以下是三个相关仓库的对比分析。

---

## 1. bmadcode/BMAD-METHOD-v5 (Legacy v5)

- **GitHub**: https://github.com/bmadcode/BMAD-METHOD-v5
- **Stars**: 177 ⭐
- **License**: MIT
- **依赖**: Node.js v20+

### 定位
原始的 BMAD Method 框架，提供完整的 AI Agent 全栈敏捷团队。

### 核心创新
1. **Agentic Planning (智能体规划)**: 专用 Agent（Analyst、PM、Architect）协同用户创建 PRD 和架构文档
2. **Context-Engineered Development (上下文工程化开发)**: Scrum Master Agent 将计划转化为超详细开发 Story，Dev Agent 直接使用

### 工作流
- **规划阶段 (Web UI)**: 创建 PRD + Architecture 文档
- **开发阶段 (IDE)**: SM → Dev → QA 协作，通过 story 文件传递上下文

### 安装方式
```bash
npx bmad-method install
# 或
git clone https://github.com/bmadcode/bmad-method.git
npm run install:bmad
```

### 特色功能
- **Expansion Packs**: 可扩展到非技术领域（创意写作、商业策略、健康等）
- **Codebase Flattener**: 将项目代码打包成 XML，方便 AI 分析
- 支持 Gemini Gem / CustomGPT 等 Web UI 部署
- Discord 社区支持

### 适用场景
- 需要完整敏捷流程的中大型项目
- 需要多 Agent 协作的团队
- 想要在 Web UI (Gemini/GPT) 中使用

---

## 2. amalik/BMAD-Enhanced

- **GitHub**: https://github.com/amalik/BMAD-Enhanced
- **Version**: 1.7.1
- **License**: MIT
- **Agents**: 7 个
- **Workflows**: 22 个

### 定位
BMAD 的增强版，专注于 **产品发现与验证** 阶段，在写代码之前验证产品想法。

### 核心理念
"Validate your product ideas before writing a single line of code"（在写一行代码之前验证你的产品想法）

### 7 个 Agent（Vortex 流）

| Agent | Stream | 功能 |
|-------|--------|------|
| **Emma** 🎯 | Contextualize | 问题定位：Personas、产品愿景、范围 |
| **Isla** 🔍 | Empathize | 用户理解：同理心地图、访谈、发现研究 |
| **Mila** 🔬 | Synthesize | 研究聚合：收敛为清晰的问题定义 |
| **Liam** 💡 | Hypothesize | 假设生成：将问题转为可测试假设 |
| **Wade** 🧪 | Externalize | 测试验证：MVP、实验、原型 |
| **Noah** 📡 | Sensitize | 信号解读：生产环境信号和用户行为分析 |
| **Max** 🧭 | Systematize | 决策制定：Pivot / Patch / Persevere |

### 与 BMAD Core 的关系
```
BMAD-Enhanced → 前期验证 ("Should we build this?")
BMAD Core     → 后期实施 ("Let's build it")
```
可独立使用，也可作为 BMAD 的扩展。

### 安装方式
```bash
npm install bmad-enhanced && npx bmad-install-vortex-agents
```

### 特色功能
- Vortex Compass 智能导航（根据当前学习成果推荐下一步）
- 10 个 Handoff Contracts (HC1-HC10) 确保 Agent 间数据传递
- 非线性流程，按需跳转
- 自动备份和版本更新

### 适用场景
- 产品发现和验证阶段
- 需要验证产品假设再开始开发
- 精益创业方法论实践者

---

## 3. aj-geddes/claude-code-bmad-skills

- **GitHub**: https://github.com/aj-geddes/claude-code-bmad-skills
- **License**: MIT
- **平台**: Windows / Linux / macOS / WSL
- **文档站**: https://aj-geddes.github.io/claude-code-bmad-skills

### 定位
将 BMAD Method 原生适配为 **Claude Code 的 Skills/Commands/Hooks**，无外部依赖。

### 核心特点

**Token 优化**:
- Helper Pattern 减少 70-85% Token 使用
- 技能文件总计 ~45.9KB (~11,475 tokens)
- 每次对话实际使用 ~15-25KB (~3,750-6,250 tokens)

**9 个 Skills**:
1. BMad Master（编排器）
2. Business Analyst（产品发现）
3. Product Manager（需求）
4. System Architect（设计）
5. Scrum Master（Sprint 规划）
6. Developer（实现）
7. UX Designer（用户体验）
8. Builder（可扩展性）
9. Creative Intelligence（头脑风暴/研究）

**15 个 Workflow Commands**:
- `/workflow-init` - 初始化 BMAD
- `/workflow-status` - 检查状态
- `/product-brief` - Phase 1: 产品发现
- `/prd` - Phase 2: 详细需求
- `/tech-spec` - Phase 2: 轻量需求
- `/architecture` - Phase 3: 系统设计
- `/sprint-planning` - Phase 4: 计划 Sprint
- `/create-story` - Phase 4: 创建用户故事
- `/dev-story` - Phase 4: 实现故事
- `/create-agent` - 自定义 Agent
- `/create-workflow` - 自定义工作流
- `/brainstorm` - 结构化头脑风暴
- `/research` - 市场/技术研究
- `/create-ux-design` - UX 设计

### 安装方式
```bash
cd /tmp
git clone https://github.com/aj-geddes/claude-code-bmad-skills.git
cd claude-code-bmad-skills
chmod +x install-v6.sh && ./install-v6.sh  # Linux/macOS
# 或 .\install-v6.ps1  # Windows
```

### 安装目录
- Skills: `~/.claude/skills/bmad/`
- Config: `~/.claude/config/bmad/`

### 适用场景
- 使用 Claude Code 作为主力开发工具
- 注重 Token 效率
- 不想依赖 Node.js / npm
- 需要跨平台支持

---

## 三者对比总结

| 维度 | BMAD-METHOD-v5 | BMAD-Enhanced | claude-code-bmad-skills |
|------|---------------|---------------|------------------------|
| **关注阶段** | 全流程（规划+开发） | 前期验证 | 全流程（规划+开发） |
| **Agent 数量** | ~6（Analyst/PM/Arch/SM/Dev/QA） | 7（Vortex 流） | 9（含 UX/Builder/Creative） |
| **目标平台** | Web UI + IDE | Claude.ai / Claude Code | Claude Code 原生 |
| **依赖** | Node.js v20+ | Node.js 18+ | 无外部依赖 |
| **Token 优化** | 无特别优化 | 无特别优化 | 70-85% 优化 |
| **安装方式** | npx / npm | npm | Shell 脚本 |
| **核心差异** | 原版框架，社区最大 | 产品发现 7 流 | Claude Code 原生集成 |
| **可扩展性** | Expansion Packs | Agent 自定义 | Builder 模块 |
| **社区活跃度** | 177⭐ Discord 社区 | 较新项目 | 较新项目 |

## 选择建议

1. **如果你使用 Claude Code 开发**: 选 `claude-code-bmad-skills`（原生集成，Token 最优）
2. **如果需要产品验证再开发**: 选 `BMAD-Enhanced`（Vortex 7 流验证流程）
3. **如果需要完整生态和社区**: 选 `BMAD-METHOD-v5`（最成熟，社区最大）
4. **组合使用**: `BMAD-Enhanced`（验证） → `BMAD-METHOD-v5` 或 `claude-code-bmad-skills`（实施）
