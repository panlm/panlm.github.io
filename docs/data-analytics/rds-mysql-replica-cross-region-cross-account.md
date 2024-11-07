---
title: rds-mysql-replica-cross-region-cross-account
description: 用于 1) 跨账号复制 RDS 数据库; 2) 或者将数据库转换成加密存储
created: 2022-10-11 20:25:32.965
last_modified: 2023-10-21 11:17:42.435
tags:
  - aws/database/rds
---

# rds-mysql-replica-cross-region-cross-account

## 概述

本地 RDS-A ，希望能创建一个跨账号的 RDS-B 作为读副本
- 先创建 RDS-A
- 创建本地 Replica
- 快照该 Replica
- 共享快照到另一个账号
- 在另一个账号中将快照复制一份
    - 此时可以使用kms，如果源库没有加密
- 从复制出来的快照恢复数据库

### 场景

- 跨账号创建读副本的 rds 数据库
- 将未加密数据库转换成加密存储

## create rds mysql 
### prep-

- 准备测试环境，建议使用 cloud9 进行操作，并且安装下面软件
- 如果跨账号复制的测试环境，你需要同样的 cloud9 在另一个环境中，并且安装下面软件
```sh
sudo yum install -y jq 
sudo rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7.rpm # for amazon linux 2, mysql80-community-release-el9.rpm for amazon linux 2023
sudo yum install -y mysql-community-client --enablerepo=mysql80-community

export AWS_PAGER=""
```

^z60dbq

- 获取 cloud9 所在子网，测试会使用该网络
```sh
# cloud 9 subnet
RDS_NAME=db1
INST_ID=$(curl http://169.254.169.254/1.0/meta-data/instance-id 2>/dev/null)
VPC_ID=$(aws ec2 describe-instances --instance-ids ${INST_ID} --query 'Reservations[0].Instances[0].VpcId' --output text)
AWS_REGION=$(curl 2>/dev/null http://169.254.169.254/latest/dynamic/instance-identity/document |jq -r '.region')

```

### subnet-group-

- 如果跨账号复制的测试环境，该步骤需要在另一个账号中被重复执行
```sh
SG_NAME=${RDS_NAME}-${RANDOM}
aws ec2 create-security-group  \
  --description ${SG_NAME}     \
  --group-name ${SG_NAME}      \
  --vpc-id ${VPC_ID}

RDS_SG=$(aws ec2 describe-security-groups      \
  --filters Name=group-name,Values=${SG_NAME}         \
            Name=vpc-id,Values=${VPC_ID}              \
  --query "SecurityGroups[0].GroupId" --output text)

echo "RDS security group ID: ${RDS_SG}"

aws ec2 authorize-security-group-ingress  \
  --group-id ${RDS_SG}                    \
  --protocol tcp                          \
  --port 3306                             \
  --cidr '0.0.0.0/0'

PUBLIC_SUBNETS_ID=$(aws ec2 describe-subnets        \
  --filters "Name=vpc-id,Values=$VPC_ID"                   \
  --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' \
  --output json | jq -c .)

# create a db subnet group
aws rds create-db-subnet-group               \
  --db-subnet-group-name ${RDS_NAME}         \
  --db-subnet-group-description ${RDS_NAME}  \
  --subnet-ids ${PUBLIC_SUBNETS_ID} 

```

^rav4er

### create rds mysql (cont.)

- 创建 rds 数据库
- 密码保存在 `~/rds_password` 中
```sh
# generate a password for RDS
export RDS_PASSWORD="$(date | md5sum  |cut -f1 -d' ')"
echo ${RDS_PASSWORD}  > ~/rds_password

# install supported oldest mysql version 
ENGINE_VER=$(aws rds describe-db-engine-versions --engine mysql --query "DBEngineVersions[].EngineVersion" |grep -Eo '5\.7\.[0-9]+' |sort |head -n 1)

# create RDS MySQL instance
# INSTANCE_TYPE=db.m5.xlarge
# STORAGE_SIZE=5000
aws rds create-db-instance                          \
  --db-instance-identifier ${RDS_NAME}              \
  --db-name ${RDS_NAME}                             \
  --db-instance-class ${INSTANCE_TYPE:-db.m5.large} \
  --engine mysql                                    \
  --engine-version ${ENGINE_VER}                    \
  --db-subnet-group-name ${RDS_NAME}                \
  --vpc-security-group-ids ${RDS_SG}                \
  --master-username ${RDS_NAME}                     \
  --publicly-accessible                             \
  --master-user-password ${RDS_PASSWORD}            \
  --backup-retention-period 1                       \
  --allocated-storage ${STORAGE_SIZE:-50} 

# --storage-encrypted

# get rds status util `available`
status=""
until [[ ${status} == "available" ]]; do
status=$(aws rds describe-db-instances       \
  --db-instance-identifier ${RDS_NAME}       \
  --query "DBInstances[].DBInstanceStatus"   \
  --output text)
echo ${status}
sleep 60
done

RDS_HOSTNAME=$(aws rds describe-db-instances    \
  --db-instance-identifier ${RDS_NAME}     \
  --query "DBInstances[].Endpoint.Address"    \
  --output text)

RDS_ARN=$(aws rds describe-db-instances    \
  --db-instance-identifier ${RDS_NAME}     \
  --query "DBInstances[].DBInstanceArn"    \
  --output text)

```

