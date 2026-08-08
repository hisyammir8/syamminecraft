update_property() {

    KEY="$1"
    VALUE="$2"

    if grep -q "^${KEY}=" "$SERVER_PROPERTIES"; then

        sed -i "s|^${KEY}=.*|${KEY}=${VALUE}|" "$SERVER_PROPERTIES"

    else

        echo "${KEY}=${VALUE}" >> "$SERVER_PROPERTIES"

    fi

}

require_server_properties() {

    if [ ! -f "$SERVER_PROPERTIES" ]; then

        fail "server.properties not found."

    fi

}

update_from_env() {

    PROPERTY="$1"

    ENV_NAME="$2"

    VALUE=$(printenv "$ENV_NAME")

    [ -z "$VALUE" ] && return

    update_property "$PROPERTY" "$VALUE"

}