FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    opensc \
    procps \
    softhsm2 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/softhsm/tokens && \
    useradd -u 1000 -g softhsm -m -s /sbin/nologin softhsm 2>/dev/null || true && \
    chown -R softhsm:softhsm /var/lib/softhsm

COPY k8s/init-token-if-empty.sh /usr/local/bin/init-token-if-empty.sh
RUN chmod +x /usr/local/bin/init-token-if-empty.sh

USER softhsm

ENTRYPOINT [ "sh", "-c", "echo starting softhsm sidecar; tail -f /dev/null" ]