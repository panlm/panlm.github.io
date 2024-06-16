---
title: sqs
description: 常用命令
created: 2023-08-31 20:18:28.430
last_modified: 2024-02-05
icon: simple/amazonsqs
tags:
  - aws/integration/sqs
---
# sqs-cmd
## create 
```sh
aws sns create-queue --queue-name sqs2 --query 'QueueUrl' --output text
```

## send and receive messages
### with curl
``` bash
# send message to sqs anonymously
message=test
sqs_url=https://sqs.ap-northeast-2.amazonaws.com/123456789012/public-queue-seoul
curl -d "Action=SendMessage&Version=2011-10-01&MessageBody=${message}" ${sqs_url}

# ReceiveMessage
curl -d "Action=ReceiveMessage&Version=2011-10-01" ${sqs_url}

```

### with awscli
``` bash
# send 100 message to sqs
for i in `seq 1 99` ; do 
  aws sqs send-message  \
    --queue-url "https://cn-northwest-1.queue.amazonaws.com.cn/123456789012/sqs-std1" \
    --message-body "message$i"
done

# retrieve 1 message
aws sqs receive-message \
  --queue-url https://cn-northwest-1.queue.amazonaws.com.cn/123456789012/sqs-std1


# one message sample
{
    "Messages": [
        {
            "Body": "aaaaa",
            "ReceiptHandle": "===ReceiptHandleString===",
            "MD5OfBody": "594f803b380a41396ed63dca39503542",
            "MessageId": "d64a9969-c287-44e3-bac7-5025f61b5b39"
        }
    ]
}

# delete message
aws sqs delete-message \
  --queue-url https://cn-northwest-1.queue.amazonaws.com.cn/123456789012/sqs-std1 \
  --receipt-handle "===ReceiptHandleString==="

```




