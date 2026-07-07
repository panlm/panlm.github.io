---
title: aws-transform-cmd
description: 常用命令
created: 2025-12-04 11:55:07.225000
last_modified: 2025-12-04
tags:
- draft
- aws/cmd
permalink: git-mkdocs/cli/awscli/aws-transform-cmd
type: note
---

# aws-transform

## install

need [[../linux/nodejs-cmd|node env]]

```sh
curl -fsSL https://desktop-release.transform.us-east-1.api.aws/install.sh | bash

```

## transform custom

```bash
atx custom def list

cd your-code-repo
atx custom def exec -n AWS/early-access-comprehensive-codebase-analysis -t -p .

# 提示任何额外信息时，请它用中文输出文档
# 然后确认它的提示，继续进行

```

## transform-config.yaml

```
# transform-config.yaml
codeRepositoryPath: ~/git/sample-connector-for-bedrock
transformationName: AWS/comprehensive-codebase-analysis
buildCommand: noop
additionalPlanContext: |
  Focus analysis on the following areas:
  - Document the overall architecture and code structure
  - Identify deprecated or outdated coding patterns
  - Highlight areas that may benefit from modernization
  - Analyze dependencies and their relationships
```

```

执行：
atx custom def exec -g file://transform-config.yaml -x -t
```