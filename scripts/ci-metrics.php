<?php

/**
 * Lee el JUnit del pipeline y publica métricas en GitHub Step Summary.
 * Porcentaje aprobado = (pruebas aprobadas / total ejecutadas) * 100
 */

$junit = $argv[1] ?? 'storage/logs/junit.xml';
$outMd = getenv('GITHUB_STEP_SUMMARY') ?: 'storage/logs/metrics.md';
$outJson = 'storage/logs/metrics.json';

$total = 0;
$passed = 0;
$failed = 0;
$skipped = 0;
$errors = 0;
$time = 0.0;

if (is_file($junit)) {
    $xml = @simplexml_load_file($junit);
    if ($xml !== false) {
        $suite = $xml;
        if ($xml->getName() === 'testsuites' && isset($xml->testsuite[0])) {
            $suite = $xml->testsuite[0];
        }
        $total = (int) ($suite['tests'] ?? 0);
        $failed = (int) ($suite['failures'] ?? 0);
        $errors = (int) ($suite['errors'] ?? 0);
        $skipped = (int) ($suite['skipped'] ?? 0);
        $time = (float) ($suite['time'] ?? 0);
    }
}

$passed = max(0, $total - $failed - $errors - $skipped);
$percent = $total > 0 ? round(($passed / $total) * 100, 2) : 0.0;
$phpstan = getenv('PHPSTAN_OUTCOME') ?: 'unknown';
$testsOutcome = getenv('TESTS_OUTCOME') ?: 'unknown';
$gate = ($phpstan === 'success' && $testsOutcome === 'success') ? 'APROBADO' : 'RECHAZADO';

$metrics = [
    'total' => $total,
    'passed' => $passed,
    'failed' => $failed + $errors,
    'skipped' => $skipped,
    'percent' => $percent,
    'duration_seconds' => round($time, 3),
    'phpstan' => $phpstan,
    'tests' => $testsOutcome,
    'gate' => $gate,
    'formula' => 'Porcentaje aprobado = (Pruebas aprobadas / Total de pruebas ejecutadas) x 100',
];

@mkdir(dirname($outJson), 0777, true);
file_put_contents($outJson, json_encode($metrics, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

$md = <<<MD
## Resultados del CI Pipeline — Arkana Cards

| Indicador | Valor |
| --- | --- |
| Total de pruebas ejecutadas | {$metrics['total']} |
| Pruebas aprobadas | {$metrics['passed']} |
| Pruebas fallidas | {$metrics['failed']} |
| Pruebas omitidas | {$metrics['skipped']} |
| **Porcentaje aprobado** | **{$metrics['percent']}%** |
| Duración de la suite (s) | {$metrics['duration_seconds']} |
| PHPStan | {$phpstan} |
| PHPUnit | {$testsOutcome} |
| Criterio de integración | **{$gate}** |

Fórmula: `Porcentaje aprobado = (Pruebas aprobadas / Total de pruebas ejecutadas) × 100`

Este porcentaje no es cobertura de código; mide cuántas pruebas de la suite pasaron en esta ejecución.

MD;

file_put_contents($outMd, $md, FILE_APPEND);
echo $md;

if ($gate !== 'APROBADO') {
    fwrite(STDERR, "Quality gate RECHAZADO (PHPStan={$phpstan}, tests={$testsOutcome}).\n");
    exit(1);
}
