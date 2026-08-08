#!/bin/sh

set -e

#########################################
# Directory
#########################################

RUNTIME_DIR="/runtime"
DATA_DIR="/data"

PAPER_JAR="${RUNTIME_DIR}/paper.jar"
VERSION_FILE="${RUNTIME_DIR}/version.txt"
METADATA_FILE="${RUNTIME_DIR}/metadata.json"

SERVER_STDIN="${RUNTIME_DIR}/minecraft.stdin"
SERVER_PID_FILE="${RUNTIME_DIR}/minecraft.pid"

SERVER_PROPERTIES="${DATA_DIR}/server.properties"

READY_PATTERN="Done ("

STARTUP_TIMEOUT="${STARTUP_TIMEOUT:-180}"

#########################################
# RCON
#########################################

RCON_HOST="127.0.0.1"
RCON_PORT="${RCON_PORT:-25575}"
RCON_PASSWORD="${RCON_PASSWORD}"

#########################################
# Health Check
#########################################

SERVER_LOG="${DATA_DIR}/logs/latest.log"
SERVER_READY_PATTERN="Done ("
LOG_POLL_INTERVAL=1
DEFAULT_TIMEOUT=180

#########################################
# Runtime State
#########################################

SERVER_STATE_FILE="${RUNTIME_DIR}/server.state"
STATE_BOOTSTRAPPING="BOOTSTRAPPING"

STATE_STARTING="STARTING"

STATE_RUNNING="RUNNING"

STATE_STOPPING="STOPPING"

STATE_STOPPED="STOPPED"

#########################################
# Runtime Binary
#########################################

BIN_DIR="${RUNTIME_DIR}/bin"

MCRCON_BIN="${BIN_DIR}/mcrcon"

MCRCON_VERSION="0.7.2"

MCRCON_BASE_URL="https://github.com/Tiiffi/mcrcon/releases/download"
#########################################
# Runtime Dependency Version
#########################################

PAPER_VERSION_FILE="${RUNTIME_DIR}/paper.version"

MCRCON_VERSION_FILE="${RUNTIME_DIR}/mcrcon.version"

#########################################
# Metrics
#########################################

METRICS_DIR="${RUNTIME_DIR}/metrics"

SERVER_METRICS="${METRICS_DIR}/server.json"

SYSTEM_METRICS="${METRICS_DIR}/system.json"

PROCESS_METRICS="${METRICS_DIR}/process.json"

#########################################
# Process Runtime Files
#########################################

SERVER_STARTED_FILE="${RUNTIME_DIR}/server.started"

SERVER_EXIT_CODE_FILE="${RUNTIME_DIR}/server.exitcode"

SERVER_RESTART_COUNT_FILE="${RUNTIME_DIR}/server.restart"

CACHE_DIR="${RUNTIME_DIR}/cache"

CPU_SNAPSHOT_FILE="${CACHE_DIR}/cpu.snapshot"

#########################################
# Services
#########################################

SERVICES_DIR="${RUNTIME_DIR}/services"

METRICS_INTERVAL="${METRICS_INTERVAL:-30}"

#########################################
# Helper
#########################################

require_env() {

    VAR="$1"

    VALUE=$(printenv "$VAR")

    if [ -z "$VALUE" ]; then

        log_error "$VAR is not defined."

        exit 1

    fi

}
ensure_directories() {

    mkdir -p "$RUNTIME_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$METRICS_DIR"
    mkdir -p "$CACHE_DIR"
    mkdir -p "$SERVICES_DIR"
}

fail() {

    log_error "$1"

    exit 1

}

save_server_pid() {

    echo "$1" > "$SERVER_PID_FILE"

}

get_server_pid() {

    [ -f "$SERVER_PID_FILE" ] || return 1

    cat "$SERVER_PID_FILE"

}

# get_server_uptime() {

#     STARTED=$(get_server_started_time)

#     if [ -z "$STARTED" ]; then
#         echo 0
#         return
#     fi

#     NOW=$(date +%s)

#     echo $((NOW - STARTED))

# } #MOVED TO process.sh

remove_server_pid() {

    rm -f "$SERVER_PID_FILE"

}

set_server_state() {

    STATE="$1"

    echo "$STATE" > "$SERVER_STATE_FILE"

}

get_server_state() {

    [ -f "$SERVER_STATE_FILE" ] || return 1

    cat "$SERVER_STATE_FILE"

}

clear_server_state() {

    rm -f "$SERVER_STATE_FILE"

}

is_server_state() {

    EXPECTED="$1"

    CURRENT=$(get_server_state 2>/dev/null) || return 1

    [ "$CURRENT" = "$EXPECTED" ]

}

atomic_write() {

    FILE="$1"

    TMP_FILE="${FILE}.tmp"

    cat > "$TMP_FILE"

    mv "$TMP_FILE" "$FILE"

}