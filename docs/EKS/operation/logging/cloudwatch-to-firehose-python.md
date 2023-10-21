---
title: "cloudwatch-to-firehose-python"
description: "在 firehose 上，处理从 cloudwatch 发送来的日志"
chapter: true
weight: 3
created: 2022-10-02 11:52:39.497
last_modified: 2022-10-02 11:52:39.497
tags: 
- aws/serverless/lambda
- aws/mgmt/cloudwatch 
- aws/analytics/kinesis/firehose 
- python 
---

# cloudwatch-to-firehose-python

```toc
min_depth: 2
max_depth: 4
```

## create

source from here
1. create from blueprint `Process CloudWatch logs sent to Kinesis Firehose`
```
Process CloudWatch logs sent to Kinesis Firehose

An Amazon Kinesis Firehose stream processor that extracts individual log events from records sent by Cloudwatch Logs subscription filters.

python3.8 · kinesis-firehose · cloudwatch-logs · splunk
```

## revision

![[lambda_function.py]]

download from [here](lambda_function.py)

## 3-party python lib

![[package.zip]]

download from [here](package.zip)

## layer version

- [[lambda-cmd#add layer to lambda]]



