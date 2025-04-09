---
title: cloudwatch-to-firehose-python
description: 在 firehose 上，处理从 cloudwatch 发送来的日志
created: 2022-10-02 11:52:39.497
last_modified: 2023-12-31
tags:
  - aws/serverless/lambda
  - aws/mgmt/cloudwatch
  - aws/analytics/kinesis/firehose
  - python
---
# cloudwatch-to-firehose-python

## create

source from here
1. create from blueprint `Process CloudWatch logs sent to Kinesis Firehose`
```
Process CloudWatch logs sent to Kinesis Firehose

An Amazon Kinesis Firehose stream processor that extracts individual log events from records sent by Cloudwatch Logs subscription filters.

python3.8 · kinesis-firehose · cloudwatch-logs · splunk
```

## revision
download [[attachments/stream-k8s-control-panel-logs-to-s3/lambda_function.py|lambda_function]]

## 3-party python lib
download from [[attachments/stream-k8s-control-panel-logs-to-s3/package.zip]]

## layer version
- [[../../../CLI/awscli/lambda-cmd#add-layer-to-lambda-]]




