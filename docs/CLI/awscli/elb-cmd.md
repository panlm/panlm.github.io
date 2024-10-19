---
title: elb
description: 常用命令
created: 2022-09-20 16:10:45.855
last_modified: 2023-12-07
icon: simple/awselasticloadbalancing
tags:
  - aws/network/elb
  - aws/cmd
---

# elb-cmd
## nlb and target group
创建nlb和tg，端口监听80

```sh
uniqstr=$(date +%Y%m%d%H%M)
port1=80
export AWS_DEFAULT_REGION=us-east-2
#VPC_ID=vpc-000a5xxxx5a67b03b
VPC_ID=$(aws ec2 describe-vpcs \
--filter Name=is-default,Values=true \
--query 'Vpcs[0].VpcId' --output text \
--region ${AWS_DEFAULT_REGION})

FIRST_SUBNET=$(aws ec2 describe-subnets \
--filters "Name=vpc-id,Values=${VPC_ID}" \
--query "Subnets[?AvailabilityZone=='"${AWS_DEFAULT_REGION}a"'].SubnetId" \
--output text \
--region ${AWS_DEFAULT_REGION})

aws elbv2 create-load-balancer \
--name nlb1-${uniqstr} \
--type network \
--scheme internet-facing \
--subnets ${FIRST_SUBNET} |tee /tmp/$$.1
nlb1_arn=$(cat /tmp/$$.1 |jq -r '.LoadBalancers[0].LoadBalancerArn')

aws elbv2 create-target-group \
--name nlb1-tg-${port1}-${uniqstr} \
--protocol TCP \
--port ${port1} \
--vpc-id ${VPC_ID} |tee /tmp/$$.2
tg1_arn=$(cat /tmp/$$.2 |jq -r '.TargetGroups[0].TargetGroupArn')

aws elbv2 create-listener --load-balancer-arn ${nlb1_arn} \
--protocol TCP --port ${port1}  \
--default-actions Type=forward,TargetGroupArn=${tg1_arn}

```

