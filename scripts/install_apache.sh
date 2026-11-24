#!/bin/bash

# Comprobamos si Apache ya está instalado
if dpkg -s apache2; then
    echo "Apache ya está instalado."
    exit 0
else
    echo "Apache no está instalado. Se procederá a instalarlo."
fi

# Actualizamos la lista de paquetes
sudo apt update

# Instalamos Apache sin intervencion del usuario
sudo DEBIAN_FRONTEND=noninteractive apt install -y apache2

# Habilitamos Apache para que arranque automaticamente
sudo systemctl enable apache2

# Iniciamos el servicio Apache
sudo systemctl start apache2

# Mostramos un mensaje de confirmacion
echo "Apache se ha instalado correctamente."
