---
title: MCP Server on ECS
description: 将 MCP Server 移动到远端，减少本地资源占用
created: 2025-05-29 13:10:24.336000
last_modified: 2026-04-30
tags:
- draft
- llm/mcp
permalink: git-mkdocs/gen-ai/deploy-mcp-server-to-ecs
---

# 将 MCP 服务部署到 AWS ECS 的方案

## 部署三个服务 (fetch-mcp, aws-doc-mcp, searxng-mcp)

### 1. 创建 ECR 仓库并推送镜像

```bash
# 设置变量
export AWS_PAGER=""
PROFILE="your-profile"
REGION="us-east-2"
ACCOUNT_ID=$(aws --profile $PROFILE sts get-caller-identity --query Account --output text)
ECR_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

# 创建 ECR 仓库
aws --profile $PROFILE --region $REGION ecr create-repository --repository-name mcp-proxy-uv
aws --profile $PROFILE --region $REGION ecr create-repository --repository-name mcp-proxy-npx

# 登录 ECR
aws --profile $PROFILE --region $REGION ecr get-login-password | docker login --username AWS --password-stdin $ECR_REPO

# 构建镜像
docker build -t mcp-proxy-uv -f mcp-proxy-uv.Dockerfile .
docker build -t mcp-proxy-npx -f mcp-proxy-npx.Dockerfile .

# 标记镜像
docker tag mcp-proxy-uv:latest $ECR_REPO/mcp-proxy-uv:latest
docker tag mcp-proxy-npx:latest $ECR_REPO/mcp-proxy-npx:latest

# 推送镜像
docker push $ECR_REPO/mcp-proxy-uv:latest
docker push $ECR_REPO/mcp-proxy-npx:latest
```

### 2. 创建 ECS 集群

```bash
# 设置变量
CLUSTER_NAME="mcp-services"

# 创建集群
aws --profile $PROFILE --region $REGION ecs create-cluster \
  --cluster-name $CLUSTER_NAME \
  --capacity-providers FARGATE FARGATE_SPOT \
  --default-capacity-provider-strategy capacityProvider=FARGATE_SPOT,weight=1
```

### 3. 网络配置

```bash
# 获取默认 VPC 信息
VPC_ID=$(aws --profile $PROFILE --region $REGION ec2 describe-vpcs \
  --filters "Name=isDefault,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text)
echo "VPC ID: $VPC_ID"

# 获取子网信息
SUBNETS=$(aws --profile $PROFILE --region $REGION ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[?AvailabilityZone==`'"$REGION"'a` || AvailabilityZone==`'"$REGION"'b`].SubnetId' \
  --output text)
SUBNET1=$(echo $SUBNETS | cut -d' ' -f1)
SUBNET2=$(echo $SUBNETS | cut -d' ' -f2)
echo "子网 ID: $SUBNET1, $SUBNET2"

# 创建安全组
SG_ID=$(aws --profile $PROFILE --region $REGION ec2 create-security-group \
  --group-name mcp-services-sg \
  --description "Security group for MCP services" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)
echo "安全组 ID: $SG_ID"

# 添加安全组规则 - 开放 80 端口（ALB path-based 路由）和 8808-8810（直接端口访问）
aws --profile $PROFILE --region $REGION ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

aws --profile $PROFILE --region $REGION ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8808-8810 \
  --cidr 0.0.0.0/0
```

### 4. 创建负载均衡器和目标组

```bash
# 创建 ALB
ALB_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-load-balancer \
  --name mcp-services-alb \
  --subnets $SUBNET1 $SUBNET2 \
  --security-groups $SG_ID \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)
echo "ALB ARN: $ALB_ARN"

# 获取 ALB DNS 名称（后续访问使用）
ALB_DNS=$(aws --profile $PROFILE --region $REGION elbv2 describe-load-balancers \
  --load-balancer-arns $ALB_ARN \
  --query 'LoadBalancers[0].DNSName' \
  --output text)
echo "ALB DNS: $ALB_DNS"

# 创建目标组
FETCH_TG_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-target-group \
  --name fetch-mcp-tg \
  --protocol HTTP \
  --port 8808 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path '/messages' \
  --matcher HttpCode=200-399 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)
echo "Fetch MCP Target Group ARN: $FETCH_TG_ARN"

AWS_DOC_TG_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-target-group \
  --name aws-doc-mcp-tg \
  --protocol HTTP \
  --port 8809 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path '/messages' \
  --matcher HttpCode=200-399 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)
echo "AWS Doc MCP Target Group ARN: $AWS_DOC_TG_ARN"

SEARXNG_TG_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-target-group \
  --name searxng-mcp-tg \
  --protocol HTTP \
  --port 8810 \
  --vpc-id $VPC_ID \
  --target-type ip \
  --health-check-path '/messages' \
  --matcher HttpCode=200-399 \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text)
echo "SearXNG MCP Target Group ARN: $SEARXNG_TG_ARN"

# 创建 Port 80 监听器 - 使用 path-based 路由（推荐，无需自定义域名）
# 默认路由到 fetch-mcp
LISTENER_80_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=$FETCH_TG_ARN \
  --query 'Listeners[0].ListenerArn' \
  --output text)
echo "Port 80 Listener ARN: $LISTENER_80_ARN"

# 添加 path-based 路由规则
# /aws-doc/* 路由到 aws-doc-mcp
aws --profile $PROFILE --region $REGION elbv2 create-rule \
  --listener-arn $LISTENER_80_ARN \
  --priority 10 \
  --conditions Field=path-pattern,Values="/aws-doc/*" \
  --actions Type=forward,TargetGroupArn=$AWS_DOC_TG_ARN

# /searxng/* 路由到 searxng-mcp
aws --profile $PROFILE --region $REGION elbv2 create-rule \
  --listener-arn $LISTENER_80_ARN \
  --priority 20 \
  --conditions Field=path-pattern,Values="/searxng/*" \
  --actions Type=forward,TargetGroupArn=$SEARXNG_TG_ARN
```

