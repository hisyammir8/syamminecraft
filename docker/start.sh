#!/bin/sh

set -e

echo "================================="
echo "Minecraft Server Startup"
echo "================================="

mkdir -p /runtime
mkdir -p /data

#####################################
# Download Paper
#####################################

/bin/sh /usr/local/bin/scripts/download-paper.sh

#####################################
# Generate Metadata
#####################################

/bin/sh /usr/local/bin/scripts/metadata.sh

#####################################
# Accept EULA
#####################################

echo "eula=true" > /data/eula.txt

#####################################
# Start Server
#####################################

cd /data

exec java \
    -Xms${JAVA_XMS} \
    -Xmx${JAVA_XMX} \
    -jar /runtime/paper.jar \
    nogui