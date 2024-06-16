# depends on: if no VPC_ID, will use default vpc as VPC_ID
# output variable: SG_ID
# quick link: https://panlm.github.io/CLI/functions/func-create-sg.sh
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
                echo "format: create-sg [-v VPC_ID] [-c VPC_CIDR] [-p PORT1] [-p PORT2]"
                echo -e "\tsample: create-sg "
                echo -e "\tsample: create-sg -v vpc-xxx -c 172.31.0.0/16"
                echo -e "\tsample: create-sg -v vpc-xxx -c 0.0.0.0/0 -p 80 -p 443"
                echo 
                echo "omit -p parameter will open all ports"
                echo
                return 0
            ;;
        esac
    done
    : ${VPC_CIDR:=0.0.0.0/0}

    if [[ -z ${VPC_ID} ]]; then
        VPC_ID=$(aws ec2 describe-vpcs --filter Name=is-default,Values=true \
        --query 'Vpcs[0].VpcId' --output text)
    fi

    if [[ -z ${PORTS} ]]; then
        local PROTOCOL=(all)
    else
        local PROTOCOL=(tcp udp)
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
        for j in ${PROTOCOL[@]} ; do
            aws ec2 authorize-security-group-ingress \
                --group-id ${SG_ID} \
                --protocol ${j} \
                --port ${i} \
                --cidr ${VPC_CIDR}
        done
    done

    # echo SG_ID
    echo "VPC_ID="${VPC_ID}
    echo "SG_ID="${SG_ID}
}
