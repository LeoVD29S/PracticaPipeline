#!/usr/bin/env bash
# Aprovisiona un servidor Ubuntu 24.04 (VM de pruebas) como ambiente de preproducción.
# Ejecutar una sola vez con sudo. No se usa en producción.
set -euo pipefail

apt-get update
apt-get install -y software-properties-common curl unzip git nginx sqlite3
add-apt-repository -y ppa:ondrej/php
apt-get update
apt-get install -y php8.2-fpm php8.2-cli php8.2-sqlite3 php8.2-mbstring php8.2-xml \
  php8.2-bcmath php8.2-curl php8.2-zip php8.2-intl

# Composer 2 (para reinstalar dependencias si se cambia de plataforma)
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Usuario y estructura de despliegue
id -u arkana >/dev/null 2>&1 || useradd -m -s /bin/bash -G www-data arkana
mkdir -p /srv/arkana/{releases,shared/database}
chown -R arkana:www-data /srv/arkana
chmod -R 775 /srv/arkana/shared

# Sitio Nginx
cp "$(dirname "$0")/nginx-arkana.conf" /etc/nginx/sites-available/arkana-preprod
ln -sfn /etc/nginx/sites-available/arkana-preprod /etc/nginx/sites-enabled/arkana-preprod
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "Servidor listo. Instala una versión con:"
echo "  sudo -u arkana bash install-preprod.sh arkana-cards-vX.Y.Z.tar.gz /srv/arkana 8080"
