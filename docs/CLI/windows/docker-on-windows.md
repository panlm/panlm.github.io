---
title: docker-on-windows
description: 
created: 2024-02-18 15:25:34.650
last_modified: 2024-03-15
tags:
  - microsoft/windows
  - docker
---

# Docker On Windows

## install-docker-on-windows-after-may-2023-
- https://github.com/OneGet/MicrosoftDockerProvider
```powershell
Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/microsoft/Windows-Containers/Main/helpful_tools/Install-DockerCE/install-docker-ce.ps1" -o install-docker-ce.ps1
.\install-docker-ce.ps1

```

![[../../git-attachment/docker-on-windows-png-1.png]]


## sample build iis + sqlcmd container
- iis + sqlcmd
```Dockerfile
FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2019

# https://learn.microsoft.com/en-us/sql/tools/sqlpackage/sqlpackage-download?view=sql-server-ver16#installation-file-download-alternative
# Download the SQL Server command-line tools installer
ADD https://go.microsoft.com/fwlink/?linkid=2262108 C:\\temp\\sqlcmd.msi
# Install sqlcmd using the installer
RUN msiexec /i C:\\temp\\sqlcmd.msi /quiet
# Add sqlcmd to the PATH environment variable
RUN setx PATH "%PATH%;C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn"

RUN powershell -NoProfile -Command Remove-Item -Recurse C:\inetpub\wwwroot\*

WORKDIR /inetpub/wwwroot

COPY index.html .

```


## windows 2016
- failed start docker daemon
```error
fatal: failed to start daemon: this version of Windows does not support the docker daemon (Windows build 17763 or higher is required)
```


## windows 2019
- no need to enable tls1.2
- [[#install-docker-on-windows-after-may-2023-]] 


## deprecated

```powershell
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module -Name DockerMsftProvider -Force
Install-Package -Name docker -ProviderName DockerMsftProvider -Force
Restart-Computer -Force
```

## enable tls1.2
- session
```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```
- global
```powershell
reg add HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319 /f /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /reg:64  
reg add HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319 /f /v SystemDefaultTlsVersions /t REG_DWORD /d 1 /reg:32  
reg add HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319 /f /v SchUseStrongCrypto /t REG_DWORD /d 1 /reg:64  
reg add HKLM\SOFTWARE\Microsoft\.NETFramework\v4.0.30319 /f /v SchUseStrongCrypto /t REG_DWORD /d 1 /reg:32
```