## func-alb-and-tg-
```sh title="func-alb-and-tg" linenums="1"
# depends on: VPC_ID / CERTIFICATE_ARN
# output variable: ALB_ARN
# quick link: https://panlm.github.io/CLI/functions/create-alb-and-tg.sh

function create-alb-and-tg () {
    OPTIND=1
    OPTSTRING="h?v:c:it:"
    local VPC_ID=""
    local CERTIFICATE_ARN=""
    local LB_SCHEME="internet-facing"
    local TYPE=""
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            v) VPC_ID=${OPTARG} ;;
            c) CERTIFICATE_ARN=${OPTARG} ;;
            i) LB_SCHEME="internal" ;;
            t) TYPE=${OPTARG} ;;
            h|\?) 
                echo "format: $0 -v VPC_ID -t [alb|nlb] [ -c CERTIFICATE_ARN ] [ -i ] "
                echo -e "\tsample: $0 -c vpc-xxxx "
                echo 
                return 0
            ;;
        esac
    done
    : ${AWS_DEFAULT_REGION:?Missing AWS_DEFAULT_REGION}

    if [[ -z ${VPC_ID} ]]; then
        VPC_ID=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true \
        --query 'Vpcs[0].VpcId' --output text)
    fi

    if [[ ${TYPE} == "alb" ]]; then
        local LB_PROTO=HTTP
        local LB_TYPE=application
    elif [[ ${TYPE} == "nlb" ]]; then
        local LB_PROTO=TCP
        local LB_TYPE=network
    else
        echo "only alb or nlb allowed in -t parameter"
        return 1
    fi

    local UNIQ_STR=$(TZ=EAT-8 date +%m%d-%H%M%S)
    local PORT80=80
    local PORT443=443

    # get public subnet for external alb
    local SUBNETS_IDS=$(aws ec2 describe-subnets \
        --filter "Name=vpc-id,Values=${VPC_ID}" \
        --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' \
        --output text)

    # get default security group 
    local DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
        --filter Name=vpc-id,Values=${VPC_ID} \
        --query "SecurityGroups[?GroupName == 'default'].GroupId" \
        --output text)

    # allow 80/443 from anywhere
    for i in 80 443 ; do
    aws ec2 authorize-security-group-ingress \
        --group-id ${DEFAULT_SG_ID} \
        --protocol tcp \
        --port $i \
        --cidr 0.0.0.0/0  
    done

    # create external alb
    aws elbv2 create-load-balancer --name ${TYPE}-${UNIQ_STR} \
        --type ${LB_TYPE} \
        --subnets ${SUBNETS_IDS} \
        --scheme ${LB_SCHEME} \
        --security-groups ${DEFAULT_SG_ID} |tee /tmp/$$-lb
    LB_ARN=$(cat /tmp/$$-lb |jq -r '.LoadBalancers[0].LoadBalancerArn')
    LB_DNSNAME=$(cat /tmp/$$-lb |jq -r '.LoadBalancers[0].DNSName')

    if [[ ${TYPE} == "alb" ]]; then
        MATCHER_OPTION='--matcher HttpCode="200-202,400-404"'
    else
        MATCHER_OPTION=""
    fi
    aws elbv2 create-target-group \
        --name ${TYPE}-tg-${PORT80}-${UNIQ_STR} \
        --protocol ${LB_PROTO} \
        --port ${PORT80} \
        --target-type ip \
        --vpc-id ${VPC_ID} ${MATCHER_OPTION} |tee /tmp/$$-tg80
    TG80_ARN=$(cat /tmp/$$-tg80 |jq -r '.TargetGroups[0].TargetGroupArn')

    if [[ ${TYPE} == "alb" ]]; then
        aws elbv2 create-listener --load-balancer-arn ${LB_ARN} \
            --protocol ${LB_PROTO} --port ${PORT80}  \
            --default-actions Type=fixed-response,FixedResponseConfig="{MessageBody=,StatusCode=404,ContentType=text/plain}" |tee /tmp/$$-lsnr80
        local LSNR80_ARN=$(cat /tmp/$$-lsnr80 |jq -r '.Listeners[0].ListenerArn')
    
        # rules with path pattern in listener 
        envsubst >/tmp/path-pattern.json <<-EOF
[{
    "Field": "path-pattern",
    "PathPatternConfig": {
        "Values": ["/*"]
    }
}]
EOF

        aws elbv2 create-rule --listener-arn ${LSNR80_ARN} \
            --conditions file:///tmp/path-pattern.json \
            --priority 5 \
            --actions Type=forward,TargetGroupArn=${TG80_ARN}
    else 
        aws elbv2 create-listener --load-balancer-arn ${LB_ARN} \
            --protocol ${LB_PROTO} --port ${PORT80}  \
            --default-actions Type=forward,TargetGroupArn=${TG80_ARN}
    fi
    
    if [[ ! -z ${CERTIFICATE_ARN} ]]; then
        aws elbv2 create-target-group \
            --name ${TYPE}-tg-${PORT443}-${UNIQ_STR} \
            --protocol HTTPS \
            --port ${PORT443} \
            --target-type ip \
            --vpc-id ${VPC_ID} \
            --matcher HttpCode="200-202\,400-404" |tee /tmp/$$-tg443
        TG443_ARN=$(cat /tmp/$$-tg443 |jq -r '.TargetGroups[0].TargetGroupArn')
    
        aws elbv2 create-listener --load-balancer-arn ${ALB_ARN} \
            --protocol HTTPS --port ${PORT443}  \
            --certificates CertificateArn=${CERTIFICATE_ARN} \
            --default-actions Type=fixed-response,FixedResponseConfig="{MessageBody=,StatusCode=404,ContentType=text/plain}" |tee /tmp/$$-lsnr443
        local LSNR443_ARN=$(cat /tmp/$$-lsnr443 |jq -r '.Listeners[0].ListenerArn')

        aws elbv2 create-rule --listener-arn ${LSNR443_ARN} \
            --conditions file:///tmp/path-pattern.json \
            --priority 5 \
            --actions Type=forward,TargetGroupArn=${TG443_ARN}
    fi
    echo "LB_ARN="${LB_ARN}
}
```

