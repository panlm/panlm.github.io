---
title: create-dashboard-for-instance-cpu-matrics
description: 快速创建 cloudwatch dashboard
created: 2023-02-17 19:45:47.979
last_modified: 2023-10-24 22:53:47.633
tags:
  - aws/mgmt/cloudwatch
---

```ad-attention
title: This is a github note
```

# create-dashboard-for-instance-cpu-matrics

## permission

- `describe-instances`
- `put-dashboard`

## each metrics with anomaly detection

```sh
#!/bin/bash 

if [[ $# -eq 0 ]]; then
    echo 'Usage: $0 i-xxxx1 i-xxxx2'
    exit 9
fi

export AWS_DEFAULT_REGION=cn-northwest-1

aws sts get-caller-identity 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
    export AWSCLI=0
else
    export AWSCLI=1
fi

DASHBOARD_FILE=dash1.json
DASHBOARD_FILE_TEMP=dash1-$$.json

cat > ${DASHBOARD_FILE} <<-EOF
{
    "widgets": [
    ]
}
EOF

TEMPLATE_FILE=temp1.json
echo '
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 8,
            "height": 5,
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization", "InstanceId", "${INSTANCE_ID}", { "id": "m1", "stat": "Maximum" } ],
                    [ { "expression": "ANOMALY_DETECTION_BAND(m1, 2)", "label": "${INSTANCE_ID} (${INSTANCE_NAME}) (expected)", "id": "ad1", "color": "#95A5A6", "region": "${AWS_DEFAULT_REGION}" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${AWS_DEFAULT_REGION}",
                "title": "CPUUtilization-${INSTANCE_NAME}",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 30
                    }
                }                
            }
        }
' |base64 > ${TEMPLATE_FILE}.b64

if [[ ${AWSCLI} -eq 1 ]]; then
    aws ec2 describe-instances > /tmp/all-instances.out
    INSTANCE_NUMBER=$(cat /tmp/all-instances.out |jq -r '.Reservations | length')
echo "total instance number: ${INSTANCE_NUMBER}"
fi

TMP=/tmp/tmp-$$
for i in $@ ; do
    export INSTANCE_ID=${i}
    export INSTANCE_NAME=$(cat /tmp/all-instances.out |jq -r '.Reservations[] | select (.Instances[0].InstanceId == "'"${INSTANCE_ID}"'") | .Instances[] |  (del((.Tags[]|select(.Key!="Name")))|.Tags[]|.Value|tostring)')
    cat ${TEMPLATE_FILE}.b64 |base64 --decode |envsubst >${TMP}
    jq --argjson groupInfo "$(<$TMP)" '.widgets += [$groupInfo]' ${DASHBOARD_FILE} > ${DASHBOARD_FILE_TEMP}
    mv ${DASHBOARD_FILE_TEMP} ${DASHBOARD_FILE}
done

if [[ ${AWSCLI} -eq 1 ]]; then
    DASHBOARD_NAME=dash-$(date +%Y%m%d%H%M%S) 
    aws cloudwatch put-dashboard --dashboard-name ${DASHBOARD_NAME} --dashboard-body file://${DASHBOARD_FILE} >/dev/null
    echo "please access dashboard: ${DASHBOARD_NAME}"
fi

```

### sample

![[git/git-mkdocs/git-attachment/lab-create-cloudwatch-dashboard-cpu-metric-png-1.png]]

## all metrics 

```sh
#!/bin/bash 

if [[ $# -eq 0 ]]; then
    echo 'Usage: $0 i-xxxx1 i-xxxx2'
    exit 9
fi

export AWS_DEFAULT_REGION=cn-north-1

aws sts get-caller-identity 2>&1 >/dev/null
if [[ $? -ne 0 ]]; then
    export AWSCLI=0
else
    export AWSCLI=1
fi

DASHBOARD_FILE=dash1.json
DASHBOARD_FILE_TEMP=dash1-$$.json

cat > ${DASHBOARD_FILE} <<-EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 16,
            "height": 12,
            "properties": {
                "metrics": [
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "${AWS_DEFAULT_REGION}",
                "title": "CPUUtilization",
                "period": 300
            }
        }
    ]
}
EOF

TEMPLATE_FILE=temp1.json
echo '
                    [ "AWS/EC2", "CPUUtilization", "InstanceId", "${INSTANCE_ID}", { "id": "m${num}", "stat": "Maximum" } ]
' |base64 > ${TEMPLATE_FILE}.b64

if [[ ${AWSCLI} -eq 1 ]]; then
    aws ec2 describe-instances > /tmp/all-instances.out
    INSTANCE_NUMBER=$(cat /tmp/all-instances.out |jq -r '.Reservations | length')
echo "total instance number: ${INSTANCE_NUMBER}"
fi

export num=1
TMP=/tmp/tmp-$$
for i in $@ ; do
    export INSTANCE_ID=${i}
    export INSTANCE_NAME=$(cat /tmp/all-instances.out |jq -r '.Reservations[] | select (.Instances[0].InstanceId == "'"${INSTANCE_ID}"'") | .Instances[] |  (del((.Tags[]|select(.Key!="Name")))|.Tags[]|.Value|tostring)')
    cat ${TEMPLATE_FILE}.b64 |base64 --decode |envsubst >${TMP}
    jq --argjson groupInfo "$(<$TMP)" '.widgets[0].properties.metrics += [$groupInfo]' ${DASHBOARD_FILE} > ${DASHBOARD_FILE_TEMP}
    mv ${DASHBOARD_FILE_TEMP} ${DASHBOARD_FILE}
    export num=$((num+1))
done

exit

if [[ ${AWSCLI} -eq 1 ]]; then
    DASHBOARD_NAME=dash-$(date +%Y%m%d%H%M%S) 
    aws cloudwatch put-dashboard --dashboard-name ${DASHBOARD_NAME} --dashboard-body file://${DASHBOARD_FILE} >/dev/null
    echo "please access dashboard: ${DASHBOARD_NAME}"
fi
```

### sample

![[git/git-mkdocs/git-attachment/lab-create-cloudwatch-dashboard-cpu-metric-png-2.png]]

- 二十个指标后，颜色开始重复


## followup

- [[aws-amg-managed-grafana]]

