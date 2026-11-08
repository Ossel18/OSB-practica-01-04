#!/bin/bash

# Detenemos el script si se produce algun error
set -e

# Comprobamos que se ejecuta como administrador
if [ "$(id -u)" -ne 0 ]; then
    echo "Ejecuta el script con sudo."
    exit 1
fi

# Comprobamos que Apache esta instalado
if ! dpkg -s apache2 >/dev/null 2>&1; then
    echo "Apache no esta instalado."
    echo "Ejecuta antes install_apache.sh."
    exit 1
fi

# Obtenemos la carpeta principal del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Comprobamos que existe el archivo .env
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo "No se encuentra scripts/.env"
    exit 1
fi

# Cargamos las variables del archivo .env
source "$SCRIPT_DIR/.env"

# Comprobamos que las variables necesarias tienen valor
for VAR in COUNTRY STATE CITY ORGANIZATION ORGANIZATIONAL_UNIT COMMON_NAME EMAIL DOMAIN ELASTIC_IP DAYS KEY_PATH CERT_PATH
do
    if [ -z "${!VAR:-}" ]; then
        echo "Falta la variable $VAR en el archivo .env"
        exit 1
    fi
done

# Comprobamos que existen las carpetas de configuracion
if [ ! -f "$PROJECT_DIR/conf/000-default.conf" ] || [ ! -f "$PROJECT_DIR/conf/practica-https-ssl.conf" ]; then
    echo "No se encuentran los archivos de configuracion en conf/."
    exit 1
fi

# Creamos las carpetas necesarias para los certificados
mkdir -p "$(dirname "$KEY_PATH")"
mkdir -p "$(dirname "$CERT_PATH")"

# Generamos la clave privada y el certificado autofirmado
openssl req -x509 -nodes -days "$DAYS" -newkey rsa:2048 \
    -keyout "$KEY_PATH" \
    -out "$CERT_PATH" \
    -subj "/C=$COUNTRY/ST=$STATE/L=$CITY/O=$ORGANIZATION/OU=$ORGANIZATIONAL_UNIT/CN=$COMMON_NAME/emailAddress=$EMAIL" \
    -addext "subjectAltName=DNS:$DOMAIN,IP:$ELASTIC_IP"

# Protegemos la clave privada
chmod 600 "$KEY_PATH"

# Copiamos las configuraciones sustituyendo las variables
sed "s|DOMAIN_PLACEHOLDER|$DOMAIN|g" \
    "$PROJECT_DIR/conf/000-default.conf" \
    > /etc/apache2/sites-available/000-default.conf

sed -e "s|DOMAIN_PLACEHOLDER|$DOMAIN|g" \
    -e "s|CERT_PATH_PLACEHOLDER|$CERT_PATH|g" \
    -e "s|KEY_PATH_PLACEHOLDER|$KEY_PATH|g" \
    "$PROJECT_DIR/conf/practica-https-ssl.conf" \
    > /etc/apache2/sites-available/practica-https-ssl.conf

# Activamos los modulos SSL y Rewrite
a2enmod ssl rewrite

# Activamos el sitio HTTPS
a2ensite practica-https-ssl.conf

# Comprobamos la configuracion de Apache
apache2ctl configtest

# Si la configuracion es correcta, reiniciamos Apache
systemctl enable apache2
systemctl restart apache2

echo "Certificado autofirmado configurado correctamente."
echo "Apache esta funcionando con HTTPS."
