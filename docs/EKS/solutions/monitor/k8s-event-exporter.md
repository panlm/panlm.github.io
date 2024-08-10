---
title: kubernetes events exporter
description: 
created: 2022-10-31 19:46:08.588
last_modified: 2024-08-06
tags:
  - kubernetes
  - aws-containers-summit-2022q4
  - aws/container/eks
---

# kubernetes events exporter
https://github.com/resmoio/kubernetes-event-exporter

## intro
- event routing & filter
- multiple receivers
- payload customization

![[attachments/k8s-event-exporter/IMG-k8s-event-exporter.png]]

![[attachments/k8s-event-exporter/IMG-k8s-event-exporter-2.png]]

## walkthrough
- send log to loki
```sh
--- a/deploy/01-config.yaml
+++ b/deploy/01-config.yaml
@@ -5,13 +5,20 @@ metadata:
   namespace: monitoring
 data:
   config.yaml: |
-    logLevel: warn
+    logLevel: info
     logFormat: json
     metricsNamePrefix: event_exporter_
     route:
       routes:
         - match:
             - receiver: "dump"
+        - match:
+            - receiver: "loki"
     receivers:
       - name: "dump"
-        stdout: {}
\ No newline at end of file
+        stdout: {}
+      - name: "loki"
+        loki:
+          streamLabels:
+            foo: bar
+          url: http://loki-gateway.loki.svc.cluster.local/loki/api/v1/push
\ No newline at end of file

```

- using grafana dashboard 17882
- install using [Bitnami Chart](https://github.com/bitnami/charts/tree/main/bitnami/kubernetes-event-exporter/) and following values 
```yaml
...
config:
  logLevel: debug
  logFormat: json # pretty
  receivers:
    - name: "dump"
      file:
        path: "/dev/stdout"
        ## Example:
        layout:
          message: "{{ .Message }}"
          reason: "{{ .Reason }}"
          type: "{{ .Type }}"
          count: "{{ .Count }}"
          kind: "{{ .InvolvedObject.Kind }}"
          name: "{{ .InvolvedObject.Name }}"
          namespace: "{{ .Namespace }}"
          component: "{{ .Source.Component }}"
          host: "{{ .Source.Host }}"
        ##
        # layout: {}
  route:
    routes:
      - match:
          - receiver: "dump"
...
```


