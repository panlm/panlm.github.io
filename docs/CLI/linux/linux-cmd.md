---
title: linux-cmd
description: 常用命令
created: 2023-01-03 12:05:10.533
last_modified: 2024-03-27
tags:
  - cmd
  - linux
---

# linux cmd

## awk
```sh
cat docs/CLI/awscli/vpc-cmd.md |awk '/^```sh title="func-.*/,/^```$/ {print}' > /tmp/$$.1
```

## awscurl
```sh
export AWS_DEFAULT_REGION=us-east-2
export AMP_QUERY_ENDPOINT=https://aps-workspaces.us-east-2.amazonaws.com/workspaces/ws-xxx/api/v1/query
awscurl -X POST --region ${AWS_DEFAULT_REGION} --service aps \
"${AMP_QUERY_ENDPOINT}" -d 'query=prometheus_tsdb_head_series' \
--header 'Content-Type: application/x-www-form-urlencoded'

```

```sh
awscurl -X POST --region ${AWS_DEFAULT_REGION} --service aps \
"${AMP_QUERY_ENDPOINT}" -d 'query=up&time=1652382537&stats=all' \
--header 'Content-Type: application/x-www-form-urlencoded'

```

```sh
query=sum+%28rate+%28go_gc_duration_seconds_count%5B1m%5D%29%29&start=1652382537&end=1652384705&step=1000&stats=all
```

### install
```sh
pip install git+https://github.com/okigan/awscurl
```

## brew
- install
```sh
sudo yum install -y git gcc make curl
git clone https://github.com/Homebrew/brew.git
sudo cp brew/bin/brew /usr/local/bin/

```


## column
```sh
column -t
```

## curl
- [[curl-sample-1]]
- badssl.com

### check http return code
```sh
curl -sL -w '%{http_code}' -o /dev/null "https://httpbin.org/status/302"

```

## datediff
- http://www.fresse.org/dateutils/
```sh
git clone https://github.com/hroptatyr/dateutils.git
cd dateutils
sudo yum install -y texinfo gperf
autoreconf -i
./configure
make
sudo make install 
```

## ec2-instance-selector
```sh
brew tap aws/tap
brew install ec2-instance-selector
```

```sh
ec2-instance-selector -c 4 -m 16 -r us-east-2 -a arm64
```

## envsubst
```sh
var1=string1
var2=string2

cat >$$.yaml <<-'EOF'
$var1
$var2
$var3
EOF

export var1 var2
cat $$.yaml |envsubst '$var1 $var2' > $$-new.yaml

```
- refer [[../../../../notes/envsubst|envsubst]]

## ffmpeg
- [[ffmpeg|ffmpeg]]

## fio
- [[../../../../notes/snapshot impact with fio|snapshot impact with fio]]

## firewall-cmd
```sh
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload
```

## function
### less or no parameters
- 在 func 中定义 local 变量，export 后在 func 外部依然无法访问
```sh
function a() {
 local var1=cccc
 echo $var1
 export var1
}

function b() {
  echo $var1
  var1=bbb
}

var1=abc

a
echo $var1

b
echo $var1

```

### parse parameter
`c:p:` 参数 c 和 p 都需要参数
`cp` 参数 c 和 p 都不需要参数

```sh
function parsepara () {
    OPTIND=1
    OPTSTRING="h?v:c:p:"
    local VPC_ID=""
    local VPC_CIDR=""
    local PORTS=()
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            v) VPC_ID=${OPTARG} ;;
            c) VPC_CIDR=${OPTARG} ;;
            p) PORTS+=("${OPTARG}") ;;
            h|\?) 
                echo "format: create-sg -v VPC_ID -c VPC_CIDR [-p PORT1] [-p PORT2]"
                echo -e "\tsample: create-sg -v vpc-xxx -p 172.31.0.0/16"
                echo -e "\tsample: create-sg -v vpc-xxx -p 0.0.0.0/0 -p 80 -p 443"
                return 0
            ;;
        esac
    done
    : ${VPC_ID:?Missing -v}
    : ${VPC_CIDR:?Missing -c}

    echo "CIDR:"${CIDR}
    echo "PORTS:"${PORTS}
    echo "PORTS[@]"${PORTS[@]}

    for i in ${PORTS[@]:--1}; do
        echo "i:"$i
    done
}

