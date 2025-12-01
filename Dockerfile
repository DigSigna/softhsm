FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar SOLO lo necesario + herramientas de diagnóstico
RUN apt-get update && apt-get install -y \
    curl \
    opensc \
    softhsm2 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/softhsm/tokens \
    && chmod 755 /var/lib/softhsm/tokens

# Configuración básica
RUN echo "directories.tokendir = /var/lib/softhsm/tokens" > /etc/softhsm2.conf

# Comando simple que inicializa y mantiene vivo
CMD ["sh", "-c", "softhsm2-util --init-token --free --label digsigna-token --so-pin 5678 --pin 1234 && echo 'HSM Sidecar ready' && tail -f /dev/null"]
# # Configuración UNIFICADA en ubicación estándar
# RUN echo "directories.tokendir = /var/lib/softhsm/tokens" > /etc/softhsm2.conf && \
#     echo "objectstore.backend = file" >> /etc/softhsm2.conf && \
#     echo "log.level = INFO" >> /etc/softhsm2.conf

# # Script de inicialización del token
# COPY init-token.sh /usr/local/bin/
# RUN chmod +x /usr/local/bin/init-token.sh

# # Health check MEJORADO que verifica token operativo
# HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
#     CMD /usr/local/bin/init-token.sh healthcheck

# ENTRYPOINT ["/usr/local/bin/init-token.sh"]