#!/bin/bash

set -ex

# set default values to optional configures

OFFSET_TOPIC=${OFFSET_TOPIC:-connect-offsets}
CONFIG_TOPIC=${CONFIG_TOPIC:-connect-config}
STATUS_TOPIC=${STATUS_TOPIC:-connect-status}
OFFSET_REPLICA=${OFFSET_REPLICA:-2}
CONFIG_REPLICA=${CONFIG_REPLICA:-2}
STATUS_REPLICA=${STATUS_REPLICA:-2}
CONNECTOR_NAME=${CONNECTOR_NAME:-kinesis-kafka-connector}
MAX_TASKS=${MAX_TASKS:-1}
MAX_CONNECTIONS=${MAX_CONNECTIONS:-1}
ENABLE_AGGREGATION=${ENABLE_AGGREGATION:-true}
RATE_LIMIT=${RATE_LIMIT:-100}
MAX_BUFFERED_TIME=${MAX_BUFFERED_TIME:-1500}
RECORD_TTL=${RECORD_TTL:-60000}

# check required options for fail-fast

if [ -z $BOOTSTRAP_SERVERS ]; then
    echo "ERROR: BOOTSTRAP_SERVERS required option is unset"
    exit 1
fi
if [ -z $REGION ]; then
    echo "ERROR: REGION required option is unset"
    exit 1
fi
if [ -z $KINESIS_STREAM ]; then
    echo "ERROR: KINESIS_STREAM required option is unset"
    exit 1
fi
if [ -z $KAFKA_TOPICS ]; then
    echo "ERROR: KAFKA_TOPICS required option is unset"
    exit 1
fi

# prepare worker configures

echo >> /worker.properties  # append each option in dedicated line

# for issue: https://issues.apache.org/jira/browse/KAFKA-3988
sed -i '/^internal\.key\.converter\.schemas\.enable=.*/d' /worker.properties
echo "internal.key.converter.schemas.enable=false" >> /worker.properties
sed -i '/^internal\.value\.converter\.schemas\.enable=.*/d' /worker.properties
echo "internal.value.converter.schemas.enable=false" >> /worker.properties

if [ -z $GROUP_ID ]; then
    echo "GROUP_ID environment variable is not set"
    echo "running in standalone mode"
else
    echo "running in distributed mode"

    sed -i '/^group\.id=.*/d' /worker.properties
    echo "group.id=${GROUP_ID}" >> /worker.properties

    sed -i '/^offset\.storage\.topic=.*/d' /worker.properties
    echo "offset.storage.topic=${OFFSET_TOPIC}" >> /worker.properties
    sed -i '/^config\.storage\.topic=.*/d' /worker.properties
    echo "config.storage.topic=${CONFIG_TOPIC}" >> /worker.properties
    sed -i '/^status\.storage\.topic=.*/d' /worker.properties
    echo "status.storage.topic=${STATUS_TOPIC}" >> /worker.properties

    sed -i '/^offset\.storage\.replication\.factor=.*/d' /worker.properties
    echo "offset.storage.replication.factor=${OFFSET_REPLICA}" >> /worker.properties
    sed -i '/^config\.storage\.replication\.factor=.*/d' /worker.properties
    echo "config.storage.replication.factor=${CONFIG_REPLICA}" >> /worker.properties
    sed -i '/^status\.storage\.replication\.factor=.*/d' /worker.properties
    echo "status.storage.replication.factor=${STATUS_REPLICA}" >> /worker.properties
fi

sed -i "/^bootstrap\.servers=.*/c\bootstrap.servers=${BOOTSTRAP_SERVERS}" /worker.properties

sed -i '/^rest\.host\.name=.*/d' /worker.properties
echo "rest.host.name=0.0.0.0" >> /worker.properties

# prepare connector configures

sed -i "/^name=.*/c\name=${CONNECTOR_NAME}" /kinesis-streams-kafka-connector.properties
sed -i "/^region=.*/c\region=${REGION}" /kinesis-streams-kafka-connector.properties
sed -i "/^streamName=.*/c\streamName=${KINESIS_STREAM}" /kinesis-streams-kafka-connector.properties
sed -i "/^topics=.*/c\topics=${KAFKA_TOPICS}" /kinesis-streams-kafka-connector.properties
sed -i "/^tasks\.max=.*/c\tasks.max=${MAX_TASKS}" /kinesis-streams-kafka-connector.properties
sed -i "/^maxConnections=.*/c\maxConnections=${MAX_CONNECTIONS}" /kinesis-streams-kafka-connector.properties
sed -i "/^aggregration=.*/c\aggregration=${ENABLE_AGGREGATION}" /kinesis-streams-kafka-connector.properties  # "aggregration" here is NOT a typo
sed -i "/^rateLimit=.*/c\rateLimit=${RATE_LIMIT}" /kinesis-streams-kafka-connector.properties
sed -i "/^maxBufferedTime=.*/c\maxBufferedTime=${MAX_BUFFERED_TIME}" /kinesis-streams-kafka-connector.properties
sed -i "/^ttl=.*/c\ttl=${RECORD_TTL}" /kinesis-streams-kafka-connector.properties

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
