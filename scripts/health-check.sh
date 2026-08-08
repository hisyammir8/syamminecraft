#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh
. /usr/local/bin/scripts/lib/process.sh

main() {

    if ! is_server_running; then

        log_error "Minecraft process is not running."

        exit 1

    fi

    if ! is_server_ready; then

        log_error "Minecraft server is not ready."

        exit 1

    fi

    log_info "Minecraft server is healthy."

    exit 0

}

main "$@"