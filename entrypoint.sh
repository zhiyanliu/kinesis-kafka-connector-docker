#!/bin/bash

set -ex

# prepare worker configures

if ! [ -z $BOOTSTRAP_SERVERS ]; then
    sed -i "/^bootstrap.servers=.*/c\bootstrap.servers=${BOOTSTRAP_SERVERS}" /worker.properties
fi

if [ -z $GROUP_ID ]; then
    echo "GROUP_ID environment variable is not set"
    echo "running in standalone mode"
    CMD=connect-standalone
else
    echo "running in distributed mode"
    CMD=connect-distributed

    if [ -z $OFFSET_TOPIC ]; then
        OFFSET_TOPIC=connect-offsets
    fi
    if [ -z $CONFIG_TOPIC ]; then
        CONFIG_TOPIC=connect-offsets
    fi
    if [ -z $STATUS_TOPIC ]; then
        STATUS_TOPIC=connect-offsets
    fi

    sed -i '/^group.id=.*/d' /worker.properties
    echo "group.id=${GROUP_ID}" >> /worker.properties
    sed -i '/^offset.storage.topic=.*/d' /worker.properties
    echo "offset.storage.topic=${OFFSET_TOPIC}" >> /worker.properties
    sed -i '/^config.storage.topic=.*/d' /worker.properties
    echo "config.storage.topic=${CONFIG_TOPIC}" >> /worker.properties
    sed -i '/^status.storage.topic=.*/d' /worker.properties
    echo "status.storage.topic=${STATUS_TOPIC}" >> /worker.properties
fi

# prepare connector configures

if ! [ -z $CONNECTOR_NAME ]; then
    sed -i "/^name=.*/c\name=${CONNECTOR_NAME}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $REGION ]; then
    sed -i "/region=.*/c\region=${REGION}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $KINESIS_STREAM ]; then
    sed -i "/streamName=.*/c\streamName=${KINESIS_STREAM}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $KAFKA_TOPICS ]; then
    sed -i "/topics=.*/c\topics=${KAFKA_TOPICS}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $MAX_TASKS ]; then
    sed -i "/tasks.max=.*/c\tasks.max=${MAX_TASKS}" /kinesis-streams-kafka-connector.properties
fi
if ! [ -z $MAX_CONNECTIONS ]; then
    sed -i "/maxConnections=.*/c\maxConnections=${MAX_CONNECTIONS}" /kinesis-streams-kafka-connector.properties
fi

/usr/bin/$CMD /worker.properties /kinesis-streams-kafka-connector.properties
