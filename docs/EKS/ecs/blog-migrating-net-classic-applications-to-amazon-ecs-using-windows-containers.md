---
title: Migrating .NET Classic Applications to Amazon ECS Using Windows Containers
description: 
created: 2024-02-19T13:36:47 (UTC +08:00)
last_modified: 2024-04-04
source: https://aws.amazon.com/blogs/compute/migrating-net-classic-applications-to-amazon-ecs-using-windows-containers/
author: 
tags:
  - aws/container/ecs
  - microsoft/dotnet
---

# Migrating .NET Classic Applications to Amazon ECS Using Windows Containers

## start from 
- [[../../../../initiate-ec2-windows-dev-environment|initiate-ec2-windows-dev-environment]]
- clone repo
- open vs2022


## lab walkthrough
- windows 2019 base AMI
- assign instance profile 
- install microsoft edge
- [[../../CLI/windows/docker-on-windows]]
- install [[ms-visual-studio]] 
    - clone repo: https://github.com/aws-samples/aws-ecs-windows-aspnet
- download 4.5.2 sdk
- restart ms vs 2022
    - open solution explorer
    - change Dockerfile ([[../../../../dotnet-core-and-framework#dotnet-framework-]])
    - right click project AWSECSSample, Add Docker support 
    - start debugging, Container (Dockerfile)
    - you will see docker image from cli
- install awscli on windows
- upload docker image to ECS
- download cloudformation ([[../../git-attachment/aspnetwincontainer.json]])
    - need windows 2019 AMI (Windows_Server-2019-English-Full-ECS_Optimized-) ([[git/git-mkdocs/CLI/awscli/ecs-cmd#get-windows-ecs-ami-list-]])
    - assign public subnet 

## refer
another ecs github 
https://github.com/aws-samples/ecs-refarch-cloudformation-windows

