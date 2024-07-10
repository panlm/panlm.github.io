---
title: web-press-testing-tool
description: 
created: 2022-10-01 08:27:42.926
last_modified: 2024-07-04
tags:
  - cmd
  - linux
---
# web-press-testing-tool

## ab
```sh
sudo yum install httpd-tools

ab -kc 150 -t 600 http://k8s-loki-lokiloki-6ece7e0eb3-1692301772.us-east-1.elb.amazonaws.com

while true ; do ab -kc 250 -t 3600 -n 1000000 http://k8s-loki-lokigate-42e5f864af-1843259072.us-east-1.elb.amazonaws.com/ ; done

```

## hey
```sh
wget https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
curl -L -o hey https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64
```

## httpie

## httpload 

## k6
k6 is a load testing suite that allows you to synthetically load and monitor your application. For more details about k6, read the [documentation](https://k6.io/docs/).

## Locust.io
- Locust.io

## distributed load test on aws
- [[Distributed Load Testing on AWS]]


## siege


## wrk
- https://github.com/wg/wrk




