#!/bin/bash

set -u

FAILED=0

echo "================================="
echo "Minecraft Service Status"
echo "================================="

echo
echo "Minecraft"

MINECRAFT_STATUS=$(docker inspect \
    minecraft-server \
    --format='{{.State.Status}}' \
    2>/dev/null || echo "NOT_FOUND")

MINECRAFT_HEALTH=$(docker inspect \
    minecraft-server \
    --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' \
    2>/dev/null || echo "N/A")

echo "  Container : $MINECRAFT_STATUS"
echo "  Health    : $MINECRAFT_HEALTH"

if [ "$MINECRAFT_STATUS" != "running" ] ||
   [ "$MINECRAFT_HEALTH" != "healthy" ]; then
    FAILED=1
fi

check_http() {
    NAME="$1"
    URL="$2"

    HTTP_STATUS=$(curl -sS \
        -o /dev/null \
        -w "%{http_code}" \
        --max-time 5 \
        "$URL" \
        2>/dev/null || echo "000")

    if [ "$HTTP_STATUS" = "200" ]; then
        echo "$NAME"
        echo "  Status    : UP"
        echo "  HTTP      : $HTTP_STATUS"
    else
        echo "$NAME"
        echo "  Status    : DOWN"
        echo "  HTTP      : $HTTP_STATUS"
        FAILED=1
    fi
}

echo
check_http \
    "Metrics Exporter" \
    "http://127.0.0.1:9100/metrics"

echo
check_http \
    "Prometheus" \
    "http://127.0.0.1:9090/-/ready"

echo
check_http \
    "Alertmanager" \
    "http://127.0.0.1:9093/-/ready"

echo
check_http \
    "Grafana" \
    "http://127.0.0.1:3000/api/health"

echo
echo "================================="

if [ "$FAILED" -eq 0 ]; then
    echo "Overall Status : HEALTHY"
    echo "================================="
    exit 0
else
    echo "Overall Status : UNHEALTHY"
    echo "================================="
    exit 1
fi
