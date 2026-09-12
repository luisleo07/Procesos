import time, requests
from google.cloud import bigquery

# TAG con el fix (NO la URL principal de prod):
MAIN = "https://promptv2---fraude-comparador-dl7olq7kiq-uc.a.run.app"
PROJ = "dev-izipay-data-storage"

def leer_referencia():
    bq = bigquery.Client(project=PROJ)
    q = f"""SELECT nombre_comercial, razon_social
            FROM `{PROJ}.raw_riesgo_operativo.lista_referencia_nomcom`
            WHERE LENGTH(TRIM(nombre_comercial)) >= 3
              AND NOT REGEXP_CONTAINS(nombre_comercial, r'^[0-9]+$')
              AND TRIM(nombre_comercial) != ''"""
    return [{"nombre": r["nombre_comercial"], "razon_social": r["razon_social"] or ""}
            for r in bq.query(q).result()]

ref = leer_referencia()
print(f"Referencia: {len(ref)}")
afil = [{"cod_comercio":"TEST_IZIUTP","nom_comercio":"IZI*UTP"},
        {"cod_comercio":"TEST_UTP","nom_comercio":"UTP"}]
j = requests.post(f"{MAIN}/compare-json",
                  json={"afiliaciones":afil,"referencia":ref,"use_ia":True}, timeout=900).json()["job_id"]
while True:
    s = requests.get(f"{MAIN}/status/{j}", timeout=30).json().get("status","")
    if s in ("done","completed","error","failed"): break
    time.sleep(5)
for ep in ("results","descartados"):
    data = requests.get(f"{MAIN}/{ep}/{j}?limit=1000", timeout=120).json()
    for r in (data.get("results") or data.get("descartados") or []):
        print(f'{r["cod_comercio"]:<14} {r["nom_comercio"]:<10} -> {r.get("nivel_alerta")}'
              f' | match={r.get("nombre_referencia_match")} | {(r.get("detalle_ia") or "")[:180]}')