## create read replica

- 创建读副本
```sh
RDS_REP1_NAME=${RDS_NAME}-rep1 

# # enable auto backup if you miss it in creation
# aws rds modify-db-instance \
#   --db-instance-identifier ${RDS_NAME} \
#   --backup-retention-period 1  \
#   --apply-immediately

# create read replica
aws rds create-db-instance-read-replica \
  --db-instance-identifier ${RDS_REP1_NAME} \
  --region ${AWS_REGION} \
  --source-region ${AWS_REGION} \
  --source-db-instance-identifier ${RDS_ARN}

# get rds status util `available`
status=""
until [[ ${status} == "available" ]]; do
status=$(aws rds describe-db-instances            \
  --db-instance-identifier ${RDS_REP1_NAME}       \
  --query "DBInstances[].DBInstanceStatus"        \
  --output text)
echo ${status}
sleep 60
done

RDS_REP1_HOSTNAME=$(aws rds describe-db-instances    \
  --db-instance-identifier ${RDS_REP1_NAME}     \
  --query "DBInstances[].Endpoint.Address"    \
  --output text)

```

### on master

- 在主库中创建复制用户
- 配置 binlog 的保留周期，需要在此期间完成远程读副本创建并且恢复复制
```sh
echo mysql -h${RDS_HOSTNAME} -u${RDS_NAME} -p${RDS_PASSWORD}
```

```sql
call mysql.rds_set_configuration('binlog retention hours', 24);
CREATE USER 'repl_user'@'%' IDENTIFIED BY 'repl_password';
GRANT REPLICATION CLIENT, REPLICATION SLAVE ON *.* TO 'repl_user'@'%';

```

^gycsd4

### on slave

```sh
echo mysql -h${RDS_REP1_HOSTNAME} -u${RDS_NAME} -p${RDS_PASSWORD}
```

- 检查复制状态
```sql
SHOW SLAVE STATUS\G
```

- 当下面值为 0 时，可以中断复制
> Seconds_Behind_Master: 0

```sql
call mysql.rds_stop_replication();
SHOW SLAVE STATUS\G
```

- 中断复制，并且记录断点，在后续恢复复制时使用

> Relay_Master_Log_File: mysql-bin-changelog.000009
> Exec_Master_Log_Pos: 154

^gjmipb

## create snapshot on replica

- 创建快照
```sh
RDS_REP1_SNAP_NAME=${RDS_REP1_NAME}-snap-1
aws rds create-db-snapshot \
--db-snapshot-identifier ${RDS_REP1_SNAP_NAME} \
--db-instance-identifier ${RDS_REP1_NAME}

SHARED_SNAP_ARN=$(aws rds describe-db-snapshots \
--db-snapshot-identifier ${RDS_REP1_SNAP_NAME} \
--query 'DBSnapshots[].DBSnapshotArn' \
--output text)

echo "SHARED_SNAP_ARN=${SHARED_SNAP_ARN}"

# get snapshot status util `available`
while true ; do
status=$(aws rds describe-db-snapshots \
--db-snapshot-identifier ${RDS_REP1_SNAP_NAME} \
--query 'DBSnapshots[].Status' \
--output text)
echo $status
if [[ $status == "available" ]]; then
  break
fi
sleep 60
done

```

## share snapshot

- 跨账号共享快照
- 输入目标账号 ID
```sh
aws rds modify-db-snapshot-attribute \
    --db-snapshot-identifier ${RDS_REP1_SNAP_NAME} \
    --attribute-name restore \
    --values-to-add <target_account_id>

```

## copy snapshot local

