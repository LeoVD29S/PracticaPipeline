#!/usr/bin/env bash
# Instala una versión de Arkana Cards en el ambiente de preproducción.
# Uso: bash install-preprod.sh arkana-cards-v1.0.0.tar.gz [/srv/arkana] [8080]
#
# Estructura que crea (despliegue por releases, permite volver atrás):
#   BASE/releases/<versión>/   código de la versión
#   BASE/shared/.env           variables de preproducción (no viajan en el artefacto)
#   BASE/shared/database/      base SQLite de preproducción
#   BASE/current -> releases/<versión>
set -euo pipefail

TARBALL="${1:?Indica el .tar.gz}"
BASE="${2:-/srv/arkana}"
PORT="${3:-8080}"
FILE="$(basename "$TARBALL")"
NAME="${FILE%.tar.gz}"
VERSION="${NAME#arkana-cards-}"
RELEASE="$BASE/releases/$VERSION"
SHARED="$BASE/shared"

step() { echo; echo "==> $*"; }
ok() { echo "    [OK] $*"; }

step "1. Requisitos del servidor"
PHPV=$(php -r 'echo PHP_VERSION;')
php -r 'exit(version_compare(PHP_VERSION, "8.2.0", ">=") ? 0 : 1);' || { echo "PHP $PHPV < 8.2" >&2; exit 1; }
ok "PHP $PHPV (>= 8.2)"
MISSING=""
for ext in pdo_sqlite mbstring openssl tokenizer xml ctype fileinfo bcmath; do
  php -m | grep -qi "^${ext}$" || MISSING="$MISSING $ext"
done
[ -z "$MISSING" ] || { echo "Faltan extensiones PHP:$MISSING" >&2; exit 1; }
ok "Extensiones: pdo_sqlite mbstring openssl tokenizer xml ctype fileinfo bcmath"

step "2. Descomprimir $FILE en $RELEASE"
rm -rf "$RELEASE"
mkdir -p "$RELEASE" "$SHARED/database"
tar -xzf "$TARBALL" -C "$RELEASE" --strip-components=1
ok "$(find "$RELEASE" -type f | wc -l) archivos · versión $(cat "$RELEASE/RELEASE_VERSION")"

step "3. Variables de entorno independientes (shared/.env)"
if [ ! -f "$SHARED/.env" ]; then
  cp "$RELEASE/deploy/.env.preproduction.example" "$SHARED/.env"
  sed -i "s#^DB_DATABASE=.*#DB_DATABASE=$SHARED/database/preprod.sqlite#" "$SHARED/.env"
  sed -i "s#^APP_URL=.*#APP_URL=http://127.0.0.1:$PORT#" "$SHARED/.env"
  if [ -n "${PREPROD_APP_KEY:-}" ]; then
    sed -i "s#^APP_KEY=.*#APP_KEY=${PREPROD_APP_KEY}#" "$SHARED/.env"
    ok "APP_KEY tomada del secreto PREPROD_APP_KEY"
  fi
  ok "shared/.env creado desde deploy/.env.preproduction.example"
else
  ok "shared/.env existente reutilizado"
fi
ln -sfn "$SHARED/.env" "$RELEASE/.env"
touch "$SHARED/database/preprod.sqlite"
cd "$RELEASE"
if ! grep -qE '^APP_KEY=base64:' .env; then
  php artisan key:generate --force --no-interaction >/dev/null
  ok "APP_KEY generada solo para preproducción (no se publica)"
fi
ok "APP_ENV=$(grep -E '^APP_ENV=' .env | cut -d= -f2) · APP_DEBUG=$(grep -E '^APP_DEBUG=' .env | cut -d= -f2)"

step "4. Permisos de storage/ y bootstrap/cache/"
mkdir -p storage/logs storage/framework/{cache/data,sessions,views} bootstrap/cache
chmod -R ug+rwX,o-w storage bootstrap/cache
find storage bootstrap/cache -type d -exec chmod 775 {} +
ok "storage $(stat -c '%a' storage) · bootstrap/cache $(stat -c '%a' bootstrap/cache)"

step "5. Preparar la aplicación"
php artisan migrate --force --no-interaction
php artisan config:cache
php artisan route:cache
php artisan view:cache
ok "migraciones aplicadas y caches de config/rutas/vistas generadas"

step "6. Activar la versión (current -> $VERSION)"
ln -sfn "$RELEASE" "$BASE/current"
ok "$(readlink "$BASE/current")"

step "7. Prueba de humo en http://127.0.0.1:$PORT"
# server.php de Laravel toma getcwd() como raíz pública: se arranca dentro de public/
( cd "$BASE/current/public" && exec php -S "127.0.0.1:$PORT" ../vendor/laravel/framework/src/Illuminate/Foundation/resources/server.php ) \
  > "$BASE/server.log" 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null || true' EXIT
for _ in $(seq 1 20); do curl -fs "http://127.0.0.1:$PORT/up" >/dev/null 2>&1 && break; sleep 0.5; done

FAILS=0
ROWS=""
probe() { # probe METODO RUTA ESPERADO [DATOS]
  local code
  if [ "$1" = "POST" ]; then
    code=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d "$4" "http://127.0.0.1:$PORT$2")
  else
    code=$(curl -s -o /dev/null -w '%{http_code}' -H 'Accept: application/json' "http://127.0.0.1:$PORT$2")
  fi
  if [ "$code" = "$3" ]; then echo "    [OK]    $1 $2 -> $code"; ROWS+="| ✅ | $1 \`$2\` | $3 | $code |"$'\n'
  else echo "    [FALLA] $1 $2 -> $code (esperado $3)"; ROWS+="| ❌ | $1 \`$2\` | $3 | $code |"$'\n'; FAILS=$((FAILS + 1)); fi
}
probe GET /up 200
probe GET / 200
probe GET /cartas 200
probe GET /api/cards 200
probe POST /api/cards 201 '{"name":"Dragon de Preproduccion","rarity":"legendary","attack":9,"defense":7,"nfc_uid":"04A1B2C3D4E5F6"}'
probe GET /cartas/1 200
probe POST /api/decks/validate 200 '{"card_ids":[1]}'
probe POST /api/decks/validate 422 '{"card_ids":[999]}'
probe GET /no-existe 404

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Entrega en preproducción — \`$VERSION\`"
    echo "PHP $PHPV · APP_ENV=staging · current → releases/$VERSION"
    echo
    echo "| Estado | Petición | Esperado | Obtenido |"
    echo "| --- | --- | --- | --- |"
    printf "%s" "$ROWS"
  } >> "$GITHUB_STEP_SUMMARY"
fi

if [ "$FAILS" -ne 0 ]; then
  echo; echo "Prueba de humo con $FAILS fallas. Log del servidor:"; tail -n 30 "$BASE/server.log"
  tail -n 30 "$RELEASE/storage/logs/"*.log 2>/dev/null || true
  exit 1
fi
echo; echo "Versión $VERSION instalada y verificada en preproducción."
