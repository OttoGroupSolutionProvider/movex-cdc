#!/bin/bash
# start Kafka inside a docker container
# part of Docker CMD or individual start in CI pipeline
# Peter Ramm, 2020-03-17

export KAFKA_HOME=/opt/kafka
export BROKER_ID=-1
export KAFKA_LISTENERS=LISTENER_EXT://0.0.0.0:9092,LISTENER_INT://0.0.0.0:9093
export KAFKA_ADVERTISED_LISTENERS=LISTENER_EXT://localhost:9092,LISTENER_INT://localhost:9093
export KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=LISTENER_EXT:PLAINTEXT,LISTENER_INT:PLAINTEXT
export KAFKA_INTER_BROKER_LISTENER_NAME=LISTENER_INT

echo "Prepare configuration"
sed -i "s|^broker.id=.*$|broker.id=$BROKER_ID|" $KAFKA_HOME/config/server.properties
echo "listeners=$KAFKA_LISTENERS"                                               >> $KAFKA_HOME/config/server.properties
echo "advertised.listeners=$KAFKA_ADVERTISED_LISTENERS"                         >> $KAFKA_HOME/config/server.properties
echo "listener.security.protocol.map=$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"     >> $KAFKA_HOME/config/server.properties
echo "inter.broker.listener.name=$KAFKA_INTER_BROKER_LISTENER_NAME"             >> $KAFKA_HOME/config/server.properties

echo "Starting Zookeeper"
$KAFKA_HOME/bin/zookeeper-server-start.sh -daemon $KAFKA_HOME/config/zookeeper.properties

echo "Starting Kafka"
$KAFKA_HOME/bin/kafka-server-start.sh     -daemon $KAFKA_HOME/config/server.properties

typeset -i LOOP_COUNT=0
KAFKA_STARTED="started (kafka.server.KafkaServer)"
echo "Wait for Kafka operation"
while [ 1 -eq 1 ]
do
  grep "$KAFKA_STARTED" $KAFKA_HOME/logs/kafkaServer.out >/dev/null
  if [ $? -eq 0 ]; then
    echo ""
    grep "$KAFKA_STARTED" $KAFKA_HOME/logs/kafkaServer.out
    echo "KAFKA_VERSION = $KAFKA_VERSION"
    echo "SCALA_VERSION = $SCALA_VERSION"
    echo "Creating topics and consumer groups"
    echo "Following double output 'org.apache.kafka.common.errors.TimeoutException' is 'works as designed'"
    $KAFKA_HOME/bin/kafka-topics.sh --create --topic TestTopic1 --partitions 4 --bootstrap-server localhost:9092 --replication-factor 1
    $KAFKA_HOME/bin/kafka-topics.sh --create --topic TestTopic2 --partitions 8 --bootstrap-server localhost:9092 --replication-factor 1
    $KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic TestTopic1 --group Group1 --timeout-ms 10000
    $KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic TestTopic1 --group Group2 --timeout-ms 10000
    $KAFKA_HOME/bin/kafka-consumer-groups.sh --bootstrap-server=localhost:9092 --list
    exit 0
  fi

  LOOP_COUNT=$LOOP_COUNT+1
  if [ $LOOP_COUNT -gt 20 ]; then
    echo ""
    echo "Kafka not in operation after 20 seconds, terminating"
    echo ""
    echo "############# Zookeeper log ##############"
    cat $KAFKA_HOME/logs/zookeeper.out
    echo ""
    echo "############# Kafka log ##############"
    cat $KAFKA_HOME/logs/kafkaServer.out
    exit 1
  fi
  echo -n "."
  sleep 1
done



