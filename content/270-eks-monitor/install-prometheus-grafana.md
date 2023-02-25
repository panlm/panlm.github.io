---
title: install-prometheus-grafana
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
[link](https://archive.eksworkshop.com/intermediate/240_monitoring/prereqs/) 

## prep
- [[ebs-for-eks]]  or
- [ebs-for-eks.md]({{< ref "ebs-for-eks.md" >}}) 


## install prometheus
```sh
kubectl create namespace prometheus

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

helm install prometheus prometheus-community/prometheus \
    --namespace prometheus \
    --set alertmanager.persistentVolume.storageClass="gp2" \
    --set server.persistentVolume.storageClass="gp2"

kubectl get all -n prometheus

```

## install grafana
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





