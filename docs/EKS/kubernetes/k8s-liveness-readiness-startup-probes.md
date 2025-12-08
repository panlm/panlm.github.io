---
title: k8s-liveness-readiness-startup-probes
description: Liveness probes, readiness probes and startup probes
created: 2024-05-07 10:22:26.304
last_modified: 2024-05-07
tags:
  - kubernetes
---

# k8s-liveness-readiness-startup-probes

**readiness probe** - This is simply a signal to inform Kubernetes when to <mark style="background: #BBFABBA6;">put this pod behind the load balancer</mark> and when to put this service behind the proxy to serve traffic. If you put an application behind the load balancer before it’s ready, then a user can reach this pod but won’t get the expected response of a healthy server.

**liveness probe** - The liveness probe let’s Kubernetes know if the pod is in a healthy state. If it isn’t healthy, then Kubernetes should <mark style="background: #BBFABBA6;">restart</mark> it.

**startup probes** - The kubelet uses startup probes to know when a container application has started. If such a probe is configured, <mark style="background: #BBFABBA6;">liveness and readiness probes do not start until it succeeds</mark>, making sure those probes don't interfere with the application startup. This can be used to adopt liveness checks on <mark style="background: #BBFABBA6;">slow starting containers</mark>, avoiding them getting killed by the kubelet before they are up and running.

## verify
- create deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: init-container
          image: busybox
          command: 
            - 'sh'
            - '-c'
            - |
              echo "Hello World" > /usr/share/nginx/html/index.html
              echo "Hello liveness" > /usr/share/nginx/html/liveness.html
              echo "Hello readiness" > /usr/share/nginx/html/readiness.html
              echo "Hello startup" > /usr/share/nginx/html/startup.html
              echo "Hello ELB" > /usr/share/nginx/html/elbcheck.html
              while true ; do sleep 60; echo ===; done
          volumeMounts:
          - name: nginx-html
            mountPath: /usr/share/nginx/html
        - name: nginx
          image: nginx:latest
          ports:
            - containerPort: 80
          volumeMounts:
            - name: nginx-html
              mountPath: /usr/share/nginx/html
          startupProbe:
            httpGet:
              path: /startup.html
              port: 80
            initialDelaySeconds: 2
            periodSeconds: 2
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /readiness.html
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 10
            failureThreshold: 1
          livenessProbe:
            httpGet:
              path: /liveness.html
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 15
            failureThreshold: 1
      volumes:
        - name: nginx-html
          emptyDir: {}

```
- ELB / startup / liveness / readiness probe 分别检查不同的 html

### startup failed
- 启动 probe 在 pod 正常启动后失效，不再检查
- 除非 liveness 检查失效，container 被重启后，才会再次 check

### liveness failed
- nginx container 重启
- init container 未重启
- ip address 不变

### readiness failed
- remove from service / ELB
- nginx container 未重启
- init container 未重启
- ip address 不变


## 结论
- startup probe 用于慢速容器启动检查
- readiness probe 检查基本雷同与 ELB 自带的健康检查，区别在于 readiness 检查由 kubelet 发起，在节点本地完成；ELB 的健康检查通过网络完成。使用其一即可
- liveness probe 是唯一检查失败后会重启容器，如果 pod 有多个容器，则只检查启用了该 probe 的 container。pod 地址保持不变。
- 场景1：ELB + liveness
    - ELB 检查失效 小于 liveness 检查失效
        - 允许服务临时不可用，ELB 检查失败将不再将流量转到该 POD。POD 在 liveness 检查失效前如果能回复，则自动加回（满足 ELB 检查成功）
    - ELB 检查失效 大于 liveness 检查失效
        - 服务将被重启
-  pod readiness gate 功能在 1.29 集群中未表现为加快 pod 注册到 ELB
    - 在 namespace 层面添加标签后，还需要额外配置 `objectSelector` 才能正常抓取到 default namespace 中的 POD

## prestop-hook-

![[attachments/k8s-liveness-readiness-startup-probes/IMG-k8s-liveness-readiness-startup-probes.png]]
- blog: [[../../../../WebClip/How to rapidly scale your application with ALB on EKS without losing traffic|How to rapidly scale your application with ALB on EKS without losing traffic]]
- blog: https://aws.amazon.com/ko/blogs/tech/case-study-lotteon-running-on-amazon-eks/


## refer
- https://aws.amazon.com/blogs/containers/preventing-kubernetes-misconfigurations-using-datree/
- https://www.datree.io/resources/kubernetes-readiness-and-liveness-probes-best-practices
- https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/
- https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.7/deploy/pod_readiness_gate/



