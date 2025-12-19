FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    opensc \
    procps \
    softhsm2 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/softhsm/tokens


# Entrada del contenedor
COPY k8s/init-token-if-empty.sh /usr/local/bin/init-token-if-empty.sh
RUN chmod +x /usr/local/bin/init-token-if-empty.sh

ENTRYPOINT [ "sh", "-c", "echo starting softhsm sidecar; tail -f /dev/null" ]