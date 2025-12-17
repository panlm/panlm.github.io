# 📚 PanLM 技术文档站点

[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Active-success?logo=github)](https://panlm.github.io/)
[![MkDocs](https://img.shields.io/badge/MkDocs-Material-526CFE?logo=materialformkdocs)](https://squidfunk.github.io/mkdocs-material/)
[![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)](https://www.python.org/)
[![Build Status](https://img.shields.io/github/actions/workflow/status/panlm/panlm.github.io/ci.yml?branch=main)](https://github.com/panlm/panlm.github.io/actions)

> **在线访问**: [https://panlm.github.io/](https://panlm.github.io/)

基于 MkDocs Material 构建的专业技术文档站点，涵盖云计算、容器编排、人工智能、数据分析等多个领域的实践笔记和解决方案。

---

## ✨ 核心特性

- 🌐 **双语支持**: 同时提供中文和英文文档，自动国际化
- 🎨 **现代化主题**: 基于 Material Design，支持暗色/亮色主题切换
- 🔍 **强大搜索**: 内置搜索建议功能，快速定位所需内容
- 🖼️ **图片浏览**: 集成 Glightbox，提供流畅的图片查看体验
- 📝 **Wiki 链接**: 支持 Obsidian 风格的 Wiki 链接语法
- 🏷️ **标签系统**: 文档标签分类，方便主题浏览
- 📅 **版本跟踪**: 自动显示文档创建和修改时间
- 📱 **响应式设计**: 完美适配桌面、平板和移动设备

---

## 📂 文档目录结构

```
docs/
├── CLI/                    # AWS CLI 命令参考和脚本示例
│   ├── awscli/            # AWS CLI 命令集合
│   └── functions/         # Shell 函数库
├── cloud9/                 # AWS Cloud9 配置和使用指南
├── serverless/             # 无服务器架构实践
│   ├── Lambda
│   ├── API Gateway
│   └── SAM/CDK 部署
├── GenAI/                  # 生成式 AI 和机器学习
│   ├── LLM 模型部署
│   ├── MCP Server 配置
│   └── AI 应用开发
├── EKS/                    # Amazon EKS 容器编排
│   ├── 集群管理
│   ├── 网络配置
│   ├── 安全最佳实践
│   └── 混合节点架构
├── data-analytics/         # 数据分析和大数据
│   ├── OpenSearch
│   ├── Redshift
│   ├── Glue
│   └── QuickSight
├── others/                 # 其他技术主题
│   ├── 网络架构
│   ├── 安全合规
│   └── 运维工具
├── git-attachment/         # 文档附件和图片资源
├── index.md               # 英文首页
├── index.zh.md            # 中文首页
└── tags.md                # 标签索引页
```

---

## 🚀 快速开始

### 环境要求

- **Python**: 3.11 或更高版本
- **pip**: Python 包管理器
- **Git**: 版本控制系统

### 安装依赖

克隆仓库并安装所需的 Python 包：

```bash
# 克隆仓库
git clone https://github.com/panlm/panlm.github.io.git
cd panlm.github.io

# 创建虚拟环境（推荐）
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# 或
venv\Scripts\activate     # Windows

# 安装依赖
pip install -r requirements.txt
```

### 本地预览

启动本地开发服务器进行实时预览：

```bash
mkdocs serve
```

访问 [http://127.0.0.1:8000](http://127.0.0.1:8000) 查看文档站点。

### 构建静态站点

生成静态 HTML 文件：

```bash
mkdocs build
```

构建完成后，静态文件将位于 `site/` 目录中。

---

## 🔧 使用的插件和扩展

### MkDocs 核心插件

| 插件名称 | 功能说明 |
|---------|---------|
| `mkdocs-material` | Material Design 主题 |
| `mkdocs-ezlinked-plugin` | 简化 Wiki 链接处理 |
| `mkdocs-awesome-nav` | 自动生成导航结构 |
| `mkdocs-git-revision-date-localized-plugin` | 显示文档修改时间 |
| `mkdocs-custom-tags-attributes` | 自定义标签和属性 |
| `mkdocs-preview-links-plugin` | 链接预览功能 |
| `mkdocs-embed-file-plugins` | 嵌入外部文件 |
| `mkdocs-encryptcontent-plugin` | 内容加密保护 |
| `mkdocs-callouts` | 醒目标注块 |
| `mkdocs-meta-descriptions-plugin` | SEO 元描述 |
| `mkdocs-glightbox` | 图片灯箱效果 |
| `mkdocs-pagetree-plugin` | 页面树状结构 |
| `mkdocs-file-filter-plugin` | 文件过滤功能 |
| `mkdocs-static-i18n` | 静态国际化支持 |

### Markdown 扩展

- **pymdownx**: 扩展 Markdown 功能（数学公式、任务列表、代码高亮等）
- **admonition**: 提示框和警告块
- **toc**: 目录生成
- **footnotes**: 脚注支持
- **tables**: 表格支持
- **mermaid**: 流程图和图表支持

---

## 📝 文档编写指南

### 添加新文档

1. 在相应的目录下创建 Markdown 文件
2. 添加 YAML 前置元数据（可选但推荐）：

```yaml
---
title: 文档标题
description: 文档描述
last_modified: 2024-01-01
tags:
  - 标签1
  - 标签2
status: myblog  # 可选: myblog, awsblog, deprecated
---
```

3. 使用标准 Markdown 语法编写内容
4. 支持 Obsidian 风格的 Wiki 链接: `[[文件名|显示文本]]`

### Markdown 最佳实践

- ✅ 使用有意义的标题层级（H1 → H2 → H3）
- ✅ 为代码块指定语言以启用语法高亮
- ✅ 使用相对路径引用图片和链接
- ✅ 添加元数据提升 SEO 和文档管理
- ✅ 使用 Admonition 语法创建提示框：

```markdown
!!! note "提示"
    这是一个提示信息

!!! warning "警告"
    这是一个警告信息

!!! tip "技巧"
    这是一个技巧分享
```

### 图片管理

- 将图片存放在 `docs/git-attachment/` 目录
- 使用相对路径引用: `![描述](../git-attachment/image.png)`

---

## 🤝 贡献指南

我们欢迎各种形式的贡献！无论是修复错误、改进文档还是添加新内容。

### 贡献流程

1. **Fork 仓库**: 点击页面右上角的 Fork 按钮

2. **克隆到本地**:
   ```bash
   git clone https://github.com/your-username/panlm.github.io.git
   cd panlm.github.io
   ```

3. **创建功能分支**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

4. **进行修改并测试**:
   ```bash
   # 安装依赖
   pip install -r requirements.txt
   
   # 本地预览
   mkdocs serve
   
   # 构建测试
   mkdocs build
   ```

5. **提交更改**:
   ```bash
   git add .
   git commit -m "描述你的更改"
   git push origin feature/your-feature-name
   ```

6. **创建 Pull Request**: 在 GitHub 上创建 PR，描述你的更改

### 贡献准则

- 📖 保持文档清晰、准确和最新
- 🎯 遵循现有的文档结构和格式
- 🌐 考虑提供中英文双语内容
- ✔️ 在提交前进行本地测试
- 💬 在 PR 中提供详细的更改说明

---

## 🔄 自动部署

本项目使用 GitHub Actions 实现自动化部署：

- **触发条件**: 推送到 `main` 或 `master` 分支
- **构建环境**: Ubuntu Latest + Python 3.11
- **部署目标**: GitHub Pages
- **工作流文件**: `.github/workflows/ci.yml`

每次推送后，GitHub Actions 会自动：
1. 检出代码（包含完整 Git 历史）
2. 安装 Python 依赖
3. 构建 MkDocs 站点
4. 部署到 GitHub Pages

---

## 📚 技术栈

| 技术 | 说明 |
|-----|------|
| [MkDocs](https://www.mkdocs.org/) | 静态站点生成器 |
| [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) | 现代化文档主题 |
| [Python](https://www.python.org/) | 运行环境 |
| [GitHub Pages](https://pages.github.com/) | 托管服务 |
| [GitHub Actions](https://github.com/features/actions) | CI/CD 自动化 |

---

## 📖 相关资源

### 官方文档

- [MkDocs 官方文档](https://www.mkdocs.org/)
- [Material for MkDocs 文档](https://squidfunk.github.io/mkdocs-material/)
- [PyMdown Extensions](https://facelessuser.github.io/pymdown-extensions/)

### 插件文档

- [mkdocs-static-i18n](https://ultrabug.github.io/mkdocs-static-i18n/)
- [mkdocs-git-revision-date-localized](https://github.com/timvink/mkdocs-git-revision-date-localized-plugin)
- [mkdocs-glightbox](https://github.com/blueswen/mkdocs-glightbox)
- [mkdocs-ezlinked-plugin](https://github.com/Mara-Li/mkdocs-ezlinked-plugin)

### Markdown 语法

- [Markdown 基础语法](https://www.markdownguide.org/basic-syntax/)
- [GitHub Flavored Markdown](https://github.github.com/gfm/)
- [Mermaid 图表语法](https://mermaid.js.org/)

---

## 🎯 项目亮点

本文档站点记录了大量实战经验和解决方案，包括但不限于：

- ☁️ **AWS 云服务**: EKS、Lambda、API Gateway、CloudFront 等
- 🐳 **容器技术**: Docker、Kubernetes、混合节点架构
- 🤖 **AI/ML**: 大语言模型、MCP Server、Bedrock 集成
- 📊 **数据平台**: OpenSearch、Redshift、Glue、QuickSight
- 🔒 **安全合规**: IAM、IRSA、Security Lake、加密
- 🌐 **网络架构**: VPC、TGW、VPN、反向代理
- 🛠️ **DevOps**: CI/CD、监控、日志、自动化脚本

---

## 📄 许可说明

本项目文档内容由作者原创和整理，主要用于技术学习和交流。

---

## 👤 作者信息

- **GitHub**: [@panlm](https://github.com/panlm)
- **项目主页**: [https://panlm.github.io/](https://panlm.github.io/)
- **仓库地址**: [https://github.com/panlm/panlm.github.io](https://github.com/panlm/panlm.github.io)

---

## 🙏 致谢

感谢以下开源项目为本站点提供支持：

- [MkDocs](https://www.mkdocs.org/) 团队
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) 的 Martin Donath
- 所有 MkDocs 插件的贡献者
- Python 和 Markdown 社区

---

## 📞 反馈与支持

如果您在使用过程中遇到问题或有改进建议：

- 📝 [提交 Issue](https://github.com/panlm/panlm.github.io/issues)
- 💡 [发起讨论](https://github.com/panlm/panlm.github.io/discussions)
- 🔀 [提交 Pull Request](https://github.com/panlm/panlm.github.io/pulls)

---

<div align="center">

**⭐ 如果这个项目对您有帮助，请给它一个 Star！⭐**

Made with ❤️ using MkDocs Material

</div>
