---
title: linux-cmd
description: 常用命令
created: 2023-01-03 12:05:10.533
last_modified: 2024-01-13
tags:
  - cmd
  - linux
---
> [!WARNING] This is a github note

# linux cmd

## awk
```sh
cat docs/CLI/awscli/vpc-cmd.md |awk '/^```sh title="func-.*/,/^```$/ {print}' > /tmp/$$.1
```

## brew
- install
```sh
sudo yum install -y git gcc make curl
git clone https://github.com/Homebrew/brew.git
sudo cp brew/bin/brew /usr/local/bin/

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

## ip-forward-
```sh
echo 'net.ipv4.ip_forward = 1
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.default.accept_source_route = 0
' |tee -a /etc/sysctl.conf
sysctl -p
```

## iptables-
### MASQUERADE-
```sh
iptables -t nat -A POSTROUTING  -j MASQUERADE
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

## rsync 
### notable folder
```bash
rsync -narv --delete /home/ubuntu/.notable /home/ubuntu/OneDrive/CrossSync/

```

### work-notes
```sh
bash

export HISTSIZE=0
cd ~/Documents/
rsync -avr --delete ./work-notes stevenpan@10.68.69.100:/Users/stevenpan/Documents/

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

## sponge & tee & redirect to same file
sponge  reads  standard input and writes it out to the specified file. Unlike a shell redirect, sponge soaks up all its input before opening the output file. This allows constructing pipelines that read from and write to the same file.

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

## ip address calc
```sh
yum -y install sipcalc --enablerepo=epel
```

```sh
brew install sipcalc 
```


## others
- [[web-press-testing-tool]]
- [[httpbin.org]]
- [[badssl.com]]



