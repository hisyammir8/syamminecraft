#!/bin/sh

set -e

#########################################
# Constants
#########################################

PAPER_DIR="/runtime"
PAPER_JAR="${PAPER_DIR}/paper.jar"
VERSION_FILE="${PAPER_DIR}/version.txt"

#########################################
# Functions
#########################################

get_latest_build() {

    curl -s \
        "https://fill.papermc.io/v3/projects/paper/versions/${MC_VERSION}" \
    | jq -r '.builds[0]'

}

get_download_url() {

    BUILD="$1"

    curl -s \
        "https://fill.papermc.io/v3/projects/paper/versions/${MC_VERSION}/builds/${BUILD}" \
    | jq -r '.downloads["server:default"].url'

}

download_paper() {

    BUILD="$1"

    URL=$(get_download_url "$BUILD")

    echo "Downloading Paper ${MC_VERSION} (Build ${BUILD})"

    curl \
        --fail \
        --location \
        --silent \
        --show-error \
        "$URL" \
        -o "$PAPER_JAR"

}

validate_jar() {

    if ! jar tf "$PAPER_JAR" >/dev/null 2>&1; then

        echo "Downloaded file is not a valid JAR."

        rm -f "$PAPER_JAR"

        exit 1

    fi

}

needs_update() {

    BUILD="$1"

    if [ ! -f "${VERSION_FILE}" ]; then
        return 0
    fi

    CURRENT=$(cat "${VERSION_FILE}")

    EXPECTED="${MC_VERSION}:${BUILD}"

    [ "${CURRENT}" != "${EXPECTED}" ]

}

get_download_sha256() {

    BUILD="$1"

    curl -s \
        "https://fill.papermc.io/v3/projects/paper/versions/${MC_VERSION}/builds/${BUILD}" \
    | jq -r '.downloads["server:default"].checksums.sha256'

}

verify_checksum() {

    BUILD="$1"

    EXPECTED=$(get_download_sha256 "$BUILD")

    ACTUAL=$(sha256sum "$PAPER_JAR" | awk '{print $1}')

    if [ "$EXPECTED" != "$ACTUAL" ]; then

        echo "Checksum verification failed."

        echo "Expected : $EXPECTED"
        echo "Actual   : $ACTUAL"

        rm -f "$PAPER_JAR"

        exit 1

    fi

    echo "Checksum verified."

}

save_version() {

    BUILD="$1"

    echo "${MC_VERSION}:${BUILD}" > "${VERSION_FILE}"

}

#########################################
# Main
#########################################

main() {

    mkdir -p "$PAPER_DIR"

    BUILD=$(get_latest_build)

    if needs_update "$BUILD"; then

        download_paper "$BUILD"

        verify_checksum "$BUILD"

        save_version "$BUILD"

    else

        echo "PaperMC already up to date."

    fi

}

main "$@"