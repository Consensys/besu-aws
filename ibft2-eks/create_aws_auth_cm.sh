#!/bin/bash

STACK_NAME=${1:-besu-eks-stack}
REGION=${2:-ap-southeast-2}
AUTH_CM_FILE=aws-auth-cm.yml

cp ./templates/$AUTH_CM_FILE ./
NODE_INSTANCE_ROLE_ARN=`aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query "Stacks[0].Outputs[?OutputKey=='NodeInstanceRole'].OutputValue" --output text`

echo Creating $AUTH_CM_FILE with NODE_INSTANCE_ROLE_ARN=$NODE_INSTANCE_ROLE_ARN
if [ "$(uname)" == "Darwin" ]; then
  sed -i '' -e 's|NODE_INSTANCE_ROLE_ARN|'$NODE_INSTANCE_ROLE_ARN'|g' $AUTH_CM_FILE
else
  sed -i 's|NODE_INSTANCE_ROLE_ARN|'$NODE_INSTANCE_ROLE_ARN'|g' $AUTH_CM_FILE
fi

