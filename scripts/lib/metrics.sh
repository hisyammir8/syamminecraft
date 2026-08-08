#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/process.sh
. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh

write_metric() {

    FILE="$1"
    CONTENT="$2"

    printf "%s\n" "$CONTENT" > "$FILE"

}
read_metric() {

    FILE="$1"

    cat "$FILE"

}

update_metric()

create_placeholder_metric() {

    FILE="$1"

    cat > "$FILE" <<EOF
{}
EOF

}

initialize_server_metrics() {

    [ -f "$SERVER_METRICS" ] && return

    atomic_write "$SERVER_METRICS" <<EOF
{
    "status": "unknown",
    "version": "",
    "motd": "",
    "onlinePlayers": 0,
    "maxPlayers": 0,
    "whitelist": false,
    "difficulty": "",
    "gamemode": "",
    "world": "",
    "lastUpdated": ""
}
EOF

}

initialize_system_metrics() {

    [ -f "$SYSTEM_METRICS" ] && return

    atomic_write "$SYSTEM_METRICS" <<EOF
{
    "cpuUsage": 0,
    "memoryUsedMB": 0,
    "memoryTotalMB": 0,
    "diskUsedMB": 0,
    "diskTotalMB": 0,
    "loadAverage": 0,
    "lastUpdated": ""
}
EOF

}

initialize_process_metrics() {

    [ -f "$PROCESS_METRICS" ] && return

    atomic_write "$PROCESS_METRICS" <<EOF
{
    "pid": 0,
    "running": false,
    "uptime": 0,
    "restartCount": 0,
    "exitCode": 0,
    "lastStarted": "",
    "lastStopped": "",
    "lastUpdated": ""
}
EOF

}

initialize_metrics() {

    initialize_server_metrics

    initialize_system_metrics

    initialize_process_metrics

}

collect_metrics() {

    collect_process_metrics

    collect_system_metrics

    collect_server_metrics

}

collect_server_metrics() {

    write_server_metrics

}

collect_system_metrics() {

  MEMORY_USED=$(get_memory_used_mb)
  MEMORY_TOTAL=$(get_memory_total_mb)
  DISK_USED=$(get_disk_used_mb)
  DISK_TOTAL=$(get_disk_total_mb)
  CPU_USAGE=$(get_cpu_usage)

  set -- $(get_load_average)

  LOAD_1="$1"
  LOAD_5="$2"
  LOAD_15="$3"

  # write_system_metrics

  write_system_metrics \
    "$MEMORY_USED" \
    "$MEMORY_TOTAL" \
    "$DISK_USED" \
    "$DISK_TOTAL" \
    "$CPU_USAGE" \
    "$LOAD_1" \
    "$LOAD_5" \
    "$LOAD_15"

}

write_server_metrics(){
  log_info "Writing server metrics..."
}

write_system_metrics() {

    memoryUsedMB="$1"
    memoryTotalMB="$2"
    diskUsedMB="$3"
    diskTotalMB="$4"
    cpuUsage="$5"
    load1="$6"
    load5="$7"
    load15="$8"

    atomic_write "$SYSTEM_METRICS" <<EOF
{
    "cpuUsage": $cpuUsage,
    "memoryUsedMB": $memoryUsedMB,
    "memoryTotalMB": $memoryTotalMB,
    "diskUsedMB": $diskUsedMB,
    "diskTotalMB": $diskTotalMB,
    "loadAverage":  {
        "1m": $load1,
        "5m": $load5,
        "15m": $load15
    },
    "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF


}

collect_process_metrics() {

    PID=$(get_server_pid)

    if is_server_running; then

        RUNNING=true

    else

        RUNNING=false

    fi

    write_process_metrics \
        "${PID:-0}" \
        "$RUNNING" \
        "$(get_server_uptime)"

}

write_process_metrics() {

    PID="$1"

    RUNNING="$2"

    UPTIME="$3"

    atomic_write "$PROCESS_METRICS" <<EOF
{
    "pid": $PID,
    "running": $RUNNING,
    "uptime": $UPTIME,
    "restartCount": $(get_restart_count),
    "exitCode": $(get_server_exit_code),
    "lastStarted": "$(format_unix_timestamp "$(get_server_started_time)")",
    "lastStopped": "",
    "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

}