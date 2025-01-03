---
title: AWS Opensearch / Elasticsearch Migration
description: 使用 snapshot 迁移 elasticsearch
created: 2024-12-28 16:56:47.742
last_modified: 2025-01-02
status: myblog
tags:
  - aws/analytics/opensearch
---

# aos-migration

## snapshot
- create role-a aos-mig-role, see detail in refer chapter
- ad `iam:PassRole` to role-b
- (only for kibana) add role-b (using by awscurl) to opensearch --> security --> role --> all_access --> mapped users
- 增量做快照，恢复时候指定最新快照名，全量恢复
- refer: https://docs.amazonaws.cn/opensearch-service/latest/developerguide/managedomains-snapshots.html
### es 7.10 snapshot
- only could use iam role in cli to execute awscurl 
- create snapshot repo
```sh
DOMAIN_NAME=vpc-src2-xxx.ap-southeast-1.es.amazonaws.com
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

```
- do snapshot
```sh
awscurl -XPUT --service es --region ap-southeast-1 https://${DOMAIN_NAME}/_snapshot/snapshot-repo-1/snapshot-1

```
- get snapshot
```sh
awscurl -XGET --service es --region ap-southeast-1 https://${DOMAIN_NAME}/_snapshot/_status

awscurl -XGET --service es --region ap-southeast-1 https://${DOMAIN_NAME}/_snapshot/snapshot-repo-1/_all?pretty

```

### es 7.10 restore
- (option) put role/user to all_access
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
-d '{"indices": "-.kibana_1"}' \
-H 'Content-Type: application/json'

```

### es 6.8 snapshot
- could use iam role / user in cli to execute awscurl 
- follow steps in es 7.10
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

### error
- 创建 opensearch repo 只能使用本 region 的 s3 桶

- 使用 curl 用 admin 登录，只能做查询，无法创建 repo，需要使用 awscurl
```
{"Message":"User: anonymous is not authorized to perform: iam:PassRole on resource: arn:aws:iam::123456789012:role/aos-mig-role because no resource-based policy allows the iam:PassRole action"}

```

- iam user could not access ES cluster 7.10 directly, assume to another iam role 
```
{
  "error" : {
    "root_cause" : [
      {
        "type" : "security_exception",
        "reason" : "no permissions for [cluster:admin/repository/get] and User [name=arn:aws:iam::123456789012:user/panlm, backend_roles=[], requestedTenant=null]"
      }
    ],
    "type" : "security_exception",
    "reason" : "no permissions for [cluster:admin/repository/get] and User [name=arn:aws:iam::123456789012:user/panlm, backend_roles=[], requestedTenant=null]"
  },
  "status" : 403
}
```


## replication
- refer: https://docs.aws.amazon.com/opensearch-service/latest/developerguide/replication.html
- 增量复制
- create connection from target, approve connection in source

```sh
DOMAIN_NAME=
INDEX_NAME=leader-99
CONNECTION_NAME=src2-target-test
awscurl -XPUT --service es --region ap-southeast-1 "https://${DOMAIN_NAME}/_plugins/_replication/${INDEX_NAME}/_start" -H 'Content-Type: application/json' -d ' 
{
  "leader_alias": "'"${CONNECTION_NAME}"'",
  "leader_index": "'"${INDEX_NAME}"'",
  "use_roles":{
    "leader_cluster_role": "all_access",
    "follower_cluster_role": "all_access"
  }
}'

awscurl -XGET --service es --region ap-southeast-1 "https://${DOMAIN_NAME}/_plugins/_replication/${INDEX_NAME}/_status?pretty"

awscurl -XGET --service es --region ap-southeast-1 "https://${DOMAIN_NAME}/${INDEX_NAME}/_search?pretty"

```



