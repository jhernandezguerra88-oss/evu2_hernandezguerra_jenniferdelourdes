#!/usr/bin/env python3
"""Analiza los registros de la ventana de observacion (apoyo; no reemplaza el analizador del docente).

Uso:
  python3 analizar_observacion.py muestras.csv --inicio 2026-11-15T05:00:00Z \
      --estabilizacion 2026-11-15T05:09:30Z [--estado estado.log] [--salida resumen.md]

--inicio:          instante en que el pipeline/controlador comienza el cambio (UTC).
--estabilizacion:  instante en que se cumplen las condiciones de estabilizacion (UTC).
"""
import argparse, csv, re, statistics, sys
from collections import Counter
from datetime import datetime, timedelta, timezone


def parse_ts(s):
    s = s.strip().replace("Z", "+00:00")
    d = datetime.fromisoformat(s)
    return d if d.tzinfo else d.replace(tzinfo=timezone.utc)


def fmt(d):
    return d.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("csv")
    ap.add_argument("--inicio", required=True)
    ap.add_argument("--estabilizacion", required=True)
    ap.add_argument("--estado")
    ap.add_argument("--salida")
    ap.add_argument("--tolerancia", type=float, default=7.0, help="separacion maxima entre muestras (s)")
    a = ap.parse_args()

    inicio, estab = parse_ts(a.inicio), parse_ts(a.estabilizacion)
    w0, w1 = inicio - timedelta(seconds=60), estab + timedelta(seconds=120)

    rows = []
    with open(a.csv, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            try:
                rows.append({"t": parse_ts(r["utc_inicio"]), "code": r["http_code"],
                             "lat": float(r["tiempo_s"]), "ver": r["version_detectada"], "err": r.get("error", "")})
            except (ValueError, KeyError):
                continue
    rows.sort(key=lambda x: x["t"])
    if not rows:
        sys.exit("Sin muestras validas en el CSV.")

    win = [r for r in rows if w0 <= r["t"] <= w1]
    out = []
    P = out.append
    P("# Resumen de la ventana de observacion\n")
    P(f"- Inicio del cambio: {fmt(inicio)}")
    P(f"- Estabilizacion: {fmt(estab)}  (duracion del cambio: {(estab - inicio).total_seconds():.0f} s)")
    P(f"- Ventana exigida: {fmt(w0)}  a  {fmt(w1)}  (inicio-60 s a estabilizacion+120 s)")
    P(f"- Primera muestra del archivo: {fmt(rows[0]['t'])} | ultima: {fmt(rows[-1]['t'])}")

    cov_ini = rows[0]["t"] <= w0 + timedelta(seconds=a.tolerancia)
    cov_fin = rows[-1]["t"] >= w1 - timedelta(seconds=a.tolerancia)
    P(f"- Cobertura al inicio de la ventana: {'OK' if cov_ini else 'INSUFICIENTE'}"
      f" (primera muestra {(rows[0]['t'] - w0).total_seconds():+.1f} s respecto del limite)")
    P(f"- Cobertura al final de la ventana: {'OK' if cov_fin else 'INSUFICIENTE'}"
      f" (ultima muestra {(rows[-1]['t'] - w1).total_seconds():+.1f} s respecto del limite)")

    P(f"\n## Muestreo HTTP dentro de la ventana ({len(win)} muestras)")
    gaps = []
    for x, y in zip(win, win[1:]):
        gaps.append(((y["t"] - x["t"]).total_seconds(), x["t"], y["t"]))
    if gaps:
        mx = max(g[0] for g in gaps)
        med = statistics.median(g[0] for g in gaps)
        P(f"- Separacion mediana: {med:.2f} s | maxima: {mx:.2f} s (limite {a.tolerancia:.0f} s): "
          f"{'OK' if mx <= a.tolerancia else 'SUPERADA'}")
        for g, t0, t1 in [g for g in gaps if g[0] > a.tolerancia][:10]:
            P(f"  - hueco de {g:.1f} s entre {fmt(t0)} y {fmt(t1)}")
    lat = [r["lat"] for r in win]
    if lat:
        lat_s = sorted(lat)
        p95 = lat_s[int(0.95 * (len(lat_s) - 1))]
        P(f"- Latencia: media {statistics.mean(lat):.3f} s | p95 {p95:.3f} s | maxima {max(lat):.3f} s")

    P("\n## Resultados HTTP")
    cnt = Counter(r["code"] for r in win)
    for k, v in sorted(cnt.items()):
        P(f"- codigo {k}: {v}")
    bad = [r for r in win if r["code"] != "200"]
    P(f"- Respuestas distintas de 200 o con timeout/error: {len(bad)} de {len(win)}"
      f" ({100 * len(bad) / max(len(win), 1):.2f} %)")
    for r in bad[:15]:
        P(f"  - {fmt(r['t'])} codigo {r['code']} {r['err']}".rstrip())

    P("\n## Version observada en las respuestas")
    fases = [("antes del inicio", [r for r in win if r["t"] < inicio]),
             ("durante el cambio", [r for r in win if inicio <= r["t"] <= estab]),
             ("despues de estabilizar", [r for r in win if r["t"] > estab])]
    for nombre, rs in fases:
        c = Counter(r["ver"] for r in rs)
        P(f"- {nombre}: " + (", ".join(f"{k}={v}" for k, v in sorted(c.items())) if c else "sin muestras"))
    vers = [r for r in win if r["ver"] not in ("NA", "")]
    if vers:
        nuevas = sorted({r["ver"] for r in vers})
        P(f"- Versiones vistas en la ventana: {', '.join(nuevas)}")
        if len(nuevas) >= 2:
            ult_ant = max((r["t"] for r in vers if r["ver"] == nuevas[0]), default=None)
            pri_nue = min((r["t"] for r in vers if r["ver"] == nuevas[-1]), default=None)
            if ult_ant and pri_nue:
                P(f"- Primera respuesta {nuevas[-1]}: {fmt(pri_nue)} | ultima {nuevas[0]}: {fmt(ult_ant)}")
                P("  (la coexistencia de ambas versiones es esperable en un reemplazo rolling)")
    post = fases[2][1]
    if post:
        ultimas = Counter(r["ver"] for r in post)
        P(f"- Version tras la estabilizacion: {ultimas.most_common(1)[0][0]} "
          f"({ultimas.most_common(1)[0][1]} de {len(post)} muestras)")

    if a.estado:
        P("\n## Registro de capacidad / controlador")
        txt = open(a.estado, encoding="utf-8", errors="replace").read()
        marcas = [parse_ts(m) for m in re.findall(r"^=== (\d{4}-\d\d-\d\dT[\d:]+Z)$", txt, re.M)]
        marcas.sort()
        P(f"- Registros: {len(marcas)} (primero {fmt(marcas[0]) if marcas else '-'}, ultimo {fmt(marcas[-1]) if marcas else '-'})")
        if len(marcas) > 1:
            d = [(y - x).total_seconds() for x, y in zip(marcas, marcas[1:])]
            P(f"- Intervalo maximo entre registros: {max(d):.0f} s (limite 30 s): {'OK' if max(d) <= 30 else 'SUPERADO'}")
        P(f"- Registro cercano al inicio de la ventana (+-30 s): "
          f"{'SI' if any(abs((m - w0).total_seconds()) <= 30 for m in marcas) else 'NO'}")
        P(f"- Registro cercano al final de la ventana (+-30 s): "
          f"{'SI' if any(abs((m - w1).total_seconds()) <= 30 for m in marcas) else 'NO'}")
        estados = Counter(re.findall(r'"Estado": "([A-Za-z]+)"', txt))
        P("- Estados vistos (refresh/instancias/destinos): " + ", ".join(f"{k}={v}" for k, v in estados.most_common()))

    texto = "\n".join(out)
    print(texto)
    if a.salida:
        open(a.salida, "w", encoding="utf-8").write(texto + "\n")


if __name__ == "__main__":
    main()
