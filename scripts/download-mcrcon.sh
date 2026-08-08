#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh
. /usr/local/bin/scripts/lib/paper.sh
. /usr/local/bin/scripts/lib/rcon.sh

main() {

    log_info "Starting mcrcon download..."

    ensure_directories

    mkdir -p "$BIN_DIR"

    if needs_update; then

        # ARCH=$(get_runtime_architecture)
        URL=$(get_download_url "$ARCH")
        install_binary "$URL"

        chmod +x "$MCRCON_BIN"

        verify_binary

        save_version

    else

        log_info "mcrcon already up to date."

    fi

}
main "$@"