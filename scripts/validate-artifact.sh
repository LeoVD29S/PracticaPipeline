#!/usr/bin/env bash
# Valida un artefacto de liberación descargado de GitHub Actions.
# Uso: bash scripts/validate-artifact.sh arkana-cards-v1.0.0.tar.gz [reporte.md]
# Sale con código 1 si alguna verificación falla.
set -uo pipefail

TARBALL="${1:?Indica la ruta del .tar.gz}"
REPORT="${2:-validation-report.md}"
[ -f "$TARBALL" ] || { echo "ERROR: no existe $TARBALL" >&2; exit 1; }

FILE="$(basename "$TARBALL")"
NAME="${FILE%.tar.gz}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
ROWS=""

check() { # check "<descripción>" <0|1> "<detalle>"
  local desc="$1" ok="$2" detail="${3:-}"
  if [ "$ok" -eq 0 ]; then
    PASS=$((PASS + 1)); ROWS+="| ✅ | ${desc} | ${detail} |"$'\n'; echo "[OK]    ${desc} ${detail}"
  else
    FAIL=$((FAIL + 1)); ROWS+="| ❌ | ${desc} | ${detail} |"$'\n'; echo "[FALLA] ${desc} ${detail}"
  fi
}

# 1. Integridad
if [ -f "${TARBALL}.sha256" ]; then
  ( cd "$(dirname "$TARBALL")" && sha256sum -c "${FILE}.sha256" >/dev/null 2>&1 )
  check "Integridad SHA-256" $? "$(cut -c1-16 "${TARBALL}.sha256")…"
else
  check "Integridad SHA-256" 1 "no se encontró ${FILE}.sha256"
fi

tar -xzf "$TARBALL" -C "$WORK" 2>/dev/null
check "El paquete se descomprime" $? "$FILE"
APP="$WORK/$NAME"
[ -d "$APP" ]; check "Carpeta raíz con la versión" $? "$NAME/"

# 2. Archivos necesarios para ejecutarse en otro entorno
REQUIRED=(
  artisan composer.json composer.lock .env.example RELEASE.json RELEASE_VERSION
  app/Models/Card.php app/Services/DeckRules.php app/Http/Controllers/CardController.php
  bootstrap/app.php bootstrap/providers.php config/app.php config/database.php
  database/migrations routes/web.php routes/api.php resources/views
  public/index.php public/.htaccess public/build/manifest.json
  vendor/autoload.php vendor/laravel/framework
  storage/framework bootstrap/cache
  deploy/install-preprod.sh deploy/.env.preproduction.example deploy/nginx-arkana.conf
)
MISSING=()
for f in "${REQUIRED[@]}"; do [ -e "$APP/$f" ] || MISSING+=("$f"); done
[ ${#MISSING[@]} -eq 0 ]; check "Archivos necesarios presentes (${#REQUIRED[@]})" $? "${MISSING[*]:-todos}"

# 3. Archivos que NO deben viajar
FORBIDDEN=(.env .env.backup .env.production .env.testing auth.json .git .github node_modules tests
           phpunit.xml phpstan.neon database/database.sqlite vendor/phpunit vendor/phpstan vendor/mockery
           vendor/fakerphp vendor/laravel/sail vendor/laravel/pail)
FOUND=()
for f in "${FORBIDDEN[@]}"; do [ -e "$APP/$f" ] && FOUND+=("$f"); done
[ ${#FOUND[@]} -eq 0 ]; check "Sin .env, .git, tests ni dependencias dev" $? "${FOUND[*]:-ninguno}"

LOGS=$(find "$APP/storage/logs" -type f -name '*.log' 2>/dev/null | wc -l)
SQLITE=$(find "$APP" -path "$APP/vendor" -prune -o -type f -name '*.sqlite' -print | wc -l)
[ "$LOGS" -eq 0 ] && [ "$SQLITE" -eq 0 ]; check "Sin logs ni bases de datos locales" $? "logs=${LOGS}, sqlite=${SQLITE}"

# 4. Búsqueda de credenciales en el código propio (vendor se excluye: son paquetes públicos)
SECRETS=$(grep -rIlE 'APP_KEY=base64:|-----BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|^DB_PASSWORD=[^[:space:]]+' \
  "$APP" --exclude-dir=vendor 2>/dev/null | sed "s#^$APP/##" | tr '\n' ' ' || true)
SECRETS="${SECRETS% }"
[ -z "$SECRETS" ]; check "Sin credenciales ni llaves en el paquete" $? "${SECRETS:-0 coincidencias}"

APPKEY=$(grep -E '^APP_KEY=' "$APP/.env.example" 2>/dev/null | cut -d= -f2-)
[ -z "$APPKEY" ]; check ".env.example sin APP_KEY real" $? "APP_KEY='${APPKEY}'"

# 5. Versión y dependencias de producción
V=$(cat "$APP/RELEASE_VERSION" 2>/dev/null)
[ "$V" = "${NAME#arkana-cards-}" ]; check "RELEASE_VERSION coincide con el nombre" $? "$V"
grep -q '"dev": false' "$APP/vendor/composer/installed.json" 2>/dev/null
check "vendor instalado con --no-dev" $? "installed.json dev=false"

if command -v php >/dev/null 2>&1; then
  php -l "$APP/public/index.php" >/dev/null 2>&1; check "Sintaxis PHP de public/index.php" $? "php -l"
fi

SIZE=$(du -h "$TARBALL" | cut -f1)
TOTAL=$((PASS + FAIL))
{
  echo "## Validación del artefacto \`${FILE}\`"
  echo
  echo "Tamaño: ${SIZE} · Verificaciones: ${PASS}/${TOTAL} aprobadas"
  echo
  echo "| Estado | Verificación | Detalle |"
  echo "| --- | --- | --- |"
  printf "%s" "$ROWS"
} > "$REPORT"
[ -n "${GITHUB_STEP_SUMMARY:-}" ] && cat "$REPORT" >> "$GITHUB_STEP_SUMMARY"

echo "Resultado: ${PASS}/${TOTAL} verificaciones aprobadas. Reporte: ${REPORT}"
[ "$FAIL" -eq 0 ]
