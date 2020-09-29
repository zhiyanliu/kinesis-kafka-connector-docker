FROM azul/zulu-openjdk-debian:14 AS build

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && apt-get upgrade -y && apt-get install -y git maven
RUN git clone https://github.com/zhiyanliu/kinesis-kafka-connector.git
# lock to the version and build
RUN cd kinesis-kafka-connector && git checkout 0b74810 && mvn package


FROM confluentinc/cp-kafka-connect-base:5.3.3-1

ENV COMPONENT=kinesis-kafka-connect

COPY --from=build /kinesis-kafka-connector/target/amazon-kinesis-kafka-connector-*-SNAPSHOT.jar \
                    /usr/share/java/kafka
COPY --from=build /kinesis-kafka-connector/config/worker.properties \
                    /kinesis-kafka-connector/config/kinesis-streams-kafka-connector.properties \
                    /

ADD entrypoint.sh /
RUN chmod u+x /entrypoint.sh

CMD ["/entrypoint.sh"]

HEALTHCHECK --start-period=120s --interval=5s --timeout=10s --retries=3 \
	CMD curl -sX GET -H "Content-Type: application/json" http://127.0.0.1:8083/connector-plugins | jq "." | grep 'com.amazon.kinesis.kafka.AmazonKinesisSinkConnector'
