"""
Agente B: fraude-quality-gate
Calcula precision/recall/F1 del día vs ground truth.
Si precision<0.7 OR F1<0.6 → dispara reprocess en comparador v6.0.
Corre 12:30 PM después del validator.
"""
import os, json, logging
from datetime import date, datetime
from fastapi import FastAPI
from google.cloud import bigquery
import requests

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("quality_gate")
app = FastAPI(title="Fraude Quality Gate v1", version="1.0.0")

BQ_PROJECT = os.getenv("BQ_PROJECT", "dev-izipay-advanced-analytics")
BQ_DATASET = os.getenv("BQ_DATASET", "raw_riesgo_operativo")
COMPARATOR_URL = os.getenv("COMPARATOR_V6_URL", "https://fraude-comparador-322392286721.us-central1.run.app")
PRECISION_THRESHOLD = float(os.getenv("PRECISION_THRESHOLD", "0.7"))
F1_THRESHOLD = float(os.getenv("F1_THRESHOLD", "0.6"))

bq = bigquery.Client(project=BQ_PROJECT)


def compute_metrics():
    query = f"""
    WITH
    validaciones AS (
      SELECT cod_comercio, veredicto, nivel_sistema
      FROM `{BQ_PROJECT}.{BQ_DATASET}.fraude_validaciones`
      WHERE DATE(fecha_validacion) = CURRENT_DATE()
    ),
    stats AS (
      SELECT
        COUNT(*) AS total,
        COUNTIF(nivel_sistema IN ('ALTA','MEDIA') AND veredicto = 'FRAUDE_CONFIRMADO') AS tp,
        COUNTIF(nivel_sistema IN ('ALTA','MEDIA') AND veredicto IN ('FALSO_POSITIVO','AGENTE_AUTORIZADO_PROBABLE')) AS fp,
        COUNTIF(veredicto = 'REVISAR_MANUAL') AS uncertain
      FROM validaciones
    )
    SELECT * FROM stats
    """
    for row in bq.query(query).result():
        tp, fp, uncertain, total = row.tp, row.fp, row.uncertain, row.total
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0.0
        recall = tp / total if total > 0 else 0.0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0.0
        return {"total": total, "tp": tp, "fp": fp, "uncertain": uncertain,
                "precision": round(precision, 3), "recall": round(recall, 3), "f1": round(f1, 3)}
    return {}


def get_dudosos():
    """Retorna los cod_comercios marcados como FALSO_POSITIVO por el validator"""
    query = f"""
    SELECT cod_comercio, nom_comercio, nivel_sistema, veredicto
    FROM `{BQ_PROJECT}.{BQ_DATASET}.fraude_validaciones`
    WHERE DATE(fecha_validacion) = CURRENT_DATE()
      AND veredicto IN ('FALSO_POSITIVO', 'AGENTE_AUTORIZADO_PROBABLE')
    LIMIT 50
    """
    return [dict(row) for row in bq.query(query).result()]


@app.get("/health")
def health():
    return {"status": "ok", "version": "1.0.0",
            "thresholds": {"precision": PRECISION_THRESHOLD, "f1": F1_THRESHOLD}}


@app.post("/evaluate")
def evaluate():
    metrics = compute_metrics()
    log.info(f"Metrics del día: {metrics}")
    target = f"{BQ_PROJECT}.{BQ_DATASET}.metricas_diarias"
    bq.insert_rows_json(target, [{
        "fecha": date.today().isoformat(),
        "precision": metrics.get("precision", 0),
        "recall": metrics.get("recall", 0),
        "f1": metrics.get("f1", 0),
        "tp": metrics.get("tp", 0),
        "fp": metrics.get("fp", 0),
        "total_evaluado": metrics.get("total", 0),
        "modelo_usado": "gpt-5.1-chat",
        "version_comparador": "v6.0.0",
        "timestamp": datetime.utcnow().isoformat()
    }])

    necesita_reproceso = (metrics.get("precision", 1) < PRECISION_THRESHOLD or
                         metrics.get("f1", 1) < F1_THRESHOLD)

    if not necesita_reproceso:
        return {"ok": True, "metrics": metrics, "reprocess_triggered": False,
                "reason": "Métricas dentro de umbral"}

    dudosos = get_dudosos()
    if not dudosos:
        return {"ok": True, "metrics": metrics, "reprocess_triggered": False,
                "reason": "No hay casos dudosos para reprocesar"}

    try:
        r = requests.post(f"{COMPARATOR_URL}/reprocess", json={
            "cod_comercios": [d["cod_comercio"] for d in dudosos],
            "strict_mode": True,
            "batch_id_origen": date.today().isoformat()
        }, timeout=30)
        r.raise_for_status()
        reprocess_info = r.json()
    except Exception as e:
        log.error(f"Reprocess trigger fallo: {e}")
        return {"ok": False, "metrics": metrics, "reprocess_triggered": False, "error": str(e)}

    return {
        "ok": True, "metrics": metrics,
        "reprocess_triggered": True,
        "dudosos_reprocesados": len(dudosos),
        "reprocess_job": reprocess_info.get("job_id")
    }
