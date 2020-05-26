## What's this

This is a set of manifests can be leveraged in the scenario of running kinesis-kafka-connector in EC2 instance with docker.

- Script `create_node_profile.sh` is used to create a proper instance profile in your AWS account, which has an inline role to allow EC2 instance pull the kinesis-kafka-connector docker image from your ECR repository.
  Some optional options can be overwrote by environment variables, you might check them at the `Configuration` section at the top of the file.
- Script `userdata.debin` as the user-data of the EC2 instance (for Ubuntu family AMI only) which will be initialized automatically by preparing the docker environment and launch kinesis-kafka-connector daemon container.
  As an example, you would have to update the option according to your environment at the `Configuration` section at the top of the file. 

## How to use

1. Make sure AWS CLI version 2 has been installed on your local and configured properly to access your target environment.
   Official installation and configuration guides at [here](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) and [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html).
2. Execute `create_node_profile.sh` to create the EC2 instance profile in your IAM.
3. For the HA and performance purpose, you probable need to leverage Amazon EC2 AutoScaling Group, it can maintain a connector fleet with a desired capacity, all connectors running under distributed mode in the same kafka consumer group.
   If so, you would have to create a `Launch Template` instead of launch a nude EC2 instance directly.
4. Finally copy whole configured `userdata.debin` content to the user-data option of the `Launch Template`, or the EC2 instance if running without AutoScaling Group support.


## Known issues

1. Failed to execute userdata script in the EC2 by ``Error response from daemon: client version 1.40 is too new. Maximum supported API version is 1.39``

The AWS ECR service in some regions is **currently (it changes fast!)** not workable with docker API version 1.40, e.g. in region `ap-northeast-1`,
this case will fail the execution of the command `docker pull` in the userdata with the error. To fix this, you need to downgrade docker-ce-cli and docker-ce versions <= 19.03.8 by setting `DOCKER_VERSION` option in `userdata.debin`,
e.g. for Ubuntu Bionic system running in that region **(again, it changes fast!)**, the option should be be configured to `5:19.03.8~3-0~ubuntu-bionic`.
