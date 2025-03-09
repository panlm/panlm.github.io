---
title: dify.ai
description: sample for dify
created: 2024-05-17 09:31:12.388
last_modified: 2024-07-28
tags:
  - llm
---

# dify.ai
## self-hosting 
- https://gaihub.awspsa.com/opensource/difyai/
- https://aws.amazon.com/cn/blogs/china/get-started-with-generative-ai-by-integrating-bedrock-claude3-with-dify/
```sh
sudo yum install docker
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

```

## sample workflow
chatbot 输入问题，直接 request 到 google CSE，返回一堆 json，用 llm 提示词进行处理，返回title 和link，然后用大语言模型返回

![[attachments/dify-sample/IMG-dify-sample.png]]

## workshop
- [Rapidly Build GenAI Apps with Dify](https://catalog.us-east-1.prod.workshops.aws/workshops/2c19fcb1-1f1c-4f52-b759-0ca4d2ae2522/zh-CN)

## dify on eks
- https://github.com/BorisPolonsky/dify-helm

