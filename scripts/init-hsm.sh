#!/bin/bash
set -e

echo " Inicializando SoftHSMv2 - Sidecar Mode"

# Configurar variable de entorno para SoftHSM
export SOFTHSM2_CONF=/opt/softhsm/config/softhsm2.conf

# Crear configuración
mkdir -p /opt/softhsm/config
echo "directories.tokendir = /var/lib/softhsm/tokens" > $SOFTHSM2_CONF
echo "objectstore.backend = file" >> $SOFTHSM2_CONF
echo "log.level = INFO" >> $SOFTHSM2_CONF

# Asegurar directorio de tokens
mkdir -p /var/lib/softhsm/tokens

# Inicializar token
if ! softhsm2-util --show-slots | grep -q "Initialized.*yes"; then
    echo "Creando nuevo token..."
    softhsm2-util --init-token --free --label "digsigna-token" --pin 1234 --so-pin 5678
else
    echo "Token ya existe, reutilizando"
fi

echo "SoftHSMv2 inicializado correctamente"
echo "Slots disponibles:"
softhsm2-util --show-slots

# Mantener contenedor ejecutando
exec tail -f /dev/null

# mkdir -p /var/lib/softhsm/tokens

# # Configurar permisos
# chmod 755 /var/lib/softhsm/tokens

# # Verificar si el token ya existe
# if [ ! -f /var/lib/softhsm/tokens/token_initialized ]; then
#     echo " Creando nuevo token HSM..."
#     softhsm2-util --init-token --free \
#         --label "digsigna-token" \
#         --pin ${HSM_USER_PIN:-1234} \
#         --so-pin ${HSM_SO_PIN:-5678} \
#         && touch /var/lib/softhsm/tokens/token_initialized
#     echo " Token creado exitosamente"
# else
#     echo " Token ya inicializado, reutilizando"
# fi

# # Mostrar información de slots
# echo " Slots HSM disponibles:"
# softhsm2-util --show-slots

# echo " SoftHSMv2 listo en modo sidecar"
# echo " Directorio tokens: $(ls -la /var/lib/softhsm/tokens/)"

# # Mantener contenedor activo
# exec tail -f /dev/null