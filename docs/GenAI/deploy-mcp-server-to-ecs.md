---
title: MCP Server on ECS
description: 将 MCP Server 移动到远端，减少本地资源占用
created: 2025-05-29 13:10:24.336
last_modified: 2025-05-29
tags:
  - draft
  - llm/mcp
---

# 将 MCP 服务部署到 AWS ECS 的方案

## 部署三个服务 (fetch-mcp, aws-doc-mcp, searxng-mcp)

### 1. 创建 ECR 仓库并推送镜像

```bash
# 设置变量
export AWS_PAGER=""
PROFILE="0527"
REGION="us-east-1"
ACCOUNT_ID="327xxx"
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

# 添加安全组规则
aws --profile $PROFILE --region $REGION ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 8808-8810 \
  --cidr 0.0.0.0/0
```

### 4. 创建负载均衡器和目标组

```bash
# 设置变量
DOMAIN="ecs.aws.xxx" # change to your domain name 

# 创建 ALB (如果已存在则跳过此步骤)
ALB_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-load-balancer \
  --name mcp-services-alb \
  --subnets $SUBNET1 $SUBNET2 \
  --security-groups $SG_ID \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text)
echo "ALB ARN: $ALB_ARN"

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

# 创建监听器 - 为每个服务创建单独的监听器，默认返回403
# 为 fetch-mcp 创建监听器 (8808端口)
FETCH_LISTENER_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 8808 \
  --default-actions Type=fixed-response,FixedResponseConfig="{StatusCode=403,ContentType=\"text/plain\",MessageBody=\"Hostname not allowed\"}" \
  --query 'Listeners[0].ListenerArn' \
  --output text)
echo "Fetch MCP Listener ARN: $FETCH_LISTENER_ARN"

# 为 aws-doc-mcp 创建监听器 (8809端口)
AWS_DOC_LISTENER_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 8809 \
  --default-actions Type=fixed-response,FixedResponseConfig="{StatusCode=403,ContentType=\"text/plain\",MessageBody=\"Hostname not allowed\"}" \
  --query 'Listeners[0].ListenerArn' \
  --output text)
echo "AWS Doc MCP Listener ARN: $AWS_DOC_LISTENER_ARN"

# 为 searxng-mcp 创建监听器 (8810端口)
SEARXNG_LISTENER_ARN=$(aws --profile $PROFILE --region $REGION elbv2 create-listener \
  --load-balancer-arn $ALB_ARN \
  --protocol HTTP \
  --port 8810 \
  --default-actions Type=fixed-response,FixedResponseConfig="{StatusCode=403,ContentType=\"text/plain\",MessageBody=\"Hostname not allowed\"}" \
  --query 'Listeners[0].ListenerArn' \
  --output text)
echo "SearXNG MCP Listener ARN: $SEARXNG_LISTENER_ARN"

# 为每个监听器添加基于主机名的规则
# 为 fetch-mcp 监听器添加主机名规则
aws --profile $PROFILE --region $REGION elbv2 create-rule \
  --listener-arn $FETCH_LISTENER_ARN \
  --priority 10 \
  --conditions Field=host-header,Values="fetch.$DOMAIN" \
  --actions Type=forward,TargetGroupArn=$FETCH_TG_ARN

# 为 aws-doc-mcp 监听器添加主机名规则
aws --profile $PROFILE --region $REGION elbv2 create-rule \
  --listener-arn $AWS_DOC_LISTENER_ARN \
  --priority 10 \
  --conditions Field=host-header,Values="aws-doc.$DOMAIN" \
  --actions Type=forward,TargetGroupArn=$AWS_DOC_TG_ARN

# 为 searxng-mcp 监听器添加主机名规则
aws --profile $PROFILE --region $REGION elbv2 create-rule \
  --listener-arn $SEARXNG_LISTENER_ARN \
  --priority 10 \
  --conditions Field=host-header,Values="searxng.$DOMAIN" \
  --actions Type=forward,TargetGroupArn=$SEARXNG_TG_ARN
```

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
echo ${YOUR_SEARXNG_URL:=https://searx.xxx}

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

注册任务定义：

```bash
# 设置变量
echo $CLUSTER_NAME

# 创建 IAM 角色
# 创建 ECS 任务执行角色 (ecsTaskExecutionRole)
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

EXECUTION_ROLE_NAME="ecsTaskExecutionRole-mcp"
EXECUTION_ROLE_ARN=$(aws --profile $PROFILE --region $REGION iam create-role \
  --role-name $EXECUTION_ROLE_NAME \
  --assume-role-policy-document file:///tmp/task-execution-role-trust.json \
  --query 'Role.Arn' \
  --output text)
echo "Task Execution Role ARN: $EXECUTION_ROLE_ARN"

# 附加 ECS 任务执行角色策略
aws --profile $PROFILE --region $REGION iam attach-role-policy \
  --role-name $EXECUTION_ROLE_NAME \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy

# 创建 ECS 任务角色 (ecsTaskRole)
cat > /tmp/task-role-trust.json << EOF
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

TASK_ROLE_NAME="ecsTaskRole-mcp"
TASK_ROLE_ARN=$(aws --profile $PROFILE --region $REGION iam create-role \
  --role-name $TASK_ROLE_NAME \
  --assume-role-policy-document file:///tmp/task-role-trust.json \
  --query 'Role.Arn' \
  --output text)
echo "Task Role ARN: $TASK_ROLE_ARN"

# 创建日志组
aws --profile $PROFILE --region $REGION logs create-log-group --log-group-name /ecs/mcp-services

# 注册任务定义（在命令中指定角色）
aws --profile $PROFILE --region $REGION ecs register-task-definition \
  --cli-input-json file:///tmp/fetch-mcp-task.json \
  --execution-role-arn $EXECUTION_ROLE_ARN \
  --task-role-arn $TASK_ROLE_ARN

aws --profile $PROFILE --region $REGION ecs register-task-definition \
  --cli-input-json file:///tmp/aws-doc-mcp-task.json \
  --execution-role-arn $EXECUTION_ROLE_ARN \
  --task-role-arn $TASK_ROLE_ARN

aws --profile $PROFILE --region $REGION ecs register-task-definition \
  --cli-input-json file:///tmp/searxng-mcp-task.json \
  --execution-role-arn $EXECUTION_ROLE_ARN \
  --task-role-arn $TASK_ROLE_ARN

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

服务访问地址：
- fetch-mcp: http://fetch.ecs.yourdomain:8808/
- aws-doc-mcp: http://aws-doc.ecs.yourdomain:8809/
- searxng-mcp: http://searxng.ecs.yourdomain:8810/


## Reference
https://aws.amazon.com/solutions/guidance/deploying-model-context-protocol-servers-on-aws/



