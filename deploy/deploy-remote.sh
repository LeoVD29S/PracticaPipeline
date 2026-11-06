#!/usr/bin/env bash
# Script de despliegue en el SERVIDOR DE PRUEBAS (se ejecuta por SSH como usuario deploy).
# Adaptación del script de referencia de la actividad: directorios por versión,
# respaldo de la base de datos, cambio atómico de la versión activa y reversión automática.
# Uso: bash deploy-remote.sh /tmp/arkana-cards-v1.0.2.tar.gz v1.0.2
set -euo pipefail
umask 002   # php-fpm (grupo www-data) debe poder escribir logs y la base

TARBALL="${1:?Ruta del artefacto}"
VERSION="${2:?Versión}"
BASE="${APP_BASE:-/var/www/arkana}"
RELEASE="$BASE/releases/$VERSION"
SHARED="$BASE/shared"
KEEP=3
TS="$(date -u +%Y%m%d%H%M%S)"
PREVIOUS="$(readlink -f "$BASE/current" 2>/dev/null || true)"

step() { echo; echo "==> [$(date -u +%H:%M:%S)] $*"; }

rollback() {
  echo "!! Falla en el despliegue de $VERSION"
  if [ -n "$PREVIOUS" ] && [ -d "$PREVIOUS" ]; then
    ln -sfn "$PREVIOUS" "$BASE/current.tmp" && mv -Tf "$BASE/current.tmp" "$BASE/current"
    sudo /usr/bin/pkill -USR2 -o php-fpm || true
    sudo /usr/sbin/nginx -s reload || true
    echo "!! Reversión: current -> $(basename "$PREVIOUS")"
  else
    echo "!! No hay versión anterior para revertir"
  fi
  exit 1
}

step "1. Transferencia recibida: $(basename "$TARBALL") ($(du -h "$TARBALL" | cut -f1))"
mkdir -p "$BASE/releases" "$SHARED/database" "$BASE/backups"
rm -rf "$RELEASE"
mkdir -p "$RELEASE"
tar -xzf "$TARBALL" -C "$RELEASE" --strip-components=1
echo "    versión del paquete: $(cat "$RELEASE/RELEASE_VERSION")"

step "2. Variables de entorno (shared/.env, fuera del artefacto)"
if [ ! -f "$SHARED/.env" ]; then
  cp "$RELEASE/deploy/.env.preproduction.example" "$SHARED/.env"
  sed -i "s#^APP_NAME=.*#APP_NAME=\"Arkana Cards (Pruebas)\"#; s#^APP_ENV=.*#APP_ENV=testing-server#; s#^APP_URL=.*#APP_URL=${APP_URL:-http://localhost}#; s#^DB_DATABASE=.*#DB_DATABASE=$SHARED/database/arkana.sqlite#" "$SHARED/.env"
  echo "    shared/.env creado"
fi
ln -sfn "$SHARED/.env" "$RELEASE/.env"
touch "$SHARED/database/arkana.sqlite"
chmod 664 "$SHARED/database/arkana.sqlite"
cd "$RELEASE"
if [ -n "${APP_KEY_SECRET:-}" ]; then
  sed -i "s#^APP_KEY=.*#APP_KEY=${APP_KEY_SECRET}#" "$SHARED/.env"; echo "    APP_KEY desde secreto"
elif ! grep -qE '^APP_KEY=base64:' "$SHARED/.env"; then
  php artisan key:generate --force --no-interaction >/dev/null; echo "    APP_KEY generada en el servidor"
fi

step "3. Dependencias de producción"
composer install --no-dev --optimize-autoloader --no-interaction --no-progress 2>&1 | tail -n 3
php -r 'exit(version_compare(PHP_VERSION,"8.2.0",">=")?0:1);'
echo "    PHP $(php -r 'echo PHP_VERSION;') · vendor sin dev: $(grep -q '"dev": false' vendor/composer/installed.json && echo sí || echo no)"

step "4. Respaldo de base de datos y migraciones"
if [ -s "$SHARED/database/arkana.sqlite" ]; then
  cp "$SHARED/database/arkana.sqlite" "$BASE/backups/arkana-$TS.sqlite"
  echo "    respaldo: backups/arkana-$TS.sqlite"
else
  echo "    base vacía, sin respaldo"
fi
php artisan migrate --force --no-interaction || rollback

step "5. Permisos y cachés"
chmod -R ug+rwX storage bootstrap/cache
find storage bootstrap/cache -type d -exec chmod 2775 {} +
php artisan optimize:clear
php artisan config:cache
php artisan route:cache
php artisan view:cache

step "6. Activar versión (cambio atómico de current)"
ln -sfn "$RELEASE" "$BASE/current.tmp"
mv -Tf "$BASE/current.tmp" "$BASE/current"
echo "    current -> releases/$VERSION (anterior: ${PREVIOUS:+$(basename "$PREVIOUS")})"

step "7. Recargar servicios"
sudo /usr/sbin/nginx -t 2>&1 | tail -n 1
sudo /usr/bin/pkill -USR2 -o php-fpm
sudo /usr/sbin/nginx -s reload
echo "    php-fpm y nginx recargados"

step "8. Verificación local"
ok=0
for _ in $(seq 1 15); do
  code=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1/up || true)
  [ "$code" = "200" ] && { ok=1; break; }
  sleep 1
done
[ "$ok" = "1" ] || rollback
if [ -n "${FORCE_FAIL:-}" ]; then
  echo "    FORCE_FAIL activo: se simula una falla de verificación"; rollback
fi
echo "    GET /up -> 200"
php artisan about --only=environment

step "9. Limpieza (se conservan $KEEP versiones)"
ls -1dt "$BASE"/releases/*/ | tail -n +$((KEEP + 1)) | xargs -r rm -rf
ls -1 "$BASE/releases"
echo
echo "DEPLOY_OK $VERSION"
