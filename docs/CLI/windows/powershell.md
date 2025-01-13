---
title: powershell
description: 常用命令
created: 2023-01-09 22:45:11.849
last_modified: 2024-03-20
tags:
  - microsoft/windows
  - microsoft/powershell
---
# powershell

## download file
```powershell
Invoke-WebRequest -uri 'https://github.com/microsoft/windows-container-tools/releases/download/v1.1/LogMonitor.exe' -OutFile 'c:\Logmonitor.exe'

Invoke-WebRequest -uri 'https://github.com/prometheus-community/windows_exporter/releases/download/v0.25.1/windows_exporter-0.25.1-amd64.msi' -OutFile 'c:\windows_exporter-0.25.1-amd64.msi'

msiexec /i 'c:\windows_exporter-0.25.1-amd64.msi' ENABLED_COLLECTORS=os,iis
# default port 9182
Invoke-WebRequest -URI 'http://localhost:9182/metrics' -UseBasicParsing

```

## download-AWSNVMe.zip-
```sh
invoke-webrequest https://s3.amazonaws.com/ec2-windows-drivers-downloads/NVMe/Latest/AWSNVMe.zip -outfile $env:USERPROFILE\nvme_driver.zip
expand-archive $env:userprofile\nvme_driver.zip -DestinationPath $env:userprofile\nvme_driver

```


## RSAT tools
- [[../../others/POC-mig-filezilla-to-transfer-family#install-some-tool-to-manage-ad-]]


## download file using base64
- tar folder, do not zip it
```powershell
function ConvertTo-Base64($file_path) {
    $content = Get-Content -Path $file_path -Raw
    $byte_array = [System.Text.Encoding]::UTF8.GetBytes($content)
    $base64 = [System.Convert]::ToBase64String($byte_array)
    return $base64
}

# 指定要转换为Base64的文件路径
$file_path = "C:\path\to\your\file.txt"

# 调用函数将文件内容转换为Base64编码
$base64_content = ConvertTo-Base64 -file_path $file_path

# 打印Base64编码后的内容
Write-Host $base64_content

```


## connecting-to-sql-server-using-dotnet-framework-
```powershell
$sqlConn = New-Object System.Data.SqlClient.SqlConnection
$sqlConn.ConnectionString = "Server=xxx.us-east-1.rds.amazonaws.com;Integrated Security=true;Initial Catalog=master"
$sqlConn.Open()

echo $SqlConn

$sqlCmd = $sqlConn.CreateCommand()
$sqlCmd.CommandText = "select session_id,client_net_address from sys.dm_exec_connections"

$sqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
$sqlAdapter.SelectCommand = $sqlCmd

$dataSet = New-Object System.Data.DataSet
$sqlAdapter.Fill($dataSet)

$dataSet.Tables[0] | Format-Table

```

```output
StatisticsEnabled                : False
AccessToken                      :
ConnectionString                 : Server=xxx.com;Integrated Security=true;Initial Catalog=master
ConnectionTimeout                : 15
Database                         : master
DataSource                       : xxx.us-east-1.rds.amazonaws.com
PacketSize                       : 8000
ClientConnectionId               : 02f6f78e-0c5c-4400-9506-2ff19679e978
ServerVersion                    : 15.00.4355
State                            : Open
WorkstationId                    : 11C683A04E28
Credential                       :
FireInfoMessageEventOnUserErrors : False
Site                             :
Container                        :
```

## get compute name
### lab1
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

### lab2
```powershell
# 导入 Active Directory 模块
Import-Module ActiveDirectory

# 设置时间阈值，例如 90 天
$threshold = (Get-Date).AddDays(-90)

# 获取所有计算机账户
$computers = Get-ADComputer -Filter * -Properties Name, LastLogonDate, Enabled

# 筛选有效的计算机账户
$activeComputers = $computers | Where-Object {
    $_.Enabled -eq $true -and
    $_.LastLogonDate -gt $threshold
}

# 导出结果到 CSV 文件
$activeComputers | Select-Object Name, LastLogonDate |
    Export-Csv -Path "C:\ActiveComputers.csv" -NoTypeInformation

# 显示结果摘要
Write-Host "总计算机数量: $($computers.Count)"
Write-Host "有效计算机数量: $($activeComputers.Count)"
Write-Host "结果已导出到 C:\ActiveComputers.csv"

```