```

## history
```bash
bash                        # open a new session.
unset HISTFILE              # avoid recording commands to file.
commands not recorded
.
.
exit

```

## imagemagick
```sh
brew install imagemagick
```

## ip-forward-
```sh
echo 'net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
' |tee -a /etc/sysctl.conf
sysctl -p
```

## ip-public
- [[../../../../cmd-my-public-ip-address|cmd-my-public-ip-address]]

## iptables-
### MASQUERADE-
```sh
iptables -t nat -A POSTROUTING -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
```

### iptables
```sh
yum install iptables-services -y;

# Start and configure iptables:
systemctl enable iptables;
systemctl start iptables;


# Configuration below allows allows all traffic:
# Set the default policies for each of the built-in chains to ACCEPT:
iptables -P INPUT ACCEPT;
iptables -P FORWARD ACCEPT;
iptables -P OUTPUT ACCEPT;

# Flush the nat and mangle tables, flush all chains (-F), and delete all non-default chains (-X):
iptables -t nat -F;
iptables -t mangle -F;
iptables -F;
iptables -X;

# Configure nat table to hairpin traffic back to GWLB:
iptables -t nat -A PREROUTING -p udp -s $gwlb_ip -d $instance_ip -i eth0 -j DNAT --to-destination $gwlb_ip:6081;
iptables -t nat -A POSTROUTING -p udp --dport 6081 -s $gwlb_ip -d $gwlb_ip -o eth0 -j MASQUERADE;

# Save iptables:
service iptables save;

```

## lsblk-
```
lsblk -o name,mountpoint,label,size,uuid
```

## network monitor
- https://www.tecmint.com/linux-network-bandwidth-monitoring-tools/

### iperf
- https://aws.amazon.com/premiumsupport/knowledge-center/network-throughput-benchmark-linux-ec2/
- server 
```sh
sudo iperf -s
```
- client 
```sh
iperf -c 172.31.30.41 --parallel 40 -i 1 -t 2
```
or
```sh
iperf -c 172.31.26.3 -t 30 -P 8
```

#### install
```sh
sudo apt install -y iperf iptraf tcpdump netperf tmux htop atop  net-tools traceroute tcptraceroute ngrep 
```


## openssl
compile
- https://gist.github.com/fernandoaleman/5459173e24d59b45ae2cfc618e20fe06

### encryption
- encrypt on mac
```sh
openssl enc -aes-256-cbc -salt -in file.txt -out file.enc
```
- decrypt on linux
```sh
openssl enc -d -aes-256-cbc -in file.enc -out file.txt -pass pass:yourpassword
```

## parallel
touch 1024 files, with parallel 128, filename will test-1, test-2, etc.
```sh
time seq 1 1024 | parallel --will-cite -j 128 touch /mnt/efs/01/tutorial/touch/${directory}/test-1.4-{}

```

## regctl
- [[regctl|regctl]]

## rsync 
### notable folder
```bash
rsync -narv --delete /home/ubuntu/.notable /home/ubuntu/OneDrive/CrossSync/

```

### sync to s3
upload only md file to s3
- --exclude 参数必须放在 --include 参数之前。
- 如果您需要上传多个类型文件，可以使用多个 --include 参数。
```sh
aws s3 sync ./work-notes s3://knowledge-base-quick-worknotes-1350/work-notes --delete  --exclude "*" --include "*.md"
```

### work-notes
```sh
bash

export HISTSIZE=0
cd ~/Documents/
rsync -avr --delete \
    --exclude='**/.venv' \
    --exclude='**/node_modules' \
    ./git \
    ./work-notes \
    ./SA-Baseline-50-12 \
    ./customers \
    ./myq \
    stevenpan@10.68.69.100:/Users/stevenpan/Documents/ 

