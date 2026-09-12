"""
Fraude NomCom API v1.1 — Izipay
Detección de fraude por nombre comercial
FastAPI + BigQuery + PostgreSQL + Azure OpenAI
"""
import os, json, time, uuid, logging, threading
from pathlib import Path
from datetime import datetime, timedelta, timezone
from typing import Optional, List
from contextlib import contextmanager

import psycopg2, psycopg2.extras
from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from google.cloud import bigquery

from engine import MatchingEngine, normalize_text

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s — %(message)s"
)
logger = logging.getLogger("api")

LIMA = timezone(timedelta(hours=-5))

DB_CONFIG = {
    "host": os.environ.get("DB_HOST", "localhost"),
    "port": int(os.environ.get("DB_PORT", "5432")),
    "dbname": os.environ.get("DB_NAME", "backoffice_test"),
    "user": os.environ.get("DB_USER", "postgres"),
    "password": os.environ.get("DB_PASSWORD", ""),
}

BQ_PROJECT = os.environ.get("BQ_PROJECT", "dev-izipay-data-storage")
BQ_DATASET = os.environ.get("BQ_DATASET", "master_party")
BQ_TABLE_REF = os.environ.get("BQ_TABLE_REF", "lista_referencia_nomcom")
BQ_TABLE_AFIL = os.environ.get("BQ_TABLE_AFIL", "lista_afiliaciones_analizar")
BQ_TABLE_RESULT = os.environ.get("BQ_TABLE_RESULT", "resultado_analisis_nomcom")
BQ_TABLE_LOG = os.environ.get("BQ_TABLE_LOG", "log_consultas_nomcom")

SYNC_INTERVAL = int(os.environ.get("SYNC_INTERVAL_SECONDS", "1800"))

engine = MatchingEngine()
_last_bq_check: Optional[float] = None
_last_ref_ts: Optional[str] = None

# ─── DB HELPERS ────────────────────────────────────────────────
@contextmanager
def pg_conn():
    conn = psycopg2.connect(**DB_CONFIG)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def pg_execute(sql, params=()):
    with pg_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)

def pg_query(sql, params=()):
    with pg_conn() as conn:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(sql, params)
            return [dict(r) for r in cur.fetchall()]

def bq_client() -> bigquery.Client:
    return bigquery.Client(project=BQ_PROJECT)

def fq(table: str) -> str:
    return f"`{BQ_PROJECT}.{BQ_DATASET}.{table}`"

# ─── APP ───────────────────────────────────────────────────────
app = FastAPI(title="Fraude NomCom API", version="2.0.0")
app.add_middleware(
    CORSMiddleware, allow_origins=["*"], allow_credentials=True,
    allow_methods=["*"], allow_headers=["*"],
)
STATIC = Path(__file__).parent / "static"
if STATIC.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC)), name="static")

# ─── MODELS ────────────────────────────────────────────────────
class MatchRequest(BaseModel):
    nombre: str = Field(..., min_length=1)
    use_ia: bool = Field(True)
    top_n: int = Field(5, ge=1, le=20)

class BatchRequest(BaseModel):
    source: str = Field("bigquery")
    items: Optional[List[dict]] = None
    use_ia: bool = Field(True)
    top_n: int = Field(3, ge=1, le=10)
    days_lookback: int = Field(3, ge=1, le=30)

# ─── REFERENCIA ────────────────────────────────────────────────
def load_reference_from_bq():
    global _last_ref_ts
    logger.info("Cargando lista de referencia desde BigQuery...")
    try:
        bq = bq_client()
        df = bq.query(f"""
            SELECT nombre_comercial, razon_social, origen
            FROM {fq(BQ_TABLE_REF)} WHERE activo = TRUE
        """).to_dataframe()

        names, origins = [], []
        for _, row in df.iterrows():
            if row["nombre_comercial"]:
                names.append(str(row["nombre_comercial"]))
                origins.append(str(row["origen"]))
            if row.get("razon_social") and str(row["razon_social"]).strip():
                names.append(str(row["razon_social"]))
                origins.append(str(row["origen"]) + "_RAZSOC")

        engine.load_reference(names, origins)
        ts_df = bq.query(f"SELECT MAX(fecha_actualizacion) as max_ts FROM {fq(BQ_TABLE_REF)}").to_dataframe()
        _last_ref_ts = str(ts_df["max_ts"].iloc[0]) if not ts_df.empty else None
        logger.info(f"Referencia cargada: {len(names)} entradas")
    except Exception as e:
        logger.error(f"Error cargando referencia: {e}")
        if not engine.is_loaded:
            _load_sample_data()

