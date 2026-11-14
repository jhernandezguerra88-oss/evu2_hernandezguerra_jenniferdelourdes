#!/usr/bin/env bash
# Observacion HTTP: 1 peticion cada 2 s, timeout 5 s, sin reintentos.
# Uso: ./observar_http.sh http://<alb-dns>/ salida.csv
# Detener con Ctrl+C (lo hace el operador: inicio -60 s ... estabilizacion +120 s).
set -u
URL="${1:?uso: $0 URL salida.csv}"
OUT="${2:?uso: $0 URL salida.csv}"
CAD=2

echo "utc_inicio,http_code,tiempo_s,version_detectada,error" > "$OUT"
while true; do
  t0=$(date +%s.%N)
  ts=$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)
  body=$(mktemp)
  res=$(curl -sS -m 5 -o "$body" -w '%{http_code},%{time_total}' "$URL" 2>/tmp/curl_err); rc=$?
  ver=$(grep -oiE 'v[12]\b' "$body" | head -1)
  err=""; [ $rc -ne 0 ] && err=$(tr -d '\n,' < /tmp/curl_err)
  [ $rc -ne 0 ] && res="000,5.000"
  echo "$ts,$res,${ver:-NA},$err" >> "$OUT"
  rm -f "$body"
  t1=$(date +%s.%N)
  rest=$(awk -v a="$t0" -v b="$t1" -v c="$CAD" 'BEGIN{d=c-(b-a); if(d<0)d=0; print d}')
  sleep "$rest"
done
