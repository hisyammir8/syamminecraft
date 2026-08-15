#!/bin/bash

BACKUP_DIR="/opt/minecraft-backups"
STATUS_FILE="$BACKUP_DIR/backup.status"
CONTAINER_NAME="minecraft-server"
KEEP_BACKUPS=7

echo "================================="
echo "Minecraft Backup Health"
echo "================================="

# --------------------------------------------------
# Backup status
# --------------------------------------------------

if [ -f "$STATUS_FILE" ]; then

    STATUS=$(grep '^STATUS=' "$STATUS_FILE" | cut -d'=' -f2-)
    TIMESTAMP=$(grep '^TIMESTAMP=' "$STATUS_FILE" | cut -d'=' -f2-)
    BACKUP_FILE=$(grep '^BACKUP_FILE=' "$STATUS_FILE" | cut -d'=' -f2-)
    LAST_SUCCESSFUL=$(grep '^LAST_SUCCESSFUL_BACKUP=' "$STATUS_FILE" | cut -d'=' -f2-)

    echo "Backup Status       : $STATUS"
    echo "Last Status Update  : $TIMESTAMP"

    if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
        BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

        echo "Last Backup         : $(basename "$BACKUP_FILE")"
        echo "Backup Size         : $BACKUP_SIZE"
    else
        echo "Last Backup         : NOT FOUND"
        echo "Backup Size         : -"
    fi

    if [ -n "$LAST_SUCCESSFUL" ] && [ -f "$LAST_SUCCESSFUL" ]; then
        echo "Last Successful     : $(basename "$LAST_SUCCESSFUL")"
    else
        echo "Last Successful     : NOT FOUND"
    fi

else

    echo "Backup Status       : UNKNOWN"
    echo "Last Status Update  : -"
    echo "Last Backup         : -"
    echo "Backup Size         : -"
    echo "Last Successful     : -"

fi

# --------------------------------------------------
# Backup count
# --------------------------------------------------

BACKUP_COUNT=$(find "$BACKUP_DIR" \
    -maxdepth 1 \
    -type f \
    -name 'minecraft-*.tar.gz' \
    | wc -l)

echo "Retention           : $BACKUP_COUNT / $KEEP_BACKUPS backups"

# --------------------------------------------------
# Disk
# --------------------------------------------------

AVAILABLE_KB=$(df -Pk "$BACKUP_DIR" | awk 'NR==2 {print $4}')
AVAILABLE_GB=$(awk "BEGIN {printf \"%.2f\", $AVAILABLE_KB / 1024 / 1024}")

echo "Available Disk      : ${AVAILABLE_GB} GB"

# --------------------------------------------------
# Minecraft
# --------------------------------------------------

if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then

    STATE=$(docker exec "$CONTAINER_NAME" \
        cat /runtime/server.state 2>/dev/null || echo "UNKNOWN")

    echo "Minecraft           : $STATE"

else

    echo "Minecraft           : STOPPED"

fi

# --------------------------------------------------
# Backup timer
# --------------------------------------------------

if systemctl is-active --quiet minecraft-backup.timer; then

    echo "Backup Timer        : ACTIVE"

    NEXT_BACKUP=$(systemctl list-timers minecraft-backup.timer \
    --no-legend \
    | awk '{print $1 " " $2 " " $3}')

    echo "Next Backup         : ${NEXT_BACKUP:-UNKNOWN}"

else

    echo "Backup Timer        : INACTIVE"
    echo "Next Backup         : -"

fi

echo "================================="
