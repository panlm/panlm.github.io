---
title: ecr-scan-on-push-notification-sns
description: ecr-scan-on-push-notification-sns
created: 2023-12-07 16:22:54.252
last_modified: 2023-12-07
tags:
  - aws/container/ecr
  - aws/integration/sns
---
> [!WARNING] This is a github note
# ecr-scan-on-push-notification-sns

## 需求
启用 ECR 的 Scan on push 之后，自动将扫描结果中 CRITICAL 的信息发送到目标 SNS 告警。

## 解决方案
使用已有的 [blog](https://aws.amazon.com/blogs/containers/logging-image-scan-findings-from-amazon-ecr-in-cloudwatch-using-an-aws-lambda-function/) 描述场景可以自动将扫描后的信息分类保存到 cloudwatch 中，可以在中国区使用 cloudformation 部署成功。如下架构图：

![[git/git-mkdocs/git-attachment/ecr-scan-on-push-notification-sns-png-1.png]]

下载 cloudformation 模板：[[../git-attachment/ecr-scan-on-push-notification-sns-template-ecr.yml|template-ecr.yml]]

我们在上述架构基础上做了额外手工修改：
- 创建特定的 SNS topic，注册邮箱并接收告警
- 给 Lambda 的执行 role 添加 SNS topic 的权限
- 更新了 lambda 函数直接将 CRITICAL 的消息同时发送到 SNS 告警
    - 下载参考 [[../git-attachment/ecr-scan-on-push-notification-sns-new-lambda.py|new-lambda.py]]

## 参考
- https://aws.amazon.com/blogs/containers/logging-image-scan-findings-from-amazon-ecr-in-cloudwatch-using-an-aws-lambda-function/
- https://aws.amazon.com/blogs/mt/get-notified-specific-lambda-function-error-patterns-using-cloudwatch/

