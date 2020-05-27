FROM azul/zulu-openjdk-debian:14 AS build

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get upgrade -y && apt-get install -y git maven
RUN git clone https://github.com/awslabs/kinesis-kafka-connector.git
# lock to the version and build
RUN cd kinesis-kafka-connector && git checkout 267524b && mvn package


FROM confluentinc/cp-kafka-connect-base:5.2.4-1

ENV COMPONENT=kinesis-kafka-connect

COPY --from=build /kinesis-kafka-connector/target/amazon-kinesis-kafka-connector-*-SNAPSHOT.jar \
                    /usr/share/java/kafka
COPY --from=build /kinesis-kafka-connector/config/worker.properties \
                    /kinesis-kafka-connector/config/kinesis-streams-kafka-connector.properties \
                    /

ADD entrypoint.sh /
RUN chmod u+x /entrypoint.sh

CMD ["/entrypoint.sh"]
