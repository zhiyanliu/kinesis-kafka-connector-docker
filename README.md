## Build the docker image

Need to provide `REGION` and `ACCOUNT` environment variables to push the image to AWS ECR, for example:

``REGION={your_aws_region} ACCOUNT={your_aws_account_id} ./build.sh``

>> **Note:**
>> - Make sure AWS CLI version 2 has been installed on your local and configured properly to access your target environment.
     Official installation and configuration guides at [here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).
>> - Update `{your_aws_region}` to the valid AWS region according to your environment, e.g. `us-west-2`.
>> - Update `{your_aws_account_id}` to the valid AWS account ID according to your environment, e.g. `123456789012`.
>> - The script `build.sh` will push the image to the container image repository named `amazon/kinesis-kafka-connector` with tag `snapshot-0.0.9` by default, and assumes it has already been created in your ECR.
>>   If needed you can use your own image repository and tag like this: ``IMG={your_repo_name} VER={your_img_tag} ./build.sh``.
>> - Due to the container image push operation on ECR, the script `build.sh` needs the permission on `ecr:InitiateLayerUpload` and `ecr:UploadLayerPart` actions,
>>   so make sure the AWS CLI works with proper role or token on your local where to execute the script.
>> - If you'd like just to build the image locally or won't like to involve ECR in, you might execute `docker build -t kinesis-kafka-connector:snapshot-0.0.9 .` instead.

## Supported parameters

Follow environment variables will be loaded as the configuration to the connector:

|                 |                                |Default value          |
|-----------------|--------------------------------|-----------------------|
|BOOTSTRAP_SERVERS|**required**                    |                       |
|GROUP_ID         |**required** in distributed mode|                       |
|OFFSET_TOPIC     |*optional*                      |connect-offsets        |
|CONFIG_TOPIC     |*optional*                      |connect-config         |
|STATUS_TOPIC     |*optional*                      |connect-status         |
|OFFSET_REPLICA   |*optional*                      |2                      |
|CONFIG_REPLICA   |*optional*                      |2                      |
|STATUS_REPLICA   |*optional*                      |2                      |
|CONNECTOR_NAME   |*optional*                      |kinesis-kafka-connector|
|REGION           |**required**                    |                       |
|KINESIS_STREAM   |**required**                    |                       |
|KAFKA_TOPICS     |**required**                    |                       |
|MAX_TASKS        |*optional*                      |1                      |
|MAX_CONNECTIONS  |*optional*                      |1                      |

The configuration options and the description at here:

- https://github.com/awslabs/kinesis-kafka-connector/blob/master/config/kinesis-streams-kafka-connector.properties
- https://github.com/awslabs/kinesis-kafka-connector/blob/master/README.md#kafka-kinesis-streams-connectorproperties
- https://github.com/awslabs/kinesis-kafka-connector/blob/master/config/worker.properties

## Useful reference

- https://github.com/awslabs/kinesis-kafka-connector
- https://docs.confluent.io/current/connect/userguide.html#distributed-mode
- https://rmoff.net/2019/08/15/reset-kafka-connect-source-connector-offsets/
- https://issues.apache.org/jira/browse/KAFKA-3988
