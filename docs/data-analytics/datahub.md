---
title: Datahub
description: 部署 Datahub，从 Redshift 和 Glue job 中获取数据血缘
created: 2024-07-31 08:28:11.479
last_modified: 2024-08-05
status: myblog
tags:
  - aws/analytics
---

# datahub
https://github.com/aws-samples/deploy-datahub-using-aws-managed-services-ingest-metadata/pull/3

## walkthrough
- https://aws.amazon.com/blogs/big-data/part-1-deploy-datahub-using-aws-managed-services-and-ingest-metadata-from-aws-glue-and-amazon-redshift/
- https://aws.amazon.com/blogs/big-data/part-2-deploy-datahub-using-aws-managed-services-and-ingest-metadata-from-aws-glue-and-amazon-redshift/

- updated github repo: https://github.com/panlm/deploy-datahub-using-aws-managed-services-ingest-metadata/tree/datahub-v0.13.2

```
changes:
- update rds instance family from r4 to r5 in rds_stack.py
- update eks version to 1.29 in cdk.json
- comment out release_version in eks_stack.py to choose newest ami for node group, comment out eks_node_ami_version in cdk.json
- update values yaml to support newest datahub helm deployment
- add comment to glue_data_lineage.py, need download Dependent JAR: acryl-spark-lineage instead of datahub-spark-lineage
```

### deploy infra
- cdk.json diff
```
--- a/cdk.json
+++ b/cdk.json
@@ -5,8 +5,8 @@
     "@aws-cdk/aws-cloudfront:defaultSecurityPolicyTLSv1.2_2021": false,
     "@aws-cdk/aws-rds:lowercaseDbIdentifier": false,
     "@aws-cdk/core:stackRelativeExports": false,
-    "ACCOUNT_ID" : "<ACCOUNT_ID>",
-    "REGION" : "<REGION>",
+    "ACCOUNT_ID" : "012345678901",
+    "REGION" : "us-west-2",
     "create_new_cluster_admin_role": "True",
     "existing_admin_role_arn": "",
     "create_new_vpc": "True",
@@ -14,14 +14,14 @@
     "vpc_cidr_mask_public": 26,
     "vpc_cidr_mask_private": 24,
     "existing_vpc_name": "VPC",
-    "eks_version": "1.21",
+    "eks_version": "1.29",
     "eks_deploy_managed_nodegroup": "True",
     "eks_node_quantity": 2,
     "eks_node_max_quantity": 5,
     "eks_node_min_quantity": 1,
     "eks_node_disk_size": 20,
     "eks_node_instance_type": "m5.large,m5a.large",
-    "eks_node_ami_version": "1.21.5-20220123",
+    // "eks_node_ami_version": "1.23-20240703",
     "eks_node_spot": "False",
     "create_cluster_exports": "True",
     "deploy_aws_lb_controller": "True",

```

- datahub_aws/eks_stack.py diff
```
--- a/datahub_aws/eks_stack.py
+++ b/datahub_aws/eks_stack.py
@@ -128,8 +128,7 @@ class EKSClusterStack(Stack):
                     # The default in CDK is to force upgrades through even if they violate - it is safer to not do that
                     force_update=False,
                     instance_types=instance_types,
-                    release_version=self.node.try_get_context(
-                        "eks_node_ami_version")
+                    # release_version=self.node.try_get_context("eks_node_ami_version")
                 )
                 eks_node_group.role.add_managed_policy(
                     iam.ManagedPolicy.from_aws_managed_policy_name("AmazonSSMManagedInstanceCore"))
@@ -164,4 +163,4 @@ class EKSClusterStack(Stack):
                 export_name="EKSSGID"
             )
             self.security_grp =  self.eks_cluster.kubectl_security_group

```

- datahub_aws/rds_stack.py diff
```
--- a/datahub_aws/rds_stack.py
+++ b/datahub_aws/rds_stack.py
@@ -28,10 +28,10 @@ class MySql(Stack):
         )
        
         if not instance_type:
-            instance_type = ec2.InstanceType.of(ec2.InstanceClass.MEMORY4, ec2.InstanceSize.LARGE)
+            instance_type = ec2.InstanceType.of(ec2.InstanceClass.MEMORY5, ec2.InstanceSize.LARGE)
 
         if not engine_version:
-            engine_version = rds.MysqlEngineVersion.VER_8_0_26
+            engine_version = rds.MysqlEngineVersion.VER_8_0_35
 
        
         #db_cluster_identifier

```

- follow blog to install infra resources

### helm datahub
- get newest values yaml ([link](https://github.com/panlm/deploy-datahub-using-aws-managed-services-ingest-metadata/tree/datahub-v0.13.2/charts))
- helm install datahub newest version (v0.13.2 works)
```sh
helm install prerequisites datahub/datahub-prerequisites --values ./charts/prerequisites/values-new.yaml
helm install datahub datahub/datahub --values ./charts/datahub/values-new.yaml

```

## ingestion
### glue
- 不需要 `table_pattern`
```yaml
source:
    type: glue
    config:
        aws_region: us-west-2
        database_pattern:
            allow:
                - clidb

```

## lineage
### glue job
script: [download](https://github.com/panlm/deploy-datahub-using-aws-managed-services-ingest-metadata/blob/datahub-v0.13.2/aws-dataplatform-meta-data-ingestion/examples/code/glue_data_lineage.py)
Dependent JAR (acryl-spark-lineage): [download](https://repo1.maven.org/maven2/io/acryl/acryl-spark-lineage/0.2.16/)

![[attachments/datahub/IMG-datahub.png|800]]

### redshift
- create table
```sql
CREATE TABLE new_table AS
SELECT t1.eventid, t1.starttime, t2.holiday
FROM event t1
JOIN date t2
ON t1.dateid = t2.dateid;

```
![[attachments/datahub/IMG-datahub-2.png|700]]

## refer 
### error message
- `externalJar/datahub-spark-lineage-0.11.0-5.jar` and lower version is supported in glue jobs, others you will got error
```
An error occurred while calling None.org.apache.spark.api.java.JavaSparkContext. datahub/spark/DatahubSparkListener has been compiled by a more recent version of the Java Runtime (class file version 55.0), this version of the Java Runtime only recognizes class file versions up to 52.0. Note: This run was executed with Flex execution. Check the logs if run failed due to executor termination.
```

- using io.acryl:acryl-spark-lineage:0.2.16 to instead of datahub-spark-lineage

