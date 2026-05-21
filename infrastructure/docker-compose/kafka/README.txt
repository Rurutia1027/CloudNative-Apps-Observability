Local Kafka (single broker)
===========================

One broker on localhost:19092, replication-factor 1. Partitions stay at 3.

After upgrading from 3 brokers, reset local cluster data once:

  cd infrastructure/docker-compose
  docker compose -f common.yml -f zookeeper.yml -f kafka_cluster.yml down
  rm -rf volumes/kafka volumes/zookeeper

  cd ../.. && ./bin/start-local.sh

Tune JVM caps in .env. Kafka Manager: compose --profile tools up -d kafka-manager
