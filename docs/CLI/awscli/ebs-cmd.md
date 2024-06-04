---
title: ebs
description: 1/ 转换 gp2 到 gp3 ; 2/ 获取指定 volume 每次 snapshot 占用的 block 数量 ; 3/ 创建两种不同类型的 dlm 策略
created: 2023-02-18 11:53:13.625
last_modified: 2024-02-05
icon: simple/amazon
tags:
  - aws/cmd
  - aws/storage/ebs
---

# ebs-cmd
## create ebs volume
```sh
aws ec2 attach-volume
--device <value>
--instance-id <value>
--volume-id <value>

aws ec2 create-volume
--availability-zone <value>
--size 200
```

## change ebs gp2 to gp3
- [Script to automatically change all gp2 volumes to gp3 with aws-cli](https://www.daniloaz.com/en/script-to-automatically-change-all-gp2-volumes-to-gp3-with-aws-cli/) 
```sh
#! /bin/bash

region='us-east-1'

# Find all gp2 volumes within the given region
volume_ids=$(/usr/bin/aws ec2 describe-volumes --region "${region}" --filters Name=volume-type,Values=gp2 | jq -r '.Volumes[].VolumeId')

# Iterate all gp2 volumes and change its type to gp3
for volume_id in ${volume_ids};do
    result=$(/usr/bin/aws ec2 modify-volume --region "${region}" --volume-type=gp3 --volume-id "${volume_id}" | jq '.VolumeModification.ModificationState' | sed 's/"//g')
    if [ $? -eq 0 ] && [ "${result}" == "modifying" ];then
        echo "OK: volume ${volume_id} changed to state 'modifying'"
    else
        echo "ERROR: couldn't change volume ${volume_id} type to gp3!"
    fi
done

```

## get-each-snapshot-change-blocks-
使用 ebs 快照生命周期管理时，查看特定 volume 每次快照占用的大小，以方便跨区域复制时预估传输量。
- 快照完成跨区域复制耗时不等，从 20+ 分钟到 45 分钟，不适合作为容灾切换使用
- 但可以加速后续复制完成，需要注意保持配置一直才可以重用之前复制的内容，例如之前跨区域复制时使用 kms，那么在后续手工快照 + 复制过程中也要选择 kms，可以快速完成，否则耗时更多

```sh
VOLUME_ID=vol-06ecbace881bf641a
aws ec2 describe-snapshots  \
  |jq -r '(
  .Snapshots[] 
  | select (.VolumeId=="'"${VOLUME_ID}"'") 
  | [.SnapshotId, .StartTime])
  |@tsv' |sort -k2 >/tmp/$$.tsv

LINE_NUM=$(wc -l /tmp/$$.tsv |awk '{print $1}')
if [[ ${LINE_NUM} -ne 1 ]]; then 
  cat /tmp/$$.tsv |awk '{print $1}' |while read LINE ; do
    FIRST=${SECOND}
    SECOND=${LINE}
    if [[ -z ${FIRST} ]]; then
      continue
    fi
    # echo $FIRST "-" $SECOND
    echo -e "${FIRST} - ${SECOND}: \c"
    aws ebs list-changed-blocks \
      --first-snapshot-id ${FIRST} \
      --second-snapshot-id ${SECOND} \
      |jq -r '.ChangedBlocks|length'
  done
fi

```

## dlm - snapshot
- default role doc ([link](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/service-role.html#default-service-roles))
```sh
# AWSDataLifecycleManagerDefaultRole
aws dlm create-default-role --resource-type snapshot
# AWSDataLifecycleManagerDefaultRoleForAMIManagement
aws dlm create-default-role --resource-type image

ROLE_NAME=AWSDataLifecycleManagerDefaultRole
ROLE_ARN=$(aws iam get-role \
--role-name ${ROLE_NAME} \
--query 'Role.Arn' --output text)

cat > $$-snapshot.json <<-EOF
{
  "PolicyType": "EBS_SNAPSHOT_MANAGEMENT",
  "ResourceTypes": [
    "INSTANCE"
  ],
  "TargetTags": [
    {
      "Key": "Name",
      "Value": "test-instance1-zhy"
    }
  ],
  "VariableTags": [
    {
      "Key": "instance-id",
      "Value": "$(instance-id)"
    },
    {
      "Key": "timestamp",
      "Value": "$(timestamp)"
    }
  ],
  "Schedules": [
    {
      "Name": "Schedule 1",
      "CopyTags": true,
      "TagsToAdd": [
        {
          "Key": "Project",
          "Value": "DR Prep"
        }
      ],
      "CreateRule": {
        "Interval": 1,
        "IntervalUnit": "HOURS",
        "Times": [
          "08:00"
        ]
      },
      "RetainRule": {
        "Count": 6
      },
      "CrossRegionCopyRules": [
        {
          "TargetRegion": "cn-north-1",
          "Encrypted": false,
          "CopyTags": true,
          "RetainRule": {
            "Interval": 1,
            "IntervalUnit": "DAYS"
          }
        }
      ]
    }
  ]
}
EOF

aws dlm create-lifecycle-policy \
    --description "My second policy" \
    --state ENABLED \
    --execution-role-arn ${ROLE_ARN} \
    --policy-details file://$$-snapshot.json

```

### dlm - ami - policy sample

```json
{
  "PolicyType": "IMAGE_MANAGEMENT",
  "ResourceTypes": [
    "INSTANCE"
  ],
  "TargetTags": [
    {
      "Key": "Name",
      "Value": "test-instance2-zhy"
    }
  ],
  "Schedules": [
    {
      "Name": "Schedule 1",
      "CopyTags": true,
      "VariableTags": [
        {
          "Key": "instance-id",
          "Value": "$(instance-id)"
        }
      ],
      "CreateRule": {
        "Interval": 1,
        "IntervalUnit": "HOURS",
        "Times": [
          "02:00"
        ]
      },
      "RetainRule": {
        "Count": 6
      },
      "CrossRegionCopyRules": [
        {
          "TargetRegion": "cn-north-1",
          "Encrypted": false,
          "CopyTags": true,
          "RetainRule": {
            "Interval": 1,
            "IntervalUnit": "DAYS"
          },
          "DeprecateRule": {
            "Interval": 1,
            "IntervalUnit": "DAYS"
          }
        }
      ]
    }
  ]
}

```


## tools
- [list nvme volume script](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-windows-volumes.html#windows-list-disks-nvme)
- [list volume script](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-windows-volumes.html#windows-list-disks)

download ebsnvme-id.zip 
- [doc](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/nvme-ebs-volumes.html)

??? note "right-click & open-in-new-tab"
    ![[../windows/powershell#download-AWSNVMe.zip-]]

### refer
https://github.com/awslabs/amazon-ebs-autoscale


