#!/bin/bash

# Configuration

if [ -z $INSTANCE_PROFILE_NAME ]; then
    INSTANCE_PROFILE_NAME=KinesisKafkaConnector
fi
if [ -z $ROLE_NAME ]; then
    ROLE_NAME=KinesisKafkaConnectorRole
fi
if [ -z $POLICY_NAME ]; then
    POLICY_NAME=KinesisKafkaConnectorECRImagePullPolicy
fi

==================================

set -ex

if ! [ -x "$(command -v aws)" ]; then
    echo "aws CLI is not found"
    exit 1
fi

export AWS_DEFAULT_OUTPUT="table"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

aws iam delete-role --role-name $ROLE_NAME > /dev/null || true
aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://$DIR/ec2_assume_role_policy.json --description "Pull docker image from ECR for all users" > /dev/null
aws iam put-role-policy --role-name $ROLE_NAME --policy-name $POLICY_NAME --policy-document file://$DIR/ecr_image_pull_policy.json > /dev/null

aws iam delete-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME > /dev/null || true
aws iam create-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME > /dev/null
aws iam add-role-to-instance-profile --instance-profile-name $INSTANCE_PROFILE_NAME --role-name $ROLE_NAME > /dev/null