def _load_sample_data():
    logger.info("Cargando datos de prueba (modo dev)...")
    names = [
        "SMART FIT", "PLAZA VEA", "INKAFARMA", "BEMBOS", "CINEPLANET",
        "INTERBANK", "REAL PLAZA", "OECHSLE", "PROMART", "CASA ANDINA",
        "PAPA JOHNS", "DUNKIN DONUTS", "MAKRO", "MIFARMA", "FINANCIERA OH",
        "ONLYFANS", "SHOPSTAR", "INNOVA SCHOOLS", "LA TINKA", "DON BELISARIO",
        "NATURA COSMETICOS", "NATURA COSMETICOS SA",
    ]
    try:
        engine.load_reference(names, ["SAMPLE"] * len(names))
    except Exception as e:
        logger.warning(f"No se pudo cargar data de prueba en PG: {e}")

def check_reference_update():
    global _last_bq_check, _last_ref_ts
    now = time.time()
    if _last_bq_check and (now - _last_bq_check) < SYNC_INTERVAL:
        return
    _last_bq_check = now
    try:
        bq = bq_client()
        df = bq.query(f"SELECT MAX(fecha_actualizacion) as max_ts FROM {fq(BQ_TABLE_REF)}").to_dataframe()
        new_ts = str(df["max_ts"].iloc[0]) if not df.empty else None
        if new_ts and new_ts != _last_ref_ts:
            logger.info(f"Cambio detectado: {_last_ref_ts} → {new_ts}")
            threading.Thread(target=load_reference_from_bq, daemon=True).start()
    except Exception as e:
        logger.warning(f"Error verificando sync: {e}")

# ─── GUARDAR EN BIGQUERY ──────────────────────────────────────
def save_results_bq(results: List[dict], origen: str, batch_id: str):
    if not results:
        return
    try:
        bq = bq_client()
        rows = []
        for r in results:
            rows.append({
                "id": str(uuid.uuid4()),
                "id_batch": batch_id,
                "cod_comercio": r.get("cod_comercio", ""),
                "nom_comercio": r.get("nom_comercio", ""),
                "nom_comercio_norm": r.get("nom_comercio_norm", ""),
                "nombre_referencia_match": r.get("nombre_referencia_match", ""),
                "origen_referencia": r.get("origen_referencia", ""),
                "score_sintactico": r.get("score_sintactico", 0),
                "score_semantico": r.get("score_semantico", 0),
                "score_ia": r.get("score_ia", 0),
                "score_final": r.get("score_final", 0),
                "nivel_alerta": r.get("nivel_alerta", ""),
                "metodo_deteccion": r.get("metodo_deteccion", ""),
                "detalle_ia": r.get("detalle_ia", ""),
                "origen": origen,
                "fecha_analisis": datetime.now(LIMA).isoformat(),
            })
        table_ref = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TABLE_RESULT}"
        errors = bq.insert_rows_json(table_ref, rows)
        if errors:
            logger.error(f"Error BQ resultado: {errors}")
        else:
            logger.info(f"Resultados BQ: {len(rows)} filas ok")
    except Exception as e:
        logger.error(f"Error guardando resultados BQ: {e}")

def save_log_bq(origen, usuario, nombre, nombre_norm, cantidad, max_score, nivel_max, ip, tiempo_ms):
    try:
        bq = bq_client()
        row = {
            "id": str(uuid.uuid4()),
            "origen": origen,
            "usuario": usuario,
            "nombre_consultado": nombre,
            "nombre_normalizado": nombre_norm,
            "cantidad_matches": cantidad,
            "max_score": max_score,
            "nivel_alerta_max": nivel_max,
            "ip_origen": ip,
            "tiempo_respuesta_ms": tiempo_ms,
            "fecha_consulta": datetime.now(LIMA).isoformat(),
        }
        table_ref = f"{BQ_PROJECT}.{BQ_DATASET}.{BQ_TABLE_LOG}"
        errors = bq.insert_rows_json(table_ref, [row])
        if errors:
            logger.error(f"Error BQ log: {errors}")
    except Exception as e:
        logger.warning(f"Error guardando log BQ: {e}")

