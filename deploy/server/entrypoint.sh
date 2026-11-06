#!/bin/sh
set -e
# La llave pública del pipeline llega montada en /authorized_keys (efímera por ejecución).
if [ -f /authorized_keys ]; then
  cp /authorized_keys /home/deploy/.ssh/authorized_keys
  chown deploy:deploy /home/deploy/.ssh/authorized_keys
  chmod 600 /home/deploy/.ssh/authorized_keys
fi
ssh-keygen -A >/dev/null
php-fpm -D
nginx
exec /usr/sbin/sshd -D -e
