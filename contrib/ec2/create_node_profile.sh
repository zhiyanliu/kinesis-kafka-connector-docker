#!/bin/bash

# Configuration

INSTANCE_PROFILE_NAME=${INSTANCE_PROFILE_NAME:-KinesisKafkaConnector}
ROLE_NAME=${ROLE_NAME:-KinesisKafkaConnectorRole}
POLICY_NAME_ECR=${POLICY_NAME_ECR:-KinesisKafkaConnectorECRImagePullPolicy}
POLICY_NAME_KINESIS=${POLICY_NAME_KINESIS:-KinesisKafkaConnectorKinesisDataStreamProducePolicy}

# ==================================

set -ex

if ! [ -x "$(command -v aws)" ]; then
    echo "aws CLI is not found"
    exit 1
fi

export AWS_DEFAULT_OUTPUT="table"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

aws iam delete-role-policy --role-name $ROLE_NAME --policy-name $POLICY_NAME_ECR > /dev/null 2>&1 || true
aws iam delete-role-policy --role-name $ROLE_NAME --policy-name $POLICY_NAME_KINESIS > /dev/null 2>&1 || true
aws iam remove-role-from-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --role-name $ROLE_NAME 2>&1 > /dev/null || true
aws iam delete-role --role-name $ROLE_NAME > /dev/null || true
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://$DIR/ec2_assume_role_policy.json --description "Pull docker image from ECR and produce record to Kinesis data stream for all users" > /dev/null
aws iam put-role-policy --role-name $ROLE_NAME --policy-name $POLICY_NAME_ECR --policy-document file://$DIR/ecr_image_pull_policy.json > /dev/null
aws iam put-role-policy --role-name $ROLE_NAME --policy-name $POLICY_NAME_KINESIS --policy-document file://$DIR/kinesis_datastream_produce_policy.json > /dev/null

aws iam delete-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME > /dev/null 2>&1 || true
aws iam create-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME > /dev/null
aws iam add-role-to-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --role-name $ROLE_NAME > /dev/null
