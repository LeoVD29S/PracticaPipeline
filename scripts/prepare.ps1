$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

composer install --prefer-dist --no-interaction
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
}
php artisan key:generate
if (-not (Test-Path "database\database.sqlite")) {
    New-Item "database\database.sqlite" -ItemType File | Out-Null
}
php artisan migrate --force
npm install
npm run build
Write-Host "Entorno preparado."
