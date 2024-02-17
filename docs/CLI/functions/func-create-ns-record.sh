# DOMAIN_NAME=poc0000.aws.panlm.xyz
# NS='ns-1716.awsdns-22.co.uk.
# ns-934.awsdns-52.net.
# ns-114.awsdns-14.com.
# ns-1223.awsdns-24.org.'

function create-ns-record () {
    OPTIND=1
    OPTSTRING="h?n:s:"
    local DOMAIN_NAME=""
    local NS=""
    while getopts ${OPTSTRING} opt; do
        case "${opt}" in
            n) DOMAIN_NAME=${OPTARG} ;;
            s) NS=${OPTARG} ;;
            h|\?) 
                echo "format: create-host-zone -n DOMAIN_NAME -s \"NS_RECORDS\" "
                echo -e "\tsample: create-host-zone -n xxx.domain.com -s \"ns-xx.awsdns-xx.com ns-xx.awsdns-xx.com\" "
                return 0
            ;;
        esac
    done
    : ${DOMAIN_NAME:?Missing -n}
    : ${NS:?Missing -s}

    # check NS number
    local NS_NUM=$(echo $NS |xargs -n 1 |wc -l)
    if [[ ${NS_NUM} -eq 1 ]]; then
        echo "your NS is: "${NS}
        echo 'typical NS record should has more than one record'
        echo 'use double quotes when you use variable for -s '
        create-ns-record -h
    fi

    PARENT_DOMAIN_NAME=${DOMAIN_NAME#*.}
    ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "${PARENT_DOMAIN_NAME}." \
    --query HostedZones[0].Id --output text)
    
    envsubst >/tmp/ns-route53-record.json <<-EOF
{
  "Comment": "UPSERT a record for poc.xxx.com ",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${DOMAIN_NAME}",
        "Type": "NS",
        "TTL": 172800,
        "ResourceRecords": [
        ]
      }
    }
  ]
}
EOF
    
    for i in ${NS}; do
        cat /tmp/ns-route53-record.json |jq '.Changes[0].ResourceRecordSet.ResourceRecords += [{"Value": "'"${i}"'"}]' \
            |tee /tmp/ns-route53-record-tmp.json
        mv -f /tmp/ns-route53-record-tmp.json /tmp/ns-route53-record.json
    done
    
    aws route53 change-resource-record-sets --hosted-zone-id ${ZONE_ID} --change-batch file:///tmp/ns-route53-record.json
    
    aws route53 list-resource-record-sets --hosted-zone-id ${ZONE_ID} --query "ResourceRecordSets[?Name == '${DOMAIN_NAME}.']"
}