#!/bin/bash
(###-SCRIPT-PART-ONE-BEGIN-###
echo "###"
echo "SCRIPT-PART-ONE-BEGIN"
echo "###"
# set size as your expectation, otherwize 100g as default volume size
# size=200

# default execute this script in EC2, not Cloud9
echo ${EXECUTE_IN_CLOUD9:=false}

# install others
export DEBIAN_FRONTEND=noninteractive
sudo -E apt update
sudo -E apt-get -yq install jq gettext bash-completion wget argon2 moreutils awscli

# install terraform 
sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo -E apt update
sudo -E apt-get -yq install terraform=1.5.7-1
sudo apt-mark hold terraform

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
tee ~/.local/share/code-server/User/settings.json <<EOF
{
"extensions.autoUpdate": false,
"extensions.autoCheckUpdates": false,
"terminal.integrated.cwd": "/home/$USER",
"terminal.integrated.wordSeparators": " ()[]{}',\"`─‘’“”|=",
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

CODE_SERVER_VER=4.96.2
wget -qO /tmp/code-server.deb https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VER}/code-server_${CODE_SERVER_VER}_amd64.deb
sudo dpkg -i /tmp/code-server.deb
sudo systemctl enable --now code-server@ubuntu
sudo systemctl restart code-server@ubuntu

# install awscli v2
# sudo -E apt-get -yq install awscli
echo "complete -C '/usr/bin/aws_completer' aws" >> ~/.bash_profile

# install ssm session plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb"
sudo dpkg -i /tmp/session-manager-plugin.deb

# your default region 
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export AWS_DEFAULT_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

# change root volume size in cloud9
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
)