def log_consulta(origen, usuario, nombre, nombre_norm, cantidad, max_score, nivel_max, ip, tiempo_ms):
    # Guardar en PostgreSQL
    try:
        pg_execute("""
            INSERT INTO log_consultas_nomcom
            (origen, usuario, nombre_consultado, nombre_normalizado,
             cantidad_matches, max_score, nivel_alerta_max, ip_origen, tiempo_respuesta_ms)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """, (origen, usuario, nombre, nombre_norm, cantidad, max_score, nivel_max, ip, tiempo_ms))
    except Exception as e:
        logger.warning(f"Error log PG: {e}")
    # Guardar en BigQuery
    save_log_bq(origen, usuario, nombre, nombre_norm, cantidad, max_score, nivel_max, ip, tiempo_ms)

# ─── STARTUP ───────────────────────────────────────────────────
@app.on_event("startup")
def startup():
    engine.set_db_config(DB_CONFIG)

    try:
        pg_execute("""
            CREATE TABLE IF NOT EXISTS log_consultas_nomcom (
                id SERIAL PRIMARY KEY, origen VARCHAR(50), usuario VARCHAR(200),
                nombre_consultado TEXT, nombre_normalizado TEXT,
                cantidad_matches INT DEFAULT 0, max_score FLOAT DEFAULT 0,
                nivel_alerta_max VARCHAR(20), ip_origen VARCHAR(50),
                tiempo_respuesta_ms INT DEFAULT 0, fecha_consulta TIMESTAMP DEFAULT NOW()
            )""")
        logger.info("PostgreSQL OK")
    except Exception as e:
        logger.warning(f"PostgreSQL no disponible: {e}")

    # Verificar si PG ya tiene datos (evita re-descargar de BQ)
    try:
        rows = pg_query('SELECT COUNT(*) as c FROM ref_nombres_comerciales')
        existing = rows[0]["c"] if rows else 0
        if existing > 1000:
            engine.reference_count = existing
            engine.is_loaded = True
            engine.last_update = __import__("time").time()
            logger.info(f"PG ya tiene {existing} registros, listo")
            return
    except Exception as e:
        logger.info(f"PG sin datos previos: {e}")

    import threading
    threading.Thread(target=load_reference_from_bq, daemon=True).start()
    logger.info("Carga de referencia iniciada en background")

# ─── ENDPOINTS ─────────────────────────────────────────────────
@app.get("/health")
def health():
    return {"status": "ok", "version": "2.0.0", "engine": engine.stats(),
            "timestamp": datetime.now(LIMA).isoformat()}

@app.get("/", response_class=HTMLResponse)
def root():
    html_file = STATIC / "app.html"
    if html_file.exists():
        return HTMLResponse(html_file.read_text(encoding="utf-8"))
    return HTMLResponse("<h1>Fraude NomCom API</h1>")

@app.post("/match")
def match(req: MatchRequest, request: Request):
    check_reference_update()
    t0 = time.time()

    matches = engine.match_single(req.nombre, use_ia=req.use_ia, top_n=req.top_n)
    results = [m.to_dict() for m in matches]

    elapsed_ms = int((time.time() - t0) * 1000)
    nombre_norm = normalize_text(req.nombre)
    max_score = max((r["score_final"] for r in results), default=0)
    nivel_max = results[0]["nivel_alerta"] if results else "NINGUNO"

    ip = request.client.host if request.client else "unknown"
    usuario = request.headers.get("X-User", "frontend")
    origen = request.headers.get("X-Origin", "FRONTEND")

    log_consulta(origen, usuario, req.nombre, nombre_norm, len(results), max_score, nivel_max, ip, elapsed_ms)

    batch_id = f"single_{datetime.now(LIMA).strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}"
    for r in results:
        r["cod_comercio"] = ""
        r["nom_comercio"] = req.nombre
        r["nom_comercio_norm"] = nombre_norm
    save_results_bq(results, origen, batch_id)

    return {
        "nombre_consultado": req.nombre,
        "nombre_normalizado": nombre_norm,
        "matches": results,
        "total_matches": len(results),
        "tiempo_ms": elapsed_ms,
    }

