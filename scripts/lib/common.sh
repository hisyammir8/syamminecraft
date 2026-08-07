#!/bin/sh

set -e

#########################################
# Directory
#########################################

RUNTIME_DIR="/runtime"
DATA_DIR="/data"

PAPER_JAR="${RUNTIME_DIR}/paper.jar"
VERSION_FILE="${RUNTIME_DIR}/version.txt"
METADATA_FILE="${RUNTIME_DIR}/metadata.json"

#########################################
# Helper
#########################################

require_env() {

    VAR="$1"

    VALUE=$(printenv "$VAR")

    if [ -z "$VALUE" ]; then

        log_error "$VAR is not defined."

        exit 1

    fi

}
ensure_directories() {

    mkdir -p "$RUNTIME_DIR"
    mkdir -p "$DATA_DIR"

}

fail() {

    log_error "$1"

    exit 1

}