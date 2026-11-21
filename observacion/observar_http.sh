#!/usr/bin/env bash
# Observacion HTTP del endpoint AWS: 1 peticion cada 2 s, timeout 5 s, SIN reintentos.
# Uso (CloudShell):  ./observar_http.sh http://<dns-del-alb>/health salida.csv
# Se inicia >= 60 s antes del cambio y se detiene (Ctrl+C) >= 120 s despues de estabilizar.
set -u
URL="${1:?uso: $0 URL salida.csv}"
OUT="${2:?uso: $0 URL salida.csv}"
CAD=2
TMP=$(mktemp)
trap 'rm -f "$TMP" "$TMP.err"; echo "Observacion detenida: $(date -u +%Y-%m-%dT%H:%M:%SZ)"; exit 0' INT TERM

echo "utc_inicio,http_code,tiempo_s,version_detectada,error" > "$OUT"
echo "Inicio de observacion: $(date -u +%Y-%m-%dT%H:%M:%SZ) -> $URL"
while true; do
  t0=$(date +%s.%N)
  ts=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
  res=$(curl -sS -m 5 -o "$TMP" -w '%{http_code},%{time_total}' "$URL" 2>"$TMP.err"); rc=$?
  ver=$(sed -n 's/.*"version": *"\(v[0-9]*\)".*/\1/p' "$TMP" | head -1)
  err=""
  if [ $rc -ne 0 ]; then err=$(tr -d '\n,' < "$TMP.err"); res="000,5.000"; fi
  echo "$ts,$res,${ver:-NA},$err" >> "$OUT"
  t1=$(date +%s.%N)
  rest=$(awk -v a="$t0" -v b="$t1" -v c="$CAD" 'BEGIN{d=c-(b-a); if(d<0)d=0; printf "%.3f", d}')
  sleep "$rest"
done
