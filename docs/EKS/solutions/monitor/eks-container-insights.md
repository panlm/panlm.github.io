---
title: EKS Container Insights
description: 启用 EKS 的 container insight 功能
created: 2022-02-22 08:08:35.714
last_modified: 2024-04-23
tags:
  - aws/container/eks
  - aws/mgmt/cloudwatch
---

# EKS Container Insights
## install
### using managed addon
- attached additional policy to node role ([docs](https://docs.amazonaws.cn/en_us/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-addon.html))
    - CloudWatchAgentServerPolicy
    - AWSXrayWriteOnlyAccess
- install cloudwatch observibility addon
```sh
CLUSTER_NAME=
ADDON_DEFAULT_VERSION=$(aws eks describe-addon-versions --addon-name amazon-cloudwatch-observability --kubernetes-version "1.30" --query 'addons[].addonVersions[?compatibilities[?defaultVersion==`true`]].addonVersion' --output text)
aws eks create-addon --cluster-name ${CLUSTER_NAME} \
--addon-name amazon-cloudwatch-observability --addon-version ${ADDON_DEFAULT_VERSION} \
--resolve-conflicts OVERWRITE
```
- it consists: 
    - [[../../addons/aws-for-fluent-bit]]
    - cloudwatch agent

### ~~from CLI~~
1. replace 2 service accounts with [CloudWatchAgentServerPolicy](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-prerequisites.htm)
```sh
CLUSTER_NAME=ekscluster1
export AWS_DEFAULT_REGION=us-east-2
eksctl utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve
```

```sh
eksctl create iamserviceaccount \
    --name cloudwatch-agent \
    --namespace amazon-cloudwatch \
    --cluster ${CLUSTER_NAME} \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
    --approve \
    --override-existing-serviceaccounts

eksctl create iamserviceaccount \
    --name fluent-bit \
    --namespace amazon-cloudwatch \
    --cluster ${CLUSTER_NAME} \
    --attach-policy-arn arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy \
    --approve \
    --override-existing-serviceaccounts

```

2. https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html
```sh
FluentBitHttpPort='2020'
FluentBitReadFromHead='On'
[[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
[[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'

output=cwqs-1.yaml
curl -o $output https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml 

# no more this line from 230819
# sed -i 's;amazon/cloudwatch-agent;public.ecr.aws/cloudwatch-agent/cloudwatch-agent;' $output

#sed -i 's;amazon/aws-for-fluent-bit:2.10.0;public.ecr.aws/aws-observability/aws-for-fluent-bit:2.28.0;' $output

cat $output | sed 's/{{cluster_name}}/'${CLUSTER_NAME}'/;s/{{region_name}}/'${AWS_DEFAULT_REGION}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' | kubectl apply -f - 

k get po -n amazon-cloudwatch

```

if you do 2 before 1, than need
- delete pods which use these service account
- check cloudtrail for "AccessDeny" events

## check pod / deployment log
- https://www.eksworkshop.com/intermediate/250_cloudwatch_container_insights/viewlogs/


## blog
- https://aws.amazon.com/blogs/containers/diving-into-container-insights-cost-optimizations-for-amazon-eks/


