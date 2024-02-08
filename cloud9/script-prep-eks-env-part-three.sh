#!/bin/bash
###-SCRIPT-PART-THREE-BEGIN-###
echo "###"
echo "SCRIPT-PART-THREE-BEGIN"
echo "###"

aws cloud9 update-environment  --environment-id $C9_PID --managed-credentials-action DISABLE
rm -vf ${HOME}/.aws/credentials

# ---
export AWS_PAGER=""
export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
C9_INST_ID=$(curl 169.254.169.254/latest/meta-data/instance-id)
ROLE_NAME=adminrole-$(TZ=CST-8 date +%Y%m%d-%H%M%S)
MY_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

cat > ec2.json <<-EOF
{
    "Effect": "Allow",
    "Principal": {
        "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
}
EOF
STATEMENT_LIST=ec2.json

for i in WSParticipantRole WSOpsRole TeamRole OpsRole ; do
  aws iam get-role --role-name $i >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    envsubst >$i.json <<-EOF
{
  "Effect": "Allow",
  "Principal": {
    "AWS": "arn:aws:iam::${MY_ACCOUNT_ID}:role/$i"
  },
  "Action": "sts:AssumeRole"
}
EOF
    STATEMENT_LIST=$(echo ${STATEMENT_LIST} "$i.json")
  fi
done

jq -n '{Version: "2012-10-17", Statement: [inputs]}' ${STATEMENT_LIST} > trust.json
echo ${STATEMENT_LIST}
rm -f ${STATEMENT_LIST}

# create role
aws iam create-role --role-name ${ROLE_NAME} \
  --assume-role-policy-document file://trust.json
aws iam attach-role-policy --role-name ${ROLE_NAME} \
  --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

instance_profile_arn=$(aws ec2 describe-iam-instance-profile-associations \
  --filter Name=instance-id,Values=$C9_INST_ID \
  --query IamInstanceProfileAssociations[0].IamInstanceProfile.Arn \
  --output text)
if [[ ${instance_profile_arn} == "None" ]]; then
  # create one
  aws iam create-instance-profile \
    --instance-profile-name ${ROLE_NAME}
  sleep 10
  # attach role to it
  aws iam add-role-to-instance-profile \
    --instance-profile-name ${ROLE_NAME} \
    --role-name ${ROLE_NAME}
  sleep 10
  # attach instance profile to ec2
  aws ec2 associate-iam-instance-profile \
    --iam-instance-profile Name=${ROLE_NAME} \
    --instance-id ${C9_INST_ID}
else
  existed_role_name=$(aws iam get-instance-profile \
    --instance-profile-name ${instance_profile_arn##*/} \
    --query 'InstanceProfile.Roles[0].RoleName' \
    --output text)
  aws iam attach-role-policy --role-name ${existed_role_name} \
    --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
fi

echo "###"
echo "SCRIPT-PART-THREE-END"
echo "###"
###-SCRIPT-PART-THREE-END-###

