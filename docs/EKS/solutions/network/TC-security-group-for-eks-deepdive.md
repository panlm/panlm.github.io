---
title: EKS Security Group Deepdive
description: 深入 EKS 安全组
created: 2022-05-17 16:11:20.840
last_modified: 2024-02-25
status: myblog
tags:
  - aws/container/eks
  - aws/network/security-group
---
# 深入 EKS 安全组

## general

eksctl 是一个用于在 Amazon EKS 上创建和管理 Kubernetes 集群的简单命令行实用程序。
- https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html
- https://eksctl.io/introduction/

使用 eksctl 创建 EKS 集群后，需要搞清楚不同安全组之间的关系，尤其是在private only集群的场景下，以便未来在更复杂场景下诊断问题提供基础。我们今天就来了解下。

我们先把所涉及到的相关安全组以功能名称可以进行细分，帮助我们更好理解架构：
1）集群安全组（Cluster SG）-- 可以在eks控制台查看，由eks集群创建；
2）附加安全组（Additional SG）-- 可以在eks控制台查看，可以在集群创建之前创建并作为参数传入`securityGroup`；另外，Additional SG在安全组名称中称为ControlPlaneSG，注意不要混淆，后续描述该SG以控制台上名称为准。
3）共享安全组（Shared SG）-- 创建集群时如果不指定，eksctl会自动创建；任何其他需要访问集群（例如跳板机）或者集群需要访问的资源（例如endpoint）都会绑定该安全组，简化安全组管理
4）节点组安全组（Nodegroup SG）-- 自管节点组创建时创建；

默认创建集群后安全组分配及其入站规则可以参照如下规则：
- eks控制平面eni将分配Cluster SG和Additional SG；
- 托管节点将分配Cluster SG，fargate节点将分配Cluster SG，Cluster SG会添加自身作为入站规则；
- 自管节点将分配Nodegroup SG和Shared SG，且Nodegroup SG与Additional SG相互添加（特定端口）以允许访问；
- 所有其他需要与eks集群互访的资源都将分配Shared SG，且Shared SG与Cluster SG相互添加以允许访问，Cluster SG会添加自身作为入站规则；

## EKS API server endpoint access is private only

在使用private only集群时，我们一般会在现有规划好的vpc中创建，并且使用一台跳板机访问集群，因此需要按照如下顺序部署：
- 创建vpc以及相关子网
- 使用cloud9作为跳板机
- 创建Shared SG，并挂载到cloud9保证其可以访问集群控制平面
- 执行eksctl创建eks集群

![[git/git-mkdocs/git-attachment/security-group-in-eks-privonly.drawio.png]]

当配置文件中指定`privateCluster: true`和`skipEndpointCreation: false`时，下列endpoint将被创建，且共享安全组（Shared SG）被分配到endpoint上。
如果你的子网可以正常访问公网，那么绝大部分情况下你可以跳过创建这些endpoint，即`skipEndpointCreation: true`。
- autoscaling (additional)
- logs (additional)
- cloudformation (additional)
- s3
- ecr dkr / ecr api
- ec2 / ec2messages
- sts
- elasticloadbalancing
- kms
- ssm / ssmmessages

### yaml

```yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ekscluster-privonly # MODIFY cluster name
  region: "us-east-2" # MODIFY region
  version: "1.21" # MODIFY version

# full private cluster
privateCluster:
  enabled: true 
  skipEndpointCreation: true
  # additionalEndpointServices:
  # - "autoscaling"
  # - "logs"
  # - "cloudformation"

# REPLACE THIS CODE BLOCK
vpc:
  subnets:
    private:
      us-east-2a:
        id: subnet-04b9
      us-east-2b:
        id: subnet-0337
    public:
      us-east-2a:
        id: subnet-0196
      us-east-2b:
        id: subnet-0190
  sharedNodeSecurityGroup: sg-07bb
  # securityGroup: sg-0ba1457c2bb55a5ff
  
cloudWatch:
  clusterLogging:
    enableTypes: ["*"]

# secretsEncryption:
#   keyARN: ${MASTER_ARN}

managedNodeGroups:
- name: managed-ng
  minSize: 1
  maxSize: 5
  desiredCapacity: 1
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true
```

## EKS API server endpoint access is public and private (or public only)

