#!/bin/bash
set -euo pipefail

# Usage: ./bin/build-images.sh <tag>
# Example: ./bin/build-images.sh v0.1.0

TAG=${1:-}
LATEST_TAG="latest"

if [ -z "$TAG" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

# Docker Hub namespace (use CI secret DOCKER_USER_NAME if available, otherwise default)
DOCKER_USER="${DOCKER_USER_NAME:-nanachi1027}"
IMAGE_PREFIX="ragent"

SERVICES=("customer" "fraud" "notification" "apigw")

echo "Using Docker Hub user: ${DOCKER_USER}"
echo "Target tag: ${TAG}"

# Ensure JARs exist for each service
for svc in "${SERVICES[@]}"; do
  echo "Checking JAR exists (${svc}/target/*.jar)..."
  if ! ls "${svc}"/target/*.jar >/dev/null 2>&1; then
    echo "ERROR: JAR for service '${svc}' not found. Please run first:"
    echo "  mvn clean package -pl ${svc} -am -DskipTests"
    exit 1
  fi
done

echo "Building and pushing multi-arch images for services: ${SERVICES[*]}"

for svc in "${SERVICES[@]}"; do
  IMAGE_NAME="${IMAGE_PREFIX}-${svc}"
  CONTEXT_DIR="${svc}"

  echo "Building and pushing image ${DOCKER_USER}/${IMAGE_NAME}:${TAG} from ${CONTEXT_DIR} ..."

  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t "${DOCKER_USER}/${IMAGE_NAME}:${TAG}" \
    -t "${DOCKER_USER}/${IMAGE_NAME}:${LATEST_TAG}" \
    --push \
    "${CONTEXT_DIR}"

  echo "Inspecting pushed image manifest for ${DOCKER_USER}/${IMAGE_NAME}:${TAG}..."
  docker buildx imagetools inspect "${DOCKER_USER}/${IMAGE_NAME}:${TAG}" || true
done

echo "All images built and pushed successfully."