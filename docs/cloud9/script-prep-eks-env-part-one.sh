#!/bin/bash
###-SCRIPT-PART-ONE-BEGIN-###
echo "###"
echo "SCRIPT-PART-ONE-BEGIN"
echo "###"
# set size as your expectation, otherwize 100g as default volume size
# size=200

# default execute this script in EC2, not Cloud9
echo ${EXECUTE_IN_CLOUD9:=false}

# install others
sudo yum -y install jq gettext bash-completion wget argon2 # moreutils

# install terraform 
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform

# install code-server
IDE_PASSWORD=$(echo -n $(aws sts get-caller-identity --query "Account" --output text) | argon2 $(uuidgen) -e)
mkdir -p ~/.config/code-server
tee ~/.config/code-server/config.yaml <<-EOF
cert: false
auth: password
hashed-password: "$IDE_PASSWORD"
bind-addr: 0.0.0.0:8088
EOF
mkdir -p ~/.local/share/code-server/User
tee ~/.local/share/code-server/User/settings.json <<EOF
{
"extensions.autoUpdate": false,
"extensions.autoCheckUpdates": false,
"terminal.integrated.cwd": "/home/$USER",
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

CODE_SERVER_VER=4.93.1
wget -qO /tmp/code-server.rpm https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VER}/code-server-${CODE_SERVER_VER}-amd64.rpm
sudo yum install -y /tmp/code-server.rpm
sudo systemctl enable --now code-server@ec2-user
sudo systemctl restart code-server@ec2-user

# install awscli v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
echo A |unzip /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install --update 2>&1 >/tmp/awscli-install.log
echo "complete -C '/usr/local/bin/aws_completer' aws" >> ~/.bash_profile

# remove existed aws
if [[ $? -eq 0 ]]; then
  sudo yum remove -y awscli
  source ~/.bash_profile
  aws --version
fi

# install awscli v1
# curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
# unzip awscli-bundle.zip
# sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

# install ssm session plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "/tmp/session-manager-plugin.rpm"
sudo yum install -y /tmp/session-manager-plugin.rpm

# your default region 
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export AWS_DEFAULT_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

# change root volume size for cloud9
if [[ ${EXECUTE_IN_CLOUD9} == "true" ]]; then
if [[ -c /dev/nvme0 ]]; then
  wget -qO- https://github.com/amazonlinux/amazon-ec2-utils/raw/main/ebsnvme-id >/tmp/ebsnvme-id
  VOLUME_ID=$(sudo python3 /tmp/ebsnvme-id -v /dev/nvme0 |awk '{print $NF}')
  DEVICE_NAME=/dev/nvme0n1
else
  C9_INST_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
  VOLUME_ID=$(aws ec2 describe-volumes --filters Name=attachment.instance-id,Values=${C9_INST_ID} --query "Volumes[0].VolumeId" --output text)
  DEVICE_NAME=/dev/xvda
fi

aws ec2 modify-volume --volume-id ${VOLUME_ID} --size ${size:-100}
sleep 10
sudo growpart ${DEVICE_NAME} 1
sudo xfs_growfs -d /

if [[ $? -eq 1 ]]; then
  ROOT_PART=$(df |grep -w / |awk '{print $1}')
  sudo resize2fs ${ROOT_PART}
fi
fi

echo "###"
echo "SCRIPT-PART-ONE-END"
echo "###"
###-SCRIPT-PART-ONE-END-###