- 如果是跨账号复制，则该步骤执行在另一个账号中，需要先进行一些环境准备工作
![[rds-mysql-replica-cross-region-cross-account#^z60dbq]]

refer: [[git/git-mkdocs/data-analytics/rds-mysql-replica-cross-region-cross-account#prep-]]

### check snapshot

- 将源账号的环境变量复制到现有账号的命令行窗口方便执行后续操作
```sh
SHARED_SNAP_ARN=???
LOCAL_SNAP_NAME=local-snap-$RANDOM

# get shared snapshot
aws rds describe-db-snapshots --include-shared \
--db-snapshot-identifier ${SHARED_SNAP_ARN}

# ensure `SnapshotType` is `shared`

```

### copy without kms

- 复制快照到本账号，且不修改原有数据库未加密状态
```sh
aws rds copy-db-snapshot \
--source-db-snapshot-identifier ${SHARED_SNAP_ARN} \
--target-db-snapshot-identifier ${LOCAL_SNAP_NAME}

```

### copy with kms (option)

- （可选）复制快照到本账号，且修改原有数据库未加密状态为加密状态
- 提前创建所需要的CMK，或者指定KMS
```sh
# KEY_ARN=???
KEY_ARN=$(aws kms create-key |jq -r '.KeyMetadata.Arn')

aws rds copy-db-snapshot \
--source-db-snapshot-identifier ${SHARED_SNAP_ARN} \
--target-db-snapshot-identifier ${LOCAL_SNAP_NAME}
--kms-key-id ${KEY_ARN}

```

### wait snapshot complete

- 等待复制快照操作完成
```sh
# get snapshot status util `available`
status=""
until [[ ${status} == "available" ]]; do
status=$(aws rds describe-db-snapshots        \
  --db-snapshot-identifier ${LOCAL_SNAP_NAME} \
  --query 'DBSnapshots[].Status'              \
  --output text)
echo ${status}
sleep 60
done

```

## restore
### prep

```sh
VPC_ID=vpc-0c6e8c75ad4af1ee5
RDS_NAME=db1-restore

```

### subnet group

- 如果是跨账号，需要重新创建 subnet group
![[rds-mysql-replica-cross-region-cross-account#^rav4er]]

refer: [[git/git-mkdocs/data-analytics/rds-mysql-replica-cross-region-cross-account#subnet-group-]]

### restore db

- 从复制的快照恢复数据库
```sh
# restore RDS MySQL instance
aws rds restore-db-instance-from-db-snapshot \
  --db-snapshot-identifier ${LOCAL_SNAP_NAME} \
  --db-instance-identifier ${RDS_NAME}     \
  --db-instance-class db.t3.micro          \
  --engine mysql                           \
  --db-subnet-group-name ${RDS_NAME}       \
  --vpc-security-group-ids ${RDS_SG}       \
  --publicly-accessible   

# get rds status util `available`
status=""
until [[ ${status} == "available" ]]; do
status=$(aws rds describe-db-instances       \
  --db-instance-identifier ${RDS_NAME}       \
  --query "DBInstances[].DBInstanceStatus"   \
  --output text)
echo ${status}
sleep 60
done

TARGET_RDS_HOSTNAME=$(aws rds describe-db-instances    \
  --db-instance-identifier ${RDS_NAME}     \
  --query "DBInstances[].Endpoint.Address"    \
  --output text)

```

### on target

- 连接到恢复后的 rds 数据库，注意用户名为源账号主库，密码在源账号 `~/rds_password` 中
```sh
# user should be origin db1 
# pass should be saved in ~/rds_password
echo mysql -h${TARGET_RDS_HOSTNAME} -u${RDS_NAME} -p${RDS_PASSWORD}

```

- 修改下面语句，并且执行
- 源账号主库dns
- 确认复制用户的用户名和密码 ([[#^gycsd4]])
- 确认之前记录的断点 ([[#^gjmipb]]) 
```sql
CALL mysql.rds_set_external_master (
  'db1.ckzqxxxxxxrg.us-east-2.rds.amazonaws.com'
  , 3306
  , 'repl_user'
  , 'repl_password'
  , 'mysql-bin-changelog.000009'
  , 154
  , 0
  );

```

- 确认恢复复制操作成功
```sql
CALL mysql.rds_start_replication();

SHOW SLAVE STATUS\G

```

- 如果恢复复制操作成功将出现下面输出
```text
+-------------------------+
| Message                 |
+-------------------------+
| Slave running normally. |
+-------------------------+
1 row in set (1.01 sec)

```


## refer

- https://aws.amazon.com/premiumsupport/knowledge-center/rds-mysql-cross-region-replica/
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/mysql_rds_set_external_master.html
- https://aws.amazon.com/premiumsupport/knowledge-center/share-encrypted-rds-snapshot-kms-key/

## issue

### host error in mysql.user

```
mysql> select user,host from mysql.user;
+------------------+-----------+
| user             | host      |
+------------------+-----------+
| rdsrepladmin     | %         |
| rdsworkshop      | %         |
| repl_user        | *         |
| mysql.infoschema | localhost |
| mysql.session    | localhost |
| mysql.sys        | localhost |
| rdsadmin         | localhost |
+------------------+-----------+
7 rows in set (0.00 sec)

mysql> update mysql.user set host='%' where user='repl_user';
Query OK, 1 row affected (0.01 sec)
Rows matched: 1  Changed: 1  Warnings: 0

mysql> flush privileges;
Query OK, 0 rows affected (0.00 sec)

mysql> 

```




