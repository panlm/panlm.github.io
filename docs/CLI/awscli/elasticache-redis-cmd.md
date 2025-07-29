---
title: elasticache-redis
description: 常用命令
created: 2022-12-02 19:04:02.899
last_modified: 2024-04-15
tags:
  - aws/database/elasticache/redis
  - aws/cmd
---
# elasticache-redis-cmd
## create 6.2 in default vpc - cluster mode disabled

```sh

# aws elasticache create-cache-parameter-group \
#    --cache-parameter-group-family "redis6.x" \
#    --cache-parameter-group-name "myparamgrp6" \
#    --description "myparamgrp6"

aws elasticache create-cache-cluster \
    --cache-cluster-id my-cluster2 \
    --cache-node-type cache.r5.large \
    --engine redis \
    --engine-version 6.2 \
    --num-cache-nodes 1 \
    --cache-parameter-group default.redis6.x 

```

## create 6.2 - cluster mode enabled
```sh
aws elasticache create-replication-group \
    --replication-group-id "mygroup"-$(date +%Y%m%d-%H%M) \
    --replication-group-description "my group" \
    --engine "redis" \
    --engine-version 6.2 \
    --num-node-groups 3 \
    --cache-node-type "cache.m5.large"

```

## connect
- [[memorydb-redis-performance-testing#connect-]]

## install redis-cli
- http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/GettingStarted.ConnectToCacheNode.Redis.html
```sh
sudo yum install gcc # This may return an "already installed" message. That's OK.
sudo yum groupinstall -y 'Development Tools'

wget http://download.redis.io/redis-stable.tar.gz && tar xvzf redis-stable.tar.gz
cd redis-stable
make BUILD_TLS=yes MALLOC=libc

```