> **可选方案：host-header 路由**
>
> 如果你有自定义域名，也可以使用 host-header 路由。为每个服务创建独立端口监听器（8808/8809/8810），然后基于域名转发：
> ```bash
> DOMAIN="ecs.aws.yourdomain.com"
> # 创建 8808 监听器，默认返回 403
> aws --profile $PROFILE --region $REGION elbv2 create-listener \
>   --load-balancer-arn $ALB_ARN \
>   --protocol HTTP --port 8808 \
>   --default-actions Type=fixed-response,FixedResponseConfig="{StatusCode=403,ContentType=\"text/plain\",MessageBody=\"Hostname not allowed\"}"
> # 添加 host-header 规则
> aws --profile $PROFILE --region $REGION elbv2 create-rule \
>   --listener-arn $FETCH_LISTENER_ARN --priority 10 \
>   --conditions Field=host-header,Values="fetch.$DOMAIN" \
>   --actions Type=forward,TargetGroupArn=$FETCH_TG_ARN
> ```

### 5. 创建 ECS 服务

首先创建任务定义文件：

fetch-mcp-task.json:
```sh
echo $ECR_REPO $REGION
envsubst > /tmp/fetch-mcp-task.json <<-EOF
{
  "family": "fetch-mcp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "fetch-mcp",
      "image": "${ECR_REPO}/mcp-proxy-uv:latest",
      "portMappings": [
        {
          "containerPort": 8808,
          "protocol": "tcp"
        }
      ],
      "command": ["--pass-environment", "--port=8808", "--sse-host", "0.0.0.0", "uvx", "mcp-server-fetch"],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/mcp-services",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "fetch-mcp"
        }
      }
    }
  ]
}
EOF
```

aws-doc-mcp-task.json:
```sh
echo $ECR_REPO $REGION
envsubst > /tmp/aws-doc-mcp-task.json <<-EOF
{
  "family": "aws-doc-mcp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "aws-doc-mcp",
      "image": "${ECR_REPO}/mcp-proxy-uv:latest",
      "portMappings": [
        {
          "containerPort": 8809,
          "protocol": "tcp"
        }
      ],
      "command": ["--pass-environment", "--port=8809", "--sse-host", "0.0.0.0", "--env", "FASTMCP_LOG_LEVEL", "ERROR", "uvx", "awslabs.aws-documentation-mcp-server@latest"],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/mcp-services",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "aws-doc-mcp"
        }
      }
    }
  ]
}
EOF
```

searxng-mcp-task.json:
```sh
echo $ECR_REPO $REGION
echo ${YOUR_SEARXNG_URL:=https://searx.yourdomain.com}

envsubst > /tmp/searxng-mcp-task.json <<-EOF
{
  "family": "searxng-mcp",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "searxng-mcp",
      "image": "${ECR_REPO}/mcp-proxy-npx:latest",
      "portMappings": [
        {
          "containerPort": 8810,
          "protocol": "tcp"
        }
      ],
      "command": ["--pass-environment", "--port=8810", "--sse-host", "0.0.0.0", "--env", "SEARXNG_URL", "${YOUR_SEARXNG_URL}", "--", "npx", "-y", "mcp-searxng"],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/mcp-services",
          "awslogs-region": "${REGION}",
          "awslogs-stream-prefix": "searxng-mcp"
        }
      }
    }
  ]
}
EOF
```

注册任务定义并创建服务：

