---
title: global-sso-and-china-aws-accounts
description: 使用 global sso 登录中国区域 aws 账号
chapter: true
hidden: false
weight: 202309
created: 2023-09-26 11:04:50.392
last_modified: 2023-10-08 08:59:12.572
tags:
  - aws/security/identity-center
---

```ad-attention
title: This is a github note
```

# global-sso-and-china-aws-accounts

- [setup](#setup)
- [refer](#refer)

## setup

- create application `External AWS Account Application` from sso `Applications`
![global-sso-and-china-aws-accounts-png-1.png](../git-attachment/global-sso-and-china-aws-accounts-png-1.png)

- download `IAM Identity Center SAML metadata file` 
- create identity provider in aws china account
![global-sso-and-china-aws-accounts-png-2.png](../git-attachment/global-sso-and-china-aws-accounts-png-2.png)

- create role for `SAML 2.0 federation` in aws china account, and assign policy to it
![global-sso-and-china-aws-accounts-png-3.png](../git-attachment/global-sso-and-china-aws-accounts-png-3.png)

- back to create application page, review application metadata
    - using `https://signin.amazonaws.cn/saml`
    - ~~original is `https://signin.aws.amazon.com/saml`~~
![global-sso-and-china-aws-accounts-png-4.png](../git-attachment/global-sso-and-china-aws-accounts-png-4.png)

- create application
- edit `attribute mappings` for this application, ensure following two field existed

| Field                                                  | Value                                                                                                      | Format      |
| ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------- | ----------- |
| https://aws.amazon.com/SAML/Attributes/Role            | arn:aws:iam::**ACCOUNTID**:saml-provider/**SAMLPROVIDERNAME**,arn:aws:iam::**ACCOUNTID**:role/**ROLENAME** | unspecified |
| https://aws.amazon.com/SAML/Attributes/RoleSessionName | <ROLE_SESSION_NAME> must match [a-zA-Z_0-9+=,.@-]{2,64}                                                    | unspecified |

- assign user to application and login
    - find login url from sso dashboard or reset user's password
![global-sso-and-china-aws-accounts-png-5.png|400](../git-attachment/global-sso-and-china-aws-accounts-png-5.png)



## refer
- https://aws.amazon.com/cn/blogs/china/use-amazon-cloud-technology-single-sign-on-service-for-amazon-cloud-technology-china/
- https://static.global.sso.amazonaws.com/app-4a24b6fe5e450fa2/instructions/index.htm


