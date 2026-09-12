#!/usr/bin/env python3
import time, requests
from google.cloud import bigquery

OLD = "https://fraude-comparador-dl7olq7kiq-uc.a.run.app"               # prompt viejo (prod)
V2  = "https://promptv2---fraude-comparador-dl7olq7kiq-uc.a.run.app"    # prompt v2 (tag)

CASOS = [  # (cod_comercio, nom_comercio sin IZI*)
 ("5957060","U S I L"),("5957083","UNIVERCY TECNOLOGICA PERFORMANCE"),
 ("5957325","CH IMPORTACIONES"),("5958665","SHALOM SAAC"),("5958941","RAPPIIIU"),
 ("5958983","COBROS Y FINANZAS SAC."),("5958984","COBROS Y FINANZAS SAC."),
 ("5959016","BOTICAS SALUD Y HOGAR"),("5959077","CRUZ DEL SUR S.A.C"),
 ("5959106","HOU IMPORT EIRL"),("5959438","IZI COMPUMARKET"),("5959445","IZICOMPUFACTOR"),
 ("5959482","CONTRATISTAS ROA SAC"),("5959510","COMERCIALIZADORA BYL"),("5959529","EDUPC"),
 ("5959536","IDIOMAS PUCP"),("5959541","TIENDA ONLINE MOVISTAR"),("5959609","MYR PERU"),
 ("5959900","TONYIMPOR S.A.C"),("5959989","YZISHALOMEXPRESSAC"),("5960154","JEL SAC"),
 ("5960263","CENTRO UTECNOLOGICO PE"),("5960369","UDEPCLIMA"),
 ("5960390","MULTISERVICIOS DIGITALES S.A.C"),("5960405","UDEP CENTRO IDIOMAS LIMA"),
 ("5960445","UTPSAE"),("5960452","TIENDA UNO"),("5960459","AGRO SAN FRANCISCO SAC"),
 ("5960461","UNIVERSIDAD SAN MARTIN DE PORRES"),("5960683","BBV TES ESTRA"),
 ("5960721","INEN NEOPLASICAS OPERACIONES"),("5960799","SHALOM EMP SAC"),
 ("5963142","IZIPAYMASTER22"),("5963514","TUKUY PERU"),("5963517","EQUIPO MOVISTAR"),
 ("5963574","CRIPTOCASH PERU"),("5963581","CESSCAR AUTOMTRIZ SAC"),("5963813","CERTUS SCR"),
 ("5963822","LA POSITIVA SEGUROS PERU LIMA SAN ISIDRO"),("5963835","METROSHOPXPRESS"),
 ("5963921","QR SHALOM EMPRES"),("5963970","SANO SAC"),("5964040","LTP PERU"),
 ("5964068","HACK YAPE"),("5964259","CONTRATOS MOVISTAR"),("5964343","ACEROS INOX SAC"),
 ("5964376","CONTRATOS MOVISTAR"),("5964380","CONTRATOS MOVISTAR"),("5964400","I CERTUS"),
 ("5964409","I.CERTUS.FINANZAS"),
]

def leer_referencia():
    bq = bigquery.Client(project="dev-izipay-data-storage")
    q = """SELECT nombre_comercial, razon_social
           FROM `dev-izipay-data-storage.raw_riesgo_operativo.lista_referencia_nomcom`
           WHERE LENGTH(TRIM(nombre_comercial)) >= 3
             AND NOT REGEXP_CONTAINS(nombre_comercial, r'^[0-9]+$')
             AND TRIM(nombre_comercial) != ''"""
    return [{"nombre": r["nombre_comercial"], "razon_social": r["razon_social"] or ""}
            for r in bq.query(q).result()]

def correr(url, afil, ref):
    j = requests.post(f"{url}/compare-json",
                      json={"afiliaciones": afil, "referencia": ref, "use_ia": True},
                      timeout=600).json()["job_id"]
    while True:
        s = requests.get(f"{url}/status/{j}", timeout=30).json().get("status","")
        if s in ("done","completed","error","failed"): break
        time.sleep(3)
    res  = requests.get(f"{url}/results/{j}?limit=100000", timeout=180).json().get("results", [])
    desc = requests.get(f"{url}/descartados/{j}?limit=100000", timeout=180).json().get("descartados", [])
    out = {}
    for x in res:  out[x["cod_comercio"]] = x
    for x in desc: out.setdefault(x["cod_comercio"], x)
    return out

ref = leer_referencia(); print(f"Referencia: {len(ref)} marcas\n")
afil = [{"cod_comercio": c, "nom_comercio": n} for c, n in CASOS]
print("Corriendo prompt VIEJO..."); old = correr(OLD, afil, ref)
print("Corriendo prompt V2...");     v2  = correr(V2,  afil, ref)

print(f"\n{'NOMBRE':<34}{'VIEJO':<11}{'V2':<11}{'MARCA_V2':<16}")
for c, n in CASOS:
    o, v = old.get(c, {}), v2.get(c, {})
    flag = "  <-- CAMBIO" if o.get("nivel_alerta") != v.get("nivel_alerta") else ""
    print(f"{n[:33]:<34}{o.get('nivel_alerta','-'):<11}{v.get('nivel_alerta','-'):<11}"
          f"{(v.get('nombre_referencia_match') or '')[:15]:<16}{flag}")
    print(f"     v2: {(v.get('detalle_ia') or '')[:230]}")
