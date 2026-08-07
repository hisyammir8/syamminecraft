#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh
. /usr/local/bin/scripts/lib/paper.sh

main() {

    log_info "Starting PaperMC download process..."

    require_env "MC_VERSION"

    ensure_directories

    LATEST_BUILD=$(get_latest_build)
    
    if [ -z "$LATEST_BUILD" ] || [ "$LATEST_BUILD" = "null" ]; then

        fail "Failed to retrieve latest Paper build."

    fi

    BUILD_METADATA=$(fetch_build_metadata "$LATEST_BUILD")


    # printf '%s\n' "$BUILD_METADATA" | jq .
    DOWNLOAD_URL=$(get_download_url "$BUILD_METADATA")
    # DOWNLOAD_URL=$(printf '%s\n' "$BUILD_METADATA" | jq -r '.downloads["server:default"].url')

    CHECKSUM=$(get_download_checksum "$BUILD_METADATA")
    # CHECKSUM=$(printf '%s\n' "$BUILD_METADATA" | jq -r '.downloads["server:default"].checksums.sha256')

    if needs_update "$LATEST_BUILD"; then

        download_paper "$DOWNLOAD_URL"
        verify_checksum \
            "$PAPER_JAR" \
            "$CHECKSUM"

        save_version "$LATEST_BUILD"

        log_info "PaperMC updated successfully."

    else

        log_info "PaperMC is already up to date."

    fi

}

main "$@"