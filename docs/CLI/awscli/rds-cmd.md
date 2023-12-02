---
title: rds
description: 常用命令
created: 2022-07-22 20:22:12.985
last_modified: 2023-12-02
tags:
  - aws/database/rds
  - aws/cmd
---
> [!WARNING] This is a github note
# rds-cmd
## create postsql
- https://www.eksworkshop.com/beginner/115_sg-per-pod/10_secgroup/

```sh
export VPC_ID=vpc-xxx
export VPC_CIDR="172.31.0.0/16"
export RDS_NAME=rdsworkshop

sudo yum install -y jq 
sudo amazon-linux-extras install -y postgresql12

SG_NAME=${RDS_NAME}-${RANDOM}
aws ec2 create-security-group  \
  --description ${SG_NAME}     \
  --group-name ${SG_NAME}      \
  --vpc-id ${VPC_ID}

export RDS_SG=$(aws ec2 describe-security-groups      \
  --filters Name=group-name,Values=${SG_NAME}         \
            Name=vpc-id,Values=${VPC_ID}              \
  --query "SecurityGroups[0].GroupId" --output text)

echo "RDS security group ID: ${RDS_SG}"

aws ec2 authorize-security-group-ingress  \
  --group-id ${RDS_SG}                    \
  --protocol tcp                          \
  --port 5432                             \
  --cidr ${VPC_CIDR}

export PUBLIC_SUBNETS_ID=$(aws ec2 describe-subnets        \
  --filters "Name=vpc-id,Values=$VPC_ID"                   \
  --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' \
  --output json | jq -c .)

# create a db subnet group
aws rds create-db-subnet-group               \
  --db-subnet-group-name ${RDS_NAME}         \
  --db-subnet-group-description ${RDS_NAME}  \
  --subnet-ids ${PUBLIC_SUBNETS_ID}

# generate a password for RDS
export RDS_PASSWORD="$(date | md5sum  |cut -f1 -d' ')"
echo ${RDS_PASSWORD}  > ~/rds_password

# create RDS Postgresql instance
aws rds create-db-instance                 \
  --db-instance-identifier ${RDS_NAME}     \
  --db-name ${RDS_NAME}                    \
  --db-instance-class db.t3.micro          \
  --engine postgres                        \
  --db-subnet-group-name ${RDS_NAME}       \
  --vpc-security-group-ids ${RDS_SG}       \
  --master-username ${RDS_NAME}            \
  --publicly-accessible                    \
  --master-user-password ${RDS_PASSWORD}   \
  --backup-retention-period 0              \
  --allocated-storage 20

aws rds describe-db-instances                \
  --db-instance-identifier ${RDS_NAME}       \
  --query "DBInstances[].DBInstanceStatus"   \
  --output text

# get RDS endpoint
export RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier ${RDS_NAME} \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "RDS endpoint: ${RDS_ENDPOINT}"


cat > /tmp/pgsql.sql <<-EoF
CREATE TABLE welcome (column1 TEXT);
insert into welcome values ('--------------------------');
insert into welcome values ('Welcome to the rdsworkshop');
insert into welcome values ('Welcome to the rdsworkshop');
insert into welcome values ('Welcome to the rdsworkshop');
insert into welcome values ('Welcome to the rdsworkshop');
insert into welcome values ('Welcome to the rdsworkshop');
insert into welcome values ('--------------------------');
EoF

export RDS_PASSWORD=$(cat ~/rds_password)
psql postgresql://${RDS_NAME}:${RDS_PASSWORD}@${RDS_ENDPOINT}:5432/${RDS_NAME} -f /tmp/pgsql.sql


```

## create mysql
- [[../../data-analytics/rds-mysql-replica-cross-region-cross-account]]

### quick create rds mysql in default vpc

??? note "right-click & open-in-new-tab: function get-default-vpc"
    ![[vpc-cmd#func-get-default-vpc-]]

??? note "right-click & open-in-new-tab: function create-sg"
    ![[ec2-cmd#func-create-sg-]]

??? note "right-click & open in new tab: function get-subnets "
    ![[vpc-cmd#func-get-subnets-]]

```sh
get-default-vpc
VPC_ID=$DEFAULT_VPC
VPC_CIDR=$DEFAULT_CIDR

create-sg ${VPC_ID} ${VPC_CIDR}
echo ${SG_ID}

get-subnets ${VPC_ID} true
echo ${SUBNET_IDS}

# create a db subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name ${SG_ID} \
  --db-subnet-group-description ${SG_ID} \
  --subnet-ids ${SUBNET_IDS}

DB_ADMIN=admin
DB_PASSWORD=admin1234567890
DB_NAME=llm-$(TZ=EAT-8 date +%Y%m%d-%H%M%S)
aws rds create-db-instance \
    --db-instance-identifier ${DB_NAME} \
    --engine mysql \
    --db-instance-class db.r6g.large \
    --master-username ${DB_ADMIN} \
    --master-user-password ${DB_PASSWORD} \
    --db-subnet-group-name ${SG_ID} \
    --vpc-security-group-ids ${SG_ID} \
    --allocated-storage 100 

aws rds wait db-instance-available --db-instance-identifier ${DB_NAME}

```

## create read replica cross region
```sh
# in china region
source_db_arn=arn:aws-cn:rds:cn-northwest-1:123456789012:db:database-1
aws rds create-db-instance-read-replica \
  --db-instance-identifier database-1-rep-from-cnnw1 \
  --region cn-north-1 \
  --source-region cn-northwest-1 \
  --source-db-instance-identifier ${source_db_arn} \
  --kms-key-id arn:aws-cn:kms:cn-north-1:123456789012:alias/aws/rds

```

## delete 
```sh
aws rds delete-db-instance --db-instance-identifier test1 \
  --skip-final-snapshot
```

## modify
```sh
aws rds modify-db-instance --db-instance-identifier test1 \
  --no-multi-az --no-publicly-accessible
```

## describe-instance

```sh
aws rds describe-db-instances
```

## ssl connection 

- download ([link](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html))
- verify with mysql ([link](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/mysql-ssl-connections.html#USER_ConnectToInstanceSSL.CLI))
```sh
wget 'https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem'
# maybe need to change surfix to pem

dbhost=xxxx
mysql -h $dbhost --ssl-ca=global-bundle.pem --ssl-mode=VERIFY_IDENTITY -P 3306 -u admin -p

```




