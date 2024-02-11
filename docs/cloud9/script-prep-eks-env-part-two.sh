#!/bin/bash
###-SCRIPT-PART-TWO-BEGIN-###
echo "###"
echo "SCRIPT-PART-TWO-BEGIN"
echo "###"

mv -f ~/.bash_completion ~/.bash_completion.$(date +%N)
# install kubectl with +/- 1 cluster version 1.24.17 / 1.25.16 / 1.26.13 / 1.27.10
# refer: https://kubernetes.io/releases/
# sudo curl --location -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo curl --silent --location -o /usr/local/bin/kubectl "https://storage.googleapis.com/kubernetes-release/release/v1.26.13/bin/linux/amd64/kubectl"
sudo chmod +x /usr/local/bin/kubectl

/usr/local/bin/kubectl completion bash >>  ~/.bash_completion
source /etc/profile.d/bash_completion.sh
source ~/.bash_completion
alias k=kubectl 
complete -F __start_kubectl k
echo "alias k=kubectl" >> ~/.bashrc
echo "complete -F __start_kubectl k" >> ~/.bashrc

# install eksctl
# consider install eksctl version 0.89.0
# if you have older version yaml 
# https://eksctl.io/announcements/nodegroup-override-announcement/
curl -L "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp/
sudo mv -v /tmp/eksctl /usr/local/bin
/usr/local/bin/eksctl completion bash >> ~/.bash_completion
source /etc/profile.d/bash_completion.sh
source ~/.bash_completion

# install kubectx
curl -L "https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubectx_v0.9.5_linux_x86_64.tar.gz" |tar xz -C /tmp/
sudo mv -f /tmp/kubectx /usr/local/bin/
# install kubens
curl -L "https://github.com/ahmetb/kubectx/releases/download/v0.9.5/kubens_v0.9.5_linux_x86_64.tar.gz" |tar xz -C /tmp/
sudo mv -f /tmp/kubens /usr/local/bin/

# install k9s
curl -L "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz" |tar xz -C /tmp/
sudo mv -f /tmp/k9s /usr/local/bin/

# install eksdemo
curl -L "https://github.com/awslabs/eksdemo/releases/latest/download/eksdemo_$(uname -s)_$(uname -p).tar.gz" |tar xz -C /tmp/
sudo mv -v /tmp/eksdemo /usr/local/bin
/usr/local/bin/eksdemo completion bash >> ~/.bash_completion
source /etc/profile.d/bash_completion.sh
source ~/.bash_completion

# helm newest version (3.10.3)
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
# helm 3.8.2 (helm 3.9.0 will have issue #10975)
# wget https://get.helm.sh/helm-v3.8.2-linux-amd64.tar.gz
# tar xf helm-v3.8.2-linux-amd64.tar.gz
# sudo mv linux-amd64/helm /usr/local/bin/helm
/usr/local/bin/helm version --short

# install aws-iam-authenticator 0.6.11 (2023/10) 
wget -O /tmp/aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.6.14/aws-iam-authenticator_0.6.14_linux_amd64
chmod +x /tmp/aws-iam-authenticator
sudo mv /tmp/aws-iam-authenticator /usr/local/bin/

# install kube-no-trouble
sh -c "$(curl -sSL https://git.io/install-kubent)"

# install kubectl convert plugin
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert" --output-dir /tmp
curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert.sha256" --output-dir /tmp
echo "$(cat /tmp/kubectl-convert.sha256) /tmp/kubectl-convert" | sha256sum --check
sudo install -o root -g root -m 0755 /tmp/kubectl-convert /usr/local/bin/kubectl-convert
rm /tmp/kubectl-convert /tmp/kubectl-convert.sha256

# option install jwt-cli
# https://github.com/mike-engel/jwt-cli/blob/main/README.md
# sudo yum -y install cargo
# cargo install jwt-cli
# sudo ln -sf ~/.cargo/bin/jwt /usr/local/bin/jwt

# install flux & fluxctl
curl -s https://fluxcd.io/install.sh | sudo -E bash
/usr/local/bin/flux -v
source <(/usr/local/bin/flux completion bash)

# sudo wget -O /usr/local/bin/fluxctl $(curl https://api.github.com/repos/fluxcd/flux/releases/latest | jq -r ".assets[] | select(.name | test(\"linux_amd64\")) | .browser_download_url")
# sudo chmod 755 /usr/local/bin/fluxctl
# fluxctl version
# fluxctl identity --k8s-fwd-ns flux

echo "###"
echo "SCRIPT-PART-TWO-END"
echo "###"
###-SCRIPT-PART-TWO-END-###

