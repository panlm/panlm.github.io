---
title: Breaking Through VPC Address Limitations - EKS Hybrid Node Architecture Implementation Guide
description: A real-world case study on how to elegantly solve VPC address space shortage using EKS hybrid node functionality
created: 2025-04-20 10:53:34.032
last_modified: 2025-05-01
tags:
  - aws/container/eks
status: myblog
---

> [!WARNING] 
> This is a translate version from [use-eks-hybrid-node-to-solve-ipaddr-exhausted.zh](use-eks-hybrid-node-to-solve-ipaddr-exhausted.zh)


# Breaking Through VPC Address Limitations: EKS Hybrid Node Architecture Implementation Guide

> "In software architecture, limitations often inspire innovation."

## Introduction: When VPC Address Exhaustion Meets Containerization

Imagine this scenario: you're implementing a containerized solution for a large retail enterprise. Everything seems perfect until you encounter a challenging problem - insufficient VPC address space. This isn't a hypothetical situation, but a real challenge we faced when implementing an EKS project in the Hong Kong region.

Let's start with a specific case: the customer planned to migrate their core business applications to a container platform. This application needed to be deployed in an already planned VPC, but the existing VPC had very limited address space. If we adopted the standard EKS deployment with AWS VPC CNI, the available IP addresses would quickly be exhausted.

## Why Is This a Challenging Problem?

You might wonder: "Why not simply extend the VPC's address space?" Indeed, AWS VPC supports attaching secondary CIDRs, which seems like an intuitive solution. However, real-world situations are often more complex than we imagine:

