---
title: Obsidian Tips
description: obsidian 使用点滴
last_modified: 2024-01-01
status: myblog
tags:
  - obsidian
---

# Obsidian Tips
文本笔记 第二大脑
https://obsidian.md/

## useful plugins
### Obsidian Attachment Management
https://github.com/trganda/obsidian-attachment-management

推荐配置
- attachment 和文档在同一父路径下，但是独立目录
- 文档图片以文件名命名
- 不要包含非图片扩展名，非图片扩展名的文件将保存在系统 attachment 目录下
- exclude 特定目录，比如 template
![[attachments/obsidian/IMG-obsidian.png|600]]

### Colorful Note Borders
https://github.com/rusi/obsidian-colorful-note-borders
增加笔记边框方便区别敏感笔记和其他笔记，当你经常讲笔记 publish 到 github 上时，可以作为自己的提醒

推荐配置
- git 路径下笔记添加红色框，提醒这个笔记将添加到 github 上
- gitlab 路径下笔记添加绿色框，提醒这个笔记将添加到公司内网 gitlab 上
![[attachments/obsidian/IMG-obsidian-1.png|600]]

### File path to URI
https://github.com/MichalBures/obsidian-file-path-to-uri

hold `ctl` click filename, choose `copy`, paste in obsidian
直接将文件以附件形式插入 obsidian，由于附件名不是图片，因此会保留在系统的 attachment 目录下

right click file, then hold `option`, click `copy xxx as Pathname` ([link](https://technastic.com/copy-file-path-mac/)), and using this plugin `File path to URI`, 
直接将文件以链接形式插入 obsidian，直接可以点击后，用第三方打开

### Tasks Plugin
- https://github.com/obsidian-tasks-group/obsidian-tasks/discussions/442#discussioncomment-4215151

### Text Format
https://github.com/Benature/obsidian-text-format

快速切换文本格式，尤其是可以切换 `title with space` 到 `title-with-space` (slugify 格式)，方便跨文档引用，以及生成更友好的 github URL

### Text expander
https://github.com/mrjackphil/obsidian-text-expand

跨文档应用，主要用于：
- 在单个项目文档中记录 weekly report
- 在周报文档中通过正则表达式搜索并提取本周更新到当前位置

### Highlightr Plugin
https://github.com/chetachiezikeuzor/Highlightr-Plugin

通过不同颜色高亮文本


### share notes
https://docs.note.sx/running-your-own-server

#### php
https://github.com/note-sx/server
- request apikey first, and put apikey to data.json
```
curl -L 'https://xxxxxx.aws.panlm.click/v1/account/get-key?id=12341234'
```
- shared notes will be in `db` folder, this folder will be keep in folder which run `docker-compose up -d` from

#### python
https://github.com/tannercollin/sharenote-py

- sample settings
```
{
  "server": "https://xxxxx.aws.panlm.click",
  "uid": "13241234",
  "apiKey": "ba29b4e8fc",
  "yamlField": "share",
  "noteWidth": "100",
  "theme": "Minimal",
  "themeMode": 0,
  "titleSource": 0,
  "removeYaml": true,
  "removeBacklinksFooter": true,
  "expiry": "2 days",
  "clipboard": true,
  "shareUnencrypted": true,
  "authRedirect": "share",
  "debug": 0
}

```
- shared notes will be in `static` folder
- seems not stable when upload same note twice 


### others 
- [Quiet Outline](https://github.com/guopenghui/obsidian-quiet-outline)
- [dataview doc](https://blacksmithgu.github.io/obsidian-dataview/)
- [Better PDF Plugin](https://github.com/MSzturc/obsidian-better-pdf-plugin/)
- [admonition](https://github.com/valentine195/obsidian-admonition)
- [[export-util-obsidianhtml]]


## Tips
### files and links
![[attachments/obsidian/IMG-obsidian-2.png|600]]


## input emoji
- press Control + Command + SPACE





