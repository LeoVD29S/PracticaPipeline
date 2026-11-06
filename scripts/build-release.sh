#!/usr/bin/env bash
# Genera el artefacto de liberación de Arkana Cards.
# Uso: bash scripts/build-release.sh v1.0.0 [dist]
# Requisitos previos (los hace el workflow):
#   composer install --no-dev --optimize-autoloader
#   npm ci && npm run build
set -euo pipefail

VERSION="${1:?Indica la versión, ej. v1.0.0}"
OUT="${2:-dist}"
NAME="arkana-cards-${VERSION}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if ! echo "$VERSION" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.]+)?$'; then
  echo "ERROR: '$VERSION' no cumple SemVer (vMAYOR.MENOR.PARCHE)" >&2
  exit 1
fi
[ -f vendor/autoload.php ] || { echo "ERROR: falta vendor/ (composer install --no-dev)" >&2; exit 1; }
[ -f public/build/manifest.json ] || { echo "ERROR: faltan assets (npm run build)" >&2; exit 1; }
if [ -d vendor/phpunit ]; then
  echo "ERROR: vendor/ contiene dependencias de desarrollo; ejecuta composer install --no-dev" >&2
  exit 1
fi

mkdir -p "$OUT"
rm -f bootstrap/cache/*.php

# Metadatos de la versión: qué se liberó, de qué commit y con qué herramientas.
echo "$VERSION" > RELEASE_VERSION
COMMIT="${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo desconocido)}"
cat > RELEASE.json <<EOF
{
  "name": "arkana-cards",
  "version": "${VERSION}",
  "commit": "${COMMIT}",
  "built_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "run_id": "${GITHUB_RUN_ID:-local}",
  "php": "$(php -r 'echo PHP_VERSION;')",
  "laravel": "$(php -r 'require "vendor/autoload.php"; echo \Composer\InstalledVersions::getPrettyVersion("laravel/framework");')"
}
EOF

# Lista de exclusión: código de desarrollo, secretos y datos locales.
tar --exclude='./.git' \
    --exclude='./.github' \
    --exclude='./.env' \
    --exclude='./.env.backup' \
    --exclude='./.env.production' \
    --exclude='./.env.testing' \
    --exclude='./auth.json' \
    --exclude='./node_modules' \
    --exclude='./tests' \
    --exclude='./docs' \
    --exclude='./performance' \
    --exclude='./scripts' \
    --exclude="./${OUT}" \
    --exclude='./storage/logs/*' \
    --exclude='./storage/framework/cache/data/*' \
    --exclude='./storage/framework/sessions/*' \
    --exclude='./storage/framework/views/*' \
    --exclude='./storage/framework/testing' \
    --exclude='./storage/phpstan' \
    --exclude='./storage/pail' \
    --exclude='./storage/*.key' \
    --exclude='./database/*.sqlite' \
    --exclude='./resources/js' \
    --exclude='./resources/css' \
    --exclude='./phpunit.xml' \
    --exclude='./phpstan.neon' \
    --exclude='./.phpunit.cache' \
    --exclude='./.phpunit.result.cache' \
    --exclude='./package.json' \
    --exclude='./package-lock.json' \
    --exclude='./vite.config.js' \
    --exclude='./.editorconfig' \
    --exclude='./.gitattributes' \
    --exclude='./.gitignore' \
    --exclude='./README.md' \
    --transform "s,^\.,${NAME}," \
    -czf "${OUT}/${NAME}.tar.gz" .

rm -f RELEASE_VERSION RELEASE.json

( cd "$OUT" && sha256sum "${NAME}.tar.gz" > "${NAME}.tar.gz.sha256" )
tar -tzf "${OUT}/${NAME}.tar.gz" | sort > "${OUT}/${NAME}.files.txt"

SIZE=$(du -h "${OUT}/${NAME}.tar.gz" | cut -f1)
COUNT=$(grep -vc '/$' "${OUT}/${NAME}.files.txt" || true)
echo "Artefacto: ${OUT}/${NAME}.tar.gz (${SIZE}, ${COUNT} archivos)"
cat "${OUT}/${NAME}.tar.gz.sha256"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "### Artefacto generado"
    echo "| Campo | Valor |"
    echo "| --- | --- |"
    echo "| Archivo | \`${NAME}.tar.gz\` |"
    echo "| Tamaño | ${SIZE} |"
    echo "| Archivos | ${COUNT} |"
    echo "| SHA-256 | \`$(cut -d' ' -f1 "${OUT}/${NAME}.tar.gz.sha256")\` |"
    echo "| Commit | \`${COMMIT}\` |"
  } >> "$GITHUB_STEP_SUMMARY"
fi
