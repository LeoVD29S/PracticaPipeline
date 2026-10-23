$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

php artisan test --log-junit storage/logs/junit.xml
if (Test-Path "vendor\bin\phpstan") {
    vendor\bin\phpstan analyse --memory-limit=512M
}
Write-Host "Verificación concluida."
