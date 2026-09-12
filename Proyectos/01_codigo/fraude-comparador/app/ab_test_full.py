#!/usr/bin/env python3
"""A/B batch completo: ~765 afiliaciones de lista_afiliaciones_analizar,
prompt viejo (prod) vs v2 (tag). Resume cambios y guarda detalle en CSV."""
import time, csv, sys, requests
from collections import Counter
from google.cloud import bigquery

OLD = "https://fraude-comparador-dl7olq7kiq-uc.a.run.app"            # prompt viejo (prod)
V2  = "https://promptv2---fraude-comparador-dl7olq7kiq-uc.a.run.app" # prompt v2 (tag)
PROJ = "dev-izipay-data-storage"

def leer_afiliaciones():
    bq = bigquery.Client(project=PROJ)
    q = f"""SELECT cod_comercio, nom_comercio
            FROM `{PROJ}.raw_riesgo_operativo.lista_afiliaciones_analizar`
            WHERE LENGTH(TRIM(nom_comercio)) >= 3
              AND NOT REGEXP_CONTAINS(nom_comercio, r'^[0-9]+$')
              AND TRIM(nom_comercio) != ''"""
    return [(r["cod_comercio"], r["nom_comercio"]) for r in bq.query(q).result()]

def leer_referencia():
    bq = bigquery.Client(project=PROJ)
    q = f"""SELECT nombre_comercial, razon_social
            FROM `{PROJ}.raw_riesgo_operativo.lista_referencia_nomcom`
            WHERE LENGTH(TRIM(nombre_comercial)) >= 3
              AND NOT REGEXP_CONTAINS(nombre_comercial, r'^[0-9]+$')
              AND TRIM(nombre_comercial) != ''"""
    return [{"nombre": r["nombre_comercial"], "razon_social": r["razon_social"] or ""}
            for r in bq.query(q).result()]

def correr(url, afil, ref, etiqueta):
    print(f"  [{etiqueta}] enviando {len(afil)} afil vs {len(ref)} ref...", flush=True)
    j = requests.post(f"{url}/compare-json",
                      json={"afiliaciones": afil, "referencia": ref, "use_ia": True},
                      timeout=900).json()["job_id"]
    t0 = time.time()
    while True:
        s = requests.get(f"{url}/status/{j}", timeout=30).json()
        st = s.get("status", "")
        if st in ("done", "completed", "error", "failed"): break
        print(f"  [{etiqueta}] {st} {s.get('processed',0)}/{s.get('total',0)} ({int(time.time()-t0)}s)", flush=True)
        time.sleep(10)
    print(f"  [{etiqueta}] listo en {int(time.time()-t0)}s", flush=True)
    res  = requests.get(f"{url}/results/{j}?limit=100000", timeout=300).json().get("results", [])
    desc = requests.get(f"{url}/descartados/{j}?limit=100000", timeout=300).json().get("descartados", [])
    out = {}
    for x in res:  out[x["cod_comercio"]] = x
    for x in desc: out.setdefault(x["cod_comercio"], x)
    return out

def niv(d, c): return (d.get(c, {}) or {}).get("nivel_alerta", "AUSENTE")

print("Leyendo BQ...", flush=True)
ref  = leer_referencia()
casos = leer_afiliaciones()
print(f"Afiliaciones: {len(casos)} | Referencia: {len(ref)}", flush=True)
afil = [{"cod_comercio": c, "nom_comercio": n} for c, n in casos]

print("Corriendo VIEJO (puede tardar)...", flush=True)
old = correr(OLD, afil, ref, "VIEJO")
print("Corriendo V2...", flush=True)
v2  = correr(V2, afil, ref, "V2")

# ── Resumen ──
print("\n" + "="*60)
print("DISTRIBUCION DE NIVELES")
co, cv = Counter(), Counter()
for c, n in casos:
    co[niv(old, c)] += 1; cv[niv(v2, c)] += 1
ordn = ["ALTA","MEDIA","BAJA","DESCARTADO","AUSENTE"]
print(f"{'nivel':<12}{'VIEJO':>8}{'V2':>8}")
for k in ordn:
    print(f"{k:<12}{co.get(k,0):>8}{cv.get(k,0):>8}")

nuevos_alta = [(c,n) for c,n in casos if niv(v2,c)=="ALTA" and niv(old,c)!="ALTA"]
perdidos_alta = [(c,n) for c,n in casos if niv(old,c)=="ALTA" and niv(v2,c)!="ALTA"]

print("\n" + "="*60)
print(f"NUEVOS ALTA en v2 (revisar FALSOS POSITIVOS): {len(nuevos_alta)}")
for c,n in nuevos_alta[:60]:
    print(f"  {c}  {n[:40]:<40} marca={ (v2.get(c,{}).get('nombre_referencia_match') or '')[:25] }")

print("\n" + "="*60)
print(f"PERDIDOS ALTA (viejo ALTA -> v2 no; ojo recall): {len(perdidos_alta)}")
for c,n in perdidos_alta[:60]:
    print(f"  {c}  {n[:40]:<40} v2={niv(v2,c)}")

# ── CSV detalle ──
with open("/home/mc2139/ab_full.csv", "w", newline="", encoding="utf-8") as f:
    w = csv.writer(f)
    w.writerow(["cod_comercio","nom_comercio","nivel_viejo","nivel_v2",
                "marca_v2","metodo_v2","score_v2","detalle_v2"])
    for c,n in casos:
        v = v2.get(c, {})
        w.writerow([c, n, niv(old,c), niv(v2,c),
                    v.get("nombre_referencia_match",""), v.get("metodo_deteccion",""),
                    v.get("score_final",""), (v.get("detalle_ia","") or "").replace("\n"," ")])
print("\nDetalle completo en ~/ab_full.csv (descárgalo para revisar a fondo).")
