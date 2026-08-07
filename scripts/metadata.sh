#!/bin/sh

set -e

. /usr/local/bin/scripts/lib/log.sh
. /usr/local/bin/scripts/lib/common.sh

#########################################
# Constants
#########################################

METADATA_FILE="/runtime/metadata.json"

#########################################
# Main
#########################################
require_env "SERVER_NAME"
require_env "MC_VERSION"

# mkdir -p /runtime
ensure_directories

cat > "${METADATA_FILE}" << EOF
{
    "serverName": "${SERVER_NAME}",
    "minecraftVersion": "${MC_VERSION}",
    "javaVersion": "21",
    "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

log_info "Metadata generated."