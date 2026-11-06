#!/usr/bin/env bash
# Validación posterior al despliegue + métricas básicas de rendimiento y disponibilidad.
# Uso: bash deploy/post-deploy-check.sh http://127.0.0.1:8081 "<comando ssh>" [salida_dir]
set -uo pipefail

URL="${1:?URL del ambiente}"
SSH="${2:?comando ssh al servidor}"
OUT="${3:-post-deploy}"
mkdir -p "$OUT"
FAILS=0
ROWS=""

row() { ROWS+="| $1 | $2 | $3 |"$'\n'; echo "[$1] $2 — $3"; [ "$1" = "❌" ] && FAILS=$((FAILS + 1)); return 0; }

# ---------- Parte 3. Validación posterior
if curl --fail --silent --show-error -o /dev/null "$URL/"; then row ✅ "Servidor web responde (curl --fail $URL/)" "200"; else row ❌ "Servidor web responde" "sin respuesta"; fi
c=$(curl -s -o /dev/null -w '%{http_code}' "$URL/up"); [ "$c" = 200 ] && row ✅ "Ruta de salud /up" "$c" || row ❌ "Ruta de salud /up" "$c"
c=$(curl -s -o /dev/null -w '%{http_code}' "$URL/cartas"); [ "$c" = 200 ] && row ✅ "Ruta principal /cartas" "$c" || row ❌ "Ruta principal /cartas" "$c"
SERVER=$(curl -sI "$URL/" | tr -d '\r' | awk -F': ' 'tolower($1)=="server"{print $2}')
row ✅ "Servidor que atiende" "${SERVER:-desconocido}"

UID_HEX=$(printf '%014X' "$(( $(date +%s) * 1000 + RANDOM ))" | tail -c 14)
BODY=$(curl -s -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' \
  -d "{\"name\":\"Fénix de Pruebas\",\"rarity\":\"epic\",\"attack\":8,\"defense\":6,\"nfc_uid\":\"$UID_HEX\"}" \
  -w '\n%{http_code}' "$URL/api/cards")
CODE=$(echo "$BODY" | tail -n1)
ID=$(echo "$BODY" | head -n1 | sed -n 's/.*"id":\([0-9]*\).*/\1/p')
[ "$CODE" = 201 ] && row ✅ "Funcionalidad: alta de carta por API" "201 · id=$ID" || row ❌ "Funcionalidad: alta de carta por API" "$CODE"
c=$(curl -s -o /dev/null -w '%{http_code}' "$URL/cartas/$ID"); [ "$c" = 200 ] && row ✅ "Funcionalidad: ficha de la carta creada" "$c" || row ❌ "Funcionalidad: ficha /cartas/$ID" "$c"
c=$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d "{\"card_ids\":[$ID]}" "$URL/api/decks/validate")
[ "$c" = 200 ] && row ✅ "Funcionalidad: validar mazo" "$c" || row ❌ "Funcionalidad: validar mazo" "$c"

DB=$($SSH "cd /var/www/arkana/current && php artisan migrate:status --no-ansi | grep -c Ran; php artisan tinker --execute='echo \"cartas=\".App\\Models\\Card::count();'" 2>&1 | tr '\n' ' ')
echo "$DB" | grep -q 'cartas=' && row ✅ "Conexión a base de datos" "migraciones Ran=$(echo "$DB" | awk '{print $1}') · $(echo "$DB" | grep -o 'cartas=[0-9]*')" || row ❌ "Conexión a base de datos" "$DB"

$SSH "tail -n 200 /var/www/arkana/current/storage/logs/*.log 2>/dev/null" > "$OUT/laravel.log" || true
ERRS=$(grep -cE '\.(ERROR|CRITICAL|EMERGENCY|ALERT):' "$OUT/laravel.log" || true)
[ "$ERRS" -eq 0 ] && row ✅ "Logs de Laravel sin errores" "0 entradas ERROR/CRITICAL" || row ❌ "Logs de Laravel" "$ERRS errores"

# ---------- Parte 4. Métricas
# Disponibilidad: 60 sondeos a /up, uno cada 0.5 s (equivalente a un monitor tipo Uptime Kuma).
UP=0
for _ in $(seq 1 60); do [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$URL/up")" = 200 ] && UP=$((UP + 1)); sleep 0.5; done
AVAIL=$(awk "BEGIN{printf \"%.1f\", $UP*100/60}")

