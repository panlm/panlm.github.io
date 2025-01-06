---
title: directory service
description: 常用命令
created: 2023-03-24 21:46:35.822
last_modified: 2024-02-05
icon: simple/amazon
tags:
  - aws/mgmt/directory-service
  - aws/cmd
---

# directory-service-cmd

## create ms ad

```sh
AD=corp1.aws.panlm.xyz
PASS=passworD.1
VPC=vpc-0946
SUBNETS=subnet-056f,subnet-033c

aws ds create-microsoft-ad \
    --name ${AD} \
    --short-name ${AD%%.*} \
    --password ${PASS} \
    --edition Standard \
    --vpc-settings VpcId=${VPC},SubnetIds=${SUBNETS}

MSDS_ID=d-xxxx
aws ds describe-directories \
    --directory-ids ${MSDS_ID} \
    --query DirectoryDescriptions[0].[Stage,DnsIpAddrs] \
    --output text

```

## create ms ad in default vpc

??? note "right-click & open-in-new-tab"
    ![[../../others/POC-mig-filezilla-to-transfer-family#create-AD-]]


## active directory - windows 2012

![[Enabling Federation to AWS Using Windows Active Directory ADFS and SAML 2.0#^zfsdkd]]


## get compute name
```powershell
# 导入 Active Directory 模块
Import-Module ActiveDirectory

# 获取所有计算机对象
$allComputers = Get-ADComputer -Filter * -Properties Name, LastLogonDate, OperatingSystem

# 设置一个时间阈值，例如 90 天
$threshold = (Get-Date).AddDays(-90)

# 筛选出最近登录的计算机
$activeComputers = $allComputers | Where-Object { $_.LastLogonDate -gt $threshold }

# 创建一个空数组来存储在线计算机
$onlineComputers = @()

# 遍历活跃计算机列表，检查是否在线
foreach ($computer in $activeComputers) {
    if (Test-Connection -ComputerName $computer.Name -Count 1 -Quiet) {
        $onlineComputers += $computer
    }
}

# 输出结果到 CSV 文件
$onlineComputers | Select-Object Name, OperatingSystem, LastLogonDate | 
    Export-Csv -Path "C:\ActiveComputers.csv" -NoTypeInformation

Write-Host "Active computers list has been exported to C:\ActiveComputers.csv"

```
