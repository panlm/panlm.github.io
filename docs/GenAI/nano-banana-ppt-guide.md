---
title: nano-banana-ppt-guide
description: 使用 nano banana 生成 ppt
type: note
permalink: main/nano-banana-ppt-guide-1
---

# Nano Banana Pro PPT 生成方案

## 概述

使用 **Nano Banana Pro** (Gemini 3 Pro Image) 逐页生成高清 slide 图片，再用 **python-pptx** 组装成 PPTX 文件。

## 工具链

```
Nano Banana Pro (图片生成) + python-pptx (PPT组装) = 完整 PPTX
```

| 组件 | 用途 | 安装 |
|---|---|---|
| Nano Banana Pro | 逐页生成 slide 图片 | Google Generative Language API |
| python-pptx | 组装成 .pptx | `pip install python-pptx` |
| google-auth | SA 认证 | `pip install google-auth` |

## 前置配置

### GCP 已启用的 API
- Vertex AI API
- Cloud Billing API / Budget API
- BigQuery (用于账单监控)

### Service Account
- **角色**: Billing Account Viewer, BigQuery Admin, Vertex AI User

## 认证代码

```python
import os, base64, requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

SCOPES = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/generative-language'
]
credentials = service_account.Credentials.from_service_account_file(
    os.path.expanduser("~/.config/gcloud/sa-key.json"),
    scopes=SCOPES
)
credentials.refresh(Request())
token = credentials.token
```

## API 调用

```python
url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-pro-image-preview:generateContent"
headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}
payload = {
    "contents": [{"parts": [{"text": "你的 prompt"}]}],
    "generationConfig": {"responseModalities": ["IMAGE", "TEXT"]}
}

resp = requests.post(url, headers=headers, json=payload, timeout=120)
data = resp.json()

# 提取图片
for part in data["candidates"][0]["content"]["parts"]:
    if "inlineData" in part:
        img_data = base64.b64decode(part["inlineData"]["data"])
        with open("slide.png", "wb") as f:
            f.write(img_data)
```

## PPT 组装

```python
from pptx import Presentation
from pptx.util import Emu
from io import BytesIO

prs = Presentation()
prs.slide_width = Emu(12192000)   # 16:9 宽
prs.slide_height = Emu(6858000)   # 16:9 高

# 每页 slide 添加全屏图片
slide = prs.slides.add_slide(prs.slide_layouts[6])  # blank layout
slide.shapes.add_picture(
    BytesIO(img_data),
    Emu(0), Emu(0),
    prs.slide_width, prs.slide_height
)

prs.save("output.pptx")
```

## 完整流程

```
1. 分析内容 (repo/文档/主题) → 确定 slide 大纲 (通常 6-10 页)
2. 为每页写 prompt (风格前缀 + 具体内容)
3. 逐页调 Nano Banana Pro 生成图片 (每页间隔 2 秒避免限速)
4. python-pptx 组装成 .pptx
5. 输出文件发给用户
```

---

## 风格模板库

### 偏好设置
- **方向**: 横屏 (16:9)
- **语言**: 中文
- **用户确认满意的风格**: ①手绘插画式 ②扁平对比式 ③手绘涂鸦式

---

### 风格 1: 手绘插画式 (NotebookLM Style) ⭐ 首选

```
Style: Hand-drawn watercolor illustration style, warm color palette 
(orange, teal, brown, green accents), cream/off-white textured paper 
background, hand-drawn watercolor-style icons with soft shadows, 
professional editorial feel. All text in Chinese. Clean, professional, 
easy to read.
```

**特点**: 暖色调、水彩手绘图标、奶白纸张背景、专业温暖
**适合**: 博客配图、技术分享、正式演讲

---

### 风格 2: 扁平对比式 (Flat Comparison)

```
Style: Modern flat design, white background, split layout with clear 
left-right comparison. Left side uses red/gray tones, right side uses 
blue/green tones. Clean geometric shapes, sans-serif typography, subtle 
shadows. All text in Chinese.
```

**特点**: 红绿对比、左右分栏、信息密度高
**适合**: Before/After、方案对比、产品对比

---

