rcon_execute() {

    COMMAND="$1"

    execute_rcon_provider "$COMMAND"

}

execute_rcon_provider() {

    fail "Not implemented."

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

    "$MCRCON_BIN" --help >/dev/null 2>&1 \
        || fail "Unable to execute mcrcon."

    log_info "mcrcon binary verified."

}

install_binary() {

    # URL="$1"

    # log_info "Downloading mcrcon..."

    # curl \
    #     --fail \
    #     --location \
    #     --silent \
    #     --show-error \
    #     "$URL" \
    #     -o "$MCRCON_BIN"

    ARCH=$(get_runtime_architecture)

    case "$ARCH" in

        amd64)

            install_prebuilt_binary

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

    fail "Not implemented."

}

install_compiled_binary() {

    fail "Not implemented."

}

get_download_url() {

    ARCH="$1"

    echo "https://...."

}