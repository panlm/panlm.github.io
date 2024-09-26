---
title: vscode
description: code-server on EC2
created: 2024-08-19 09:36:24.009
last_modified: 2024-09-19
tags:
  - draft
---

# vscode
https://github.com/coder/code-server

## cloudformation template for deploy
-  deploy vscode on ec2 ([[example_instancestack_vscode.yaml]])
- run command on cloudshell
```sh
wget -O example_instancestack_vscode.yaml https://panlm.github.io/cloud9/example_instancestack_vscode.yaml
aws configure list
export AWS_DEFAULT_REGION AWS_REGION
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
    --filter Name=is-default,Values=true \
    --query 'Vpcs[0].VpcId' --output text \
    --region ${AWS_DEFAULT_REGION})
VPC_ID=${VPC_ID:=$DEFAULT_VPC_ID}

if [[ ! -z ${VPC_ID} ]]; then
    FIRST_SUBNET=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=${VPC_ID}" \
        --query 'Subnets[?(MapPublicIpOnLaunch==`true`)].SubnetId' \
        --output text \
        --region ${AWS_DEFAULT_REGION} |\
        xargs -n 1 |tail -n 1)
    STACK_NAME=vscode-$(TZ=EAT-8 date +%Y%m%d-%H%M%S)
    aws cloudformation create-stack --stack-name ${STACK_NAME} \
        --parameters ParameterKey=VpcId,ParameterValue="${VPC_ID}" \
                     ParameterKey=PublicSubnetId,ParameterValue="${FIRST_SUBNET}" \
                     ParameterKey=EC2InstanceOS,ParameterValue="ubuntu22" \
        --capabilities CAPABILITY_IAM --region ${AWS_DEFAULT_REGION} \
        --template-body file://./example_instancestack_vscode.yaml
else
    echo "you have no default vpc in ${AWS_DEFAULT_REGION}"
fi

aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
aws cloudformation describe-stacks --stack-name ${STACK_NAME} \
    --query 'Stacks[0].Outputs[?OutputKey==`AccessURL` || OutputKey==`Password`].OutputValue'

```

## deploy on al2023
- ec2-user user
```sh
codeServerVersion=4.92.2
curl -fsSL https://code-server.dev/install.sh | sh -s -- --version ${codeServerVersion}
sudo systemctl enable --now code-server@$USER

IDE_PASSWORD=$(uuidgen)
mkdir -p ~/.config/code-server
touch ~/.config/code-server/config.yaml
tee ~/.config/code-server/config.yaml <<EOF
cert: true 
auth: password
password: "$IDE_PASSWORD"
bind-addr: 0.0.0.0:9090
EOF

sudo systemctl restart code-server@$USER

```

## extension
### continue
integrate with brconnector ([link](https://docs.continue.dev/reference/Model%20Providers/openai))



## ~~install on ubuntu~~
- https://code.visualstudio.com/docs/setup/linux
```sh
wget -O '/tmp/linux-deb-x64.deb'  'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64'
sudo apt update
sudo apt install /tmp/linux-deb-x64.deb -f

```

### ~~systemctl~~
```sh
sudo tee /etc/systemd/system/code-server.service <<EOF
[Unit]
Description=Start code server

[Service]
ExecStart=/usr/bin/code serve-web --port 8080 --host 127.0.0.1 --without-connection-token
#ExecStart=/usr/bin/code serve-web --port 8080 --host 0.0.0.0 --connection-token token-string 
Restart=always
Type=simple
User=ubuntu

[Install]
WantedBy = multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now code-server
sudo systemctl restart code-server

```

### ~~access web ui with token~~
```
http://public-ip-address:8080/?tkn=token-string
```

### ~~add basic auth~~
- refer: [[../others/network/caddy#basic-http-auth-|basic auth]]


