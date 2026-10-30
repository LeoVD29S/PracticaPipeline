$ErrorActionPreference = "Stop"
Set-Location (Split-Path -Parent $PSScriptRoot)

New-Item -ItemType Directory -Force -Path "storage\logs" | Out-Null
php artisan test --log-junit storage/logs/junit.xml --testdox
$testsOk = ($LASTEXITCODE -eq 0)
$phpstanOk = $true
if (Test-Path "vendor\bin\phpstan") {
    vendor\bin\phpstan analyse --memory-limit=512M
    if ($LASTEXITCODE -ne 0) { $phpstanOk = $false }
}
$env:PHPSTAN_OUTCOME = if ($phpstanOk) { "success" } else { "failure" }
$env:TESTS_OUTCOME = if ($testsOk) { "success" } else { "failure" }
php scripts/ci-metrics.php storage/logs/junit.xml
Write-Host "Verificación concluida."
