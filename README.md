## Build the docker image

Need to provide `REGION` and `ACCOUNT` environment variables to push the image to AWS ECR, for example:

``REGION=us-west-2 ACCOUNT=123456789012 ./build.sh``

>> **Note:**
>> If you'd like just to build the image locally or won't like to involve ECR in, you might execute `docker build -t kinesis-kafka-connector:snapshot .` instead.

## Supported parameters

Follow environment variables will be loaded as the configuration to the connector:

- BOOTSTRAP_SERVERS
- GROUP_ID
- CONNECTOR_NAME
- REGION
- KINESIS_STREAM
- KAFKA_TOPICS
- MAX_TASKS
- MAX_CONNECTIONS

The configuration options and the description at here:

- https://github.com/awslabs/kinesis-kafka-connector/blob/master/config/kinesis-streams-kafka-connector.properties
- https://github.com/awslabs/kinesis-kafka-connector/blob/master/README.md#kafka-kinesis-streams-connectorproperties
- https://github.com/awslabs/kinesis-kafka-connector/blob/master/config/worker.properties

## Useful reference

- https://docs.confluent.io/current/connect/userguide.html#distributed-mode
- https://rmoff.net/2019/08/15/reset-kafka-connect-source-connector-offsets/
- https://issues.apache.org/jira/browse/KAFKA-3988

