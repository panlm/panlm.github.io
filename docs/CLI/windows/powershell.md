---
title: powershell
created: 2023-01-09 22:45:11.849
last_modified: 2023-12-02
tags:
  - microsoft/windows
  - microsoft/powershell
---
> [!WARNING] This is a github note
# powershell

## download file
```powershell
Invoke-WebRequest -uri 'https://github.com/microsoft/windows-container-tools/releases/download/v1.1/LogMonitor.exe' -OutFile 'c:\Logmonitor.exe'

https://github.com/prometheus-community/windows_exporter/releases/download/v0.18.1/windows_exporter-0.18.1-amd64.msi

Invoke-WebRequest -uri 'https://github.com/prometheus-community/windows_exporter/releases/download/v0.18.1/windows_exporter-0.18.1-amd64.msi' -OutFile 'c:\windows_exporter-0.18.1-amd64.msi'

```

## download-AWSNVMe.zip-
```sh
invoke-webrequest https://s3.amazonaws.com/ec2-windows-drivers-downloads/NVMe/Latest/AWSNVMe.zip -outfile $env:USERPROFILE\nvme_driver.zip
expand-archive $env:userprofile\nvme_driver.zip -DestinationPath $env:userprofile\nvme_driver

```




