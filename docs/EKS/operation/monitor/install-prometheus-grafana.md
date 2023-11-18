---
title: install-prometheus-grafana-on-eks
description: 安装 grafana 和 prometheus
created: 2023-02-18 21:31:31.678
last_modified: 2023-11-13
tags:
  - grafana
  - prometheus
  - aws/container/eks
---
> [!WARNING] This is a github note

# install-prometheus-grafana

## prep

- [[../../infra/storage/ebs-for-eks#install-using-eksdemo-]] 

## (Prefer) install-prometheus-operator

- https://blog.devgenius.io/step-by-step-guide-to-setting-up-prometheus-operator-in-your-kubernetes-cluster-7167a8228877

![install-prometheus-grafana-png-1.png](install-prometheus-grafana-png-1.png)

```sh
DEPLOY_NAME=prom-operator-run-abc
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring
helm install ${DEPLOY_NAME} prometheus-community/kube-prometheus-stack --namespace monitoring

```

### forward to local

- port forward to cloud9
```sh
k get svc/${DEPLOY_NAME}-grafana
k port-forward svc/${DEPLOY_NAME}-grafana 3000:80 --address='0.0.0.0'

```

- access from your laptop
```sh
# you need AKSK environment variables
INST_ID=<cloud9_inst_id>
aws ssm start-session --target ${INST_ID} --document-name AWS-StartPortForwardingSession --parameters '{"localPortNumber":["3000"],"portNumber":["3000"]}'

###
# access local 3000 with 
# admin / prom-operator
###

```

### install exporter on 2nd eks cluster

```sh

```


### install with thanos

```sh
helm show values prometheus-community/kube-prometheus-stack > values_default2.yaml

helm install -f values-1.yaml ${DEPLOY_NAME} prometheus-community/kube-prometheus-stack --namespace monitoring

```

- refer: [[thanos/POC-prometheus-ha-architect-with-thanos#go-through-]]

## (Optional) install prometheus and grafana

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

- https://archive.eksworkshop.com/intermediate/240_monitoring/prereqs/



