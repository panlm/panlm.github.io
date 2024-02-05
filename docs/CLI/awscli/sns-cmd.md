---
title: sns
description: 常用命令
created: 2021-08-22T01:08:41.391Z
last_modified: 2024-02-05
icon: simple/amazonaws
tags:
  - aws/integration/sns
---
> [!WARNING] This is a github note
# sns-cmd
## send file as message
``` bash
TOPIC_ARN=
aws sns publish --topic-arn ${TOPIC_ARN} --message file:///tmp/file1.json

```

## subscription confirmation
``` bash
echo '{
  "Type" : "SubscriptionConfirmation",
  "MessageId" : "xxx",
  ...
  "SigningCertURL" : "https://sns.ap-southeast-1.amazonaws.com/SimpleNotificationService-xxx.pem"
}' |tee /tmp/$$.json

message_id=$( cat /tmp/$$.json |jq -r '.MessageId' )
arn=$( cat /tmp/$$.json |jq -r '.TopicArn' )
region=$(echo $arn |awk -F":" '{print $4}')
url=$( cat /tmp/$$.json |jq -r '.SubscribeURL' )
token=$( cat /tmp/$$.json |jq -r '.Token')

aws sns confirm-subscription --topic-arn $arn --token $token --region $region

```
- output
```json
{
    "SubscriptionArn": "arn:aws:sns:ap-southeast-1:123456789012:notificate-to-panlm:xxx"
}
```

- or
```bash
curl -X POST -d @$$.json \
  -H 'Connection: Keep-Alive' \
  -H 'Content-Type: text/plain; charset=UTF-8' \
  -H 'x-amz-sns-message-type: SubscriptionConfirmation' \
  -H 'x-amz-sns-message-id: '"$message_id" \
  -H 'x-amz-sns-topic-arn: '"$arn" \
  "$url"
```
- output
```xml
<ConfirmSubscriptionResponse xmlns="http://sns.amazonaws.com/doc/2010-03-31/">
  <ConfirmSubscriptionResult>
    <SubscriptionArn>arn:aws:sns:ap-southeast-1:123456789012:notificate-to-panlm:xxx</SubscriptionArn>
  </ConfirmSubscriptionResult>
  <ResponseMetadata>
    <RequestId>xxx</RequestId>
  </ResponseMetadata>
</ConfirmSubscriptionResponse>
```









