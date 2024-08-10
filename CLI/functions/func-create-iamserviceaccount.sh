# depends on: CLUSTER_NAME / NAMESPACE_NAME
# output variable: S3_ADMIN_ROLE_ARN
# quick link: https://panlm.github.io/CLI/functions/func-create-iamserviceaccount.sh

function create-iamserviceaccount () {
    OPTIND=1
    OPTSTRING="h?s:c:n:r:"
    local SA_NAME=""
    local CLUSTER_NAME=""
    local NAMESPACE_NAME=""
    local ROLE_ONLY=""
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            s) SA_NAME=${OPTARG} ;;
            c) CLUSTER_NAME=${OPTARG} ;;
            n) NAMESPACE_NAME=${OPTARG} ;;
            r) ROLE_ONLY=${OPTARG} ;;
            h|\?) 
                echo "format: create-iamserviceaccount -s SERVICE_ACCOUNT_NAME -c CLUSTER_NAME -n NAMESPACE_NAME -r [true|false] "
                echo -e "\tsample: create-iamserviceaccount -s sa_name -c ekscluster1 -n monitoring -r true "
                return 0
            ;;
        esac
    done
    : ${SA_NAME:?Missing -s}
    : ${CLUSTER_NAME:?Missing -c}
    : ${NAMESPACE_NAME:?Missing -n}
    : ${ROLE_ONLY:?Missing -r}

    if [[ ROLE_ONLY == "true" ]]; then
        local ROLE_OPTION="--role-only"
    elif [[ ROLE_ONLY == "false" ]]; then
        local ROLE_OPTION=""
    else
        echo "only true/false allow in parameter '-r' "
        return 9
    fi

    echo ${SA_NAME:=sa-s3-admin-$(TZ=EAT-8 date +%Y%m%d-%H%M%S)}
    eksctl create iamserviceaccount -c ${CLUSTER_NAME} \
        --name ${SA_NAME} --namespace ${NAMESPACE_NAME} \
        --attach-policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
        --role-name ${SA_NAME}-$(TZ=EAT-8 date +%Y%m%d-%H%M%S) ${ROLE_OPTION} --approve \
        --override-existing-serviceaccounts
    unset S3_ADMIN_ROLE_ARN
    S3_ADMIN_ROLE_ARN=$(eksctl get iamserviceaccount -c $CLUSTER_NAME \
        --name ${SA_NAME} -o json |jq -r '.[].status.roleARN')
    echo ${S3_ADMIN_ROLE_ARN}
}