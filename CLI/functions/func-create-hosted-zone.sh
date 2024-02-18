function create-hosted-zone () {
    OPTIND=1
    OPTSTRING="h?n:"
    local DOMAIN_NAME=""
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            n) DOMAIN_NAME=${OPTARG} ;;
            h|\?) 
                echo "format: create-host-zone -n DOMAIN_NAME "
                echo -e "\tsample: create-host-zone -n xxx.domain.com "
                return 0
            ;;
        esac
    done
    : ${DOMAIN_NAME:?Missing -n}
        
    aws route53 create-hosted-zone --name "${DOMAIN_NAME}." \
      --caller-reference "external-dns-test-$(date +%s)"
    
    local ZONE_ID=$(aws route53 list-hosted-zones-by-name --output json \
      --dns-name "${DOMAIN_NAME}." --query HostedZones[0].Id --out text)
    
    local NS=$(aws route53 list-resource-record-sets --output text \
      --hosted-zone-id $ZONE_ID --query \
      "ResourceRecordSets[?Type == 'NS'].ResourceRecords[*].Value | []")
    
    echo '###'
    echo '# get bash function from here: https://panlm.github.io/CLI/awscli/route53-cmd/#func-create-ns-record-'
    echo '# copy below output to add NS record on your upstream domain registrar'
    echo '###'
    echo 'DOMAIN_NAME='${DOMAIN_NAME}
    echo 'NS="'${NS}'"'
    echo 'curl -sL -o /tmp/func-create-ns-record.sh https://panlm.github.io/CLI/functions/func-create-ns-record.sh'
    echo 'source /tmp/func-create-ns-record.sh'
    echo 'create-ns-record -n ${DOMAIN_NAME} -s "${NS}"'
    echo ''
}