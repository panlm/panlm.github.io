#!/bin/bash
(###-SCRIPT-PART-ONE-BEGIN-###
echo "###"
echo "SCRIPT-PART-ONE-BEGIN"
echo "###"
# set size as your expectation, otherwize 100g as default volume size
# size=200

# install others
export DEBIAN_FRONTEND=noninteractive
sudo -E apt update
sudo -E apt-get -yq install jq gettext bash-completion moreutils wget

# install terraform 
sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo -E apt update
sudo -E apt-get -yq install terraform=1.5.7-1
sudo apt-mark hold terraform

# install code-server
CODE_SERVER_VER=4.92.2
wget -O code-server.deb https://github.com/coder/code-server/releases/download/v$CODE_SERVER_VER/code-server_CODE_SERVER_VER_amd64.deb
sudo dpkg -i code-server.deb
sudo systemctl enable --now code-server@ubuntu
sudo systemctl restart code-server@ubuntu

# install awscli v2
sudo -E apt-get -yq install awscli
echo "complete -C '/usr/bin/aws_completer' aws" >> ~/.bash_profile

# install ssm session plugin
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "/tmp/session-manager-plugin.deb"
sudo dpkg -i /tmp/session-manager-plugin.deb

# your default region 
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export AWS_DEFAULT_REGION=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

# change root volume size
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

echo "###"
echo "SCRIPT-PART-ONE-END"
echo "###"
###-SCRIPT-PART-ONE-END-###
)



