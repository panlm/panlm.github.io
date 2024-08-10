---
title: aws-signer
description: 
created: 2024-08-06 08:58:44.376
last_modified: 2024-08-06
tags:
  - draft
  - aws/security/signer
  - aws/NotInCN
  - aws/container
---

# aws-signer

profile supported platform: 
- lambda
- notation for container registries

## walkthrough
- create profile and get arn
- notation plugins ([docs](https://docs.aws.amazon.com/signer/latest/developerguide/image-signing-prerequisites.html)) and folder struction ([docs](https://notaryproject.dev/docs/user-guides/how-to/directory-structure/))
- sign image
```sh
export NOTATION_PASSWORD=$(aws ecr get-login-password --region us-west-2)
export NOTATION_USERNAME=AWS
notation sign 123456789012.dkr.ecr.us-west-2.amazonaws.com/nginx:latest \
    --plugin com.amazonaws.signer.notation.plugin \
    --id arn:aws:signer:us-west-2:123456789012:/signing-profiles/profile1
```






## not in china region
N/A






