#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/communication.sh
. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh

SERVER_PID=""

#########################################
# Lifecycle
#########################################

start_server() {

    log_info "Starting Minecraft server..."

    # start_java_server
    start_minecraft_server

}

start_minecraft_server() {

    set_server_state "$STATE_STARTING"

    log_info "Starting Minecraft server..."

    log_info "Step 1"
    start_java_server

    log_info "Step 2"
    wait_until_server_ready

    log_info "Step 3"
    save_server_pid "$SERVER_PID"

    save_server_started_time
    log_info "Step 4"
    set_server_state "$STATE_RUNNING"

    log_info "Step 5"
    start_runtime_services

    log_info "Step 6"
    wait_process_exit "$SERVER_PID"
    log_info "Step 7"
}

start_java_server() {

    log_info "Starting Java process..."

    cd "$DATA_DIR"

    java \
        -Xms"$JAVA_XMS" \
        -Xmx"$JAVA_XMX" \
        -jar "$PAPER_JAR" \
        nogui &

    SERVER_PID=$!

    # echo "$SERVER_PID" > "$SERVER_PID_FILE"
    save_server_pid "$SERVER_PID"

    log_info "Java PID: $SERVER_PID"

}

stop_server() {

    log_info "Stopping Minecraft server..."

    stop_server_command

}

wait_process_exit() {

    PID="$1"

    wait "$PID"

}

register_signal_handlers() {

    # trap shutdown_server TERM INT
    trap shutdown_handler TERM INT

}

#########################################
# Waiting Utilities
#########################################

wait_for_server() {

    SERVER_PID=$(get_server_pid) || return

    wait "$SERVER_PID"

}

wait_until_server_ready() {

    log_info "Waiting for Minecraft server..."

    # SECONDS_WAITED=0

    # until is_server_ready
    # do

    #     sleep 1

    #     SECONDS_WAITED=$((SECONDS_WAITED+1))

    #     if [ "$SECONDS_WAITED" -ge "$STARTUP_TIMEOUT" ]; then

    #         fail "Server startup timeout."

    #     fi

    # done
    wait_for_log_pattern \
        "$SERVER_LOG" \
        "$SERVER_READY_PATTERN" \
        "$DEFAULT_TIMEOUT"

    log_info "Minecraft server is ready."
    
}

wait_for_log_pattern() {

    FILE="$1"
    PATTERN="$2"
    TIMEOUT="$3"

    log_info "Waiting for log pattern: $PATTERN"

    ELAPSED=0

    while true
    do

        # if [ -f "$FILE" ] && grep -Fq "$PATTERN" "$FILE"; then

        #     return 0

        # fi

        if log_contains "$FILE" "$PATTERN"; then
            return 0
        fi

        # sleep 1
        sleep "$LOG_POLL_INTERVAL"

        # ELAPSED=$((ELAPSED + 1))
        ELAPSED=$((ELAPSED + LOG_POLL_INTERVAL))

        if [ "$ELAPSED" -ge "$TIMEOUT" ]; then

            fail "Timeout waiting for log pattern: $PATTERN"

        fi

    done

}

#########################################
# Log Utilities
#########################################

log_contains() {

    FILE="$1"
    PATTERN="$2"

    [ -f "$FILE" ] || return 1

    grep -Fq "$PATTERN" "$FILE"

}

#########################################
# Cleanup
#########################################

cleanup() {

    # rm -f "$SERVER_STDIN"
    # rm -f "$SERVER_PID_FILE"
    log_info "Cleaning runtime..."

    remove_server_pid
    set_server_state "$STATE_STOPPED"
    # clear_server_state

}

#########################################


bootstrap_required() {

    [ ! -f "$SERVER_PROPERTIES" ]

}


bootstrap_server() {

    log_info "First startup detected."

    log_info "Generating default Paper configuration..."

    log_info "Bootstrap required."

    # start_java_server
    start_minecraft_server #DONE

    
    wait_until_bootstrap_ready

    stop_bootstrap_server

    verify_bootstrap

    set_server_state "$STATE_BOOTSTRAPPING"
}


verify_bootstrap() {

    [ -f "$SERVER_PROPERTIES" ] \
        || fail "Bootstrap failed."

    log_info "Bootstrap completed."

}

wait_until_bootstrap_ready() {

    log_info "Waiting for Paper to generate default files..."

}



stop_bootstrap_server() {

    log_info "Stopping bootstrap server..."

}



verify_bootstrap() {

    [ -f "$SERVER_PROPERTIES" ] \
        || fail "Bootstrap failed. server.properties not found."

    log_info "Bootstrap completed."

}

is_server_ready() {

    [ -f "$SERVER_LOG" ] || return 1

    grep -q "$READY_PATTERN" "$SERVER_LOG"

}