# -ni # check any files will be deleted

```


## sed
```sh
file=file.md
gsed -i 's/^!\[\[\([^]]\+\)\]\]/![](\1)/' ${file}
# change 
# ![[stream-k8s-control-panel-logs-to-s3-21.png]]
# to 
# ![](stream-k8s-control-panel-logs-to-s3-21.png)
```

## snapd
```sh
sudo mkdir -p /etc/systemd/system/snapd.service.d/
echo -e '[Service]\nEnvironment="http_proxy=http://1.2.3.4:3128/"' \
      | sudo tee /etc/systemd/system/snapd.service.d/http-proxy.conf
echo -e '[Service]\nEnvironment="https_proxy=http://1.2.3.4:3128/"' \
      | sudo tee /etc/systemd/system/snapd.service.d/https-proxy.conf
sudo systemctl daemon-reload
sudo systemctl restart snapd

```

## sponge & tee & redirect to same file
sponge  reads  standard input and writes it out to the specified file. Unlike a shell redirect, sponge soaks up all its input before opening the output file. This allows constructing pipelines that read from and write to the same file.

## ssh
- [[../../../../ssh-cmd|ssh-cmd]]

## stress-ng

```
stress-ng --vm-bytes $(awk '_MemFree_{printf "%d\n", $2 * 0.95;}' < _proc_meminfo)k --vm-keep -m 1
```

### container
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cpu-stress-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stress-ng
  template:
    metadata:
      labels:
        app: stress-ng
    spec:
      containers:
      - name: stress-ng-container
        image: polinux/stress-ng # progrium/stress
        command:
        - 'sh'
        - '-c'
        - |
          while true ; do
            echo "start stress (10 min)"
            stress-ng --cpu 2 --timeout 600
            echo "start sleep (10min)"
            sleep 600
          done
        resources:
          limits:
            cpu: "1"
          requests:
            cpu: "1"
```

## tar
```sh
tar cf a.tar ./blue-green-upgrade/ --exclude=".terraform"
```

## tcp setting - TIME_WIAT
```sh
net.ipv4.tcp_fin_timeout = 30
net.ipv4.ip_local_port_range = 15000 65000
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1

net.ipv4.ip_forward=1
net.ipv4.conf.all.accept_source_route = 1

```

## tc - traffic control
```sh
yum install iproute-tc

```

### doc
- https://lartc.org/lartc.html#LARTC.COOKBOOK.FULLNAT.INTRO

### scenario
- [[connection-network-with-overlap-cidrs#Solution for Overlapping CIDRs using AWS Transit Gateway in VPC and NAT Instances]]

## tcpdump
dump multicast packages
```
tcpdump -i ens5 -s0 -vv net 224.0.0.0/4 -A
```

## ts
add timestamp at the front of every command output
```sh
yum install moreutils
ls |ts
```

## vim
- [[vim-cmd|vim-cmd]]

## wscat-

```sh
sudo apt install -y npm
npm install wscat

```


## webi.sh
### go-
```sh
curl -sS https://webi.sh/golang | sh
source ~/.config/envman/PATH.env

```

## xfs
### xfs-mount-
```sh
mount -t xfs -o nouuid /dev/nvme1n1 /mnt
```

### get uuid
```sh
xfs_db -c uuid /dev/nvme1n1
```

## xtop
- top
- htop
- [[atop]]
- iftop
```
iftop -t -s 10 > output
```

## yum
```sh
yum --showduplicates list terraform
yum install terraform-1.5.7-1
yum versionlock terraform
```

### fixed version

=== "centos7"

    ```sh
    yum install yum-plugin-versionlock
    ```

=== "centos8/9"

    ```sh
    yum install python3-dnf-plugin-versionlock
    ```

## ip address calc
```sh
yum -y install sipcalc --enablerepo=epel
```

```sh
brew install sipcalc 
```


## others
- [[web-performance-testing-tool]]
- [[httpbin.org]]
- [[badssl.com]]



