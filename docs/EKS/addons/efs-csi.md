---
title: EFS CSI on EKS
description: 使用 EFS 作为 Pod 持久化存储
created: 2022-05-23 09:57:50.932
last_modified: 2024-04-19
tags:
  - aws/storage/efs
  - aws/container/eks
---

# EFS CSI on EKS

## link

- [efs workshop](https://www.eksworkshop.com/beginner/190_efs/launching-efs/)
- [[efs-on-eks-mini-priviledge]]
- [Introducing Amazon EFS CSI dynamic provisioning](https://aws.amazon.com/blogs/containers/introducing-efs-csi-dynamic-provisioning/)

## create-efs- 

```sh
echo ${CLUSTER_NAME:=ekscluster1}
echo ${AWS_DEFAULT_REGION:=cn-northwest-1} ; export AWS_DEFAULT_REGION

VPC_ID=$(aws eks describe-cluster \
  --name ${CLUSTER_NAME} \
  --query "cluster.resourcesVpcConfig.vpcId" --output text )
VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids ${VPC_ID} \
  --query "Vpcs[].CidrBlock" --output text )

# create security group
SG_ID=$(aws ec2 create-security-group --description ${CLUSTER_NAME}-efs-eks-sg \
  --group-name efs-sg-$RANDOM --vpc-id ${VPC_ID} |jq -r '.GroupId' )
# allow tcp 2049 (nfs v4)
aws ec2 authorize-security-group-ingress --group-id ${SG_ID}  --protocol tcp --port 2049 --cidr ${VPC_CIDR}

# create efs
FILESYSTEM_ID=$(aws efs create-file-system \
    --creation-token ${CLUSTER_NAME} |jq -r '.FileSystemId' )
echo ${FILESYSTEM_ID}

while true ; do
aws efs describe-file-systems \
    --file-system-id ${FILESYSTEM_ID} \
    --query 'FileSystems[].LifeCycleState' \
    --output text |grep -q available
if [[ $? -eq 0 ]]; then
  break
else
  echo "wait..."
  sleep 10
fi  
done

# create mount target
TAG=tag:kubernetes.io/role/internal-elb
SUBNETS=($(aws eks describe-cluster --name ${CLUSTER_NAME} \
    |jq -r '.cluster.resourcesVpcConfig.subnetIds[]'))
PRIV_SUBNETS=($(aws ec2 describe-subnets --filters "Name=${TAG},Values=1" \
    --subnet-ids ${SUBNETS[@]} |jq -r '.Subnets[].SubnetId' ) )
for i in ${PRIV_SUBNETS[@]} ; do
    echo "creating mount target in: " $i
    aws efs create-mount-target --file-system-id ${FILESYSTEM_ID} \
        --subnet-id ${i} --security-group ${SG_ID}
done

```

## install efs-csi
### install using eksdemo
```sh
eksdemo  install storage efs-csi -c ekscluster1

```

### install from github
直接安装不额外配置权限的话，只能验证静态 provision
如果验证动态 provision，会有权限不够的告警，因为需要动态创建 access point，可以通过节点 role方式加载权限，或者重新部署为 irsa

```sh
git clone https://github.com/kubernetes-sigs/aws-efs-csi-driver.git
kubectl apply -k ./aws-efs-csi-driver/deploy/kubernetes/overlays/stable

# verify pod running
kubectl get pods -n kube-system

# verify version
pod1=$(kubectl get pod -n kube-system -l app=efs-csi-controller |tail -n 1 |awk '{print $1}')
kubectl exec -it ${pod1} -n kube-system -- mount.efs --version

```

#### uninstall
```sh
cd aws-efs-csi-driver/deploy/kubernetes/overlays/stable
kubectl kustomize |kubectl delete -f -
```


### install from helm
https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/README.md#installation

#### node role (alternative)
- you will got error in creating pod:  `User: arn:aws:sts::xxx:assumed-role/eksctl-ekscluster1-nodegroup-mana-NodeInstanceRole-1LTHOM1WRDBIS/i-xxx is not authorized to perform: elasticfilesystem:DescribeMountTargets on the specified resource`, if you miss this step
```sh
wget -O iam-policy.json 'https://github.com/kubernetes-sigs/aws-efs-csi-driver/raw/master/docs/iam-policy-example.json'
# cp aws-efs-csi-driver/docs/iam-policy-example.json iam-policy.json

## Create an IAM policy 
POLICY_ARN=$(aws iam create-policy \
  --policy-name EFSCSIControllerIAMPolicy-$RANDOM \
  --policy-document file://iam-policy.json |jq -r '.Policy.Arn' )
echo ${POLICY_ARN}

## attach policy to node role MANUALLY

```

#### sa role
```sh

# do steps in **node role** chapter
# need POLICY_ARN

echo ${CLUSTER_NAME}
echo ${AWS_DEFAULT_REGION}
echo ${POLICY_ARN}

eksctl utils associate-iam-oidc-provider \
    --cluster ${CLUSTER_NAME} \
    --approve
eksctl create iamserviceaccount \
    --cluster=${CLUSTER_NAME} \
    --namespace=kube-system \
    --name=efs-csi-controller-sa \
    --override-existing-serviceaccounts \
    --attach-policy-arn=${POLICY_ARN} \
    --approve
```

#### install
```sh
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver
helm repo update

# get url for your region 
# https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
# add `.cn` postfix for china region
if [[ ${AWS_DEFAULT_REGION%%-*} == "cn" ]]; then 
  REGISTRY=961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn
else 
  REGISTRY=602401143452.dkr.ecr.us-east-1.amazonaws.com
fi
helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
  --namespace kube-system \
  --set image.repository=${REGISTRY}/eks/aws-efs-csi-driver \
  --set controller.serviceAccount.create=false \
  --set controller.serviceAccount.name=efs-csi-controller-sa

```
find registry url from [[eks-container-image-registries-url-by-region]]

##### for private cluster 
https://github.com/kubernetes-sigs/aws-efs-csi-driver/blob/master/docs/README.md#installation

```sh
--set sidecars.livenessProbe.image.repository=602401143452.dkr.ecr.region-code.amazonaws.com/eks/livenessprobe \
--set sidecars.node-driver-registrar.image.repository=602401143452.dkr.ecr.region-code.amazonaws.com/eks/csi-node-driver-registrar \
--set sidecars.csiProvisioner.image.repository=602401143452.dkr.ecr.region-code.amazonaws.com/eks/csi-provisioner
```

#### uninstall
```sh
helm uninstall aws-efs-csi-driver -n kube-system
```

## verify
### static provisioning
[link](https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/examples/kubernetes/multiple_pods)
using static provision with mount, no access point needed, so no additional iam policy

```sh
echo ${FILESYSTEM_ID}

cat > storageclass.yaml <<-EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc-mnt
provisioner: efs.csi.aws.com
EOF

# ensure volumeHandle has been replaced by your efs filesystem id
envsubst > pv.yaml <<-EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv-mnt
spec:
  capacity:
    storage: 6Gi             # equal or bigger pvc, but it's a soft limit
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc-mnt
  csi:
    driver: efs.csi.aws.com
    volumeHandle: ${FILESYSTEM_ID}
EOF

cat > pvc.yaml <<-EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim-mnt
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc-mnt
  resources:
    requests:
      storage: 5Gi           # it's a soft limit
EOF

echo '---
apiVersion: v1
kind: Pod
metadata:
  name: efs-app1
spec:
  containers:
  - name: efs-app1
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date -u) >> /data/out1.txt; sleep 5; done"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: efs-claim-mnt
---
apiVersion: v1
kind: Pod
metadata:
  name: efs-app2
spec:
  containers:
  - name: efs-app2
    image: busybox
    command: ["/bin/sh"]
    args: ["-c", "while true; do echo $(date -u) >> /data/out2.txt; sleep 5; done"]
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: efs-claim-mnt
' |tee pod.yaml


kubectl apply -f storageclass.yaml
kubectl apply -f pv.yaml
kubectl apply -f pvc.yaml
kubectl apply -f pod.yaml

```

### dynamic provisioning with efs access point 
https://github.com/kubernetes-sigs/aws-efs-csi-driver/tree/master/examples/kubernetes/dynamic_provisioning
need additional iam policy, execute `node role` part, or reinstall with irsa

```sh
echo ${FILESYSTEM_ID}

# ensure volumeHandle has been replaced by your efs filesystem id
envsubst > ./dy-storageclass.yaml <<-EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
# reclaimPolicy: Ratain # delete pod
parameters:
  provisioningMode: efs-ap
  fileSystemId: ${FILESYSTEM_ID}
  directoryPerms: "700"
  gidRangeStart: "1000" # optional
  gidRangeEnd: "2000" # optional
  basePath: "/dynamic_provisioning" # optional
EOF

echo '---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi                      # soft limit
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: efs-app-dy1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: efs-app-dy1
  template:
    metadata:
      labels:
        app: efs-app-dy1
    spec:
      containers:
        - name: app
          image: public.ecr.aws/docker/library/centos:centos7.9.2009
          command: ["/bin/sh"]
          args: ["-c", "while true; do echo $(date -u) >> /data/out1; sleep 5; done"]
          volumeMounts:
            - name: persistent-storage
              mountPath: /data
      volumes:
        - name: persistent-storage
          persistentVolumeClaim:
            claimName: efs-claim
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: efs-app-dy2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: efs-app-dy2
  template:
    metadata:
      labels:
        app: efs-app-dy2
    spec:
      containers:
        - name: app
          image: public.ecr.aws/docker/library/centos:centos7.9.2009
          command: ["/bin/sh"]
          args: ["-c", "while true; do echo $(date -u) >> /data/out2; sleep 5; done"]
          volumeMounts:
            - name: persistent-storage
              mountPath: /data
      volumes:
        - name: persistent-storage
          persistentVolumeClaim:
            claimName: efs-claim
' |tee ./dy-pod.yaml

kubectl apply -f dy-storageclass.yaml
kubectl apply -f dy-pod.yaml

```

## check log
```sh
kubectl logs deployment/efs-csi-controller -n kube-system -c efs-plugin
kubectl logs daemonset/efs-csi-node -n kube-system -c efs-plugin

```


## reference
- [Amazon EFS quotas and limits](https://docs.aws.amazon.com/efs/latest/ug/limits.html)

### redeploy deployment and daemonset
```sh
kubectl rollout restart deploy efs-csi-controller -n kube-system
kubectl rollout restart ds efs-csi-node -n kube-system

```



## todo
- [ ] #todo cross vpc efs csi mount


