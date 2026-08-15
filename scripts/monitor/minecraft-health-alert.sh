#!/bin/bash

set -e

ENV_FILE="/etc/minecraft-health-alert.env"
STATE_FILE="/var/lib/minecraft-health/state"

if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: Discord environment file not found."
    exit 1
fi

source "$ENV_FILE"

if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
    echo "ERROR: DISCORD_WEBHOOK_URL is not configured."
    exit 1
fi

STATUS="${1:-UNKNOWN}"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

CURRENT_STATE="HEALTHY"

if [ -f "$STATE_FILE" ]; then
    CURRENT_STATE=$(cat "$STATE_FILE")
fi

case "$STATUS" in

    FAILED)

        if [ "$CURRENT_STATE" = "FAILED" ]; then
            echo "No failure alert required. Current state: FAILED"
            exit 0
        fi

        MESSAGE=$(printf '🔴 **Minecraft Server Alert**\nHealth check FAILED.\nTime: %s' "$TIMESTAMP")

        PAYLOAD=$(printf '%s' "$MESSAGE" | python3 -c '
import json
import sys

message = sys.stdin.read()
print(json.dumps({"content": message}))
')

        curl \
            --fail \
            --silent \
            --show-error \
            --max-time 10 \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD" \
            "$DISCORD_WEBHOOK_URL"

        echo "FAILED" > "$STATE_FILE"

        echo
        echo "Discord alert sent: FAILED"
        ;;

    RECOVERED)

        if [ "$CURRENT_STATE" != "FAILED" ]; then
            echo "No recovery alert required. Current state: $CURRENT_STATE"
            exit 0
        fi

MESSAGE=$(printf '🟢 **Minecraft Server Recovered**\nHealth check is HEALTHY.\nTime: %s' "$TIMESTAMP")

        PAYLOAD=$(printf '%s' "$MESSAGE" | python3 -c '
import json
import sys

message = sys.stdin.read()
print(json.dumps({"content": message}))
')

        curl \
            --fail \
            --silent \
            --show-error \
            --max-time 10 \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD" \
            "$DISCORD_WEBHOOK_URL"

        echo "HEALTHY" > "$STATE_FILE"

        echo
        echo "Discord alert sent: RECOVERED"
        ;;

    *)
        echo "Usage: $0 {FAILED|RECOVERED}"
        exit 1
        ;;

esac
