#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh
. /usr/local/bin/scripts/lib/metrics.sh

main() {

    log_info "Initializing metrics..."

    ensure_directories

    initialize_metrics

    log_info "Metrics initialized."

}

main "$@"