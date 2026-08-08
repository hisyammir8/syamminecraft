#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/rcon.sh

get_latest_build() {

    curl -s \
        "https://fill.papermc.io/v3/projects/paper/versions/${MC_VERSION}" \
    | jq -r '.builds[0]'

}

get_download_url() {

    printf '%s' "$1" \
    | jq -r '.downloads["server:default"].url'

}

download_paper() {

    URL="$1"

    log_info "Downloading Paper ${MC_VERSION}"

    curl \
        --fail \
        --location \
        --silent \
        --show-error \
        "$URL" \
        -o "$PAPER_JAR"

}

needs_update() {

    LATEST_BUILD="$1"

    if [ ! -f "${VERSION_FILE}" ]; then
        return 0
    fi

    CURRENT=$(cat "${VERSION_FILE}")

    EXPECTED="${MC_VERSION}:${LATEST_BUILD}"

    [ "${CURRENT}" != "${EXPECTED}" ]

}


get_download_checksum() {

    printf '%s' "$1" \
    | jq -r '.downloads["server:default"].checksums.sha256'

}

get_download_name() {

    echo "$1" \
    | jq -r '.downloads["server:default"].name'

}

get_download_size() {

    echo "$1" \
    | jq -r '.downloads["server:default"].size'

}

verify_checksum() {

    FILE="$1"
    EXPECTED="$2"

    ACTUAL=$(sha256sum "$FILE" | awk '{print $1}')

    if [ "$EXPECTED" != "$ACTUAL" ]; then

        fail "Checksum verification failed."

    fi

    log_info "Checksum verified."

}

save_version() {

    LATEST_BUILD="$1"

    echo "${MC_VERSION}:${LATEST_BUILD}" > "$VERSION_FILE"

    log_info "Version file updated."

}

fetch_build_metadata() {

    LATEST_BUILD="$1"

    curl -s \
        "https://fill.papermc.io/v3/projects/paper/versions/${MC_VERSION}/builds/${LATEST_BUILD}"

}

save_world() {

    log_info "Saving world..."

    rcon_command "save-all"

}

stop_world() {

    log_info "Stopping server via RCON..."

    rcon_command "stop"

}