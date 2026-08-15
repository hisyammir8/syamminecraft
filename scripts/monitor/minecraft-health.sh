#!/bin/bash

CONTAINER_NAME="minecraft-server"

# Resource thresholds
CPU_WARNING_THRESHOLD=80
MEMORY_WARNING_THRESHOLD=80
DISK_WARNING_THRESHOLD_GB=10
DISK_CRITICAL_THRESHOLD_GB=5


RESOURCE_WARNING=false

HEALTH_OK=true

echo "================================="
echo "Minecraft Server Health"
echo "================================="

# --------------------------------------------------
# Host metrics
# --------------------------------------------------

LOAD=$(awk '{print $1, $2, $3}' /proc/loadavg)

MEM_AVAILABLE=$(free -h | awk '/^Mem:/ {print $7}')

DISK_AVAILABLE=$(df -h / | awk 'NR==2 {print $4}')
DISK_AVAILABLE_GB=$(df -BG / | awk 'NR==2 {gsub(/G/, "", $4); print $4}')


echo "Host Load         : $LOAD"
echo "Memory Available  : $MEM_AVAILABLE"
echo "Disk Available    : $DISK_AVAILABLE"

# --------------------------------------------------
# Docker container
# --------------------------------------------------

CONTAINER_STATUS=$(docker inspect \
    "$CONTAINER_NAME" \
    --format='{{.State.Status}}' 2>/dev/null || echo "NOT_FOUND")

if [ "$CONTAINER_STATUS" = "running" ]; then
    echo "Container         : RUNNING"
else
    echo "Container         : $CONTAINER_STATUS"
    HEALTH_OK=false
fi

# --------------------------------------------------
# Docker health
# --------------------------------------------------

CONTAINER_HEALTH=$(docker inspect \
    "$CONTAINER_NAME" \
    --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' \
    2>/dev/null || echo "N/A")

if [ "$CONTAINER_HEALTH" = "healthy" ]; then
    echo "Container Health  : HEALTHY"
else
    echo "Container Health  : $CONTAINER_HEALTH"
    HEALTH_OK=false
fi

# --------------------------------------------------
# Minecraft runtime state
# --------------------------------------------------

MINECRAFT_STATE=$(docker exec "$CONTAINER_NAME" \
    cat /runtime/server.state 2>/dev/null || echo "UNKNOWN")

if [ "$MINECRAFT_STATE" = "RUNNING" ]; then
    echo "Minecraft         : RUNNING"
else
    echo "Minecraft         : $MINECRAFT_STATE"
    HEALTH_OK=false
fi

# --------------------------------------------------
# Container resource usage
# --------------------------------------------------

STATS=$(docker stats "$CONTAINER_NAME" --no-stream \
    --format '{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.PIDs}}' \
    2>/dev/null || echo "N/A|N/A|N/A|N/A")

IFS='|' read -r CPU_USAGE MEM_USAGE MEM_PERCENT PIDS <<< "$STATS"

echo "CPU Usage         : $CPU_USAGE"
echo "Memory Usage      : $MEM_USAGE"
echo "Memory Percent    : $MEM_PERCENT"
echo "PIDs              : $PIDS"

# --------------------------------------------------
# Resource threshold
# --------------------------------------------------

CPU_VALUE=$(echo "$CPU_USAGE" | tr -d '%' | tr -d ' ')

MEMORY_VALUE=$(echo "$MEM_PERCENT" | tr -d '%' | tr -d ' ')

if [ -n "$CPU_VALUE" ] && \
   [ "$CPU_VALUE" != "N/A" ] && \
   awk "BEGIN {exit !($CPU_VALUE >= $CPU_WARNING_THRESHOLD)}"
then
    RESOURCE_WARNING=true
fi

if [ -n "$MEMORY_VALUE" ] && \
   [ "$MEMORY_VALUE" != "N/A" ] && \
   awk "BEGIN {exit !($MEMORY_VALUE >= $MEMORY_WARNING_THRESHOLD)}"
then
    RESOURCE_WARNING=true
fi

echo "Resource Warning : $RESOURCE_WARNING"

# --------------------------------------------------
# Disk threshold
# --------------------------------------------------

DISK_STATUS="NORMAL"

if [ -n "$DISK_AVAILABLE_GB" ] && \
   [ "$DISK_AVAILABLE_GB" -lt "$DISK_CRITICAL_THRESHOLD_GB" ]; then

    DISK_STATUS="CRITICAL"
    RESOURCE_WARNING=true

elif [ -n "$DISK_AVAILABLE_GB" ] && \
     [ "$DISK_AVAILABLE_GB" -le "$DISK_WARNING_THRESHOLD_GB" ]; then

    DISK_STATUS="WARNING"
    RESOURCE_WARNING=true
fi

echo "Disk Status       : $DISK_STATUS"

# --------------------------------------------------
# Resource state
# --------------------------------------------------

RESOURCE_STATUS="NORMAL"

if [ "$DISK_STATUS" = "CRITICAL" ]; then
    RESOURCE_STATUS="CRITICAL"

elif [ "$RESOURCE_WARNING" = true ]; then
    RESOURCE_STATUS="WARNING"
fi

echo "Resource Status  : $RESOURCE_STATUS"

RESOURCE_STATE_FILE="/var/lib/minecraft-health/resource.state"

if [ -f "$RESOURCE_STATE_FILE" ]; then
    PREVIOUS_RESOURCE_STATUS=$(cat "$RESOURCE_STATE_FILE")
else
    PREVIOUS_RESOURCE_STATUS="NORMAL"
fi

echo "Previous Resource: $PREVIOUS_RESOURCE_STATUS"

RESOURCE_STATE_CHANGED=false

if [ "$RESOURCE_STATUS" != "$PREVIOUS_RESOURCE_STATUS" ]; then
    RESOURCE_STATE_CHANGED=true
fi



echo "Resource Changed : $RESOURCE_STATE_CHANGED"

echo "$RESOURCE_STATUS" > "$RESOURCE_STATE_FILE"

echo "================================="

# --------------------------------------------------
# Health history
# --------------------------------------------------

HISTORY_FILE="/var/lib/minecraft-health/history.csv"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ "$HEALTH_OK" = true ]; then
    HEALTH_STATUS="HEALTHY"
else
    HEALTH_STATUS="UNHEALTHY"
fi

echo "$TIMESTAMP,$HEALTH_STATUS,\"$LOAD\",$MEM_AVAILABLE,$DISK_AVAILABLE,$CONTAINER_STATUS,$CONTAINER_HEALTH,$MINECRAFT_STATE,$CPU_USAGE,\"$MEM_USAGE\",$MEM_PERCENT,$PIDS" \
    >> "$HISTORY_FILE" 2>/dev/null || true

# Keep header + latest 2000 records
if [ -f "$HISTORY_FILE" ]; then
    LINE_COUNT=$(wc -l < "$HISTORY_FILE")

    if [ "$LINE_COUNT" -gt 2001 ]; then
        TMP_HISTORY="${HISTORY_FILE}.tmp"

        {
            head -1 "$HISTORY_FILE"
            tail -2000 "$HISTORY_FILE"
        } > "$TMP_HISTORY" 2>/dev/null && \
        mv "$TMP_HISTORY" "$HISTORY_FILE" 2>/dev/null || \
        rm -f "$TMP_HISTORY" 2>/dev/null || true
    fi
fi

if [ "$HEALTH_OK" = true ]; then
    echo "Health Status     : HEALTHY"
    echo "================================="
    exit 0
else
    echo "Health Status     : UNHEALTHY"
    echo "================================="
    exit 1
fi