# Carga controlada: 300 peticiones, 10 concurrentes, sobre 3 rutas (ambiente de pruebas, nunca producción).
: > "$OUT/load.txt"
seq 1 300 | xargs -P 10 -I{} sh -c '
  case $(( {} % 3 )) in 0) p=/ ;; 1) p=/cartas ;; *) p=/api/cards ;; esac
  curl -s -o /dev/null -w "%{http_code} %{time_total}\n" --max-time 10 "'"$URL"'$p"' >> "$OUT/load.txt"
TOTAL=$(wc -l < "$OUT/load.txt")
E4=$(awk '$1>=400 && $1<500' "$OUT/load.txt" | wc -l)
E5=$(awk '$1>=500 || $1==0' "$OUT/load.txt" | wc -l)
read -r AVG P95 MAX <<<"$(awk '{print $2*1000}' "$OUT/load.txt" | sort -n | awk '{a[NR]=$1; s+=$1} END{i=int(NR*0.95); if(i<1)i=1; printf "%.0f %.0f %.0f", s/NR, a[i], a[NR]}')"
ERRRATE=$(awk "BEGIN{printf \"%.2f\", ($E4+$E5)*100/$TOTAL}")
RPS_START=$(date +%s%N)
seq 1 100 | xargs -P 10 -I{} curl -s -o /dev/null "$URL/api/cards"
RPS=$(awk "BEGIN{printf \"%.1f\", 100/(($(date +%s%N)-$RPS_START)/1e9)}")

STATS=$(docker stats --no-stream --format '{{.CPUPerc}} {{.MemUsage}}' arkana-pruebas 2>/dev/null || echo "n/d n/d")
CPU=$(echo "$STATS" | awk '{print $1}')
MEM=$(echo "$STATS" | awk '{print $2}')
ERRS_AFTER=$($SSH "cat /var/www/arkana/current/storage/logs/*.log 2>/dev/null | grep -cE '\.(ERROR|CRITICAL):'" 2>/dev/null || echo 0)

cat > "$OUT/metrics.json" <<EOF
{"disponibilidad_pct": $AVAIL, "sondeos_ok": $UP, "sondeos": 60,
 "peticiones": $TOTAL, "concurrencia": 10, "resp_prom_ms": $AVG, "resp_p95_ms": $P95, "resp_max_ms": $MAX,
 "errores_4xx": $E4, "errores_5xx": $E5, "tasa_error_pct": $ERRRATE, "rps_api_cards": $RPS,
 "cpu": "$CPU", "memoria": "$MEM", "errores_laravel": ${ERRS_AFTER:-0}}
EOF

REPORT="$OUT/post-deploy-report.md"
{
  echo "## Validación posterior al despliegue"
  echo "| Estado | Verificación | Resultado |"
  echo "| --- | --- | --- |"
  printf "%s" "$ROWS"
  echo
  echo "## Métricas después de la liberación"
  echo "| Métrica | Valor | Herramienta |"
  echo "| --- | --- | --- |"
  echo "| Disponibilidad | ${AVAIL} % ($UP/60 sondeos a /up) | curl en bucle (equivalente Uptime Kuma) |"
  echo "| Tiempo de respuesta | prom ${AVG} ms · p95 ${P95} ms · máx ${MAX} ms | 300 peticiones, 10 concurrentes |"
  echo "| Tasa de errores HTTP | ${ERRRATE} % (4xx=$E4, 5xx=$E5) | códigos de respuesta |"
  echo "| Rendimiento | ${RPS} peticiones/s en /api/cards | 100 peticiones, 10 concurrentes |"
  echo "| Uso de CPU | ${CPU} | docker stats |"
  echo "| Uso de memoria | ${MEM} | docker stats |"
  echo "| Errores de aplicación | ${ERRS_AFTER:-0} en logs de Laravel | storage/logs |"
} > "$REPORT"
cat "$REPORT"
[ -n "${GITHUB_STEP_SUMMARY:-}" ] && cat "$REPORT" >> "$GITHUB_STEP_SUMMARY"
[ "$FAILS" -eq 0 ]
