#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh
. /usr/local/bin/scripts/lib/process.sh
. /usr/local/bin/scripts/lib/service.sh

echo "================================="
echo "Minecraft Server Startup"
echo "================================="

start_runtime_services() {

    start_service \
        metrics \
        sh \
        /usr/local/bin/scripts/metrics-service.sh

}

handle_shutdown_signal() {

    log_info "Shutdown signal received."

    cleanup

    exit 0

}

main() {

    log_info "================================="
    log_info "Minecraft Server Startup"
    log_info "================================="

    ensure_directories

    # /usr/local/bin/scripts/download-paper.sh

    # /usr/local/bin/scripts/metadata.sh

    /bin/sh /usr/local/bin/scripts/download-paper.sh

    /bin/sh /usr/local/bin/scripts/download-mcrcon.sh #PENDING

    /bin/sh /usr/local/bin/scripts/metadata.sh

    /bin/sh /usr/local/bin/scripts/initialize-metrics.sh

    /bin/sh /usr/local/bin/scripts/configure-server.sh

    # trap handle_shutdown_signal TERM INT

    register_signal_handlers

    if bootstrap_required; then

        bootstrap_server

    fi
    
    echo "eula=true" > "${DATA_DIR}/eula.txt"

    # register_signal_handlers

    start_server

    wait_for_server
    
    cleanup

}

main "$@"

# mkdir -p /runtime
# mkdir -p /data

# #####################################
# # Download Paper
# #####################################

# /bin/sh /usr/local/bin/scripts/download-paper.sh

# #####################################
# # Generate Metadata
# #####################################

# /bin/sh /usr/local/bin/scripts/metadata.sh

# #####################################
# # Accept EULA
# #####################################

# echo "eula=true" > /data/eula.txt

# #####################################
# # Start Server
# #####################################

# cd /data

# exec java \
#     -Xms${JAVA_XMS} \
#     -Xmx${JAVA_XMX} \
#     -jar /runtime/paper.jar \
#     nogui