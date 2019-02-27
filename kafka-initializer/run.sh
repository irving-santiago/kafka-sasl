#!/bin/sh
set -x
create_topic_with_retry() {
  for i in $(seq 1 5)
  do
    /usr/bin/kafka-topics --zookeeper zookeeper:22181 --create --partitions 2 --replication-factor 1 --topic $1 && break
    echo "Error while creating topic $1, retrying in 3 seconds..."
    sleep 3
  done
}

for topic in "$@"
do
  create_topic_with_retry $topic
done

cub zk-ready zookeeper:22181 120
kafka-configs --zookeeper zookeeper:22181 --alter --add-config "SCRAM-SHA-256=[iterations=4096,password=password]" --entity-type users --entity-name metricsreporter
kafka-configs --zookeeper zookeeper:22181 --alter --add-config "SCRAM-SHA-256=[iterations=4096,password=!@#^()%n&0*ABCDabcd123]" --entity-type users --entity-name kafkaclient
kafka-configs --zookeeper zookeeper:22181 --alter --add-config "SCRAM-SHA-256=[iterations=4096,password=password]" --entity-type users --entity-name kafkabroker
