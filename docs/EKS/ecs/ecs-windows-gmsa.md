---
title: ecs-windows-gmsa
description: 
created: 2024-02-26 08:53:45.476
last_modified: 2024-04-04
tags:
  - microsoft/windows
  - aws/container/ecs
---
# ecs-windows-gmsa

| ecs node | ec2          | fargate        |     |
| -------- | ------------ | -------------- | --- |
| windows  | support gMSA | do not support |     |
| linux    | support gMSA | support gMSA   |     |
|          |              |                |     |


- ecs
    - windows node
        - on ec2 
            - join domain: [[ws-windows-containers-on-aws]] lab 4
            - domainless: [[poc-container-on-domainless-windows-node-in-ecs]] 
        - on fargate do not support
    - linux
        - on ec2: https://docs.aws.amazon.com/zh_cn/AmazonECS/latest/developerguide/linux-gmsa.html
        - on fargate: https://aws.amazon.com/blogs/containers/windows-authentication-with-gmsa-on-linux-containers-on-amazon-ecs-with-aws-fargate/


## walkthrough
https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/manage-serviceaccounts

![[attachments/ecs-windows-gmsa/IMG-ecs-windows-gmsa.png]]

create ad group and user
```powershell
$gmsa = "WebApp02"
$groupname = "WebApp02Group"
$username = "WebApp02Account"
$password = "Password1234!"
$domainname = "containersws.local"

# Create the security group
New-ADGroup -Name "$groupname Authorized Accounts" -SamAccountName $groupname -GroupScope DomainLocal

# Create the gMSA
New-ADServiceAccount -Name $gmsa -DnsHostName "$gmsa.$domainname" -ServicePrincipalNames "host/$gmsa", "host/$gmsa.$domainname" -PrincipalsAllowedToRetrieveManagedPassword $groupname

# Create the standard user account. This account information needs to be stored in a secret store and will be retrieved by the ccg.exe hosted plug-in to retrieve the gMSA password. Replace 'StandardUser01' and 'p@ssw0rd' with a unique username and password. We recommend using a random, long, machine-generated password.
New-ADUser -Name $username -AccountPassword (ConvertTo-SecureString -AsPlainText $password -Force) -Enabled 1

# Add your container hosts to the security group
Add-ADGroupMember -Identity $groupname -Members $username

```

create credspec
```powershell
Install-Module -Name CredentialSpec -Force
New-CredentialSpec -AccountName $gmsa -Path "C:\MyFolder\WebApp01_CredSpec.json"
```

save user / password in secret manager
https://docs.amazonaws.cn/en_us/AmazonECS/latest/developerguide/tutorial-gmsa-windows.html#tutorial-gmsa-windows-step2
```
aws secretsmanager create-secret \
--name gmsa-plugin-input-domainless \
--description "Amazon ECS - gMSA Portable Identity." \
--secret-string '{"username":"StandardUser01","password":"Password1234!","domainName":"containersws.local"}'
```

modify for ECS 
https://docs.amazonaws.cn/en_us/AmazonECS/latest/developerguide/tutorial-gmsa-windows.html#tutorial-gmsa-windows-step3
```json
"HostAccountConfig": {
      "PortableCcgVersion": "1",
      "PluginGUID": "{859E1386-BDB4-49E8-85C7-3070B13920E1}",
      "PluginInput": "{\"credentialArn\": \"arn:aws:secretsmanager:aws-region:111122223333:secret:gmsa-plugin-input\"}"
    }
```


## refer
- [Additional credential spec configuration for non-domain-joined container host use case](https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-containers/manage-serviceaccounts#additional-credential-spec-configuration-for-non-domain-joined-container-host-use-case) 
- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/windows-gmsa.html


## troubleshooting
https://github.com/microsoft/SDN/issues/339
```powershell
PS C:\> nltest /sc_verify:containersws.local
Flags: b0 HAS_IP  HAS_TIMESERV
Trusted DC Name \\IP-C61302A0.containersws.local
Trusted DC Connection Status Status = 0 0x0 NERR_Success
Trust Verification Status = 0 0x0 NERR_Success
The command completed successfully

```

```powershell
dir \\containersws.local\sysvol

```

```powershell
klist get krbtgt
klist sessions
```



