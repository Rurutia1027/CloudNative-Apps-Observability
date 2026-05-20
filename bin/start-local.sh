#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_DIR="${PROJECT_ROOT}/infrastructure/docker-compose"

RESET_DB=false
DB_ONLY=false

for arg in "$@"; do
  case "$arg" in
    --reset-db)
      RESET_DB=true
      ;;
    --db-only)
      DB_ONLY=true
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--reset-db] [--db-only]"
      exit 1
      ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is required but not found in PATH."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose is required but not available."
  exit 1
fi

cd "${COMPOSE_DIR}"

if [[ "${RESET_DB}" == "true" ]]; then
  echo "Resetting Postgres volume (this removes local DB data)..."
  docker compose -f common.yml -f postgres.yml down -v
fi

echo "Starting Postgres..."
docker compose -f common.yml -f postgres.yml up -d

if [[ "${DB_ONLY}" == "true" ]]; then
  echo "Postgres is up. Use profile: SPRING_PROFILES_ACTIVE=docker"
  exit 0
fi

echo "Starting Zookeeper + Kafka cluster..."
docker compose -f common.yml -f zookeeper.yml -f kafka_cluster.yml up -d

echo "Initializing Kafka topics..."
docker compose -f common.yml -f zookeeper.yml -f kafka_cluster.yml -f init_kafka.yml run --rm init-kafka

echo
echo "Local infrastructure is ready."
echo "Recommended before running services:"
echo "  export SPRING_PROFILES_ACTIVE=docker"