## alb and target group (sample)
创建alb和tg，端口监听80

```sh
uniqstr=$(TZ=EAT-8 date +%Y%m%d-%H%M)
port1=80
export AWS_DEFAULT_REGION=us-east-2
#VPC_ID=vpc-xxx
VPC_ID=$(aws ec2 describe-vpcs \
--filter Name=is-default,Values=true \
--query 'Vpcs[0].VpcId' --output text \
--region ${AWS_DEFAULT_REGION})

FIRST_SUBNET=$(aws ec2 describe-subnets \
--filters "Name=vpc-id,Values=${VPC_ID}" \
--query "Subnets[?AvailabilityZone=='"${AWS_DEFAULT_REGION}a"'].SubnetId" \
--output text \
--region ${AWS_DEFAULT_REGION})
SECOND_SUBNET=$(aws ec2 describe-subnets \
--filters "Name=vpc-id,Values=${VPC_ID}" \
--query "Subnets[?AvailabilityZone=='"${AWS_DEFAULT_REGION}b"'].SubnetId" \
--output text \
--region ${AWS_DEFAULT_REGION})

DEFAULT_SG_ID=$(aws ec2 describe-security-groups \
--filter Name=vpc-id,Values=${VPC_ID} \
--query "SecurityGroups[?GroupName == 'default'].GroupId" \
--output text \
--region ${AWS_DEFAULT_REGION})

aws elbv2 create-load-balancer --name alb1-${uniqstr} \
--subnets ${FIRST_SUBNET} ${SECOND_SUBNET} \
--security-groups ${DEFAULT_SG_ID} |tee /tmp/$$.1
alb1_arn=$(cat /tmp/$$.1 |jq -r '.LoadBalancers[0].LoadBalancerArn')
alb1_dnsname=$(cat /tmp/$$.1 |jq -r '.LoadBalancers[0].DNSName')

aws elbv2 create-target-group \
--name alb1-tg-${port1}-${uniqstr} \
--protocol HTTP \
--port ${port1} \
--target-type ip \
--vpc-id ${VPC_ID} |tee /tmp/$$.2
tg1_arn=$(cat /tmp/$$.2 |jq -r '.TargetGroups[0].TargetGroupArn')

aws elbv2 create-listener --load-balancer-arn ${alb1_arn} \
--protocol HTTP --port ${port1}  \
--default-actions Type=forward,TargetGroupArn=${tg1_arn}

```

### example
- [[TC-private-apigw-dataflow#步骤 1-2]]
- ~~[[gitlab/MK/apigw/POC-apigw-dataflow#external alb]]~~

## create tg and listener

```sh
NLB_NAME=(nlb1 nlb2)
for i in ${NLB_NAME[@]}; do
aws elbv2 create-target-group \
--name ${i}-tg-80 \
--protocol TCP \
--port 80 \
--vpc-id ${VPC_ID}

aws elbv2 create-target-group \
--name ${i}-tg-81 \
--protocol TCP \
--port 81 \
--vpc-id ${VPC_ID}
done

```

```sh
for i in `seq 80 99`; do
aws elbv2 create-target-group \
--name tg-tcp-${i} \
--protocol TCP \
--port ${i} \
--vpc-id ${VPC_ID}
done

NLB_ARN=arn:aws:elasticloadbalancing:us-east-1:xxx:loadbalancer/net/nlb/xxx

for i in `seq 80 99`; do
TG_ARN=$(aws elbv2 describe-target-groups --query 'TargetGroups[?TargetGroupName==`tg-tcp-'"${i}"'`].TargetGroupArn' --output text)

aws elbv2 create-listener \
--load-balancer-arn ${NLB_ARN} \
--protocol TCP \
--port ${i} \
--default-actions Type=forward,TargetGroupArn=${TG_ARN}
done

```


## create alb-type target group
- [[TC-private-apigw-dataflow#步骤 5-7]]

## refer
- https://cloudaffaire.com/network-load-balancer-target-group-health-checks/




