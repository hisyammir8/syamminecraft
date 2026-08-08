#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh
. /usr/local/bin/scripts/lib/metrics.sh

collect_metrics_once() {

    /bin/sh \
        /usr/local/bin/scripts/collect-metrics.sh

}

main() {

    log_info "Metrics service started."

    while true
    do
        if ! collect_metrics_once; then

          log_warn "Metrics collection failed."

        else
          log_info "Metrics collection completed."
        fi

        # sleep 30
        sleep "$METRICS_INTERVAL"

    done

}

main "$@"