#!/bin/bash
set -e
TOKEN_DIR="/var/lib/softhsm/tokens"
TOKEN_LABEL="${TOKEN_LABEL:-digsigna-token}"
USER_PIN="${USER_PIN:-1234}"
SO_PIN="${SO_PIN:-5678}"

# Forzar que SoftHSM use el config montado
export SOFTHSM2_CONF=${SOFTHSM2_CONF:-/etc/softhsm2.conf}

# Crear token dir si no existe y asegurar permisos
mkdir -p "$TOKEN_DIR"
chmod 700 "$TOKEN_DIR"

# Si existe cualquier carpeta dentro de TOKEN_DIR, asumimos tokens ya presentes -> no inicializar
if [ "$(ls -A "$TOKEN_DIR" 2>/dev/null | wc -l)" -gt 0 ]; then
  echo "Tokens existentes detectados en $TOKEN_DIR, omitiendo inicialización."
else
  echo "No se encontraron tokens en $TOKEN_DIR. Inicializando nuevo token..."
  softhsm2-util --init-token --free --label "$TOKEN_LABEL" --pin "$USER_PIN" --so-pin "$SO_PIN"
  echo "Token inicializado."
fi

# Mantener contenedor
exec tail -f /dev/null
