#!/bin/bash

set -e

log() {
    echo $(date -u +"%Y-%m-%dT%H:%M:%SZ") "${@}"
}

if [[ $# -lt 2 ]]; then
    log "Usage: $0 <image-name> <version> [dockerfile-path]"
    exit 1
fi

IMAGE_NAME="$1"
VERSION="$2"
DOCKERFILE_PATH="${3:-Dockerfile}"
DOCKER_USERNAME="dockerdemo786"
REGISTRY_URL="docker.io"

# Validate Dockerfile existence
if [[ ! -f "$DOCKERFILE_PATH" ]]; then
    log "Error: Dockerfile not found at $DOCKERFILE_PATH"
    exit 1
fi

BUILD_CONTEXT=$(dirname "$DOCKERFILE_PATH")

log "Building Docker image $IMAGE_NAME:$VERSION using Dockerfile at $DOCKERFILE_PATH (context: $BUILD_CONTEXT)"
docker build -t "$DOCKER_USERNAME/$IMAGE_NAME:$VERSION" -f "$DOCKERFILE_PATH" "$BUILD_CONTEXT"

log "Docker image $IMAGE_NAME:$VERSION built successfully."

log "Pushing Docker image $IMAGE_NAME:$VERSION to Docker Hub..."
docker push "$DOCKER_USERNAME/$IMAGE_NAME:$VERSION"

log "Docker image $IMAGE_NAME:$VERSION pushed successfully."
