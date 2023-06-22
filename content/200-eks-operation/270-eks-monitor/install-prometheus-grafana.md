---
title: install-prometheus-grafana-on-eks
description: "安装 grafana 和 prometheus"
chapter: true
created: 2023-02-18 21:31:31.678
last_modified: 2023-02-18 21:31:31.678
tags: 
- grafana 
- prometheus 
- aws/container/eks 
---

```ad-attention
title: This is a github note

```

# install-prometheus-grafana

- [prep](#prep)
- [install-prometheus-operator (prefer)](#install-prometheus-operator-prefer)
	- [forward to local](#forward-to-local)
- [install prometheus and grafana (optional)](#install-prometheus-and-grafana-optional)
- [refer](#refer)

## prep

- [[ebs-for-eks]]  or huge link: [ebs-for-eks.md]({{< ref "ebs-for-eks.md" >}}) 

## install-prometheus-operator (prefer)
[link](https://blog.devgenius.io/step-by-step-guide-to-setting-up-prometheus-operator-in-your-kubernetes-cluster-7167a8228877)

![install-prometheus-grafana-png-1.png](install-prometheus-grafana-png-1.png)

```sh
DEPLOY_NAME=prom-operator-run-abc
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install ${DEPLOY_NAME} prometheus-community/kube-prometheus-stack

```

### forward to local
```sh
k get svc/${DEPLOY_NAME}-grafana
k port-forward svc/${DEPLOY_NAME}-grafana 3000:80

INST_ID=<cloud9_inst_id>
aws ssm start-session --target ${INST_ID} --document-name AWS-StartPortForwardingSession --parameters '{"localPortNumber":["3000"],"portNumber":["3000"]}'

###
# access local 3000 with 
# admin / prom-operator
###

```


## install prometheus and grafana (optional)
- install prometheus
```sh
kubectl create namespace prometheus

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm install prometheus prometheus-community/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="gp2" \
    --set server.persistentVolume.storageClass="gp2"

kubectl get all -n prometheus

```

- install grafana
```sh
cat > ./grafana.yaml <<-EOF
datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server.prometheus.svc.cluster.local
      access: proxy
      isDefault: true
EOF

helm repo add grafana https://grafana.github.io/helm-charts
kubectl create namespace grafana
helm install grafana grafana/grafana \
    --namespace grafana \
    --set persistence.storageClassName="gp2" \
    --set persistence.enabled=true \
    --set adminPassword='EKS!sAWSome' \
    --values ./grafana.yaml \
    --set service.type=LoadBalancer
kubectl get all -n grafana

```

- dashboard
	- cluster monitoring dashboard: **3119**
	- pod monitoring dashboard: **6417**


## refer
[link](https://archive.eksworkshop.com/intermediate/240_monitoring/prereqs/) 



