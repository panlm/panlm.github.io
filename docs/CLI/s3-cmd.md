---
title: s3
description: 
created: 2021-07-10 02:23:54.765
last_modified: 2023-10-22 20:59:25.361
tags:
  - aws/storage/s3
  - aws/cmd
---

```ad-attention
title: This is a github note
```

# s3-cmd

## versioning
### create s3 with versioning

```sh
bucket_name=p1panlm
aws_region=us-east-2
aws s3api create-bucket --bucket $bucket_name \
--create-bucket-configuration LocationConstraint=${aws_region} 

aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Enabled
```

### delete s3 with versioning enabled

```sh
bucket_name=aws-codestar-ap-southeast-1-xxxxxx-proj1-pipe
aws s3api put-bucket-versioning --bucket $bucket_name --versioning-configuration Status=Suspended
aws s3api delete-objects \
      --bucket $bucket_name \
      --delete "$(aws s3api list-object-versions \
      --bucket $bucket_name | \
      jq '{Objects: [.Versions[] | {Key:.Key, VersionId : .VersionId}], Quiet: false}')"
```

### delete s3 without versioning

```bash
for i in $a ; do 
aws s3 rm s3://$i --region us-east-1 --recursive
aws s3 rb s3://$i --force --region us-east-1
done
 ```

## download s3 folder

```sh
aws s3 sync s3://my-exported-logs .
```

## create folder

```sh
aws s3api put-object \
--bucket ${bucket_name} \
--key ${folder_name}/

```


## head object 

```sh
aws s3api head-object --bucket lcf-1350 --key stop_sensor_data.sh

# sample output: 
{
    "AcceptRanges": "bytes",
    "Expiration": "expiry-date=\"Thu, 02 Nov 2023 00:00:00 GMT\", rule-id=\"rule1\"",
    "LastModified": "2023-10-22T09:41:20+00:00",
    "ContentLength": 162,
    "ETag": "\"65c759947d7b4e98624fa5bec23e0df0\"",
    "ContentType": "text/x-sh",
    "ServerSideEncryption": "AES256",
    "Metadata": {}
}
```
- ETag, is md5
- Expiration, when you has rule for this object
- LastModified, only timestamp

## get object 

### get object

```sh
aws s3api get-object \
  --key results/15c2c468a4c4.txt \
  --bucket athena-bucket-1115 \
  --region us-east-2 \
  download.txt
```

### get object from access point

```sh
# using access point alias
aws s3api get-object \
  --key results/15c2c468a4c4.txt \
  --bucket arn:aws:s3:us-east-2:ACCOUNT_ID:accesspoint/testap-internet \
  --region us-east-2 \
  download.txt
```

## update access point policy

```sh
aws s3control get-access-point-policy \
  --region us-east-2 \
  --account-id ACCOUNT_ID \
  --name testap-internet
```

```sh
aws s3control put-access-point-policy \
  --region us-east-2 \
  --account-id ACCOUNT_ID \
  --name testap-internet \
  --policy file://policy.json
```


## presigned url

### for download

```sh
OBJECT_KEY="folder/subfolder/file.txt"
EXPIRES=3600 # max 7 days
aws s3 presign s3://my-bucket/${OBJECT_KEY} --expires-in ${EXPIRES} --region xxx # keep region same with bucket
```

### for upload

```sh

```

## public-access-

- https://repost.aws/knowledge-center/read-access-objects-s3-bucket
- https://aws.amazon.com/blogs/networking-and-content-delivery/amazon-s3-amazon-cloudfront-a-match-made-in-the-cloud/

