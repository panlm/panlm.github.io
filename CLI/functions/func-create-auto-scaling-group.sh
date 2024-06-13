function create-auto-scaling-group () {
    OPTIND=1
    OPTSTRING="h?l:"
    local LAUNCH_TEMPLATE_ID=""
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            l) SG_ID=${OPTARG} ;;
            h|\?) 
                echo "format: create-auto-scaling-group -s LAUNCH_TEMPLATE_ID"
                echo
                return 0
            ;;
        esac
    done
    : ${LAUNCH_TEMPLATE_ID:?Missing -v}

    local TMP=$(mktemp --suffix .asg)
    # get sg id
    aws ec2 describe-launch-template-versions --launch-template-id ${LAUNCH_TEMPLATE_ID} --versions '$Latest' |tee ${TMP}.lt
    local VERSION_NUM=$(cat ${TMP}.lt |jq -r '.LaunchTemplateVersions[0].VersionNumber')
    local SG_IDS=($(cat ${TMP}.lt |jq -r '.LaunchTemplateVersions[0].LaunchTemplateData.SecurityGroupIds[]'))
    local VPC_IDS=($(aws ec2 describe-security-groups --group-ids ${SG_IDS[@]} |jq -r '.SecurityGroups[].VpcId'))
    if [[ ${#VPC_IDS[@]} -ne 1 ]]; then
        echo 'SG belongs to different VPC'
        return
    fi

    # get private subnets or public subnets
    local VPC_ID=${VPC_IDS[@]}
    local SUBNET_IDS=$(aws ec2 describe-subnets \
        --filter "Name=vpc-id,Values=${VPC_ID}" \
        --query 'Subnets[?MapPublicIpOnLaunch==`false`].SubnetId' \
        --output text)

    if [[ -z ${SUBNET_IDS} ]]; then
        local SUBNET_IDS=$(aws ec2 describe-subnets \
            --filter "Name=vpc-id,Values=${VPC_ID}" \
            --query 'Subnets[?MapPublicIpOnLaunch==`true`].SubnetId' \
            --output text)
    fi

    local SUBNET_STR=$(echo ${SUBNET_IDS} |xargs |tr ' ' ',')

    local ASG_NAME=autoscaling-$(TZ=CST-8 date +%Y%m%d-%H%M)
    envsubst >${TMP}.asg <<-EOF
{
  "AutoScalingGroupName": "${ASG_NAME}",
  "MinSize": 0,
  "MaxSize": 10,
  "VPCZoneIdentifier": "${SUBNET_STR}",
  "NewInstancesProtectedFromScaleIn": true,
  "MixedInstancesPolicy":{
    "LaunchTemplate":{
      "LaunchTemplateSpecification":{
        "LaunchTemplateId": "${LAUNCH_TEMPLATE_ID}",
        "Version": "${VERSION_NUM}"
      },
      "Overrides":[{}]
    }
  }
}
EOF

    aws autoscaling create-auto-scaling-group \
        --cli-input-json file://${TMP}.asg 
    aws autoscaling describe-auto-scaling-groups \
        --auto-scaling-group-names ${ASG_NAME} |tee ${TMP}.asg.out
    ASG_ARN=$(cat ${TMP}.asg.out |jq -r '.AutoScalingGroups[0].AutoScalingGroupARN')
    echo "ASG_ARN="${ASG_ARN}
} # funcend