### 风格 3: 手绘涂鸦式 (Doodle / Whiteboard)

```
Style: Hand-drawn doodle on white notebook/grid paper background with 
pencil sketch lines, colored marker accents (blue, orange, green, red), 
casual handwriting feel. Like someone drew it on a whiteboard with 
colored markers. Doodle stars, underlines, arrows. All text in Chinese.
```

**特点**: 白板风格、彩色马克笔、网格纸背景、轻松有趣
**适合**: 社交分享、轻松演讲、头脑风暴

---

### 风格 4: 复古纸张式 (Vintage Paper / Aged Document)

```
Style: Vintage aged paper background with slight yellowing and subtle 
stains. Woodcut/linocut style illustrations in dark brown and sepia tones. 
Serif typography with old-school typographic ornaments. Decorative borders 
and dividers. Warm muted color palette. All text in Chinese.
```

**特点**: 复古泛黄纸张、木刻插图风格、深棕色调、装饰边框
**适合**: 历史回顾、品牌故事、经典内容

---

### 风格 5: 日系清新式 (Japanese Minimal / Muji Style)

```
Style: Japanese minimalist design inspired by Muji aesthetics. Very clean 
white/light gray background. Simple thin-line geometric icons. Pastel 
accent colors (soft pink, light blue, sage green). Generous whitespace. 
Subtle grid alignment. Delicate, refined, understated. All text in Chinese.
```

**特点**: 极简、柔和马卡龙配色、大量留白、精致细腻
**适合**: 高端展示、简报、产品介绍

---

### 风格 6: 蓝图技术式 (Blueprint / Technical Drawing)

```
Style: Technical blueprint style with dark navy blue background, white and 
cyan thin lines, engineering drawing aesthetics. Grid overlay, technical 
annotations, measurement marks, cross-section style diagrams. Monospace 
font for labels. Color accents in bright cyan, yellow, and white only. 
All text in Chinese.
```

**特点**: 深蓝背景、技术蓝图风格、工程图纸感、霓虹白线
**适合**: 架构图、系统设计、技术深度内容

---

### 风格 7: 杂志封面式 (Magazine Editorial)

```
Style: High-end magazine editorial layout. Bold dramatic typography with 
large headlines. Rich photography-style backgrounds with overlay text. 
Strong contrast between sections. Professional color scheme (deep navy, 
gold accents, white text). Multi-column layout with pull quotes. 
All text in Chinese.
```

**特点**: 杂志排版、大标题、强对比、深色配金色
**适合**: 正式报告、白皮书、企业展示

---

### 风格 8: 像素复古式 (Pixel Art / Retro Game)

```
Style: Retro pixel art style with 8-bit/16-bit game aesthetics. Pixelated 
icons and characters. Dark background with bright neon pixel colors 
(green, cyan, magenta, yellow). CRT screen scanline effect. Blocky pixel 
font. Nostalgic gaming vibes. All text in Chinese.
```

**特点**: 像素风、复古游戏、霓虹色、CRT 扫描线
**适合**: 趣味分享、游戏相关、吸引注意

---

## 注意事项

1. **中文渲染**: Nano Banana Pro 对中文支持良好，标题和短文本无问题
2. **每页间隔**: 建议每页生成之间 sleep 2 秒，避免 API 限速
3. **图片格式**: API 返回 PNG，每张约 600KB-900KB
4. **PPTX 大小**: 6 页约 5MB
5. **不可编辑**: 每页是整张图片，文字不可单独编辑，需修改时重新生成该页
6. **费用**: Nano Banana Pro 约 $0.09-0.24/张（取决于分辨率）

---

## Amazon Nova Canvas 备选方案

AWS Bedrock 上的图片生成模型，不需要 Google API。

### 模型信息
- **模型 ID**: `amazon.nova-canvas-v1:0`
- **区域**: us-east-1
- **单价**: ~$0.06-0.08/张
- **最大分辨率**: 2048×2048 (4.19M 像素)
- **中文支持**: ❗ 字体效果差，只适合英文

### Prompt 写法差异（重要！）

Nova Canvas 是 diffusion 模型，prompt 写法和 Nano Banana Pro（多模态 LLM）完全不同：

