"""
main.py - Comparador v6.0
Endpoints:
 - GET /health
 - POST /compare-json (compatible con v5.3)
 - POST /reprocess (loop auto-mejora desde quality-gate)
 - GET /status/{job_id}
 - GET /results/{job_id}
"""
import os, logging, threading
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import List, Optional
import psycopg2

from engine_v6 import EngineV6, VERSION

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(name)s: %(message)s')
log = logging.getLogger("main")

app = FastAPI(title="Fraude Comparador v6.0", version=VERSION)
engine = EngineV6()
PG_DSN = os.getenv("PG_DSN", "")


class AfiliacionRecord(BaseModel):
    cod_comercio: str = Field("")
    nom_comercio: str
    ruc: Optional[str] = Field("")
    razon_social: Optional[str] = Field("")

class ReferenciaRecord(BaseModel):
    nombre: str
    ruc: Optional[str] = Field("")
    razon_social: Optional[str] = Field("")
    cod_comercio: Optional[str] = Field("")

class CompareRequest(BaseModel):
    afiliaciones: List[AfiliacionRecord]
    referencia: List[ReferenciaRecord]
    use_ia: bool = True
    threshold: float = 0.40
    ia_threshold: float = 0.30

class ReprocessRequest(BaseModel):
    cod_comercios: List[str]
    strict_mode: bool = True
    batch_id_origen: str


@app.get("/health")
def health():
    try:
        conn = psycopg2.connect(PG_DSN)
        conn.close()
        pg_ok = True
    except Exception:
        pg_ok = False
    return {
        "status": "ok",
        "version": VERSION,
        "model": "gpt-5.1-chat",
        "json_api": True,
        "pgvector": True,
        "whitelist": True,
        "pg": pg_ok
    }


def worker_thread(job_id):
    try:
        engine.run_comparison(job_id)
    except Exception as e:
        log.exception(f"Worker failed for {job_id}: {e}")
        try:
            conn = psycopg2.connect(PG_DSN)
            with conn.cursor() as cur:
                cur.execute("UPDATE fraude.jobs SET status='error', phase=%s WHERE job_id=%s",
                            (f"Error: {str(e)[:200]}", job_id))
                conn.commit()
            conn.close()
        except Exception:
            pass


@app.post("/compare-json")
async def compare_json(payload: CompareRequest):
    if not payload.afiliaciones:
        raise HTTPException(400, "afiliaciones vacio")
    if not payload.referencia:
        raise HTTPException(400, "referencia vacio")

    ref_records = [
        {"nombre": r.nombre, "ruc": r.ruc or "",
         "razon_social": r.razon_social or "",
         "cod_comercio": r.cod_comercio or ""}
        for r in payload.referencia if r.nombre.strip()
    ]
    afil_records = [
        {"nom_comercio": a.nom_comercio, "cod_comercio": a.cod_comercio or "",
         "ruc": a.ruc or "", "razon_social": a.razon_social or ""}
        for a in payload.afiliaciones if a.nom_comercio.strip()
    ]

    job_id = engine.create_job(payload.use_ia, payload.threshold, payload.ia_threshold)
    n_ref = engine.save_referencia(job_id, ref_records)
    n_afil = engine.save_afiliaciones(job_id, afil_records)

    threading.Thread(target=worker_thread, args=(job_id,), daemon=True).start()

    return {
        "job_id": job_id,
        "status": "processing",
        "referencia": n_ref,
        "afiliaciones": n_afil,
        "api": "json_v6",
        "engine": VERSION
    }


@app.post("/reprocess")
async def reprocess(req: ReprocessRequest):
    """
    Endpoint llamado por Quality-Gate cuando precision < 0.7 o F1 < 0.6.
    Reprocesa los cod_comercios dudosos con prompt estricto + umbrales más altos.
    """
    if not req.cod_comercios:
        raise HTTPException(400, "cod_comercios vacio")

    import os as _os
    _os.environ["STRICT_MODE"] = "1" if req.strict_mode else "0"

    conn = psycopg2.connect(PG_DSN)
    with conn.cursor() as cur:
        cur.execute("""
            SELECT cod_comercio, nom_comercio, ruc, razon_social
            FROM fraude.upload_afiliaciones
            WHERE cod_comercio = ANY(%s)
        """, (req.cod_comercios,))
        afils = [{"cod_comercio": r[0], "nom_comercio": r[1], "ruc": r[2] or "", "razon_social": r[3] or ""}
                 for r in cur.fetchall()]

        cur.execute("""
            SELECT DISTINCT nombre, ruc FROM fraude.upload_referencia
            WHERE job_id IN (
                SELECT job_id FROM fraude.jobs
                WHERE job_id LIKE %s ORDER BY created_at DESC LIMIT 1
            )
        """, (f"%{req.batch_id_origen}%",))
        refs = [{"nombre": r[0], "ruc": r[1] or ""} for r in cur.fetchall()]
    conn.close()

    if not afils:
        raise HTTPException(404, "No se encontraron afiliaciones")

    job_id = engine.create_job(use_ia=True, threshold=0.5, ia_threshold=0.4)
    engine.save_referencia(job_id, refs)
    engine.save_afiliaciones(job_id, afils)
    threading.Thread(target=worker_thread, args=(job_id,), daemon=True).start()

    return {
        "job_id": job_id,
        "status": "reprocessing",
        "afiliaciones": len(afils),
        "strict_mode": req.strict_mode,
        "trigger": "quality_gate_loop"
    }


@app.get("/status/{job_id}")
def status(job_id: str):
    conn = psycopg2.connect(PG_DSN)
    with conn.cursor() as cur:
        cur.execute("""
            SELECT status, phase, total, processed, matches_total,
                   matches_alta, matches_media, matches_baja,
                   elapsed_ms, engine_version
            FROM fraude.jobs WHERE job_id=%s
        """, (job_id,))
        row = cur.fetchone()
    conn.close()
    if not row:
        raise HTTPException(404, "job not found")
    return {
        "job_id": job_id, "status": row[0], "phase": row[1],
        "total": row[2] or 0, "processed": row[3] or 0,
        "matches_total": row[4] or 0, "matches_alta": row[5] or 0,
        "matches_media": row[6] or 0, "matches_baja": row[7] or 0,
        "elapsed_ms": row[8] or 0, "engine_version": row[9]
    }


@app.get("/results/{job_id}")
def results(job_id: str, limit: int = 1000):
    conn = psycopg2.connect(PG_DSN)
    with conn.cursor() as cur:
        cur.execute("""
            SELECT cod_comercio, nom_comercio, nombre_referencia_match,
                   score_sintactico, score_semantico, score_ia, score_final,
                   nivel_alerta, tecnica_suplantacion, marca_identificada,
                   es_fraude_ia, es_agente_autorizado, whitelist_reason,
                   detalle_ia
            FROM fraude.resultados WHERE job_id=%s LIMIT %s
        """, (job_id, limit))
        cols = [d[0] for d in cur.description]
        rows = [dict(zip(cols, r)) for r in cur.fetchall()]
    conn.close()
    return {"job_id": job_id, "count": len(rows), "results": rows}
