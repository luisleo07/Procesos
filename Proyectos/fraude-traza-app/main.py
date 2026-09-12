from fastapi import FastAPI, Query, HTTPException
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
from contextlib import contextmanager
import psycopg2
import psycopg2.extras
import uuid
import os
import json
import logging
import time

logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
log = logging.getLogger(__name__)

app = FastAPI(title="Fraude NomCom — Trazabilidad", version="6.0")

PG_DSN = os.getenv("PG_DSN", "host=<<DB_HOST>> dbname=<<DB_NAME>> user=<<DB_USER>> password=<<DB_PASSWORD>>")
BQ_PROJECT = "dev-izipay-data-storage"
BQ_DATASET = "raw_riesgo_operativo"


@contextmanager
def get_db():
    conn = psycopg2.connect(PG_DSN)
    conn.autocommit = True
    try:
        yield conn
    finally:
        conn.close()


def dict_cursor(conn):
    return conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)


@app.get("/health")
def health():
    try:
        with get_db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT COUNT(*) FROM fraude.batch_runs")
            n = cur.fetchone()[0]
        return {"status": "ok", "pg": True, "batch_runs": n}
    except Exception as e:
        return {"status": "error", "pg": False, "error": str(e)}


@app.get("/batches")
def list_batches(
    desde: Optional[date] = None,
    hasta: Optional[date] = None,
    estado: Optional[str] = None,
    limit: int = Query(20, le=100)
):
    with get_db() as conn:
        cur = dict_cursor(conn)
        where, params = ["1=1"], []
        if desde:
            where.append("fecha_batch >= %s"); params.append(desde)
        if hasta:
            where.append("fecha_batch <= %s"); params.append(hasta)
        if estado:
            where.append("estado = %s"); params.append(estado)
        cur.execute(f"SELECT * FROM fraude.batch_runs WHERE {' AND '.join(where)} ORDER BY created_at DESC LIMIT %s", params + [limit])
        return {"total": cur.rowcount, "batches": cur.fetchall()}


@app.get("/batch/{id_batch}")
def get_batch(id_batch: str):
    with get_db() as conn:
        cur = dict_cursor(conn)
        cur.execute("SELECT * FROM fraude.batch_runs WHERE id_batch = %s", (id_batch,))
        batch = cur.fetchone()
        if not batch:
            raise HTTPException(404, "Batch no encontrado")
        cur.execute("""
            SELECT cod_comercio, nom_comercio, score_final, nivel_alerta,
                   nombre_referencia_match, tecnica_suplantacion, fase_skip, origen
            FROM fraude.resultados_cache WHERE id_batch = %s ORDER BY score_final DESC
        """, (id_batch,))
        return {"batch": batch, "resultados": cur.fetchall()}


@app.get("/batch/{id_batch}/logs")
def get_batch_logs(id_batch: str, nivel: Optional[str] = None):
    with get_db() as conn:
        cur = dict_cursor(conn)
        where, params = "id_batch = %s", [id_batch]
        if nivel:
            where += " AND nivel = %s"; params.append(nivel)
        cur.execute(f"SELECT paso, nivel, mensaje, detalle, created_at FROM fraude.batch_log WHERE {where} ORDER BY created_at", params)
        return {"id_batch": id_batch, "total": cur.rowcount, "logs": cur.fetchall()}


@app.get("/alertas")
def get_alertas(fecha: Optional[date] = None, nivel: Optional[str] = None, limit: int = Query(50, le=200)):
    with get_db() as conn:
        cur = dict_cursor(conn)
        where, params = ["rv.id IS NULL"], []
        if nivel:
            where.append("rc.nivel_alerta = %s"); params.append(nivel)
        else:
            where.append("rc.nivel_alerta IN ('ALTA','MEDIA')")
        if fecha:
            where.append("rc.fecha_batch = %s"); params.append(fecha)
        cur.execute(f"""
            SELECT rc.id, rc.fecha_batch, rc.cod_comercio, rc.nom_comercio, rc.tipo_documento,
                   rc.nombre_referencia_match, rc.marca_identificada, rc.tecnica_suplantacion,
                   rc.score_final, rc.nivel_alerta, rc.detalle_ia, rc.origen
            FROM fraude.resultados_cache rc
            LEFT JOIN fraude.revision_royc rv ON rc.id = rv.id_resultado_bq
            WHERE {' AND '.join(where)} ORDER BY rc.score_final DESC LIMIT %s
        """, params + [limit])
        return {"total": cur.rowcount, "alertas": cur.fetchall()}


@app.get("/traza/{cod_comercio}")
def get_traza(cod_comercio: str):
    with get_db() as conn:
        cur = dict_cursor(conn)
        cur.execute("SELECT * FROM fraude.v_traza_comercio WHERE cod_comercio = %s", (cod_comercio,))
        analisis = cur.fetchall()
        cur.execute("SELECT * FROM fraude.revision_royc WHERE cod_comercio = %s ORDER BY created_at DESC", (cod_comercio,))
        revisiones = cur.fetchall()
        cur.execute("SELECT * FROM fraude.incidencias WHERE cod_comercio = %s ORDER BY created_at DESC", (cod_comercio,))
        incidencias = cur.fetchall()
        cur.execute("SELECT * FROM fraude.audit_trail WHERE registro_id = %s ORDER BY created_at DESC", (cod_comercio,))
        audit = cur.fetchall()
        return {"cod_comercio": cod_comercio, "analisis": analisis, "revisiones": revisiones, "incidencias": incidencias, "audit": audit}


