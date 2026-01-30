---
title: aws-msk-managed-kafka
description: aws MSK
created: 2023-06-01 11:41:18.866
last_modified: 2023-10-15 11:41:14.323
tags:
  - aws/analytics/msk
  - aws/NotInCN
---

# msk-managed-kafka

## not in china part

- serverless version not available in china region
    - 26Q1
- ~~msk connect - depend on pca 2023 Q3~~


## 推荐参数

|     | 参数                             | Standard (3-AZ)      | Standard (2-AZ)  | Express (仅 3-AZ) |
| --- | ------------------------------ | -------------------- | ---------------- | ---------------- |
| 1   | min.insync.replicas            | 2 (默认)               | 1 (默认)           | 2 (强制)           |
| 2   | default.replication.factor     | 3 (默认)               | 2 (默认)           | 3 (强制)           |
| 3   | unclean.leader.election.enable | 建议 false (默认true) ⚠️ | true (默认true) ⚠️ | false (强制)       |
| 4   | acks                           | all(3.x 默认)          | all(3.x 默认)      | all(3.x 默认)      |
| 5   | enable.idempotence             | true(3.x 默认)         | true(3.x 默认)     | true(3.x 默认)     |


## 最佳实践

standard broker 
https://docs.aws.amazon.com/msk/latest/developerguide/bestpractices.html

## 容灾

- 直接使用 MSK Replicator  MSK 复制器

推荐博客

| 博客 | 内容简介 | 链接 |
|-----|---------|------|
| Build multi-Region resilient Apache Kafka applications with identical topic names | ⭐ 最详细的容灾指南，介绍如何用 MSK Replicator 实现跨 Region 复制，保持相同 topic 名称，包含完整的 failover/failback 流程 | 链接 (https://aws.amazon.com/blogs/big-data/build-multi-region-resilient-apache-kafka-applications-with-identical-topic-names-using-amazon-msk-and-amazon-msk-replicator) |
| Fitch Group achieves multi-Region resiliency | ⭐ 真实客户案例，Fitch Group（信用评级公司）如何用 MSK Replicator 实现多 Region 容灾 | 链接 (https://aws.amazon.com/blogs/big-data/fitch-group-achieves-multi-region-resiliency-for-mission-critical-kafka-infrastructure-with-amazon-msk-replicator) |
| Amazon MSK Replicator and MirrorMaker2: Choosing the right replication strategy | ⭐ 新博客（2025年9月），对比 MSK Replicator 和 MirrorMaker2 的选择策略 | 链接 (https://aws.amazon.com/blogs/big-data/amazon-msk-replicator-and-mirrormaker2-choosing-the-right-replication-strategy-for-apache-kafka-disaster-recovery-and-migrations) |
| Introducing Amazon MSK Replicator | MSK Replicator 发布公告，介绍基本功能和使用场景 | 链接 (https://aws.amazon.com/blogs/aws/introducing-amazon-msk-replicator-fully-managed-replication-across-msk-clusters-in-same-or-different-aws-regions) |

官方文档

| 文档 | 内容 |
|-----|------|
| Use replication to increase resiliency (https://docs.aws.amazon.com/msk/latest/developerguide/msk-replicator-increase-resiliency.html) | Active-Active / Active-Passive 架构说明 |
| Perform planned failover (https://docs.aws.amazon.com/msk/latest/developerguide/msk-replicator-perform-planned-failover.html) | 计划内切换步骤 |
| Perform unplanned failover (https://docs.aws.amazon.com/msk/latest/developerguide/msk-replicator-perform-unplanned-failover.html) | 非计划切换（灾难恢复）步骤 |
| Perform failback (https://docs.aws.amazon.com/msk/latest/developerguide/msk-replicator-perform-failback.html) | 故障恢复后回切步骤 |


## community

### client download

https://kafka.apache.org/quickstart


## refer

性能测试相关博客推荐

| 博客标题                                                                                                                                                                                                                        | 内容简介                                              |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| Best practices for right-sizing your Apache Kafka clusters to optimize performance and cost (https://aws.amazon.com/blogs/big-data/best-practices-for-right-sizing-your-apache-kafka-clusters-to-optimize-performance-and-cost) | 详细介绍 Kafka 集群性能测试框架、如何正确确定集群规模 |
| Express brokers for Amazon MSK: Turbo-charged Kafka scaling (https://aws.amazon.com/blogs/big-data/express-brokers-for-amazon-msk-turbo-charged-kafka-scaling-with-up-to-20-times-faster-performance/)                          | Express broker 性能对比测试，展示 3x 吞吐量提升       |
| Amazon MSK now provides up to 29% more throughput with Graviton3 (https://aws.amazon.com/blogs/big-data/amazon-msk-now-provides-up-to-29-more-throughput-and-up-to-24-lower-costs-with-aws-graviton3-support)                   | Graviton3 性能基准测试，29% 吞吐量提升                |
| Benchmarking Apache Kafka on MSK, EC2, Kubernetes (https://mraniketr.medium.com/benchmarking-apache-kafka-on-msk-ec2-kubernetes-c26925339f67)                                                                                   | 多平台 Kafka 性能对比基准测试                         |
| Load testing AWS MSK with xk6-kafka (https://mostafa.dev/load-testing-aws-msk-7c92ba036f64)                                                                                                                                     | 使用 k6 进行 MSK 负载测试实践                         |


- [[Split your monolithic Apache Kafka clusters using Amazon MSK Serverless]] 

- mysql-msk-redshift
    - https://aws.amazon.com/blogs/big-data/break-data-silos-and-stream-your-cdc-data-with-amazon-redshift-streaming-and-amazon-msk/


官方文档

- Best practices for Standard brokers (https://docs.aws.amazon.com/msk/latest/developerguide/bestpractices.html) - 官方最佳实践指南
- Amazon MSK Express brokers (https://docs.aws.amazon.com/msk/latest/developerguide/msk-broker-types-express.html) - Express broker 详细文档


- [aws-msk-kafka-streams-guide](aws-msk-kafka-streams-guide.md) 



