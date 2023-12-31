---
title: cloudwatch
description: 常用命令
created: 2022-08-18 21:42:04.979
last_modified: 2023-10-25 08:03:10.232
tags:
  - aws/mgmt/cloudwatch
---
> [!WARNING] This is a github note

# cloudwatch-cmd


## log group and log stream
### create log group

```sh
LOGGROUP_NAME=apigw-access-log
aws logs create-log-group \
--log-group-name ${LOGGROUP_NAME}
LOGGROUP_ARN=$(aws logs describe-log-groups \
--log-group-name-prefix ${LOGGROUP_NAME} \
--query 'logGroups[0].arn' --output text)
LOGGROUP_ARN=${LOGGROUP_ARN%:*}

```

### describe log stream

```sh
aws logs describe-log-streams \
  --log-group-name /aws/eks/ekscluster1/cluster \
  --log-stream-name-prefix kube-apiserver-audit- \
  |jq -r '.logStreams[] | (.creationTime, .logStreamName )' \
  |xargs -n 2 |sort -r |sed -n '2,$p' |awk '{print $NF}'

```

### delete log stream

```sh
aws logs delete-log-stream \
  --log-group-name /aws/eks/ekscluster1/cluster \
  --log-stream-name kube-apiserver-audit-c26edac46f343347e73694744d70ab2a
  
```

## check log size

**IncomingBytes**
refer: [Which Log Group is causing a sudden increase in my CloudWatch Logs bill?](https://aws.amazon.com/premiumsupport/knowledge-center/cloudwatch-logs-bill-increase/)

```sh
aws cloudwatch get-metric-statistics \
  --metric-name IncomingBytes \
  --start-time 2022-08-13T00:00:00Z --end-time 2022-08-18T23:59:59Z \
  --period 2592000 \
  --namespace AWS/Logs --statistics Sum --region us-east-2

```

```sh
# period = 30 days
aws cloudwatch get-metric-statistics \
  --metric-name IncomingBytes \
  --start-time 2022-08-13T00:00:00Z --end-time 2022-08-18T23:59:59Z \
  --period 2592000 \
  --namespace AWS/Logs --statistics Sum --region us-east-2 \
  --dimensions Name=LogGroupName,Value=/aws/eks/ekscluster1/cluster

```

## export task

- [[../../EKS/solutions/logging/export-cloudwatch-log-group-to-s3]]

## subscription firehose

- [[../../EKS/solutions/logging/stream-k8s-control-panel-logs-to-s3]]

## log-insights

- [[cloudwatch-logs-insights]]




## metric

```
SELECT AVG(WriteIOPS) FROM SCHEMA("AWS/ES", ClientId,DomainName,NodeId) WHERE DomainName = 'myaos-20221210-130610' GROUP BY NodeId, DomainName

{
    "metrics": [
        [ { "expression": "SEARCH('{AWS/ES,ClientId,DomainName,NodeId} MetricName=ReadIOPS', 'Average', 300)", "id": "e1", "period": 300 } ],
        [ { "expression": "SEARCH('{AWS/ES,ClientId,DomainName,NodeId} MetricName=WriteIOPS', 'Average', 300)", "id": "e2", "period": 300 } ]
    ],
    "view": "timeSeries",
    "stacked": false,
    "region": "us-east-2",
    "stat": "Average",
    "period": 300
}

```


## add alarm

```sh
account_id=2086xxxx7602
opensearch_name=opensearch-uez6sk9a

aws cloudwatch put-metric-alarm \
--alarm-name ClusterStatus-red-abcd \
--evaluation-periods 5 \
--comparison-operator GreaterThanOrEqualToThreshold \
--alarm-description "OS cluster status red greater than 1 minute" \
--metric-name ClusterStatus.red \
--namespace AWS/ES \
--statistic Average \
--period 60 \
--threshold 1 \
--treat-missing-data missing \
--dimensions Name=ClientId,Value=${account_id} Name=DomainName,Value=${opensearch_name}


```