@app.post("/match/batch")
def match_batch(req: BatchRequest, request: Request):
    check_reference_update()
    t0 = time.time()
    batch_id = f"batch_{datetime.now(LIMA).strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}"

    if req.source == "bigquery":
        try:
            bq = bq_client()
            df = bq.query(f"""
                SELECT cod_comercio, nom_comercio
                FROM {fq(BQ_TABLE_AFIL)}
                WHERE fecha_carga >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {req.days_lookback} DAY)
            """).to_dataframe()
            items = df.to_dict("records")
        except Exception as e:
            raise HTTPException(500, f"Error leyendo BigQuery: {e}")
    elif req.source == "inline" and req.items:
        items = req.items
    else:
        raise HTTPException(400, "Indicar source='bigquery' o enviar items[]")

    results = engine.match_batch(items, use_ia=req.use_ia, top_n=req.top_n)

    ip = request.client.host if request.client else "unknown"
    usuario = request.headers.get("X-User", "pipeline")
    origen = request.headers.get("X-Origin", "BATCH")

    log_consulta(origen, usuario, f"batch:{len(items)}", f"batch_id:{batch_id}",
                 len(results), 0, "BATCH", ip, int((time.time() - t0) * 1000))
    save_results_bq(results, origen, batch_id)

    return {
        "batch_id": batch_id, "total_evaluados": len(items),
        "total_matches": len(results), "tiempo_ms": int((time.time() - t0) * 1000),
        "results": results[:500], "truncated": len(results) > 500,
    }



@app.post("/match/batch-sql")
def match_batch_sql(req: BatchRequest, request: Request):
    """Batch optimizado: cruce directo en PostgreSQL (1 query)"""
    check_reference_update()
    t0 = time.time()
    batch_id = f"bsql_{datetime.now(LIMA).strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}"

    if req.source == "bigquery":
        try:
            bq = bq_client()
            df = bq.query(f"""
                SELECT cod_comercio, nom_comercio
                FROM {fq(BQ_TABLE_AFIL)}
                WHERE fecha_carga >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {req.days_lookback} DAY)
            """).to_dataframe()
            items = df.to_dict("records")
        except Exception as e:
            raise HTTPException(500, f"Error leyendo BigQuery: {e}")
    elif req.source == "inline" and req.items:
        items = req.items
    else:
        raise HTTPException(400, "Indicar source='bigquery' o enviar items[]")

    results = engine.batch_sql(items, top_n=req.top_n)

    ip = request.client.host if request.client else "unknown"
    usuario = request.headers.get("X-User", "pipeline")
    origen = request.headers.get("X-Origin", "BATCH_SQL")

    elapsed_ms = int((time.time() - t0) * 1000)
    log_consulta(origen, usuario, f"batch-sql:{len(items)}", f"batch_id:{batch_id}",
                 len(results), 0, "BATCH_SQL", ip, elapsed_ms)
    save_results_bq(results, origen, batch_id)

    return {
        "batch_id": batch_id, "total_evaluados": len(items),
        "total_matches": len(results), "tiempo_ms": elapsed_ms,
        "results": results[:500], "truncated": len(results) > 500,
    }

@app.get("/search/history")
def search_history(limit: int = Query(50, ge=1, le=500),
                   origen: Optional[str] = Query(None), usuario: Optional[str] = Query(None)):
    conditions, params = ["1=1"], []
    if origen:
        conditions.append("origen = %s"); params.append(origen)
    if usuario:
        conditions.append("usuario ILIKE %s"); params.append(f"%{usuario}%")
    try:
        rows = pg_query(
            f"""SELECT id, origen, usuario, nombre_consultado, nombre_normalizado,
                       cantidad_matches, max_score, nivel_alerta_max, ip_origen,
                       tiempo_respuesta_ms, fecha_consulta
                FROM log_consultas_nomcom WHERE {' AND '.join(conditions)}
                ORDER BY fecha_consulta DESC LIMIT %s""", (*params, limit))
        for r in rows:
            if r.get("fecha_consulta"): r["fecha_consulta"] = r["fecha_consulta"].isoformat()
        return {"history": rows, "count": len(rows)}
    except Exception as e:
        raise HTTPException(500, f"Error: {e}")

@app.post("/reference-list/reload")
def reload_reference():
    load_reference_from_bq()
    return {"status": "reloaded", "engine": engine.stats()}

@app.get("/engine/stats")
def engine_stats():
    return engine.stats()
