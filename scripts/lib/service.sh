#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/process.sh
. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh


get_service_pid_file() {

    SERVICE_NAME="$1"

    echo "${SERVICES_DIR}/${SERVICE_NAME}.pid"

}

start_service() {

    SERVICE_NAME="$1"

    shift

    "$@" &

    PID=$!

    save_service_pid \
        "$SERVICE_NAME" \
        "$PID"

}

stop_service() {

    SERVICE_NAME="$1"

    PID=$(get_service_pid "$SERVICE_NAME") || return 0

    terminate_process "$PID"

    remove_service_pid "$SERVICE_NAME"

}

stop_runtime_services() {

    log_info "Stopping runtime services..."

    stop_service metrics

    # stop_service watchdog

    # stop_service backup

}

restart_service() {

    SERVICE_NAME="$1"

}

is_service_running() {

    SERVICE_NAME="$1"

    PID=$(get_service_pid "$SERVICE_NAME")

    [ -n "$PID" ] || return 1

    is_process_running "$PID"

}

save_service_pid() {

    SERVICE_NAME="$1"
    PID="$2"

    echo "$PID" > "$(get_service_pid_file "$SERVICE_NAME")"

}

get_service_pid() {

    SERVICE_NAME="$1"

    PID_FILE=$(get_service_pid_file "$SERVICE_NAME")

    [ -f "$PID_FILE" ] || return

    cat "$PID_FILE"

}

remove_service_pid() {

    SERVICE_NAME="$1"

    rm -f "$(get_service_pid_file "$SERVICE_NAME")"

}



wait_process_exit() {

    PID="$1"

}

wait_interval() {

    sleep "$1"

}