shutdown_handler() {

    log_warn "Shutdown signal received."

    stop_server

    cleanup

    exit 0

}

is_server_running() {

    PID=$(get_server_pid) || return 1

    kill -0 "$PID" 2>/dev/null

}

is_server_ready() {

    log_contains \
        "$SERVER_LOG" \
        "$SERVER_READY_PATTERN"

}

request_shutdown() {

    set_server_state "$STATE_STOPPING"
    stop_server

}

wait_for_shutdown() {

    PID=$(get_server_pid) || return

    wait "$PID"

}

is_shutdown_requested() {

    [ ! -f "$SERVER_PID_FILE" ]

}

save_server_started_time() {

    date +%s > "$SERVER_STARTED_FILE"

}

get_server_started_time() {

    [ -f "$SERVER_STARTED_FILE" ] || return

    cat "$SERVER_STARTED_FILE"

}

get_server_uptime() {

    STARTED=$(get_server_started_time)

    [ -n "$STARTED" ] || {
        echo 0
        return
    }

    NOW=$(date +%s)

    echo $((NOW - STARTED))

}

save_server_exit_code() {

    EXIT_CODE="$1"

    echo "$EXIT_CODE" > "$SERVER_EXIT_CODE_FILE"

}

get_server_exit_code() {

    [ -f "$SERVER_EXIT_CODE_FILE" ] || {
        echo 0
        return
    }

    cat "$SERVER_EXIT_CODE_FILE"

}

increment_restart_count() {

    CURRENT=$(get_restart_count)

    echo $((CURRENT + 1)) > "$SERVER_RESTART_COUNT_FILE"

}

get_restart_count() {

    [ -f "$SERVER_RESTART_COUNT_FILE" ] || {
        echo 0
        return
    }

    cat "$SERVER_RESTART_COUNT_FILE"

}

format_unix_timestamp() {

    TIMESTAMP="$1"

    [ -n "$TIMESTAMP" ] || {
        echo ""
        return
    }

    date -u -d "@$TIMESTAMP" +"%Y-%m-%dT%H:%M:%SZ"

}

get_memory_used_mb() {

    TOTAL=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)

    AVAILABLE=$(awk '/MemAvailable/ { print $2 }' /proc/meminfo)

    echo $(((TOTAL - AVAILABLE) / 1024))

}

get_memory_total_mb() {

    awk '/MemTotal/ { print int($2 / 1024) }' /proc/meminfo

}

get_disk_total_mb() {

    df -Pm "$DATA_DIR" \
    | awk 'NR==2 { print $2 }'

}

get_disk_used_mb() {

    df -Pm "$DATA_DIR" \
    | awk 'NR==2 { print $3 }'

}

read_cpu_snapshot() {

    [ -f "$CPU_SNAPSHOT_FILE" ] || return 1

    cat "$CPU_SNAPSHOT_FILE"

}

save_cpu_snapshot() {

    TOTAL="$1"
    IDLE="$2"

    cat > "$CPU_SNAPSHOT_FILE" <<EOF
$TOTAL
$IDLE
EOF

}

get_cpu_usage() {

    CURRENT=$(read_cpu_stat)

    CURRENT_TOTAL=$(echo "$CURRENT" | awk '{print $1}')
    CURRENT_IDLE=$(echo "$CURRENT" | awk '{print $2}')

    if [ ! -f "$CPU_SNAPSHOT_FILE" ]; then

        save_cpu_snapshot \
            "$CURRENT_TOTAL" \
            "$CURRENT_IDLE"

        echo "0.0"

        return

    fi

    PREVIOUS_TOTAL=$(sed -n '1p' "$CPU_SNAPSHOT_FILE")
    PREVIOUS_IDLE=$(sed -n '2p' "$CPU_SNAPSHOT_FILE")

    TOTAL_DIFF=$((CURRENT_TOTAL - PREVIOUS_TOTAL))
    IDLE_DIFF=$((CURRENT_IDLE - PREVIOUS_IDLE))

    save_cpu_snapshot \
        "$CURRENT_TOTAL" \
        "$CURRENT_IDLE"

    if [ "$TOTAL_DIFF" -eq 0 ]; then

        echo "0.0"

        return

    fi

    awk \
        -v total="$TOTAL_DIFF" \
        -v idle="$IDLE_DIFF" \
        'BEGIN {
            printf "%.2f", (100 * (total - idle) / total)
        }'

}

read_cpu_stat() {

    awk '/^cpu / {
        total = 0

        for (i = 2; i <= NF; i++) {
            total += $i
        }

        idle = $5 + $6

        print total, idle
    }' /proc/stat

}

get_load_average() {

    awk '
    {
        printf "%s %s %s", $1, $2, $3
    }
    ' /proc/loadavg

}