| | Nano Banana Pro | Nova Canvas |
|---|---|---|
| 写法 | 指令式："Generate a slide..." | **描述式**："A dark green chalkboard with..." |
| 中文 | 可以直接写中文指令 | 只能用英文描述 |
| 复杂布局 | 能理解复杂指令 | 需简化，描述位置 |
| 反向提示 | 无 | ✅ 支持 negativeText |
| CFG Scale | 无 | ✅ 支持（推荐 8）|

### 调用代码

```python
import boto3, json, base64

client = boto3.client("bedrock-runtime", region_name="us-east-1")

body = json.dumps({
    "taskType": "TEXT_IMAGE",
    "textToImageParams": {
        "text": "图片描述式 prompt",
        "negativeText": "blurry, distorted, low quality, cluttered, messy text"
    },
    "imageGenerationConfig": {
        "width": 1280,
        "height": 720,
        "numberOfImages": 1,
        "quality": "premium",
        "cfgScale": 8
    }
})

response = client.invoke_model(
    modelId="amazon.nova-canvas-v1:0",
    contentType="application/json",
    accept="application/json",
    body=body
)

result = json.loads(response["body"].read())
img_data = base64.b64decode(result["images"][0])
```

### Nova Canvas Prompt 最佳实践

1. **写成图片描述**，不是指令（“A photo of...” 不是 “Generate...”）
2. **用 negativeText** 排除不想要的元素
3. **CFG=8** 严格遵循 prompt
4. **简化内容**，每页不要塞太多文字
5. **不要用否定词**（"no", "not", "without"），放到 negativeText 里

---

## 参考资源

### Prompt 库 & 示例

| 项目 | 说明 | 链接 |
|---|---|---|
| **awesome-nano-banana-pro-prompts** | 10000+ 精选 prompt，含 infographic 分类，16 种语言 | https://github.com/YouMind-OpenLab/awesome-nano-banana-pro-prompts |
| **Google 官方 Nano Banana Pro notebook** | 官方示例，含 infographic 生成 | https://github.com/GoogleCloudPlatform/generative-ai/blob/main/gemini/getting-started/intro_gemini_3_image_gen.ipynb |
| **Google 官方 Nano Banana 2 notebook** | Flash Image 示例 | https://github.com/GoogleCloudPlatform/generative-ai/blob/main/gemini/getting-started/intro_gemini_3_1_flash_image_gen.ipynb |
| **AWS Nova Canvas 官方文档** | API 格式、prompt 最佳实践 | https://docs.aws.amazon.com/nova/latest/userguide/image-gen-access.html |
| **AWS Nova Canvas 博客** | 教程 + prompt 技巧 + CFG/seed 说明 | https://aws.amazon.com/blogs/machine-learning/text-to-image-basics-with-amazon-nova-canvas |

### PPT 生成工具

| 项目 | 说明 | 链接 |
|---|---|---|
| **Presenton** | 开源 AI PPT 生成器，支持 Gemini/OpenAI，Docker 部署（较重） | https://github.com/presenton/presenton |
| **Paper2Slides** | 论文→PPT 一键转换 | https://github.com/HKUDS/Paper2Slides |
| **Scientific-Slides Skill** | Agent Skill，用 Nano Banana Pro 生成单页 slide 图片 | https://smithery.ai/skills/davila7/scientific-slides |
| **nano-banana-mcp** | MCP Server，可接入 AI Agent | https://github.com/bcharleson/nano-banana-mcp |
| **ai-agents-skills/nano-banana-pro** | Agent Skill，含 infographic 生成 | https://github.com/hoodini/ai-agents-skills/blob/master/skills/nano-banana-pro/SKILL.md |

### 其他参考

| 项目 | 说明 | 链接 |
|---|---|---|
| **awesome-nano-banana** | Nano Banana 生成图片集锦 + prompt | https://github.com/jimmylv/awesome-nano-banana |
| **Nano Banana Pro API 教程** | 完整开发者指南 | https://github.com/TaiChiFlow/nano-banana-pro-api |
| **notex** | 开源 NotebookLM 替代，内置 infographic 生成 | https://github.com/smallnest/notex |