```bash
echo $CLUSTER_NAME

# 使用已有的 ecsTaskExecutionRole，如果不存在则创建
EXECUTION_ROLE_ARN=$(aws --profile $PROFILE --region $REGION iam get-role \
  --role-name ecsTaskExecutionRole \
  --query 'Role.Arn' \
  --output text 2>/dev/null)

if [ -z "$EXECUTION_ROLE_ARN" ]; then
  # 创建 ECS 任务执行角色
  cat > /tmp/task-execution-role-trust.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  EXECUTION_ROLE_ARN=$(aws --profile $PROFILE --region $REGION iam create-role \
    --role-name ecsTaskExecutionRole \
    --assume-role-policy-document file:///tmp/task-execution-role-trust.json \
    --query 'Role.Arn' \
    --output text)

  aws --profile $PROFILE --region $REGION iam attach-role-policy \
    --role-name ecsTaskExecutionRole \
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
fi
echo "Task Execution Role ARN: $EXECUTION_ROLE_ARN"

# 创建日志组
aws --profile $PROFILE --region $REGION logs create-log-group --log-group-name /ecs/mcp-services 2>/dev/null || true

# 注册任务定义
aws --profile $PROFILE --region $REGION ecs register-task-definition \
  --cli-input-json file:///tmp/fetch-mcp-task.json \
  --execution-role-arn $EXECUTION_ROLE_ARN

aws --profile $PROFILE --region $REGION ecs register-task-definition \
  --cli-input-json file:///tmp/aws-doc-mcp-task.json \
  --execution-role-arn $EXECUTION_ROLE_ARN

aws --profile $PROFILE --region $REGION ecs register-task-definition \
  --cli-input-json file:///tmp/searxng-mcp-task.json \
  --execution-role-arn $EXECUTION_ROLE_ARN

# 创建服务
aws --profile $PROFILE --region $REGION ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name fetch-mcp \
  --task-definition fetch-mcp \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$FETCH_TG_ARN,containerName=fetch-mcp,containerPort=8808"

aws --profile $PROFILE --region $REGION ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name aws-doc-mcp \
  --task-definition aws-doc-mcp \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$AWS_DOC_TG_ARN,containerName=aws-doc-mcp,containerPort=8809"

aws --profile $PROFILE --region $REGION ecs create-service \
  --cluster $CLUSTER_NAME \
  --service-name searxng-mcp \
  --task-definition searxng-mcp \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNET1,$SUBNET2],securityGroups=[$SG_ID],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$SEARXNG_TG_ARN,containerName=searxng-mcp,containerPort=8810"
```

### 6. 验证部署

```bash
# 检查服务状态
aws --profile $PROFILE --region $REGION ecs describe-services \
  --cluster $CLUSTER_NAME \
  --services fetch-mcp aws-doc-mcp searxng-mcp \
  --query 'services[*].[serviceName,runningCount,desiredCount]' \
  --output table

# 获取 ALB DNS
echo "ALB DNS: $ALB_DNS"
```

服务访问地址（通过 ALB port 80 path-based 路由）：

- fetch-mcp: `http://<ALB_DNS>/sse`
- aws-doc-mcp: `http://<ALB_DNS>/aws-doc/sse`
- searxng-mcp: `http://<ALB_DNS>/searxng/sse`

### 7. 清理资源

```bash
# 停止服务（将 desired-count 设为 0）
aws --profile $PROFILE --region $REGION ecs update-service --cluster $CLUSTER_NAME --service fetch-mcp --desired-count 0
aws --profile $PROFILE --region $REGION ecs update-service --cluster $CLUSTER_NAME --service aws-doc-mcp --desired-count 0
aws --profile $PROFILE --region $REGION ecs update-service --cluster $CLUSTER_NAME --service searxng-mcp --desired-count 0

# 删除服务
aws --profile $PROFILE --region $REGION ecs delete-service --cluster $CLUSTER_NAME --service fetch-mcp
aws --profile $PROFILE --region $REGION ecs delete-service --cluster $CLUSTER_NAME --service aws-doc-mcp
aws --profile $PROFILE --region $REGION ecs delete-service --cluster $CLUSTER_NAME --service searxng-mcp

# 删除集群
aws --profile $PROFILE --region $REGION ecs delete-cluster --cluster $CLUSTER_NAME

# 删除 ALB 和目标组
aws --profile $PROFILE --region $REGION elbv2 delete-load-balancer --load-balancer-arn $ALB_ARN
aws --profile $PROFILE --region $REGION elbv2 delete-target-group --target-group-arn $FETCH_TG_ARN
aws --profile $PROFILE --region $REGION elbv2 delete-target-group --target-group-arn $AWS_DOC_TG_ARN
aws --profile $PROFILE --region $REGION elbv2 delete-target-group --target-group-arn $SEARXNG_TG_ARN

# 删除安全组
aws --profile $PROFILE --region $REGION ec2 delete-security-group --group-id $SG_ID

# 删除日志组
aws --profile $PROFILE --region $REGION logs delete-log-group --log-group-name /ecs/mcp-services
```

## Reference

- [Deploying Model Context Protocol Servers on AWS](https://aws.amazon.com/solutions/guidance/deploying-model-context-protocol-servers-on-aws/)
- [[../../../basic-memory/aws-api-mcp-server 源码深度剖析|aws-api-mcp-server 源码深度剖析]]


