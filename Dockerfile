FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    opensc \
    softhsm2 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/softhsm/tokens

# Copiar script de inicialización
COPY k8s/init-token-if-empty.sh /usr/local/bin/init-token.sh
RUN chmod +x /usr/local/bin/init-token.sh

# Entrada del contenedor
COPY k8s/init-token-if-empty.sh /usr/local/bin/init-token-if-empty.sh
RUN chmod +x /usr/local/bin/init-token-if-empty.sh

ENTRYPOINT [ "sh", "-c", "echo starting softhsm sidecar; tail -f /dev/null" ]