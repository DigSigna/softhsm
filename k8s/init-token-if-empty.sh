#!/bin/sh
set -e

TOKEN_DIR="/var/lib/softhsm/tokens"
TOKEN_LABEL="${TOKEN_LABEL:-digsigna-token}"
USER_PIN="${USER_PIN:-1234}"
SO_PIN="${SO_PIN:-5678}"

# Forzar config montado
export SOFTHSM2_CONF=${SOFTHSM2_CONF:-/etc/softhsm2.conf}

# Esperar que el mount aparezca (evita race)
RETRIES=10
while [ $RETRIES -gt 0 ] && [ ! -d "$TOKEN_DIR" ]; do
  echo "Waiting for token dir $TOKEN_DIR to be available..."
  sleep 1
  RETRIES=$((RETRIES-1))
done


# Si ya hay algo en el dir --> nada que hacer
if [ "$(ls -A "$TOKEN_DIR" 2>/dev/null | wc -l)" -gt 0 ]; then
  echo "Tokens detected in $TOKEN_DIR — skipping initialization."
  exit 0
fi

SLOTS=$(softhsm2-util --show-slots 2>/dev/null || true)

if echo "$SLOTS" | grep -q "$TOKEN_LABEL"; then
  echo "Token label $TOKEN_LABEL detected via softhsm2-util — skipping."
  exit 0
fi

echo "Initializing SoftHSM token with label: $TOKEN_LABEL"
softhsm2-util --init-token --free --label "$TOKEN_LABEL" --pin "$USER_PIN" --so-pin "$SO_PIN"

echo "Token initialized successfully."
