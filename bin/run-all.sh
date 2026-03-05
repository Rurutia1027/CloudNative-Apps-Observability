#!/bin/bash
set -euo pipefail

# Run full stack: deps (Postgres, RabbitMQ, Jaeger, Prometheus, PgAdmin) + micro app images
# Uses docker-compose.yml by default. Override with COMPOSE_FILE=docker-compose.yml if needed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

COMPOSE_FILE="${COMPOSE_FILE:-../docker-compose.yml}"
if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "ERROR: Compose file not found: $COMPOSE_FILE"
  exit 1
fi

echo "Using compose file: $COMPOSE_FILE"
echo "Docker user (images): ${DOCKER_USER:-nanachi1027}"
echo "Image tag: ${IMAGE_TAG:-latest}"
echo ""

# Optional: pull images first (set PULL=1 to enable)
if [[ "${PULL:-0}" == "1" ]]; then
  echo "Pulling images..."
  docker compose -f "$COMPOSE_FILE" pull
fi

echo "Starting dependencies (postgres, rabbitmq, jaeger, prometheus, pgadmin) and app services..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "Waiting for infra to be healthy (postgres, rabbitmq)..."
sleep 5
until docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U amigoscode -q 2>/dev/null; do
  echo "  waiting for postgres..."
  sleep 2
done
echo "  postgres ready."

until docker compose -f "$COMPOSE_FILE" exec -T rabbitmq rabbitmq-diagnostics -q ping 2>/dev/null; do
  echo "  waiting for rabbitmq..."
  sleep 2
done
echo "  rabbitmq ready."

echo ""
echo "Stack is up. Useful URLs (host):"
echo "  API Gateway:     http://localhost:8083"
echo "  Customer:        http://localhost:8080"
echo "  Fraud:           http://localhost:8081"
echo "  Notification:    http://localhost:8082"
echo "  Jaeger UI:       http://localhost:16686"
echo "  Prometheus:      http://localhost:9090"
echo "  RabbitMQ admin:  http://localhost:15672"
echo "  PgAdmin:         http://localhost:5050"
echo ""
echo "Logs: docker compose -f $COMPOSE_FILE logs -f"
echo "Stop: docker compose -f $COMPOSE_FILE down"
