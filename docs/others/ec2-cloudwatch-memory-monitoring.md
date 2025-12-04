---
title: Use CloudWatch Agent to Collector EC2 Memory Metrics
description: 使用 AWS CloudWatch Agent 监控 EC2 实例内存
created: 2025-10-31 16:34:59.481
last_modified: 2025-10-31
tags:
  - draft
  - aws/mgmt/cloudwatch
---

# 使用 AWS CloudWatch Agent 监控 EC2 实例内存

本文提供了在 EC2 实例上设置 CloudWatch Agent 以监控内存指标的分步指南。

## 前提条件

- 一个运行中的 EC2 实例
- 能够登录到该实例的权限（SSH 或控制台）
- AWS IAM 权限，允许实例发送指标到 CloudWatch

## 设置 CloudWatch Agent

登录到 EC2 实例后，执行以下操作：

### 1. 安装 CloudWatch Agent

```bash
# 安装 CloudWatch Agent
sudo apt update
sudo apt install -y amazon-cloudwatch-agent
```

对于 Amazon Linux 2:

```bash
sudo yum install -y amazon-cloudwatch-agent
```

### 2. 创建 CloudWatch Agent 配置文件

```bash
# 创建配置文件
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json > /dev/null << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "metrics": {
    "aggregation_dimensions" : [["InstanceId"]],
    "metrics_collected": {
      "mem": {
        "measurement": [
          "mem_used_percent",
          "mem_total",
          "mem_used",
          "mem_available",
          "mem_cached"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent",
          "swap_used",
          "swap_free"
        ],
        "metrics_collection_interval": 60
      }
    },
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"
    }
  }
}
EOF
```

### 3. 启动 CloudWatch Agent

```bash
# 应用配置并启动 CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
```

### 4. 验证 CloudWatch Agent 状态

```bash
# 检查 CloudWatch Agent 状态
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a status
```

## 关键配置元素

### CloudWatch Agent 配置文件详解

这个配置文件设置了 CloudWatch Agent 来收集以下内容：

1. **使用实例 ID 作为指标标识符**：
   - `aggregation_dimensions` 部分设置为 `[["InstanceId"]]`，确保指标按 EC2 实例 ID 聚合，而不是主机名。
   - `append_dimensions` 部分中的 `"InstanceId": "${aws:InstanceId}"` 将实例 ID 作为维度附加到所有指标。

2. **内存指标**：
   - `mem_used_percent`：内存使用百分比
   - `mem_total`：可用总内存
   - `mem_used`：已使用内存
   - `mem_available`：可用内存
   - `mem_cached`：缓存的内存

3. **交换空间指标**：
   - `swap_used_percent`：交换空间使用百分比
   - `swap_used`：已使用的交换空间
   - `swap_free`：可用的交换空间

4. **收集间隔**：
   - 所有指标每 60 秒（1 分钟）收集一次

## 故障排除

### 重启 CloudWatch Agent

如果您更改了配置或者代理无法正常工作：

```bash
# 停止 CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop

# 启动 CloudWatch Agent
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start
```

### 查看代理日志

```bash
# 查看 CloudWatch Agent 日志
sudo tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

### 检查 IAM 角色

确保您的实例有附加一个 IAM 角色，该角色包含 `CloudWatchAgentServerPolicy`。

## 在 CloudWatch 控制台中查看指标

1. 打开 [CloudWatch 控制台](https://console.aws.amazon.com/cloudwatch/)
2. 导航至 Metrics > All metrics（指标 > 所有指标）
3. 选择 "CWAgent" 命名空间
4. 查找维度为 "InstanceId" = 您的实例 ID 的指标
5. 您现在可以创建图表和仪表板来监控您的内存使用情况

## 设置内存告警

您可以设置告警来监控高内存使用率：

1. 在 CloudWatch 控制台中，找到 `mem_used_percent` 指标
2. 点击 "Create alarm"（创建告警）
3. 设置阈值，例如当内存使用率 > 85% 时
4. 配置告警操作（例如发送到 SNS 主题）
5. 保存告警

## 清理

如果您想卸载 CloudWatch Agent：

```bash
# 卸载 CloudWatch Agent
sudo apt remove -y amazon-cloudwatch-agent    # Ubuntu
# 或
sudo yum remove -y amazon-cloudwatch-agent    # Amazon Linux
```