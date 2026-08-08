#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh


is_rcon_enabled() {

    [ "$ENABLE_RCON" = "true" ]

}

is_rcon_available() {

    rcon_command "list" >/dev/null 2>&1

}

build_rcon_arguments() {

    echo \
        -H "$RCON_HOST" \
        -P "$RCON_PORT" \
        -p "$RCON_PASSWORD"

}

# execute_rcon() {

#     "$MCRCON_BIN" "$@"

#     return $?

# }

rcon_command() {

    COMMAND="$1"

    rcon_execute \
        "$COMMAND"

}

rcon_execute() {

    COMMAND="$1"

    execute_rcon_provider \
        $(build_rcon_arguments) \
        "$COMMAND"

}

execute_rcon_provider() {

    # fail "Not implemented."
    "$MCRCON_BIN" "$@"

}

get_runtime_architecture() {

    case "$(uname -m)" in

        x86_64)

            echo "amd64"

            ;;

        aarch64|arm64)

            echo "arm64"

            ;;

        *)

            fail "Unsupported architecture."

            ;;

    esac

}

needs_update() {

    if [ ! -f "$MCRCON_VERSION_FILE" ]; then
        return 0
    fi

    CURRENT=$(cat "$MCRCON_VERSION_FILE")

    [ "$CURRENT" != "$MCRCON_VERSION" ]

}

save_version() {

    echo "$MCRCON_VERSION" > "$MCRCON_VERSION_FILE"

}

verify_binary() {

    [ -f "$MCRCON_BIN" ] \
        || fail "mcrcon binary not found."

    [ -x "$MCRCON_BIN" ] \
        || fail "mcrcon binary is not executable."

    if ! "$MCRCON_BIN" -h >/dev/null; then
        fail "Unable to execute mcrcon."
    fi

    log_info "mcrcon binary verified."

}

install_binary() {

    ARCH="$1"

    case "$ARCH" in
        amd64)
            install_prebuilt_binary "$ARCH"
            ;;
        arm64)
            install_compiled_binary
            ;;
        *)
            fail "Unsupported architecture."
            ;;
    esac

}

install_prebuilt_binary() {

    ARCH="$1"

    URL=$(get_download_url "$ARCH")

    download_archive "$URL"

    extract_archive

    install_binary_file

}

install_compiled_binary() {

    fail \
        "Compiling mcrcon is not implemented yet."

}

get_download_url() {

    ARCH="$1"

    case "$ARCH" in
        amd64)
            echo "https://github.com/Tiiffi/mcrcon/releases/download/v0.7.2/mcrcon-0.7.2-linux-x86-64-static.zip"
            ;;
        *)
            return 1
            ;;
    esac

}

download_archive() {

    URL="$1"

    log_info "Downloading mcrcon..."

    curl \
        --fail \
        --location \
        --silent \
        --show-error \
        "$URL" \
        -o "$CACHE_DIR/mcrcon.zip"

}

extract_archive() {

    log_info "Extracting mcrcon..."

    unzip \
        -o \
        "$CACHE_DIR/mcrcon.zip" \
        -d "$CACHE_DIR"

}

install_binary_file() {

    log_info "Installing mcrcon..."

    BINARY_PATH=$(
        find "$CACHE_DIR" \
            -type f \
            -name mcrcon \
            | head -n 1
    )

    [ -n "$BINARY_PATH" ] \
        || fail "mcrcon binary not found."

    mv \
        "$BINARY_PATH" \
        "$MCRCON_BIN"

}

cleanup_archive() {

    rm -f \
        "$CACHE_DIR/mcrcon.zip"

}