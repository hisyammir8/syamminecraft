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

HEALTHCHECK \
    --interval=30s \
    --timeout=10s \
    --start-period=90s \
    --retries=3 \
    CMD ["/usr/local/bin/scripts/health-check.sh"]

ENTRYPOINT ["/bin/sh", "/usr/local/bin/start.sh"]