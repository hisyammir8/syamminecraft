#!/bin/bash

set -u

CONTAINER_NAME="minecraft-server"
COMPOSE_SERVICE="minecraft"

PROJECT_DIR="/opt/syamminecraft"

HEALTH_SCRIPT="$PROJECT_DIR/scripts/monitor/minecraft-health.sh"
SERVICE_STATUS_SCRIPT="$PROJECT_DIR/scripts/service-status.sh"

TIMEOUT=180
INTERVAL=5

echo "================================="
echo "Minecraft Recovery"
echo "================================="

echo
echo "=== CURRENT STATE ==="

CONTAINER_STATUS=$(docker inspect \
    "$CONTAINER_NAME" \
    --format='{{.State.Status}}' \
    2>/dev/null || echo "NOT_FOUND")

CONTAINER_HEALTH=$(docker inspect \
    "$CONTAINER_NAME" \
    --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' \
    2>/dev/null || echo "N/A")

echo "Container : $CONTAINER_STATUS"
echo "Health    : $CONTAINER_HEALTH"

if [ "$CONTAINER_STATUS" = "running" ] &&
   [ "$CONTAINER_HEALTH" = "healthy" ]; then

    echo
    echo "Minecraft is already healthy."
    echo "No recovery action required."
    echo "================================="
    exit 0
fi

echo
echo "=== RECOVERY ACTION ==="
echo "Starting Minecraft service..."

cd "$PROJECT_DIR" || {
    echo "ERROR: Cannot access project directory."
    exit 1
}

if ! docker compose up -d "$COMPOSE_SERVICE"; then
    echo "ERROR: Failed to start Minecraft service."
    exit 1
fi

echo
echo "Waiting for Minecraft health..."
echo "Timeout : ${TIMEOUT}s"

ELAPSED=0

while [ "$ELAPSED" -lt "$TIMEOUT" ]; do

    CONTAINER_STATUS=$(docker inspect \
        "$CONTAINER_NAME" \
        --format='{{.State.Status}}' \
        2>/dev/null || echo "NOT_FOUND")

    CONTAINER_HEALTH=$(docker inspect \
        "$CONTAINER_NAME" \
        --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' \
        2>/dev/null || echo "N/A")

    echo "[$ELAPSED s] Container=$CONTAINER_STATUS Health=$CONTAINER_HEALTH"

    if [ "$CONTAINER_STATUS" = "running" ] &&
       [ "$CONTAINER_HEALTH" = "healthy" ]; then

        echo
        echo "Minecraft container is healthy."
        break
    fi

    sleep "$INTERVAL"
    ELAPSED=$((ELAPSED + INTERVAL))
done

if [ "$CONTAINER_STATUS" != "running" ] ||
   [ "$CONTAINER_HEALTH" != "healthy" ]; then

    echo
    echo "ERROR: Minecraft failed to become healthy."
    echo "================================="
    exit 1
fi

echo
echo "=== HEALTH VERIFICATION ==="

if ! bash "$HEALTH_SCRIPT"; then
    echo
    echo "ERROR: Minecraft health verification failed."
    echo "================================="
    exit 1
fi

echo
echo "=== SERVICE VERIFICATION ==="

if ! bash "$SERVICE_STATUS_SCRIPT"; then
    echo
    echo "ERROR: Service status verification failed."
    echo "================================="
    exit 1
fi

echo
echo "================================="
echo "Recovery Status : SUCCESS"
echo "================================="

exit 0
