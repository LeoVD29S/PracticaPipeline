# Actividad 12 — Ambiente de preproducción de Arkana Cards

Alumno: **Villaseñor Dorantes, Leonardo** · IDGS 102 · UTVT

## Flujo de entrega continua

```
push tag vX.Y.Z / workflow_dispatch
  └─ ci              Checkout → Composer → npm build → PHPStan → PHPUnit (gate obligatorio)
      └─ build-release   composer --no-dev → npm build → build-release.sh → validate-artifact.sh → upload-artifact
          └─ deploy-preprod  download-artifact → sha256 → install-preprod.sh → prueba de humo
```

Workflow: `.github/workflows/release.yml`

## Versionado (SemVer)

| Cambio | Ejemplo | Cuándo |
| --- | --- | --- |
| PARCHE | v1.0.0 → v1.0.1 | Corrección sin cambiar el API |
| MENOR | v1.0.1 → v1.1.0 | Funcionalidad nueva compatible |
| MAYOR | v1.1.0 → v2.0.0 | Cambio incompatible en API o base de datos |
| Candidata | v1.0.0-rc.7 | Ejecución manual sin tag (`VERSION` + número de run) |

Se libera con:

```bash
git tag -a v1.0.0 -m "Arkana Cards v1.0.0"
git push origin v1.0.0
```

## Parámetros del ambiente

| Parámetro | Valor en preproducción |
| --- | --- |
| Sistema | Ubuntu 24.04 LTS (VM de pruebas o runner `ubuntu-latest`) |
| PHP | 8.2.x (mínimo 8.2.0, requerido por Laravel 12) |
| Extensiones PHP | pdo_sqlite, sqlite3, mbstring, openssl, tokenizer, xml, ctype, fileinfo, bcmath, curl |
| Composer | 2.x (solo si se reinstala; el artefacto ya trae `vendor/` sin dev) |
| Servidor web | Nginx + PHP-FPM 8.2 (`deploy/nginx-arkana.conf`); en el pipeline, servidor embebido de PHP en :8080 |
| Raíz web | `/srv/arkana/current/public` |
| Base de datos | SQLite independiente `/srv/arkana/shared/database/preprod.sqlite` |
| Variables | `/srv/arkana/shared/.env` desde `deploy/.env.preproduction.example`; `APP_ENV=staging`, `APP_DEBUG=false` |
| APP_KEY | Secreto `PREPROD_APP_KEY` del environment `preproduccion` o generada en el servidor; nunca en el artefacto |
| Permisos | `storage/` y `bootstrap/cache/` 775, propietario `arkana:www-data` |
| Releases | `/srv/arkana/releases/<versión>`; `current` es un enlace simbólico (rollback = re-apuntar) |
| Retención del artefacto | 7 días en GitHub Actions |

## Scripts

| Script | Uso |
| --- | --- |
| `scripts/build-release.sh v1.0.0 dist` | Empaqueta la versión (tar.gz + sha256 + lista de archivos) |
| `scripts/validate-artifact.sh dist/arkana-cards-v1.0.0.tar.gz` | Verifica archivos requeridos, ausencia de `.env`/credenciales/dev |
| `deploy/provision-preprod.sh` | Prepara una VM Ubuntu (PHP 8.2, Nginx, usuario, carpetas) |
| `deploy/install-preprod.sh <tar.gz> /srv/arkana 8080` | Instala, migra, cachea, activa y hace prueba de humo |
