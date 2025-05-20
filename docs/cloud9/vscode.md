---
title: CodeServer
description: Using code-server on EC2 instead of Cloud9 due to it has been deprecated
created: 2024-08-19 09:36:24.009
last_modified: 2025-05-20
status: myblog
tags:
  - draft
---

# vscode
https://github.com/coder/code-server

## manual install vscode
```sh
sudo apt-get -yq install argon2 moreutils awscli
# install code-server
IDE_PASSWORD=$(echo -n $(aws sts get-caller-identity --query "Account" --output text) | argon2 $(uuidgen) -e)
mkdir -p ~/.config/code-server
tee ~/.config/code-server/config.yaml <<-EOF
cert: false
auth: password
hashed-password: "${IDE_PASSWORD}"
bind-addr: 0.0.0.0:8088
EOF

mkdir -p ~/.local/share/code-server/User
tee ~/.local/share/code-server/User/settings.json <<-'EOF'
{
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "terminal.integrated.cwd": "/home/ubuntu",
  "telemetry.telemetryLevel": "off",
  "security.workspace.trust.startupPrompt": "never",
  "security.workspace.trust.enabled": false,
  "security.workspace.trust.banner": "never",
  "security.workspace.trust.emptyWindow": false,
  "workbench.startupEditor": "terminal",
  "task.allowAutomaticTasks": "on",
  "editor.indentSize": "tabSize",
  "editor.tabSize": 2,
  "python.testing.pytestEnabled": true,
  "auto-run-command.rules": [
    {
      "command": "workbench.action.terminal.new"
    }
  ]
}
EOF

# CODE_SERVER_VER=4.100.2
# wget -qO /tmp/code-server.deb https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VER}/code-server_${CODE_SERVER_VER}_amd64.deb
# sudo dpkg -i /tmp/code-server.deb
# sudo systemctl enable --now code-server@ubuntu
# sudo systemctl restart code-server@ubuntu

wget -O- https://github.com/coder/code-server/raw/refs/heads/main/install.sh |sh
sudo systemctl enable --now code-server@$USER

```

## cloudformation template for deploy
-  deploy vscode on ec2 ([[example_instancestack_vscode.yaml]])
- run command on cloudshell
```sh
# OS=amazonlinux2023
wget -O example_instancestack_vscode.yaml https://panlm.github.io/cloud9/example_instancestack_vscode.yaml
aws configure list
export AWS_DEFAULT_REGION AWS_REGION
# TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
# export AWS_DEFAULT_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
# export AWS_REGION=${AWS_DEFAULT_REGION}
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
                     ParameterKey=EC2InstanceOS,ParameterValue="${OS:-ubuntu22}" \
                     ParameterKey=EC2InstanceType,ParameterValue="m5.large" \
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
codeServerVersion=4.100.2
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


