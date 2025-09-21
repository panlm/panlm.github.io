---
title: Enable Quicksight with Identity Center
description: 中国区域启用 Quicksight 并且集成 Microsoft Entra
created: 2024-05-28 23:30:40.961
last_modified: 2024-06-28
status: myblog
tags:
  - aws/analytics/quicksight
  - aws/security/identity-center
  - azure
---

# Enable Quicksight with Identity Center

## Using Microsoft Entra as External IdP

In BJS region, Quicksight does not support SAML Authentication Method (refer Appendix chapter). If you try to integration with existing SSO, for example Microsoft Entra ID, you need enable Amazon IAM Identity Center (short for AWS-SSO) with SAML support to carry out ([[saml-2.0]])

### Walkthrough

- One Microsoft Entra tenant, at least `Microsoft Entra ID P1`  license  ([link](https://www.microsoft.com/en-us/security/business/microsoft-entra-pricing))
- Enable AWS-SSO account instance in this lab
    - If your account joined AWS Organizations, you could choose enable AWS-SSO with organization instance ([link](https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-instances.html))
    - refer this blog for AWS-SSO deployment pattern ([link](https://aws.amazon.com/cn/blogs/security/how-to-use-multiple-instances-of-aws-iam-identity-center/))
- Using SAML IdP for AWS-SSO, integration with existing Microsoft Entra tenant 
    - Following this [link](https://docs.aws.amazon.com/singlesignon/latest/userguide/idp-microsoft-entra.html) 
    - Complete `Step 1`, and
        - New a Microsoft 365 Group for Quicksight and assign user to this group
        - assign group to SSO application in Microsoft Entra directly (P1 license needed)
        - verify sign in URL: ([account portal](https://myaccount.microsoft.com) & [app portal](https://myapplications.microsoft.com/))
        - Dont forgot firstName and lastName. If missing these properties will cause 
        - SCIM sync failure
    - Complete `Step 2.2` (Other steps is only for AWS-SSO organization instance)
    - Complete `Step 3` and `Step 4`
- Enable Quicksight 
![[attachments/enable-quicksight-with-identity-center/IMG-enable-quicksight-with-identity-center.png|500]]
- assign group to reader/author/admin role in Quicksight
- create vpc connection
- create redshift vpc endpoint
- Quicksight will use this role: `aws-quicksight-service-role-v0` to access aws resources
- [Open Quicksight](cn-north-1.quicksight.amazonaws.cn)

### Another sample - use Okta as IdP for AWS-SSO to login Quicksight

In this sample, use Okta as IdP for AWS-SSO. Just like our lab using Microsoft Entra ID instead of. Put sign-in process here for your reference.

- blog: [[WebClip/Simplify business intelligence identity management with Amazon QuickSight and AWS IAM Identity Center|Simplify business intelligence identity management with Amazon QuickSight and AWS IAM Identity Center]] ([link](https://aws.amazon.com/cn/blogs/business-intelligence/simplify-business-intelligence-identity-management-with-amazon-quicksight-and-aws-iam-identity-center/))
- QuickSight service provider (SP) initiated sign-in
![[attachments/enable-quicksight-with-identity-center/IMG-enable-quicksight-with-identity-center-1.png]]
- External IdP initiated sign-in
![[attachments/enable-quicksight-with-identity-center/IMG-enable-quicksight-with-identity-center-2.png]]


## Using Identity Center local directory

Using AWS-SSO local directory as identity source. This mode works both in global region and BJS region. No AWS Organizations needed.

### Walkthrough

- create user `abcdeabcdeab` in identity center (length need 12+)
- create group with any name
- enable Quicksight in account level with user name and group name
    - default Quicksight role works ([role policy](https://docs.aws.amazon.com/quicksight/latest/user/iam-policy-examples.html#security_iam_id-based-policy-examples-all-access-enterprise-edition-sso) & [trust](https://docs.aws.amazon.com/quicksight/latest/user/security_iam_service-with-iam.html#security-create-iam-role))


## Appendix

- Supported Authentication Method for Quicksight in global region ([link](https://docs.aws.amazon.com/quicksight/latest/user/identity.html))
    - Use IAM federated identities & QuickSight-managed users
    - Use AWS IAM Identity Center
    - Use IAM federated identities only
    - Use Active Directory
- Supported Authentication Method for Quicksight in China region (until Jun 2024)
    - Use Amazon IAM Identity Center
    - Use Active Directory
- Other refer
    - https://docs.amazonaws.cn/aws/latest/userguide/iam-identity-center.html
    - https://learn.microsoft.com/en-us/entra/identity/saas-apps/aws-single-sign-on-tutorial

