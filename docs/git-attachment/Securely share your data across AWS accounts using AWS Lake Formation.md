---
title: Securely share your data across AWS accounts using AWS Lake Formation
description: 
created: 2024-04-28T13:25:37 (UTC +08:00)
last_modified: 2024-04-28
source: https://aws.amazon.com/blogs/big-data/securely-share-your-data-across-aws-accounts-using-aws-lake-formation/
author: 
tags:
  - aws/analytics/lake-formation
---

# Securely share your data across AWS accounts using AWS Lake Formation | AWS Big Data Blog
https://aws.amazon.com/blogs/big-data/securely-share-your-data-across-aws-accounts-using-aws-lake-formation/


## Overview of tag-based access control

Lake Formation tag-based access control is an authorization strategy that defines permissions based on attributes. In Lake Formation, these attributes are called _LF-tags_. You can attach LF-tags to Data Catalog resources and Lake Formation principals. Data lake administrators can assign and revoke permissions on Lake Formation resources using these LF-tags. For more details about tag-based access control, refer to [Easily manage your data lake at scale using AWS Lake Formation Tag-based access control](https://aws.amazon.com/blogs/big-data/easily-manage-your-data-lake-at-scale-using-tag-based-access-control-in-aws-lake-formation/).

The following diagram illustrates the architecture of this method.
![](Securely%20share%20your%20data%20across%20AWS%20accounts%20using%20AWS%20Lake%20Formation%20%20AWS%20Big%20Data%20Blog/BDB-1748-image001.jpg)

We recommend tag-based access control for the following use cases:

-   You have a large number of tables and principals that the data lake administrator has to grant access to
-   You want to classify your data based on an ontology and grant permissions based on classification
-   The data lake administrator wants to assign permissions dynamically, in a loosely coupled way

You can also use tag-based access control to share Data Catalog resources (databases, tables, and columns) with external AWS accounts.

## Overview of named resources

The Lake Formation named resource method is an authorization strategy that defines permissions for resources. Resources include databases, tables, and columns. Data lake administrators can assign and revoke permissions on Lake Formation resources. See [Cross-Account Access: How It Works](https://docs.aws.amazon.com/lake-formation/latest/dg/crosss-account-how-works.html) for details.

The following diagram illustrates the architecture for this method.  
![](Securely%20share%20your%20data%20across%20AWS%20accounts%20using%20AWS%20Lake%20Formation%20%20AWS%20Big%20Data%20Blog/BDB-1748-image003.jpg)

We recommend using named resources if the data lake administrator prefers granting permissions explicitly to individual resources.

When you use the named resource method to grant Lake Formation permissions on a Data Catalog resource to an external account, Lake Formation uses [AWS Resource Access Manager](http://aws.amazon.com/ram) (AWS RAM) to share the resource.

Now, let’s take a closer look at how to configure cross-account access with these two options. We refer to the account that has the source table as the producer account, and refer to the account that needs access to the source table as consumer account.

