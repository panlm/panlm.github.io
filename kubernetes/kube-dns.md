
# create pods and connect each other with dns name

```yml
apiVersion: v1
kind: Service
metadata:
  name: default-subdomain
spec:
  selector:
    name: busybox
  clusterIP: None
  ports:
  - name: foo # Actually, no port is needed.
    port: 1234
    targetPort: 1234
---
apiVersion: v1
kind: Pod
metadata:
  name: busybox-0
  labels:
    name: busybox
spec:
  hostname: busybox-0
  subdomain: default-subdomain
  containers:
  - image: busybox
    command:
      - sleep
      - "3600"
    name: busybox
---
apiVersion: v1
kind: Pod
metadata:
  name: busybox-1
  labels:
    name: busybox
spec:
  hostname: busybox-1
  subdomain: default-subdomain
  containers:
  - image: busybox
    command:
      - sleep
      - "3600"
    name: busybox
```

```bash
kubectl exec -it busybox-0 /bin/sh
echo $HOSTNAME
ping busybox-1.default-subdomain.default.svc.cluster.local
```

  also you could resolve domain name if you on node and point dns server to kube-dns internal address (10.200.0.2)

you could resolv ip address as follow in nslookup:<br/>
``` 10-200-0-2.default.pod.cluster.local ```




