#!/bin/bash

set -ex

# prepare worker configures

echo >> /worker.properties  # append each option in dedicated line

# for issue: https://issues.apache.org/jira/browse/KAFKA-3988
sed -i '/internal\.key\.converter\.schemas\.enable=.*/d' /worker.properties
echo "internal.key.converter.schemas.enable=false" >> /worker.properties
sed -i '/internal\.value\.converter\.schemas\.enable=.*/d' /worker.properties
echo "internal.value.converter.schemas.enable=false" >> /worker.properties

if [ -z $GROUP_ID ]; then
    echo "GROUP_ID environment variable is not set"
    echo "running in standalone mode"
else
    echo "running in distributed mode"

    if [ -z $OFFSET_TOPIC ]; then
        OFFSET_TOPIC=connect-offsets
    fi
    if [ -z $CONFIG_TOPIC ]; then
        CONFIG_TOPIC=connect-config
    fi
    if [ -z $STATUS_TOPIC ]; then
        STATUS_TOPIC=connect-status
    fi

    sed -i '/^group\.id=.*/d' /worker.properties
    echo "group.id=${GROUP_ID}" >> /worker.properties
    sed -i '/^offset\.storage\.topic=.*/d' /worker.properties
    echo "offset.storage.topic=${OFFSET_TOPIC}" >> /worker.properties
    sed -i '/^config\.storage\.topic=.*/d' /worker.properties
    echo "config.storage.topic=${CONFIG_TOPIC}" >> /worker.properties
    sed -i '/^status\.storage\.topic=.*/d' /worker.properties
    echo "status.storage.topic=${STATUS_TOPIC}" >> /worker.properties
fi

if ! [ -z $BOOTSTRAP_SERVERS ]; then
    sed -i "/^bootstrap\.servers=.*/c\bootstrap.servers=${BOOTSTRAP_SERVERS}" /worker.properties
fi

sed -i '/^rest\.host\.name=.*/d' /worker.properties
echo "rest.host.name=0.0.0.0" >> /worker.properties


# prepare connector configures

if ! [ -z $CONNECTOR_NAME ]; then
    sed -i "/^name=.*/c\name=${CONNECTOR_NAME}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $REGION ]; then
    sed -i "/^region=.*/c\region=${REGION}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $KINESIS_STREAM ]; then
    sed -i "/^streamName=.*/c\streamName=${KINESIS_STREAM}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $KAFKA_TOPICS ]; then
    sed -i "/^topics=.*/c\topics=${KAFKA_TOPICS}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $MAX_TASKS ]; then
    sed -i "/^tasks\.max=.*/c\tasks.max=${MAX_TASKS}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $MAX_CONNECTIONS ]; then
    sed -i "/^maxConnections=.*/c\maxConnections=${MAX_CONNECTIONS}" /kinesis-streams-kafka-connector.properties
fi

if ! [ -z $GROUP_ID ]; then
    wget -q https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -O /usr/bin/jq
    chmod u+x /usr/bin/jq
    grep -v '#' /kinesis-streams-kafka-connector.properties | \
        jq -sR '{
                   "name": split("\n")[0:1][] | rtrimstr("\\r") | split("=") | (.[1]),
                   "config": [split("\n")[1:-1][] | rtrimstr("\\r") | split("=") | {(.[0]): .[1]}]  | add
                }' - > /kinesis-streams-kafka-connector.post
fi

# print connector configures

echo "worker.properties file content:"
cat /worker.properties
if [ -z $GROUP_ID ]; then
    echo "kinesis-streams-kafka-connector.properties file content:"
    cat /kinesis-streams-kafka-connector.properties
else
    echo "kinesis-streams-kafka-connector REST post body:"
    cat /kinesis-streams-kafka-connector.post
fi

# start connector
if [ -z $GROUP_ID ]; then
    /usr/bin/connect-standalone /worker.properties /kinesis-streams-kafka-connector.properties
else
    /usr/bin/connect-distributed /worker.properties
fi
