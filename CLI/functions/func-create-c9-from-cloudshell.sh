# quick link: https://panlm.github.io/CLI/functions/func-create-c9-from-cloudshell.sh

aws configure list
export AWS_DEFAULT_REGION AWS_REGION
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

# check role/panlm exists or not
aws iam get-role --role-name panlm 2>&1 >/dev/null
if [[ $? -eq 0 ]]; then
    echo "role/panlm existed"
    PARAMETERS='--parameters ParameterKey=ExampleC9EnvOwner,ParameterValue="3rdParty" ParameterKey=ExampleOwnerArn,ParameterValue="arn:aws:sts::'"${AWS_ACCOUNT_ID}"':assumed-role/panlm/granted"'
else
    echo "role/panlm does not existed"
    PARAMETERS=''
fi

wget -O example_instancestack_ubuntu.yaml 'https://panlm.github.io/cloud9/example_instancestack_ubuntu.yaml'

STACK_NAME=cloud9-$(TZ=EAT-8 date +%m%d-%H%M)
aws cloudformation create-stack --stack-name ${STACK_NAME} \
    --template-body file://./example_instancestack_ubuntu.yaml \
    --capabilities CAPABILITY_IAM \
    --on-failure DO_NOTHING \
    ${PARAMETERS}
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}

aws cloudformation describe-stacks --stack-name ${STACK_NAME} \
    --query 'Stacks[].Outputs[?OutputKey==`Cloud9IDE`].OutputValue' --output text

