---
title: ebs-cmd
description: ""
chapter: true
created: 2023-02-18 11:53:13.625
last_modified: 2023-02-18 11:53:13.625
tags: 
- aws/compute/ec2 
- aws/storage/ebs 
---
```ad-attention
title: This is a github note

```
# ebs-cmd

> ## Excerpt
> 1/ 转换 gp2 到 gp3 ； 2/ 获取指定 volume 每次 snapshot 占用的 block 数量

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

[Script to automatically change all gp2 volumes to gp3 with aws-cli](https://www.daniloaz.com/en/script-to-automatically-change-all-gp2-volumes-to-gp3-with-aws-cli/) 
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

## get-each-snapshot-change-blocks-📚

获取指定 volume 每次 snapshot 占用的 block 数量
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

## tools

- [list nvme volume script](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-windows-volumes.html#windows-list-disks-nvme)
- [list volume script](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/ec2-windows-volumes.html#windows-list-disks)

download ebsnvme-id.zip 
- [doc](https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/nvme-ebs-volumes.html)
![[powershell#download AWSNVMe.zip]]

### refer
https://github.com/awslabs/amazon-ebs-autoscale


