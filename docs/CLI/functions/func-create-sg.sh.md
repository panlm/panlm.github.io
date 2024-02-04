---
title: func-create-sg.sh
description: 
created: 2023-12-10 13:51:39.632
last_modified: 2024-01-30
tags:
  - aws/cmd
  - bash/function
---

```sh title="func-create-sg"
# deps: VPC_ID
# output: SG_ID
# format: create-sg -v VPC_ID -c VPC_CIDR [-p PORT1] [-p PORT2]
function create-sg () {
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
                echo 
                echo "omit -p parameter will open all ports"
                echo
                return 0
            ;;
        esac
    done
    : ${VPC_ID:?Missing -v}
    : ${VPC_CIDR:?Missing -c}

    if [[ -z ${PORTS} ]]; then
        local PROTOCOL=all
    else
        local PROTOCOL=tcp
    fi

    # create sg
    SG_NAME=mysg-$(TZ=EAT-8 date +%Y%m%d-%H%M%S)
    SG_ID=$(aws ec2 create-security-group \
        --description ${SG_NAME} \
        --group-name ${SG_NAME} \
        --vpc-id ${VPC_ID} \
        --query 'GroupId' --output text )

    # all traffic allowed
    for i in ${PORTS[@]:--1}; do
        aws ec2 authorize-security-group-ingress \
            --group-id ${SG_ID} \
            --protocol ${PROTOCOL} \
            --port ${i} \
            --cidr ${VPC_CIDR}
    done
}
```




