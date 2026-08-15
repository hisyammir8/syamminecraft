#!/bin/bash

ENV_FILE="/etc/minecraft-health-alert.env"

if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

if [ -z "${DISCORD_WEBHOOK_URL:-}" ]; then
    echo "ERROR: DISCORD_WEBHOOK_URL is not configured."
    exit 1
fi

RESOURCE_STATUS="${1:-}"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

case "$RESOURCE_STATUS" in

    WARNING)
        MESSAGE="⚠️ Minecraft Resource Warning

Resource usage has exceeded the configured warning threshold.

Time: $TIMESTAMP"
        ;;

    CRITICAL)
        MESSAGE="🚨 Minecraft Resource Critical

Minecraft server resource usage has reached a critical level.

Time: $TIMESTAMP"
        ;;

    RECOVERED)
        MESSAGE="✅ Minecraft Resource Recovered

Minecraft server resource usage has returned to normal.

Time: $TIMESTAMP"
        ;;

    *)
        echo "ERROR: Invalid resource status: $RESOURCE_STATUS"
        exit 1
        ;;

esac

PAYLOAD=$(printf '%s' "$MESSAGE" | python3 -c '
import json
import sys

message = sys.stdin.read()

print(json.dumps({
    "content": message
}))
')

HTTP_STATUS=$(curl -sS \
    -o /dev/null \
    -w "%{http_code}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$DISCORD_WEBHOOK_URL")

if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
    echo "Discord resource alert sent: $RESOURCE_STATUS"
    exit 0
else
    echo "ERROR: Discord webhook returned HTTP $HTTP_STATUS"
    exit 1
fi
