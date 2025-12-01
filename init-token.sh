#!/bin/bash
set -e

TOKEN_DIR="/var/lib/softhsm/tokens"
TOKEN_LABEL="digsigna-token"
USER_PIN="1234"
SO_PIN="5678"

healthcheck() {
    # Verificar que el token existe y es accesible
    if pkcs11-tool --module /usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so --list-token-slots | grep -q "$TOKEN_LABEL"; then
        echo "Token $TOKEN_LABEL está operativo"
        exit 0
    else
        echo "Token $TOKEN_LABEL no encontrado"
        exit 1
    fi
}

initialize_token() {
    # Verificar si el token ya existe
    if pkcs11-tool --module /usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so --list-token-slots | grep -q "$TOKEN_LABEL"; then
        echo "Token $TOKEN_LABEL ya existe, omitiendo inicialización"
        return 0
    fi

    echo "Inicializando token $TOKEN_LABEL..."
    
    # Crear directorio de tokens
    mkdir -p $TOKEN_DIR
    
    # Inicializar token
    softhsm2-util --init-token --free --label "$TOKEN_LABEL" --so-pin "$SO_PIN" --pin "$USER_PIN"
    
    echo "Token $TOKEN_LABEL inicializado exitosamente"
}

case "${1}" in
    "healthcheck")
        healthcheck
        ;;
    "init")
        initialize_token
        exec tail -f /dev/null
        ;;
    *)
        initialize_token
        echo "Sidecar SoftHSM listo - manteniendo contenedor activo"
        exec tail -f /dev/null
        ;;
esac