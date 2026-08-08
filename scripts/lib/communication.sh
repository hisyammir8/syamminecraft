#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh

send_command() {

    COMMAND="$1"

    rcon_execute "$COMMAND"

    log_info "Sending command: $COMMAND"

}

stop_server_command() {

    send_command "stop"

}

save_world() {

    send_command "save-all"

}


disable_auto_save() {

    send_command "save-off"

}

enable_auto_save() {

    send_command "save-on"

}

broadcast_message() {

    MESSAGE="$1"

    send_command "say $MESSAGE"

}

list_players() {

    send_command "list"

}