#!/bin/sh

log_info() {

    echo "[INFO ] $(date '+%Y-%m-%d %H:%M:%S') $*"

}

log_warn() {

    echo "[WARN ] $(date '+%Y-%m-%d %H:%M:%S') $*"

}

log_error() {

    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*"

}