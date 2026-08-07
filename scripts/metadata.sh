#!/bin/sh

set -e

#########################################
# Constants
#########################################

METADATA_FILE="/runtime/metadata.json"

#########################################
# Main
#########################################

mkdir -p /runtime

cat > "${METADATA_FILE}" << EOF
{
    "serverName": "${SERVER_NAME}",
    "minecraftVersion": "${MC_VERSION}",
    "javaVersion": "21",
    "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF

echo "Metadata generated."