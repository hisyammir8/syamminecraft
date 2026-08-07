FROM eclipse-temurin:21-jre

RUN apt-get update && \
    apt-get install -y curl jq && \
    rm -rf /var/lib/apt/lists/*

COPY docker/start.sh /usr/local/bin/start.sh
COPY scripts/ /usr/local/bin/scripts/

RUN chmod +x /usr/local/bin/start.sh && \
    chmod +x /usr/local/bin/scripts/*.sh

WORKDIR /data

EXPOSE 25565

ENTRYPOINT ["/bin/sh", "/usr/local/bin/start.sh"]