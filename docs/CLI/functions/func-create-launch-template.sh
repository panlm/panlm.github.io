function create-launch-template () {
    OPTIND=1
    OPTSTRING="h?s:a:"
    local SG_ID=""
    local AMI_ID=""
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            s) SG_ID=${OPTARG} ;;
            a) AMI_ID=${OPTARG} ;;
            h|\?) 
                echo "format: create-launch-template -s SG_ID -a AMI_ID"
                echo
                return 0
            ;;
        esac
    done
    : ${SG_ID:?Missing -v}
    : ${AMI_ID:?Missing -v}

    LAUNCH_TEMPLATE_NAME=launchtemplate-$(TZ=CST-8 date +%Y%m%d-%H%M)
    local TMP=$(mktemp --suffix .${LAUNCH_TEMPLATE_NAME})
    envsubst >${TMP} <<-EOF
{
    "InstanceType": "m5.large",
    "ImageId": "${AMI_ID}",
    "SecurityGroupIds": [
        "${SG_ID}"
    ],
    "TagSpecifications": [{
        "ResourceType": "instance",
        "Tags": [{
            "Key": "Name",
            "Value": "${LAUNCH_TEMPLATE_NAME}"
        }]
    },
    {
        "ResourceType": "volume",
        "Tags": [{
            "Key": "Name",
            "Value": "${LAUNCH_TEMPLATE_NAME}"
        }]
    }]
}
EOF

    aws ec2 create-launch-template \
        --launch-template-name ${LAUNCH_TEMPLATE_NAME} \
        --launch-template-data file://${TMP} |tee ${TMP}.out
    LAUNCH_TEMPLATE_ID=$(cat ${TMP}.out |jq -r '.LaunchTemplate.LaunchTemplateId')
    echo "LAUNCH_TEMPLATE_ID="${LAUNCH_TEMPLATE_ID}
} # funcend