@app.get("/incidencias")
def list_incidencias(estado: str = "ABIERTA", severidad: Optional[str] = None, limit: int = Query(50, le=200)):
    with get_db() as conn:
        cur = dict_cursor(conn)
        where, params = ["estado = %s"], [estado]
        if severidad:
            where.append("severidad = %s"); params.append(severidad)
        cur.execute(f"SELECT * FROM fraude.incidencias WHERE {' AND '.join(where)} ORDER BY created_at DESC LIMIT %s", params + [limit])
        return {"total": cur.rowcount, "incidencias": cur.fetchall()}


@app.get("/stats")
def get_stats(dias: int = Query(30, le=365)):
    with get_db() as conn:
        cur = dict_cursor(conn)
        cur.execute("SELECT * FROM fraude.stats_diarias WHERE fecha >= CURRENT_DATE - %s * INTERVAL '1 day' ORDER BY fecha DESC", (dias,))
        stats = cur.fetchall()
        cur.execute("""
            SELECT COUNT(*) AS total_batches, COALESCE(SUM(alertas_alta),0) AS total_alta,
                   COALESCE(SUM(alertas_media),0) AS total_media,
                   COALESCE(SUM(confirmados_fraude),0) AS total_confirmados,
                   COALESCE(SUM(falsos_positivos),0) AS total_fp,
                   CASE WHEN COALESCE(SUM(confirmados_fraude),0) + COALESCE(SUM(falsos_positivos),0) > 0
                        THEN ROUND(SUM(confirmados_fraude)::numeric / (SUM(confirmados_fraude) + SUM(falsos_positivos)) * 100, 1)
                        ELSE 0 END AS precision_pct
            FROM fraude.stats_diarias WHERE fecha >= CURRENT_DATE - %s * INTERVAL '1 day'
        """, (dias,))
        return {"resumen": cur.fetchone(), "detalle": stats}


@app.get("/dashboard")
def dashboard():
    with get_db() as conn:
        cur = dict_cursor(conn)
        cur.execute("SELECT * FROM fraude.v_dashboard LIMIT 30")
        return {"batches": cur.fetchall()}


class RevisionInput(BaseModel):
    decision: str
    motivo: Optional[str] = None
    accion_tomada: Optional[str] = None
    revisado_por: str

@app.post("/alertas/{id_resultado}/revision")
def registrar_revision(id_resultado: str, body: RevisionInput):
    with get_db() as conn:
        cur = dict_cursor(conn)
        cur.execute("SELECT id, id_batch, cod_comercio, nom_comercio, nivel_alerta, score_final FROM fraude.resultados_cache WHERE id = %s", (id_resultado,))
        r = cur.fetchone()
        if not r:
            raise HTTPException(404, "Resultado no encontrado en cache")
        cur.execute("""
            INSERT INTO fraude.revision_royc (id_resultado_bq, id_batch, cod_comercio, nom_comercio, nivel_alerta, score_final, decision, motivo, accion_tomada, revisado_por)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) RETURNING id
        """, (id_resultado, r["id_batch"], r["cod_comercio"], r["nom_comercio"], r["nivel_alerta"], r["score_final"], body.decision, body.motivo, body.accion_tomada, body.revisado_por))
        rev_id = cur.fetchone()["id"]
        cur.execute("INSERT INTO fraude.audit_trail (tabla, accion, registro_id, campo_modificado, valor_nuevo, usuario) VALUES ('revision_royc','INSERT',%s,'decision',%s,%s)",
                    (r["cod_comercio"], body.decision, body.revisado_por))
        return {"ok": True, "revision_id": rev_id}


class IncidenciaInput(BaseModel):
    tipo: str
    severidad: str = "MEDIA"
    titulo: str
    detalle: Optional[str] = None
    cod_comercio: Optional[str] = None
    id_batch: Optional[str] = None

@app.post("/incidencias")
def crear_incidencia(body: IncidenciaInput):
    with get_db() as conn:
        cur = dict_cursor(conn)
        cur.execute("INSERT INTO fraude.incidencias (id_batch, tipo, severidad, titulo, detalle, cod_comercio) VALUES (%s,%s,%s,%s,%s,%s) RETURNING id",
                    (body.id_batch, body.tipo, body.severidad, body.titulo, body.detalle, body.cod_comercio))
        return {"ok": True, "incidencia_id": cur.fetchone()["id"]}


@app.post("/incidencias/{id}/resolver")
def resolver_incidencia(id: int, resuelta_por: str = Query(...)):
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("UPDATE fraude.incidencias SET estado='RESUELTA', resuelta_por=%s, fecha_resolucion=NOW() WHERE id=%s AND estado!='RESUELTA'", (resuelta_por, id))
        if cur.rowcount == 0:
            raise HTTPException(404, "No encontrada o ya resuelta")
        return {"ok": True, "id": id, "estado": "RESUELTA"}


@app.post("/sync")
def sync_bq_to_pg(fecha: Optional[date] = None):
    from google.cloud import bigquery
    bq = bigquery.Client(project=BQ_PROJECT)
    f = fecha or date.today()
    rows = list(bq.query(f"""
        SELECT * FROM `{BQ_PROJECT}.{BQ_DATASET}.resultado_analisis_fraude_nomcom`
        WHERE DATE(fecha_analisis) = '{f.isoformat()}'
    """).result())
    if not rows:
        return {"ok": True, "synced": 0, "msg": "Sin datos para esta fecha"}
    synced = _insert_cache_pg(rows, f)
    return {"ok": True, "synced": synced, "fecha": f.isoformat()}


from pipeline import run_pipeline as _run_pipeline

@app.post("/pipeline/run")
def pipeline_run(origen: str = Query("PIPELINE_DIARIO")):
    return _run_pipeline(get_db, origen)