1. **Technical Limitations**: AWS has strict limitations on VPC CIDR expansion. For example, according to [AWS official documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-cidr-blocks.html#add-cidr-block-restrictions), when a VPC's primary CIDR is within the 10.0.0.0/8 range, only 100.64.0.0/10 can be attached as a secondary CIDR, and other ranges like 198.19.0.0/16 cannot be attached as secondary CIDRs.

2. **Enterprise Network Planning**: More critically, the enterprise already had a strict global IP address allocation policy:
   - 10.0.0.0/8 range: Reserved for AWS cloud environments and data centers
   - 100.64.0.0/10 range: Specifically used for store networks

This carefully designed network planning made the available address space extremely precious.

## First Attempt: The Pitfalls of Overlay Networks

So we first thought of using an overlay network solution. This seemed like a good idea: using CNI plugins like Calico or Cilium to create an overlay network, which would allow running a large number of Pods on limited VPC address space. However, during implementation, we encountered another challenge: the Pod's overlay network addresses were completely invisible to the EKS control plane. This caused network communication issues between the api-server and pods. Although we could temporarily solve this problem by setting `hostNetwork: true` in some critical Pods (such as admission controller webhooks), this solution was not perfect.

## Designing a New Solution: Balancing Multiple Requirements

Faced with these challenges, we needed to rethink the entire architecture design. The new solution had to simultaneously meet several key requirements:

1. **Enterprise Internal Access Capability**: All application components in the EKS VPC (including databases) must support enterprise internal access, or be accessible by other applications within the enterprise
   - Need to support bastion host access to databases for database auditing
   - Allow applications to expose services to other businesses through ingress

2. **Network Connectivity**
   - Pods must be able to access the enterprise's two core network segments: 10.0.0.0/8 and 100.64.0.0/10
   - Maintain enterprise network stability without introducing additional CIDR announcements

3. **Cost Effectiveness**
   - Balance the overall cost while meeting technical requirements
   - Consider the convenience of long-term maintenance and expansion

## Innovative Solutions: Breaking Through Traditional Architecture Limitations

After deep thinking and repeated validation, we found that solving this problem required thinking outside the box. Eventually, we designed two innovative solutions, each cleverly solving the IP address space shortage problem from different angles. Let's look at the ingenuity of these two solutions.

### Solution 1: Clever Use of ALB Cross-VPC Deployment

The inspiration for the first solution came from a little-known feature of the AWS Load Balancer Controller - cross-VPC deployment mode. The idea of this solution is very clever: instead of struggling to squeeze more address space out of the existing VPC, we took a different approach by deploying the EKS cluster and application PODs in a brand new VPC. Let's look at the specific design of this solution:

![[attachments/use-eks-hybrid-node-to-solve-ipaddr-exhausted.en/IMG-20250505-090108-408.png|800]]

For more technical details, refer to the AWS official blog: [Expose Amazon EKS pods through cross-account load balancer](https://aws.amazon.com/blogs/containers/expose-amazon-eks-pods-through-cross-account-load-balancer/)

In this solution, we created a separate VPC (shown as 172.16 in the diagram) and connected it to the original VPC (shown as 10.255) through VPC Peering, while the EKS cluster was deployed in the newly created VPC (using 172.16.0.0/16 as the CIDR). This separated architecture design brings several key advantages:

First, by deploying the EKS cluster in a separate VPC, we can allocate sufficient IP address space for container workloads without affecting existing business applications. Second, when deploying the AWS Load Balancer Controller, we configured it to use the original VPC, ensuring that the load balancer can correctly handle inbound and outbound traffic. Specifically, inbound traffic will go through the load balancer deployed in the business application A's VPC, accessing the application Pods in the EKS VPC via VPC Peering.

To handle outbound traffic, we deployed an internal NAT device in the original VPC. This device is equipped with two elastic network interfaces (ENIs), connected to the two VPCs respectively, for handling traffic from application Pods. This design ensures that application Pods can normally access external resources while maintaining the controllability and security of network traffic. (feature blog)

Additionally, we placed the database and other components required by the business application backend in the original VPC (10.255), ensuring direct access from other enterprise internal applications, such as bastion hosts.

### Solution 2: The Innovation of Hybrid Node Architecture

The second solution demonstrates another innovation by AWS in the field of container orchestration. It cleverly utilizes the Hybrid Node feature of Amazon EKS, released at the 2024 re:Invent conference, providing us with a workaround solution.

Let's look at the architecture of this solution:

![[attachments/use-eks-hybrid-node-to-solve-ipaddr-exhausted.en/IMG-20250505-090108-542.png|800]]

The core of this solution lies in its flexibility and scalability. We create a separate VPC (shown as 172.16 in the diagram) and interconnect it with the original VPC (shown as 10.255) using TGW. The main reason for using TGW instead of VPC Peering is that we need fine-grained control over the routing of invisible Overlay segments (RemotePODNetwork).

Components that need to be directly accessed by other enterprise applications, including databases and specific applications not suitable for running in an Overlay environment, are deployed in the original VPC. Applications that can run on the Overlay network are deployed in the separate VPC and exposed to the original VPC through the AWS Load Balancer Controller.

Similarly, to handle outbound traffic, we deployed an internal NAT device in the original VPC. This device is equipped with two elastic network interfaces (ENIs), connected to the two VPCs respectively, for handling traffic from application Pods. This design ensures that application Pods can normally access external resources while maintaining the controllability and security of network traffic.

<mark style="background: #FF5582A6;">When using this solution, the following additional considerations need to be taken into account</mark>:
- According to [AWS official documentation](https://docs.aws.amazon.com/eks/latest/userguide/hybrid-nodes-overview.html): Amazon EKS hybrid node functionality is not supported for running in cloud infrastructure (including AWS Regions, AWS Local Zones, AWS Outposts, or other clouds). If you run hybrid nodes on Amazon EC2 instances, you will be charged for using the hybrid node functionality.
- Cannot use the 100.64 network segment as the CIDR for the remote POD network
- Cannot use a CIDR that overlaps with existing VPCs as the CIDR for the remote node network
- Additional cost of the TGW network component

In the following sections, we will detail the specific implementation steps of this workaround solution, including environment preparation, network configuration, node deployment, and the installation and configuration of related components.
## Implementation Deployment Guide: From Theory to Practice

In this section, we will guide you step by step through implementing the EKS hybrid node architecture. To ensure a clear and controlled deployment process, we have designed a complete test environment as a practical foundation. This environment consists of two core VPCs:

- Original VPC (CIDR: 10.10.0.0/16): Used for deploying the EKS control plane and management components
- Newly created separate VPC (CIDR: 10.20.0.0/16): Used for deploying hybrid nodes and business applications

This configuration perfectly corresponds to our previously discussed architecture design, allowing us to validate the effectiveness of each technical decision in practice. Next, we will follow clear steps to complete the entire process from infrastructure building to application deployment.

### Network Architecture Design: Building a Solid Foundation

Before starting the specific deployment, let's first understand the design of the entire network architecture. The following diagram shows our complete network architecture design, including VPC configuration, subnet division, routing settings, and connection relationships between components:

![[attachments/use-eks-hybrid-node-to-solve-ipaddr-exhausted.en/IMG-20250505-090108-702.png|800]]
### Infrastructure Deployment: Step-by-Step Implementation Guide

Before deploying hybrid nodes, we need to first complete the infrastructure deployment. This process includes creating an EKS cluster, configuring network resources, and preparing hybrid node instances. Let's explore each step in detail.

#### Phase One: Creating the EKS Cluster

First, we use the [eksdemo](https://github.com/awslabs/eksdemo) tool to create a standard EKS cluster. This tool not only simplifies the cluster creation process but also automatically creates a VPC with CIDR 10.10.0.0/16. Detailed creation commands can be referenced at: [[git/git-mkdocs/CLI/linux/eksdemo#create-eks-cluster-]]

#### Phase Two: Configuring the Network Environment

Next, we need to create and configure the network environment for business applications. This includes creating a dedicated VPC and setting up network interconnection.

1. Creating the IDC VPC
   Using the [Amazon Q Developer CLI](https://github.com/aws/amazon-q-developer-cli) tool, we can quickly create a well-structured VPC:
```text
In the us-west-2 region, create a vpc named idc with CIDR 10.20.0.0/16. The vpc needs 3 public subnets, 3 private subnets, and 3 tgw subnets. Public subnets share 1 route table with default route pointing to igw, private subnets share 1 route table with default route pointing to nat, and tgw subnets share 1 route table with no default route.
```

2. Configuring Network Interconnection
   Next is a key step: establishing a communication bridge between VPCs. We choose to use Transit Gateway as the core network hub to achieve efficient interconnection between VPCs. Using the Amazon Q Developer CLI tool, we can complete this configuration with one command:

   ```text
   In the us-west-2 region, now interconnect the ekscluster1 vpc and idc vpc using tgw. The idc vpc already has dedicated tgw subnets. You need to create dedicated tgw subnets in the ekscluster1 vpc and automatically set up all route tables so that networks can interconnect and communicate.
   ```

3. Deploying Hybrid Node Instances
   After the network infrastructure is ready, we need to deploy EC2 instances in the IDC VPC that will serve as hybrid nodes. These instances need to meet specific requirements to ensure they can successfully join the EKS cluster:

   ```text
   In the us-west-2 region idc vpc, create 1 ec2 in each private subnet using ubuntu22 AMI with instance type m5.large. Then create an EC2 Instance Connect Endpoint in the idc vpc.
   ```

4. Configuring Instance Network
   To ensure hybrid nodes can work properly, we need to make some special network configurations for the EC2 instances:

   - **Security Group Settings**
     - Configure inbound rules: Allow all traffic from the 10.0.0.0/8 segment
     - Purpose: Ensure smooth communication between cluster components

   - **Network Interface Optimization**
     - Disable source/destination check
     - Reason: This is a necessary condition for overlay networks to work properly
#### Phase Three: Configuring EKS Cluster Network

After completing the basic network setup, we need to make specific network configurations for the EKS cluster to support the integration of hybrid nodes:

1. **Cluster Security Group Configuration**
   Configure security group rules to allow necessary network communications:
   ```sh
   # Allow all traffic from the 10.0.0.0/8 segment
   aws ec2 authorize-security-group-ingress \
     --group-id ${CLUSTER_SG_ID} \
     --protocol all \
     --cidr 10.0.0.0/8
   ```

2. **Hybrid Node Network Settings**
   Enable hybrid node support in the EKS cluster configuration, setting two key parameters:
   - remoteNodeNetworks: Specify the range of private subnets in the IDC VPC
   - remotePodNetworks: Define the Overlay CIDR range that Cilium will use

   As shown in the figure below, these settings will be configured in the EKS console:
![[attachments/use-eks-hybrid-node-to-solve-ipaddr-exhausted.en/IMG-20250505-090108-848.png|800]]

#### Phase Four: Configuring Systems Manager

AWS Systems Manager (SSM) plays a key role in the hybrid node architecture, responsible for establishing and maintaining secure communication channels between the EKS control plane and remote nodes.

1. **Creating SSM Activation Configuration**
   First, we need to create an SSM activation configuration, which will generate credentials for node registration:
```
aws ssm create-activation \
     --region us-west-2 \
     --default-instance-name eks-hybrid-nodes \
     --description "Activation for EKS hybrid nodes" \
     --iam-role vscode-server-VSCodeInstanceBootstrapRole \
     --tags Key=EKSClusterARN,Value=arn:aws:eks:us-west-2:123456789012:cluster/ekscluster1 \
     --registration-limit 100
```

2. **Initializing Hybrid Nodes**
   After obtaining the activation credentials, we need to perform initialization configuration on each hybrid node. This process is divided into three main steps:

```sh
# 1. install nodeadm
curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm'
chmod a+x nodeadm
apt update
./nodeadm install 1.31 --credential-provider ssm
# 2. prepare config
cat >nodeConfig.yaml <<-EOF
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ekscluster1
    region: us-west-2
  hybrid:
    ssm:
      activationCode: xxxx
      activationId: xxxx
EOF
# 3. init hybrid node
./nodeadm init -c file://./nodeConfig.yaml
```

   > Note: This initialization process needs to be repeated on each hybrid node. Make sure the node's network and security group settings are correctly configured before execution.
### Installing and Configuring Cluster Components

After completing the basic configuration of hybrid nodes, we need to install and configure some necessary cluster components to ensure the entire environment can run normally. These components include load balancer controllers and network plugins.

#### Configuring Load Balancer

First, we need to install the AWS Load Balancer Controller to manage application load balancers:
```sh
eksdemo install aws-lb-controller -c ${CLUSTER_NAME} --namespace awslb
```

To ensure the stable operation of the load balancer controller, we can control its deployment location through node affinity configuration. If you don't want to deploy the controller on hybrid nodes, you can add the following configuration:
```yaml
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: eks.amazonaws.com/compute-type
                operator: NotIn
                values:
                - hybrid
```

#### Configuring Network Plugin

Next, we need to install and configure Cilium as the cluster's network plugin. Cilium is a powerful CNI plugin that not only provides basic network connectivity but also supports advanced network policies and observability features. In our hybrid node architecture, Cilium will be responsible for managing Pod network communications across VPCs.

Here's an explanation of the key parts of the Cilium configuration:
1. **Node Affinity Configuration**: Through affinity settings, ensure that Cilium Agent only runs on hybrid nodes, while Operator components run on non-hybrid nodes, optimizing network performance and management efficiency.
2. **IP Address Management**: Using the cluster-pool mode for IP allocation, each node gets a `/24` segment, allowing for more granular address management while maintaining network scalability.
3. **Network Optimization**: Disabled unnecessary Envoy components and configured unmanagedPodWatcher to optimize Pod network management, improving overall performance.

```sh
helm repo add cilium https://helm.cilium.io/
cat >cilium-values.yaml <<-EOF
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/compute-type
          operator: In
          values:
          - hybrid
ipam:
  mode: cluster-pool
  operator:
    clusterPoolIPv4MaskSize: 24
    clusterPoolIPv4PodCIDRList:
    - 10.30.0.0/16
operator:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: eks.amazonaws.com/compute-type
            operator: NotIn
            values:
              - hybrid
  unmanagedPodWatcher:
    restart: false
envoy:
  enabled: false
EOF

helm upgrade -i cilium cilium/cilium \
    --version v1.16.9 \
    --namespace kube-system \
    --values cilium-values.yaml 
```

After completing the installation and configuration of Cilium, we can verify the status of hybrid nodes. At this point, the hybrid nodes previously added to the cluster should transition from NotReady to Ready status. Use the following command to check node status:
```sh
kubectl get ciliumnode
```

#### Deployment Verification

To verify the functionality of the entire environment, we can deploy a test Nginx Pod and create an Ingress resource through the AWS Load Balancer Controller. During this process, we will observe a phenomenon: although the ALB can be successfully created, the Pod addresses in the Target Group will show as unreachable. This issue will be resolved in the subsequent network routing configuration section.

Deploy the verification nginx POD ([[../../others/nginx-sample#sample-for-hybrid-node-]])
### Network Routing Configuration: Building Reliable Communication Channels

In the hybrid node architecture, network routing configuration is the core of the entire system. Proper routing settings not only ensure communication between Pods but also maintain the network connectivity of the entire cluster. Let's delve into this critical configuration process.

#### Pod Network Routing Architecture

In our design, the Pod network uses 10.30.0.0/16 as the overall CIDR range, with each hybrid node getting a /24 subnet. This design both ensures effective utilization of address space and facilitates fine-grained traffic control.

#### Routing Configuration Steps

1. **EKS VPC Routing Configuration**
   Configure the routing table in the public subnets of the EKS VPC, mainly used for handling inbound traffic from ALB:
   ![[attachments/use-eks-hybrid-node-to-solve-ipaddr-exhausted.en/IMG-20250505-090108-981.png|800]]

2. **Transit Gateway Core Routing**
   Configure Transit Gateway as the central hub of the network:
   - Forward all traffic destined for 10.30.0.0/16 to the IDC VPC
   - Ensure Pod network traffic can correctly reach the target nodes
   ![[attachments/use-eks-hybrid-node-to-solve-ipaddr-exhausted.en/IMG-20250505-090109-172.png|800]]

3. **IDC VPC Fine-Grained Routing**
   Configure fine-grained Pod network routing in the TGW subnets of the IDC VPC:
   - Configure a dedicated /24 segment for each hybrid node
   - For example: 10.30.0.0/24 → Hybrid Node 1
   - Ensure traffic can accurately reach the target Pods
   ![[attachments/use-eks-hybrid-node-to-solve-ipaddr-exhausted.en/IMG-20250505-090109-293.png|800]]

4. **Bidirectional Communication Guarantee**
   To ensure bidirectional connectivity of the network, the following routes need to be configured:

   a. IDC VPC Return Route:
      - Destination: 10.10.0.0/16 (EKS VPC)
      - Next Hop: Transit Gateway
      - Function: Ensure traffic from Pods can return to the EKS cluster

   b. Transit Gateway Return Configuration:
      - Maintain routes to EKS VPC (10.10.0.0/16)
      - Ensure bidirectional communication between cluster components

### Automation Tool: Route Table Synchronization Script

In the hybrid node architecture, Pod CIDR routing configuration needs to be updated as nodes change. To automate this process, we developed a route table synchronization script. This script can monitor the status of Cilium nodes and automatically update the corresponding routing configuration.

#### Background
When using Cilium as the CNI plugin, each node is assigned an overlay network CIDR (such as 10.30.x.0/24). This CIDR information can be viewed using the `kubectl get ciliumnode` command. To ensure the network works properly, we need to synchronize this CIDR information to the VPC's route table and set the target to the corresponding node's ENI.

#### Script Functionality
This automation script provides the following functions:
- Automatically obtain Cilium node information and assigned CIDRs
- Update route entries in the route table
- Clean up expired route configurations
- Keep the route table synchronized with the current cluster state
```sh
#!/bin/bash -x

# Configuration - please replace with your actual values
REGION="us-west-2"  # Please replace with your actual region
ROUTE_TABLE_ID="rtb-074975b4268607ffd"  # Please replace with the route table ID used by TGW

echo "Starting to sync Cilium routes to route table $ROUTE_TABLE_ID..."

# Get Cilium node information
echo "Getting Cilium node information..."
CILIUM_NODES=$(kubectl get ciliumnode -o json)

# Create an array to store valid Cilium CIDRs
declare -a VALID_CIDRS

# Traverse each Cilium node, collecting valid CIDRs
while read -r node; do
  OVERLAY_CIDR=$(echo $node | jq -r '.spec.ipam.podCIDRs[0]')
  if [[ -n "$OVERLAY_CIDR" && "$OVERLAY_CIDR" != "null" ]]; then
    VALID_CIDRS+=("$OVERLAY_CIDR")
    echo "Valid CIDR: $OVERLAY_CIDR"
  fi
done < <(echo $CILIUM_NODES | jq -c '.items[]')

# Get current route table information
echo "Getting current routes for route table $ROUTE_TABLE_ID..."
CURRENT_ROUTES=$(aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_ID --query 'RouteTables[0].Routes' --output json --region $REGION)

# Traverse each Cilium node, update routes
echo $CILIUM_NODES | jq -c '.items[]' | while read -r node; do
  NODE_NAME=$(echo $node | jq -r '.metadata.name')
  OVERLAY_CIDR=$(echo $node | jq -r '.spec.ipam.podCIDRs[0]')
  NODE_IP=$(echo $node | jq -r '.spec.addresses[] | select(.type=="InternalIP").ip')
  
  echo "Node: $NODE_NAME, IP: $NODE_IP, CIDR: $OVERLAY_CIDR"
  
  # Find instance ID through node IP
  INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$NODE_IP" --query 'Reservations[0].Instances[0].InstanceId' --output text --region $REGION)
  
  if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "None" ]]; then
    echo "Warning: Cannot find instance ID through IP $NODE_IP, skipping this node"
    continue
  fi
  
  echo "Found instance ID: $INSTANCE_ID"
  
  # Check if route needs to be updated
  ROUTE_EXISTS=$(echo $CURRENT_ROUTES | jq --arg cidr "$OVERLAY_CIDR" 'any(.[] | .DestinationCidrBlock == $cidr)' 2>/dev/null)
  
  if [[ "$ROUTE_EXISTS" != "true" ]]; then
    echo "Adding or updating route: $OVERLAY_CIDR -> $INSTANCE_ID"
    
    # Get ENI ID of the instance
    ENI_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].NetworkInterfaces[0].NetworkInterfaceId' --output text --region $REGION)
    
    if [[ -n "$ENI_ID" && "$ENI_ID" != "None" ]]; then
      # Add or replace route
      aws ec2 replace-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block $OVERLAY_CIDR --network-interface-id $ENI_ID --region $REGION || \
      aws ec2 create-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block $OVERLAY_CIDR --network-interface-id $ENI_ID --region $REGION
      
      echo "Route updated: $OVERLAY_CIDR -> $ENI_ID"
    else
      echo "Warning: Cannot get ENI ID for $INSTANCE_ID"
    fi
  else
    echo "Route already exists: $OVERLAY_CIDR"
  fi
done

# Get the latest route table information again (as it may have been updated)
UPDATED_ROUTES=$(aws ec2 describe-route-tables --route-table-ids $ROUTE_TABLE_ID --query 'RouteTables[0].Routes' --output json --region $REGION)

# Check and delete excess 10.30.x.0/24 routes
echo "Checking and deleting excess 10.30.x.0/24 routes..."
echo $UPDATED_ROUTES | jq -c '.[]' | while read -r route; do
  CIDR=$(echo $route | jq -r '.DestinationCidrBlock // ""')
  
  # Check if it's a route in 10.30.x.0/24 format
  if [[ $CIDR =~ ^10\.30\.[0-9]+\.0/24$ ]]; then
    # Check if this CIDR is in the valid CIDR list
    FOUND=false
    for VALID_CIDR in "${VALID_CIDRS[@]}"; do
      if [[ "$VALID_CIDR" == "$CIDR" ]]; then
        FOUND=true
        break
      fi
    done
    
    # If not in the valid list, delete this route
    if [[ "$FOUND" == "false" ]]; then
      echo "Deleting excess route: $CIDR"
      aws ec2 delete-route --route-table-id $ROUTE_TABLE_ID --destination-cidr-block $CIDR --region $REGION
    else
      echo "Keeping valid route: $CIDR"
    fi
  fi
done

echo "Synchronization complete!"
```

## Environment Cleanup: Dismantling Architecture in Dependency Order

After completing the testing, to avoid unnecessary resource costs, we need to clean up the environment in the correct order. This process requires special attention to the dependencies between resources, ensuring that cleanup operations do not fail due to dependency conflicts.

### Application Cleanup

First, clean up application resources running in the cluster:
```sh
# Delete all application-level resources
kubectl delete deployment,service,ingress --all
```

### Node Cleanup

Before deleting the cluster, you need to first clean up hybrid nodes and their related configurations:
```sh
# Reset hybrid nodes (execute on each node)
sudo ./nodeadm reset

# Clean up SSM activation configuration
aws ssm delete-activation --activation-id <your-activation-id>
```

### Cluster Component Cleanup

Following the dependency relationship, start cleaning from the upper-layer components:
```sh
# 1. Delete load balancer controller
eksdemo delete aws-lb-controller -c ${CLUSTER_NAME}

# 2. Delete network plugin
helm delete cilium -n kube-system
```
### Network Resource Cleanup

Network resource cleanup needs to follow an inside-out order:

1. **Route Configuration**
   - Delete route entries in the Transit Gateway route table
   - Clean up custom routes in the VPC route tables

2. **Network Connections**
   - Detach and delete Transit Gateway Attachments
   - Delete Transit Gateway
   - Clean up TGW subnet route tables

### Compute Resource Cleanup

Delete all compute resources in the IDC VPC:

1. **Instance Resources**
   - Terminate hybrid node EC2 instances
   - Delete EC2 Instance Connect Endpoint

2. **Network Security**
   - Delete custom security group rules
   - Delete security groups

### Infrastructure Cleanup

Finally, clean up basic network resources:

1. **VPC Resources**
   ```sh
   # Delete IDC VPC
   aws ec2 delete-vpc --vpc-id ${IDC_VPC_ID}

   # Delete EKS cluster (this will also delete the EKS VPC)
   eksdemo delete cluster ${CLUSTER_NAME}
   ```

### Cleanup Verification

Execute the following commands to ensure all resources have been properly cleaned up:
```sh
# Verify EKS cluster
aws eks describe-cluster --name ${CLUSTER_NAME}

# Verify VPC resources
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=idc"

# Verify network components
aws ec2 describe-transit-gateways
```

> Tip: When performing cleanup operations, it's recommended to keep track of the resource deletion order. If deletion fails, it's usually because of undiscovered resource dependencies, which need to be found and deleted first.


## References

### AWS Official Documentation
- [EKS Hybrid Nodes Overview](https://docs.aws.amazon.com/eks/latest/userguide/hybrid-nodes-overview.html) - Official guide for comprehensive understanding of EKS hybrid node functionality

### Technical Blogs
- [Deep Dive into EKS Hybrid Nodes](https://aws.amazon.com/blogs/containers/a-deep-dive-into-amazon-eks-hybrid-nodes/) - AWS official blog, detailing the technical principles of hybrid nodes
- [Expose EKS Pods through Cross-Account Load Balancer](https://aws.amazon.com/blogs/containers/expose-amazon-eks-pods-through-cross-account-load-balancer/) - Detailed implementation of cross-VPC deployment solutions

### Community Resources
- [Unpacking the Cluster Networking for Amazon EKS Hybrid Nodes](https://repost.aws/articles/ARL44xuau6TG2t-JoJ3mJ5Mw/unpacking-the-cluster-networking-for-amazon-eks-hybrid-nodes) - Technical article on AWS re:Post, in-depth analysis of network architecture
