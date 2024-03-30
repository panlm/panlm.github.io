---
title: sts
description: 常用命令
created: 2023-09-10 22:52:34.617
last_modified: 2024-03-14
icon: simple/amazonaws
tags:
  - aws/cmd
---
> [!WARNING] This is a github note
# sts-cmd
## get session token

```
export CRED=$(aws sts get-session-token --duration-seconds 86400)
export AWS_ACCESS_KEY_ID=$(echo "${CRED}" | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo "${CRED}" | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo "${CRED}" | jq -r '.Credentials.SessionToken')

```

## environment in powershell
```powershell
$Env:AWS_ACCESS_KEY_ID=""
$Env:AWS_SECRET_ACCESS_KEY=""
$Env:AWS_SESSION_TOKEN=""

```


