# Arkana Cards — CI Pipeline

Repositorio: https://github.com/LeoVD29S/PracticaPipeline

Módulo web en **Laravel 12 / PHP 8.2** para el catálogo digital de cartas del proyecto **Arkana**. Este repositorio resuelve la Actividad 08 (selección de pruebas y herramientas) y la Actividad 09 (diseño y configuración del CI Pipeline).

Alumno: **Villaseñor Dorantes, Leonardo** · Grupo **IDGS 102** · UTVT

## Qué hace la aplicación

- Publica el catálogo de cartas coleccionables.
- Registra la identidad NFC de cada carta física.
- Expone un API REST para listar cartas y validar mazos.
- Aplica reglas de negocio: máximo 8 cartas y 2 legendarias por mazo.

## Stack

| Elemento | Tecnología |
| --- | --- |
| Lenguaje | PHP 8.2 |
| Framework | Laravel 12 |
| Arquitectura | MVC + API REST |
| Base de datos | SQLite (local y CI) |
| Pruebas | PHPUnit (`php artisan test`) |
| Análisis estático | PHPStan |
| Frontend | Vite + npm |
| CI | GitHub Actions |

## Flujo del pipeline (imagen de referencia)

El workflow `.github/workflows/ci.yml` sigue el flujo pedido:

1. **Checkout** — obtener el código fuente.
2. **Preparación** — configurar PHP y dependencias (`composer`, `npm`).
3. **Build** — construir o verificar la aplicación (`key:generate`, `npm run build`).
4. **Test** — ejecutar pruebas automatizadas y PHPStan.
5. **Resultados** — publicar estado, artefactos JUnit y logs.

Eventos que lo disparan: `push` y `pull_request` hacia `main`.

El pipeline **aprueba** si PHPStan y `php artisan test` terminan en verde. **Rechaza** el cambio si falla cualquier etapa; el merge no debe realizarse hasta corregir el error.

## Preparar el entorno (local)

```bash
composer install
copy .env.example .env
php artisan key:generate
php artisan migrate --force
npm install
npm run build
```

En PowerShell también puede usarse:

```powershell
.\scripts\prepare.ps1
```

## Verificar el entorno y las pruebas

```bash
php artisan test
vendor\bin\phpstan analyse --memory-limit=512M
```

```powershell
.\scripts\verify.ps1
```

Pruebas de rendimiento (opcional, requiere la app en `http://127.0.0.1:8000` y k6 instalado):

```bash
php artisan serve
k6 run performance/cards-load.js
```

## Herramientas seleccionadas (Actividad 08)

| Tipo de prueba | Herramienta | ¿Va en el CI? |
| --- | --- | --- |
| Unitarias | PHPUnit | Sí |
| Análisis estático | PHPStan | Sí |
| Aceptación | PHPUnit Feature | Sí |
| Integración | PHPUnit + SQLite | Sí |
| Regresión | misma suite en cada push | Sí |
| Rendimiento | k6 | No en cada push (se corre bajo demanda) |
| Esfuerzo | estimación de horas de mantenimiento | No es una prueba ejecutable |

## Evidencias

Las capturas y reportes de las actividades 08 y 09 están en `docs/`.
