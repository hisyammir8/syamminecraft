#!/bin/bash

set -e

PROJECT_DIR="/opt/syamminecraft"
DATA_DIR="$PROJECT_DIR/data"
BACKUP_DIR="/opt/minecraft-backups"
STATUS_FILE="$BACKUP_DIR/backup.status"
MIN_FREE_SPACE_GB=5

CONTAINER_NAME="minecraft-server"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/minecraft-$TIMESTAMP.tar.gz"
CHECKSUM_FILE="$BACKUP_FILE.sha256"

SERVER_WAS_RUNNING=false
BACKUP_SUCCESS=false
KEEP_BACKUPS=7

log() {
    echo "[BACKUP] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

fail() {

    log "ERROR: $1"

    write_backup_status "FAILED"

    exit 1
}

handle_error() {

    EXIT_CODE=$?

    log "ERROR: Backup process failed with exit code $EXIT_CODE."

    write_backup_status "FAILED"

    exit "$EXIT_CODE"
}

write_backup_status() {

    STATUS="$1"

    LAST_SUCCESSFUL_BACKUP=""

    if [ -f "$STATUS_FILE" ]; then
        LAST_SUCCESSFUL_BACKUP=$(grep '^LAST_SUCCESSFUL_BACKUP=' "$STATUS_FILE" \
            | cut -d'=' -f2- || true)
    fi

    if [ "$STATUS" = "SUCCESS" ]; then
        LAST_SUCCESSFUL_BACKUP="$BACKUP_FILE"
    fi

    cat > "$STATUS_FILE" <<EOF
STATUS=$STATUS
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE=${BACKUP_FILE:-}
LAST_SUCCESSFUL_BACKUP=${LAST_SUCCESSFUL_BACKUP:-}
EOF

}

check_disk_space() {

    log "Checking available disk space..."

    AVAILABLE_KB=$(df -Pk "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    MIN_FREE_KB=$((MIN_FREE_SPACE_GB * 1024 * 1024))

    AVAILABLE_GB=$(awk "BEGIN {printf \"%.2f\", $AVAILABLE_KB / 1024 / 1024}")

    log "Available disk space: ${AVAILABLE_GB} GB"
    log "Minimum required: ${MIN_FREE_SPACE_GB} GB"

    if [ "$AVAILABLE_KB" -lt "$MIN_FREE_KB" ]; then
        fail "Insufficient disk space. Available: ${AVAILABLE_GB} GB, required: ${MIN_FREE_SPACE_GB} GB."
    fi

    log "Disk space check passed."
}

start_server() {

    log "Starting Minecraft server..."

    cd "$PROJECT_DIR"

    docker compose up -d

    log "Waiting for Minecraft server..."

    for i in $(seq 1 90); do

        STATE=$(docker exec "$CONTAINER_NAME" \
            cat /runtime/server.state 2>/dev/null || true)

        if [ "$STATE" = "RUNNING" ]; then
            log "Minecraft server is RUNNING."
            return 0
        fi

        sleep 2

    done

    log "ERROR: Minecraft server failed to reach RUNNING state."

    return 1
}

cleanup_old_backups() {

    log "Checking backup retention..."

    mapfile -t BACKUPS < <(
        find "$BACKUP_DIR" \
            -maxdepth 1 \
            -type f \
            -name 'minecraft-*.tar.gz' \
            -printf '%f\n' \
            | sort -r
    )

    BACKUP_COUNT=${#BACKUPS[@]}

    log "Backup count: $BACKUP_COUNT"
    log "Retention limit: $KEEP_BACKUPS"

    if [ "$BACKUP_COUNT" -le "$KEEP_BACKUPS" ]; then
        log "No old backups to remove."
        return 0
    fi

    for ((i=KEEP_BACKUPS; i<BACKUP_COUNT; i++)); do

        OLD_BACKUP="${BACKUPS[$i]}"
        OLD_BACKUP_PATH="$BACKUP_DIR/$OLD_BACKUP"

        log "Removing old backup:"
        log "$OLD_BACKUP_PATH"

        sudo rm -f "$OLD_BACKUP_PATH"
        sudo rm -f "$OLD_BACKUP_PATH.sha256"

    done

    log "Backup retention cleanup completed."
}

cleanup() {

    if [ "$SERVER_WAS_RUNNING" = true ]; then

        if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then

            log "Server is stopped. Attempting recovery..."

            if start_server; then
                log "Minecraft server recovery successful."
            else
                log "ERROR: Failed to recover Minecraft server."
            fi

        fi

    fi
}

trap handle_error ERR
trap cleanup EXIT

log "================================="
log "Minecraft Backup"
log "================================="

mkdir -p "$BACKUP_DIR"

# --------------------------------------------------
# Check server
# --------------------------------------------------

if docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then

    SERVER_WAS_RUNNING=true

    log "Minecraft server is RUNNING."

else

    fail "Minecraft container is not running."

fi

# --------------------------------------------------
# Disk space check
# --------------------------------------------------

check_disk_space

# --------------------------------------------------
# Stop server
# --------------------------------------------------

log "Stopping Minecraft server gracefully..."

docker stop -t 60 "$CONTAINER_NAME"

log "Minecraft server stopped."

# --------------------------------------------------
# Create backup
# --------------------------------------------------

log "Creating backup..."

sudo tar \
    --exclude='./cache' \
    --exclude='./libraries' \
    --exclude='./versions' \
    --exclude='./logs' \
    --exclude='*/session.lock' \
    --exclude='./usercache.json' \
    --exclude='./version_history.json' \
    -czf "$BACKUP_FILE" \
    -C "$DATA_DIR" .

log "Backup created:"
log "$BACKUP_FILE"

# --------------------------------------------------
# Checksum
# --------------------------------------------------

log "Generating SHA-256..."

sudo sha256sum "$BACKUP_FILE" | sudo tee "$CHECKSUM_FILE" > /dev/null

log "Checksum created:"
log "$CHECKSUM_FILE"

# --------------------------------------------------
# Verify checksum
# --------------------------------------------------

log "Verifying backup checksum..."

sudo sha256sum -c "$CHECKSUM_FILE"

log "Checksum verification successful."

# --------------------------------------------------
# Verify archive
# --------------------------------------------------

log "Verifying backup archive..."

if sudo tar -tzf "$BACKUP_FILE" > /dev/null; then
    log "Backup archive is valid."
else
    fail "Backup archive verification failed."
fi

# --------------------------------------------------
# Verify session.lock exclusion
# --------------------------------------------------

if sudo tar -tzf "$BACKUP_FILE" | grep -q 'session.lock'; then
    fail "session.lock found inside backup."
fi

log "session.lock exclusion verified."

# --------------------------------------------------
# Backup successful
# --------------------------------------------------

BACKUP_SUCCESS=true
write_backup_status "SUCCESS"

log "================================="
log "Backup completed successfully."
log "================================="

cleanup_old_backups
