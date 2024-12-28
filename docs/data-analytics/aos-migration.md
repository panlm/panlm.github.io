---
title: aos-migration
description: 使用 snapshot 迁移 elasticsearch
created: 2024-12-28 16:56:47.742
last_modified: 2024-12-28
tags:
  - aws/analytics/opensearch
---

# aos-migration
- create aos-mig-role, see detail in refer chapter
- put role (using by awscurl) to opensearch --> security --> role --> all_access --> mapping user/role, 

## es 7.10 snapshot
- create snapshot repo
```sh
awscurl -XPUT --service es --region ap-southeast-1 https://vpc-src2-xxx.ap-southeast-1.es.amazonaws.com/_snapshot/snapshot-repo-1 -H 'Content-Type: application/json' -d ' 
{
  "type": "s3",
  "settings": {
    "bucket": "aos-mig-20241226",
    "base_path": "snapshot",
    "region": "ap-southeast-1",
    "role_arn": "arn:aws:iam::123456789012:role/aos-mig-role"
  }
}'
```
- do snapshot
```sh
awscurl -XPUT --service es --region ap-southeast-1 https://vpc-src2-xxx.ap-southeast-1.es.amazonaws.com/_snapshot/snapshot-repo-1/snapshot-1

```
- get snapshot
```sh
awscurl -XGET --service es --region ap-southeast-1 https://vpc-src2-xxx.ap-southeast-1.es.amazonaws.com/_snapshot/_status

awscurl -XGET --service es --region ap-southeast-1 https://vpc-src2-xxx.ap-southeast-1.es.amazonaws.com/_snapshot/snapshot-repo-1/_all?pretty

```

## es 7.10 restore
- put role/user to all_access
- create repo
```sh
DOMAIN_NAME=vpc-target2-xxx.ap-southeast-1.es.amazonaws.com
awscurl -XPUT --service es --region ap-southeast-1 https://${DOMAIN_NAME}/_snapshot/snapshot-repo-1 -H 'Content-Type: application/json' -d ' 
{
  "type": "s3",
  "settings": {
    "bucket": "aos-mig-20241226",
    "base_path": "snapshot",
    "region": "ap-southeast-1",
    "role_arn": "arn:aws:iam::123456789012:role/aos-mig-role"
  }
}'

awscurl -XGET --service es --region ap-southeast-1 "https://${DOMAIN_NAME}/_snapshot/snapshot-repo-1/_all?pretty"

awscurl -XGET --service es --region ap-southeast-1 "https://${DOMAIN_NAME}/_snapshot?pretty"

```
- get all indice and delete one of them
```sh
# get all indice
awscurl -XGET --service es --region ap-southeast-1 "https://${DOMAIN_NAME}/_all"
# delete one of them 
awscurl -XDELETE --service es --region ap-southeast-1 "https://${DOMAIN_NAME}/.kibana_1"

```
- restore
```sh
awscurl -XPOST --service es --region ap-southeast-1 "https://${DOMAIN_NAME}/_snapshot/snapshot-repo-1/snapshot-1/_restore" \
-d '{"indices": ".kibana_1"}' \
-H 'Content-Type: application/json'

```

## es 6.8 snapshot
- it works in es 6.8
```sh
DOMAIN_NAME=vpc-src1-xxx.ap-southeast-1.es.amazonaws.com

awscurl -XPUT --service es --region ap-southeast-1 http://${DOMAIN_NAME}/_snapshot/snapshot-repo-1 -H 'Content-Type: application/json' -d ' 
{
  "type": "s3",
  "settings": {
    "bucket": "aos-mig-20241226",
    "base_path": "snapshot-src1",
    "region": "ap-southeast-1",
    "role_arn": "arn:aws:iam::123456789012:role/aos-mig-role"
  }
}'

```

## error
- 使用 curl 用 admin 登录，只能做查询，无法创建 repo，需要使用 awscurl
```
{"Message":"User: anonymous is not authorized to perform: iam:PassRole on resource: arn:aws:iam::123456789012:role/aos-mig-role because no resource-based policy allows the iam:PassRole action"}

```

## refer
https://docs.amazonaws.cn/opensearch-service/latest/developerguide/managedomains-snapshots.html


