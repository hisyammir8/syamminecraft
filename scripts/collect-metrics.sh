#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh
. /usr/local/bin/scripts/lib/metrics.sh

main() {

    log_info "Collecting metrics..."

    collect_metrics

    log_info "Metrics collected."

}

main "$@"