创建可以公网访问api server的eks集群相对比较简单，适合用于测试或者实验环境。在配置中vpc章节，不指定具体的id以及相关子网信息，eksctl会创建全新子网来运行eks集群，如下图：

![[git/git-mkdocs/git-attachment/security-group-in-eks-pub-and-priv.drawio.png]]

相关安全组分配、入站规则等与private only集群相同。我们来看下当应用发布时对于安全组又有哪些更新：
- LB托管安全组（Managed SG for LB）-- 安全组名称类似`k8s-ingressname-随机字符串`，包含应用对外访问端口，例如80，443；
- LB共享后端安全组（Shared Backend SG for LB）-- 安全组名称类似`k8s-traffic-eks集群名称-随机字符串`

我们再看下相关SG入站规则情况（包含完整规则）
- Cluster SG
    - 允许自身
    - 允许Shared SG
    - 允许LB共享后端安全组，且使用Nodeport端口(instance mode)或者Pod端口(ip mode)
- Additional SG
    - 允许Nodegroup SG 443端口 （自管节点组访问集群控制平面）
- Shared SG
    - 允许自身
    - 允许Cluster SG
- Nodegroup SG
    - 允许Additional SG 443 端口 （kube-proxy）和 1025-65535 端口 （回包端口）
    - 允许LB共享后端安全组， 且使用Nodeport端口(instance mode)或者Pod端口(ip mode)

如果发布的应用自身不带SG，则使用节点组主ENI的SG
- 如果Pod运行在管理节点组，LB共享后端安全组会自动添加到Cluster SG（如果elb类型为instance，添加Nodeport Port；如果elb类型为ip，添加Pod Port）
- 如果Pod运行在自管节点组，LB共享后端安全组会自动添加到Nodegroup SG（如果elb类型为instance，添加Nodeport Port；如果elb类型为ip，添加Pod Port）

如果发布的应用自身有SG，则会使用它
- 一般我们会手工添加应用自带SG且目的端口53，到Cluster SG和Nodegroup SG，方便应用与coredns服务通讯
- LB共享后端安全组会自动添加到应用自带SG（如果elb类型为ip，添加Pod Port）
- LB共享后端安全组会自动添加到Cluster SG（如果elb类型为instance，添加Nodeport Port）

补充应用发布在fargate上的场景
- 应用自身不带SG
    - elb类型为instance时，LB共享后端安全组将添加Nodeport Port到Cluster SG中
    - elb类型为ip时，LB共享后端安全组将添加Pod Port到Cluster SG中
- 应用自身有SG
    - elb类型为instance时，LB共享后端安全组将添加Nodeport Port到Cluster SG中
    - elb类型为ip时，LB共享后端安全组将添加Pod Port到应用自带SG中


### yaml

```yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ekscluster1 # MODIFY cluster name 
  region: "us-east-1" # MODIFY region
  version: "1.21" # MODIFY version

vpc:
  clusterEndpoints:
    privateAccess: true
    publicAccess: true

cloudWatch:
  clusterLogging:
    enableTypes: ["*"]

# secretsEncryption:
#   keyARN: ${MASTER_ARN}

managedNodeGroups:
- name: mng1
  minSize: 1
  maxSize: 5
  desiredCapacity: 1
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true

nodeGroups:
- name: ng1
  ami: ami-06a8
  amiFamily: AmazonLinux2
  minSize: 1
  maxSize: 5
  desiredCapacity: 1
  instanceType: m5.large
  ssh:
    enableSsm: true
  privateNetworking: true
  overrideBootstrapCommand: |
    #!/bin/bash
    source /var/lib/cloud/scripts/eksctl/bootstrap.helper.sh
    /etc/eks/bootstrap.sh ${CLUSTER_NAME} --container-runtime containerd --kubelet-extra-args "--node-labels=${NODE_LABELS}"

```

## refer 

- file:///Users/panlm/Documents/SA-Baseline-50-12/eks/security-group-in-eks-0614.drawio
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/examples/echo_server/
- [[enable-sg-on-pod]]
- [[git/git-mkdocs/EKS/cluster/eks-public-access-cluster]]
- [[git/git-mkdocs/EKS/cluster/eks-private-access-cluster]]


## TODO

- endpoint for elb & appmesh-envoy-management 





