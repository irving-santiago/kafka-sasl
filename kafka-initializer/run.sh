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
