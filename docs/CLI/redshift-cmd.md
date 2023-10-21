---
title: redshift
created: 2022-11-23 23:18:21.581
last_modified: 2023-10-21 11:21:12.123
tags:
  - aws/database/redshift
---

```ad-attention
title: This is a github note
```

# redshift-cmd


## setup

![[git/git-mkdocs/data-analytics/redshift-data-api-lab#初始化-redshift-集群-]]

refer: [[git/git-mkdocs/data-analytics/redshift-data-api-lab#初始化-redshift-集群-]]

## unload

- https://docs.aws.amazon.com/zh_cn/redshift/latest/dg/t_unloading_encrypted_files.html 
- https://hevodata.com/learn/redshift-unload-command-usage-and-examples/#r2

CSE:
```sh
echo 01234567890123456789012345678901 |base64
```

```output
MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDEK
```

```sql
unload ('select * from dev.public.customer')
to 's3://template1-rs3bucket-1bor4w2qr4rti/unload_encrypted/'
iam_role 'arn:aws:iam::012345678901:role/RedshiftImmersionRole'
master_symmetric_key 'MDEyMzQ1Njc4OTAxMjM0NTY3ODkwMTIzNDU2Nzg5MDEK'
encrypted;
```

SSE:
```sql

```

## create database
```sql
create database lab798

```

## create table
```
create table table_utf8(
col1 integer not null,
col2 varchar(100) not null ,
col3 varchar(100) not null
);

insert into table_utf8 values
(  1,'中文1','中文2'),
(  2,'中文1','中文2'),
(  3,'中文1','中文2');

```

## others

- https://github.com/awslabs/amazon-redshift-utils/tree/master/src/UnloadCopyUtility

## create cluster

```sh
aws redshift create-cluster \
--cluster-identifier my-redshift-cluster \
--node-type dc2.large \
--master-username myadmin \
--master-user-password passworD.1 \
--number-of-nodes 3 

```



