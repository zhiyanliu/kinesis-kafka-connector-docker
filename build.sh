#!/bin/bash

set -ex

if ! [ -x "$(command -v docker)" ]; then
    echo "docker command is not found"
    exit 1
fi
if ! [ -x "$(command -v aws)" ]; then
    echo "aws CLI is not found"
    exit 1
fi

if [ -z $ACCOUNT ]; then
    echo "ACCOUNT environment variable is not set"
    exit 1
fi
if [ -z $REGION ]; then
    echo "REGION environment variable is not set"
    exit 1
fi

if [ -z $IMG ]; then
    IMG=amazon/kinesis-kafka-connector
fi
if [ -z $VER ]; then
    VER=snaphot-0.0.9
fi

REPO=$ACCOUNT.dkr.ecr.$REGION.amazonaws.com

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

docker build -t $REPO/$IMG:$VER --rm $DIR
docker rmi $(docker images -f "dangling=true" -q)  # remove intermediate images in build stage, optional

aws ecr get-login-password --region $REGION \
    | docker login --username AWS --password-stdin $REPO  # assume the repository exists already

docker push $REPO/$IMG:$VER
