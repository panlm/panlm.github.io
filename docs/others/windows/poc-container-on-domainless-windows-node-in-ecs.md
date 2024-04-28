---
title: poc-container-on-domainless-windows-in-ecs
description: 
created: 2024-03-20 09:34:50.210
last_modified: 2024-03-20
tags:
  - microsoft/windows
  - aws/container/ecs
---
# poc-container-on-domainless-windows-in-ecs

## walkthrough

- background ([[ecs-windows-gmsa|ecs-windows-gmsa]])
- complete step 1 in [[ws-gmsa-linux-containers-ecs]] or [workshop link](https://catalog.us-east-1.prod.workshops.aws/workshops/a6761c4f-f1f8-44e9-8455-fda420122632/en-US/3-domainless-authentication/step-1-deploy-infrastructure) 
- create seperate ecs cluster with windows node, and setup asg to 1
    - [[../../CLI/awscli/ecs-cmd|ecs-cmd]]
- create outbound endpoint in vpc for your domain name resolution
- go workshop step 4, create credspec
- build sample web app in step 5 to build windows iis container 
    - rollback to .net6 commit id 1d58ce653829dea3a63005b0cc48cc903bfcd560
- modify credspec to domain less format ([[ecs-windows-gmsa]])
    - script \\ shell script works fine
- run task and verify access sqlserver in domain 
    - [[git/git-mkdocs/CLI/windows/powershell#connecting-to-sql-server-using-dotnet-framework-]]



