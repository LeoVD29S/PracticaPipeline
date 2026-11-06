# Servidor de PRUEBAS de Arkana Cards: Debian + PHP-FPM 8.2 + Nginx + OpenSSH.
# Simula el host de destino al que el pipeline se conecta por SSH. No es producción.
FROM php:8.2-fpm-bookworm

RUN apt-get update \
 && apt-get install -y --no-install-recommends nginx openssh-server sqlite3 curl unzip procps sudo \
 && docker-php-ext-install bcmath opcache \
 && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Usuario de despliegue: solo llave pública, sin contraseña, sin root.
RUN useradd -m -s /bin/bash -G www-data deploy \
 && mkdir -p /home/deploy/.ssh /var/www/arkana/releases /var/www/arkana/shared/database /var/www/arkana/backups \
 && chown -R deploy:www-data /var/www/arkana && chmod -R 2775 /var/www/arkana \
 && chmod 700 /home/deploy/.ssh && chown deploy:deploy /home/deploy/.ssh \
 && echo 'deploy ALL=(root) NOPASSWD: /usr/sbin/nginx -t, /usr/sbin/nginx -s reload, /usr/bin/pkill -USR2 -o php-fpm' > /etc/sudoers.d/deploy \
 && chmod 440 /etc/sudoers.d/deploy \
 && sed -ri 's/^#?PasswordAuthentication .*/PasswordAuthentication no/; s/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config \
 && mkdir -p /run/sshd

COPY nginx-site.conf /etc/nginx/sites-available/default
COPY php-fpm-pool.conf /usr/local/etc/php-fpm.d/zz-arkana.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 80
ENTRYPOINT ["/entrypoint.sh"]
