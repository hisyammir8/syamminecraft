#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh
. /usr/local/bin/scripts/lib/config.sh

main() {

    require_server_properties

    log_info "Configuring server.properties..."

    update_from_env "server-port" "SERVER_PORT"
    update_from_env "motd" "MOTD"
    update_from_env "max-players" "MAX_PLAYERS"
    update_from_env "difficulty" "DIFFICULTY"
    update_from_env "online-mode" "ONLINE_MODE"
    # update_from_env "enable-rcon" "ENABLE_RCON"
    # update_from_env "rcon.port" "RCON_PORT"
    # update_from_env "rcon.password" "RCON_PASSWORD"

    # configure_server

    configure_rcon

}
main "$@"