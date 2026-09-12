"""
Agente D: fraude-evolver
Corre lunes 8 AM. Analiza últimos 7 días y sugiere mejoras:
- Falsos positivos recurrentes → ajustar threshold por rubro
- Marcas nuevas frecuentes → agregar a referencia
- Agentes autorizados repetidos → agregar a whitelist
Genera sugerencias en tabla fraude.sugerencias_mejora (NO aplica cambios automáticos).
"""
import os, json, logging
from datetime import date, datetime, timedelta
from fastapi import FastAPI
from google.cloud import bigquery
import requests

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("evolver")
app = FastAPI(title="Fraude Evolver v1", version="1.0.0")

BQ_PROJECT = os.getenv("BQ_PROJECT", "dev-izipay-advanced-analytics")
BQ_DATASET = os.getenv("BQ_DATASET", "raw_riesgo_operativo")
GPT51_ENDPOINT = os.getenv("GPT51_ENDPOINT")
GPT51_API_KEY = os.getenv("GPT51_API_KEY", "")
GPT51_DEPLOYMENT = os.getenv("GPT51_DEPLOYMENT", "gpt-5.1-chat")
API_VERSION = "2025-04-01-preview"

bq = bigquery.Client(project=BQ_PROJECT)


def call_gpt51(system, user, max_tokens=2000):
    url = f"{GPT51_ENDPOINT}/openai/responses?api-version={API_VERSION}"
    payload = {"model": GPT51_DEPLOYMENT,
               "input": [{"role": "system", "content": system}, {"role": "user", "content": user}],
               "max_output_tokens": max_tokens, "temperature": 0.1}
    r = requests.post(url, json=payload, headers={"Content-Type": "application/json", "api-key": GPT51_API_KEY}, timeout=120)
    r.raise_for_status()
    data = r.json()
    text = data.get("output_text") or data["output"][0]["content"][0]["text"]
    if text.strip().startswith("```"):
        text = text.split("```")[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.strip().rstrip("`").strip()
    return json.loads(text)


@app.get("/health")
def health():
    return {"status": "ok", "version": "1.0.0"}


@app.post("/weekly-analysis")
def weekly_analysis():
    fecha_fin = date.today()
    fecha_inicio = fecha_fin - timedelta(days=7)

    fp_query = f"""
    SELECT marca_suplantada, COUNT(*) n,
           ARRAY_AGG(STRUCT(nom_comercio, razonamiento) LIMIT 3) ejemplos
    FROM `{BQ_PROJECT}.{BQ_DATASET}.fraude_validaciones`
    WHERE DATE(fecha_validacion) BETWEEN '{fecha_inicio}' AND '{fecha_fin}'
      AND veredicto = 'FALSO_POSITIVO'
    GROUP BY 1
    HAVING n >= 3
    ORDER BY n DESC
    LIMIT 20
    """
    fp_recurrentes = [dict(r) for r in bq.query(fp_query).result()]

    ag_query = f"""
    SELECT marca_suplantada, COUNT(*) n, ARRAY_AGG(cod_comercio LIMIT 5) codigos
    FROM `{BQ_PROJECT}.{BQ_DATASET}.fraude_validaciones`
    WHERE DATE(fecha_validacion) BETWEEN '{fecha_inicio}' AND '{fecha_fin}'
      AND veredicto = 'AGENTE_AUTORIZADO_PROBABLE'
    GROUP BY 1
    HAVING n >= 2
    LIMIT 30
    """
    agentes_repetidos = [dict(r) for r in bq.query(ag_query).result()]

    metricas_query = f"""
    SELECT fecha, precision, recall, f1, tp, fp
    FROM `{BQ_PROJECT}.{BQ_DATASET}.metricas_diarias`
    WHERE fecha BETWEEN '{fecha_inicio}' AND '{fecha_fin}'
    ORDER BY fecha
    """
    metricas_semana = [dict(r) for r in bq.query(metricas_query).result()]

    system = """Eres analista senior de sistemas antifraude. Analizas 7 días de resultados 
y generas sugerencias accionables para mejorar precisión del pipeline.

Respondes SOLO en JSON estricto:
{
  "resumen_ejecutivo": "2-3 líneas",
  "tendencia_metricas": "mejora|estable|empeora",
  "sugerencias": [
    {
      "tipo": "whitelist_add" | "threshold_adjust" | "prompt_change" | "reference_add" | "reference_remove",
      "prioridad": "alta|media|baja",
      "descripcion": "qué hacer",
      "justificacion": "por qué",
      "sql_o_accion": "comando concreto o descripción técnica"
    }
  ],
  "marcas_problemáticas": ["marca1", "marca2"]
}"""

    user = f"""Análisis semana {fecha_inicio} a {fecha_fin}:

FALSOS POSITIVOS RECURRENTES (>=3):
{json.dumps(fp_recurrentes, ensure_ascii=False, indent=2, default=str)}

AGENTES AUTORIZADOS REPETIDOS (>=2):
{json.dumps(agentes_repetidos, ensure_ascii=False, indent=2, default=str)}

MÉTRICAS DIARIAS:
{json.dumps(metricas_semana, ensure_ascii=False, indent=2, default=str)}

Genera sugerencias accionables en JSON."""

    try:
        analysis = call_gpt51(system, user)
    except Exception as e:
        log.error(f"GPT evolver fallo: {e}")
        return {"ok": False, "error": str(e)}

    sugerencias_rows = []
    for s in analysis.get("sugerencias", []):
        sugerencias_rows.append({
            "fecha_generada": date.today().isoformat(),
            "semana_inicio": fecha_inicio.isoformat(),
            "semana_fin": fecha_fin.isoformat(),
            "tipo": s.get("tipo"),
            "prioridad": s.get("prioridad"),
            "descripcion": s.get("descripcion"),
            "justificacion": s.get("justificacion"),
            "sql_o_accion": s.get("sql_o_accion"),
            "estado": "pendiente_revision",
            "modelo": GPT51_DEPLOYMENT,
            "timestamp": datetime.utcnow().isoformat()
        })

    if sugerencias_rows:
        target = f"{BQ_PROJECT}.{BQ_DATASET}.sugerencias_mejora"
        bq.insert_rows_json(target, sugerencias_rows)

    return {
        "ok": True,
        "periodo": f"{fecha_inicio} - {fecha_fin}",
        "resumen_ejecutivo": analysis.get("resumen_ejecutivo"),
        "tendencia": analysis.get("tendencia_metricas"),
        "total_sugerencias": len(sugerencias_rows),
        "marcas_problematicas": analysis.get("marcas_problemáticas", []),
        "falsos_positivos_recurrentes": len(fp_recurrentes),
        "agentes_repetidos": len(agentes_repetidos)
    }
