"""
pipeline.py — Motor del pipeline diario
Lee de BQ → genera Excel en memoria → sube a fraude-comparador → poll → escribe BQ + PG
"""
import os
import io
import time
import uuid
import json
import logging
import requests
import openpyxl
import re
def _clean(s):
    if not s: return ""
    return re.sub(r"[\x00-\x08\x0b-\x0c\x0e-\x1f\x7f]", "", str(s))

def _es_vacio(s):
    return not s or str(s).strip().lower() in ("", "null", "none", "nan")
from datetime import date, datetime
from google.cloud import bigquery

log = logging.getLogger(__name__)

BQ_JOB_PROJECT = os.getenv("BQ_JOB_PROJECT", "dev-izipay-data-storage")
BQ_DATA_PROJECT = os.getenv("BQ_DATA_PROJECT", "dev-izipay-data-storage")
BQ_DATASET = os.getenv("BQ_DATASET", "raw_riesgo_operativo")
BQ_DATASET_OUTPUT = os.getenv("BQ_DATASET_OUTPUT", "raw_riesgo_operativo")
FRAUDE_API = "https://fraude-comparador-dl7olq7kiq-uc.a.run.app"
ALERT_EMAIL_URL = "<<LOGIC_APP_URL>>"
ALERT_EMAILS = ["<<ALERT_EMAIL_1>>", "<<ALERT_EMAIL_2>>", "<<ALERT_EMAIL_3>>"]


def run_pipeline(pg_conn_func, origen="PIPELINE_DIARIO"):
    bq = bigquery.Client(project=BQ_JOB_PROJECT)
    t0 = time.time()
    batch_id = f"pipe_{date.today().isoformat()}_{uuid.uuid4().hex[:8]}"
    hoy = date.today()

    _pg_exec(pg_conn_func, """
        INSERT INTO fraude.batch_runs (id_batch, fecha_batch, origen, estado, iniciado_por)
        VALUES (%s,%s,%s,'EN_PROCESO',%s)
    """, (batch_id, hoy, origen, origen))
    _log(pg_conn_func, batch_id, "INICIO", f"Pipeline iniciado — {origen}")

    try:
        afil = _leer_afiliaciones(bq)
        _log(pg_conn_func, batch_id, "LECTURA_BQ", f"{len(afil)} afiliaciones pendientes")
        if not afil:
            _finalizar(pg_conn_func, batch_id, t0, 0, 0, 0, 0, 0, 0)
            return {"ok": True, "batch_id": batch_id, "total": 0, "msg": "Sin afiliaciones nuevas"}

        ref = _leer_referencia(bq)
        _log(pg_conn_func, batch_id, "LECTURA_BQ", f"{len(ref)} registros referencia activos")

        xlsx_afil = _generar_excel_afiliaciones(afil)
        xlsx_ref = _generar_excel_referencia(ref)
        _log(pg_conn_func, batch_id, "EXCEL", "Excel generados en memoria")

        job_id = _subir_a_comparador(xlsx_afil, xlsx_ref)
        _log(pg_conn_func, batch_id, "API_UPLOAD", f"Job creado: {job_id}")

        _esperar_job(pg_conn_func, batch_id, job_id)

        resultados = _obtener_resultados(job_id)
        _log(pg_conn_func, batch_id, "API_RESULTS", f"{len(resultados)} resultados obtenidos")

        alta, media, baja, skipped = _escribir_resultados(
            bq, pg_conn_func, batch_id, hoy, afil, resultados, origen
        )

        # Auditoria: descartados (IA + pre-filtro) a tabla aparte. No bloquea el batch.
        try:
            descartados = _obtener_descartados(job_id)
            n_desc = _escribir_descartados(bq, batch_id, hoy, afil, descartados, origen)
            _log(pg_conn_func, batch_id, "API_DESCARTADOS", f"{n_desc} descartados auditados")
        except Exception as e:
            log.warning(f"Auditoria descartados error: {e}")
            _log(pg_conn_func, batch_id, "API_DESCARTADOS", f"Error auditoria: {str(e)[:200]}", nivel="WARN")

        duracion = int(time.time() - t0)
        _finalizar(pg_conn_func, batch_id, t0, len(afil), len(resultados), skipped, alta, media, baja)

        _log(pg_conn_func, batch_id, "FIN",
             f"Completado en {duracion}s — {alta} ALTA, {media} MEDIA, {baja} BAJA, {skipped} skip")

        if alta + media > 0:
            _enviar_alertas(pg_conn_func, batch_id, resultados)

        return {
            "ok": True, "batch_id": batch_id, "job_id": job_id,
            "total_input": len(afil), "total_resultados": len(resultados),
            "alertas": {"alta": alta, "media": media, "baja": baja, "skip": skipped},
            "duracion_seg": duracion
        }

    except Exception as e:
        log.error(f"Pipeline error: {e}", exc_info=True)
        _log(pg_conn_func, batch_id, "ERROR", str(e)[:500], nivel="ERROR")
        _pg_exec(pg_conn_func, """
            UPDATE fraude.batch_runs SET estado='ERROR', error_message=%s, finished_at=NOW()
            WHERE id_batch=%s
        """, (str(e)[:500], batch_id))
        _pg_exec(pg_conn_func, """
            INSERT INTO fraude.incidencias (id_batch, tipo, severidad, titulo, detalle)
            VALUES (%s,'PIPELINE_ERROR','ALTA','Error en pipeline diario',%s)
        """, (batch_id, str(e)[:1000]))
        raise


def _leer_afiliaciones(bq):
    query = f"""
        SELECT cod_comercio, nom_comercio, razon_social,
               representante_legal, tipo_documento, fecha_apertura_comercio
        FROM `{BQ_DATA_PROJECT}.{BQ_DATASET}.lista_afiliaciones_analizar`
        WHERE LENGTH(TRIM(nom_comercio)) >= 3
          AND NOT REGEXP_CONTAINS(nom_comercio, r'^[0-9]+$')
          AND TRIM(nom_comercio) != ''
    """
    return [dict(row) for row in bq.query(query).result()]


def _leer_referencia(bq):
    query = f"""
        SELECT nombre_comercial, razon_social, origen
        FROM `{BQ_DATA_PROJECT}.{BQ_DATASET}.lista_referencia_nomcom`
        WHERE LENGTH(TRIM(nombre_comercial)) >= 3
          AND NOT REGEXP_CONTAINS(nombre_comercial, r'^[0-9]+$')
          AND TRIM(nombre_comercial) != ''
    """
    return [dict(row) for row in bq.query(query).result()]


def _generar_excel_afiliaciones(afil):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Afiliaciones"
    ws.append(["nombre_comercial", "ruc", "razon_social", "cod_comercio"])
    for a in afil:
        nombre = _clean(a.get("nom_comercio", ""))
        if _es_vacio(nombre):
            continue
        ws.append([
            nombre,
            "",
            _clean(a.get("razon_social", "")),
            _clean(a.get("cod_comercio", "")),
        ])
    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    return buf


def _generar_excel_referencia(ref):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Referencia"
    ws.append(["nombre_comercial", "ruc", "razon_social", "cod_comercio"])
    for r in ref:
        nombre = _clean(r.get("nombre_comercial", ""))
        if _es_vacio(nombre):
            continue
        ws.append([
            nombre,
            "",
            _clean(r.get("razon_social", "")),
            "",
        ])
    buf = io.BytesIO()
    wb.save(buf)
    buf.seek(0)
    return buf


def _subir_a_comparador(xlsx_afil, xlsx_ref):
    resp = requests.post(
        f"{FRAUDE_API}/upload-and-compare",
        files={
            "afiliaciones": ("afiliaciones.xlsx", xlsx_afil, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
            "referencia": ("referencia.xlsx", xlsx_ref, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"),
        },
        timeout=600
    )
    resp.raise_for_status()
    data = resp.json()
    job_id = data.get("job_id") or data.get("id") or data.get("task_id")
    if not job_id:
        raise RuntimeError(f"No job_id en respuesta: {data}")
    return job_id


def _esperar_job(pg_conn_func, batch_id, job_id, timeout=900, interval=5):
    inicio = time.time()
    while time.time() - inicio < timeout:
        resp = requests.get(f"{FRAUDE_API}/status/{job_id}", timeout=30)
        resp.raise_for_status()
        status = resp.json()
        estado = status.get("status") or status.get("estado") or ""
        progreso = status.get("progress") or status.get("progreso") or 0

        if estado.lower() in ("completed", "done", "completado", "finished"):
            _log(pg_conn_func, batch_id, "API_STATUS", f"Job completado — {progreso}%")
            return
        elif estado.lower() in ("error", "failed", "fallido"):
            raise RuntimeError(f"Job {job_id} falló: {status}")

        if int(time.time() - inicio) % 30 == 0:
            _log(pg_conn_func, batch_id, "API_STATUS", f"Procesando... {progreso}% ({estado})")

        time.sleep(interval)

    raise TimeoutError(f"Job {job_id} no terminó en {timeout}s")


def _obtener_resultados(job_id):
    resp = requests.get(f"{FRAUDE_API}/results/{job_id}", timeout=600)
    resp.raise_for_status()
    data = resp.json()
    if isinstance(data, list):
        return data
    return data.get("resultados") or data.get("results") or data.get("data") or []


def _obtener_descartados(job_id):
    resp = requests.get(f"{FRAUDE_API}/descartados/{job_id}?limit=100000", timeout=600)
    resp.raise_for_status()
    data = resp.json()
    return data if isinstance(data, list) else (data.get("descartados") or [])


def _escribir_descartados(bq, batch_id, hoy, afil_orig, descartados, origen):
    if not descartados:
        return 0
    afil_map = {a["cod_comercio"]: a for a in afil_orig}
    rows = []
    for r in descartados:
        cod = r.get("cod_comercio", "")
        a = afil_map.get(cod, {})
        rows.append({
            "id": str(uuid.uuid4()),
            "id_batch": batch_id,
            "fecha_batch": hoy.isoformat(),
            "cod_comercio": cod,
            "nom_comercio": r.get("nom_comercio", ""),
            "nom_comercio_norm": r.get("nom_comercio_norm"),
            "tipo_documento": a.get("tipo_documento"),
            "fecha_apertura_comercio": str(a.get("fecha_apertura_comercio", "")) or None,
            "nombre_referencia_match": r.get("nombre_referencia_match"),
            "origen_referencia": r.get("origen_referencia"),
            "score_sintactico": r.get("score_sintactico"),
            "score_semantico": r.get("score_semantico"),
            "score_ia": r.get("score_ia"),
            "score_final": r.get("score_final"),
            "nivel_alerta": r.get("nivel_alerta") or "DESCARTADO",
            "metodo_deteccion": r.get("metodo_deteccion"),
            "detalle_ia": r.get("detalle_ia"),
            "razon_social": a.get("razon_social"),
            "representante_legal": a.get("representante_legal"),
            "origen": origen,
            "procesado_por": "fraude-comparador-v5.6",
            "fecha_analisis": datetime.utcnow().isoformat(),
        })
    table_ref = bq.dataset(BQ_DATASET_OUTPUT, project=BQ_JOB_PROJECT).table("auditoria_descartados_fraude_nomcom")
    errors = bq.insert_rows_json(table_ref, rows)
    if errors:
        log.error(f"BQ audit insert errors: {errors[:3]}")
    return len(rows)


def _escribir_resultados(bq, pg_conn_func, batch_id, hoy, afil_orig, resultados, origen):
    afil_map = {a["cod_comercio"]: a for a in afil_orig}
    bq_rows = []
    pg_rows = []
    alta = media = baja = skipped = 0

    for r in resultados:
        rid = str(uuid.uuid4())
        cod = r.get("cod_comercio", "")
        afil_data = afil_map.get(cod, {})

        row = {
            "id": rid,
            "id_batch": batch_id,
            "fecha_batch": hoy.isoformat(),
            "cod_comercio": cod,
            "nom_comercio": r.get("nom_comercio", ""),
            "nom_comercio_norm": r.get("nom_comercio_norm"),
            "tipo_documento": afil_data.get("tipo_documento"),
            "fecha_apertura_comercio": str(afil_data.get("fecha_apertura_comercio", "")) or None,
            "nombre_referencia_match": r.get("nombre_referencia_match"),
            "origen_referencia": r.get("origen_referencia"),
            "score_sintactico": r.get("score_sintactico") or r.get("score_fuzzy"),
            "score_semantico": r.get("score_semantico") or r.get("score_fonetico"),
            "score_ia": r.get("score_ia"),
            "score_final": r.get("score_final") or r.get("score"),
            "nivel_alerta": r.get("nivel_alerta") or r.get("alerta"),
            "metodo_deteccion": r.get("metodo_deteccion"),
            "detalle_ia": r.get("detalle_ia") or r.get("detalle"),
            "origen": origen,
            "fecha_analisis": datetime.utcnow().isoformat(),
            "tecnica_suplantacion": r.get("tecnica_suplantacion"),
            "marca_identificada": r.get("marca_identificada"),
            "es_fraude_ia": r.get("es_fraude") or r.get("es_fraude_ia"),
            "fase_skip": r.get("fase_skip") or r.get("skip_reason"),
            "procesado_por": "fraude-comparador-v5.1",
            "razon_social": afil_data.get("razon_social"),
            "representante_legal": afil_data.get("representante_legal"),
        }

        nivel = (row["nivel_alerta"] or "").upper()
        if row["fase_skip"]:
            skipped += 1
        elif nivel == "ALTA":
            alta += 1
        elif nivel == "MEDIA":
            media += 1
        elif nivel == "BAJA":
            baja += 1

        bq_rows.append(row)
        pg_rows.append(row)

    if bq_rows:
        table_ref = bq.dataset(BQ_DATASET_OUTPUT, project=BQ_JOB_PROJECT).table("resultado_analisis_fraude_nomcom")
        errors = bq.insert_rows_json(table_ref, bq_rows)
        if errors:
            log.error(f"BQ insert errors: {errors[:3]}")

    if pg_rows:
        with pg_conn_func() as conn:
            cur = conn.cursor()
            for row in pg_rows:
                cur.execute("""
                    INSERT INTO fraude.resultados_cache
                    (id, id_batch, fecha_batch, cod_comercio, nom_comercio, nom_comercio_norm,
                     tipo_documento, fecha_apertura_comercio, nombre_referencia_match, origen_referencia,
                     score_sintactico, score_semantico, score_ia, score_final, nivel_alerta, metodo_deteccion,
                     tecnica_suplantacion, marca_identificada, detalle_ia, fase_skip, origen, fecha_analisis)
                    VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                    ON CONFLICT (id) DO NOTHING
                """, (
                    row["id"], row["id_batch"], row["fecha_batch"], row["cod_comercio"],
                    row["nom_comercio"], row["nom_comercio_norm"], row["tipo_documento"],
                    row["fecha_apertura_comercio"], row["nombre_referencia_match"],
                    row["origen_referencia"], row["score_sintactico"], row["score_semantico"],
                    row["score_ia"], row["score_final"], row["nivel_alerta"], row["metodo_deteccion"],
                    row["tecnica_suplantacion"], row["marca_identificada"], row["detalle_ia"],
                    row["fase_skip"], row["origen"], row["fecha_analisis"]
                ))

    return alta, media, baja, skipped


def _finalizar(pg_conn_func, batch_id, t0, total_input, total_eval, skipped, alta, media, baja):
    duracion = int(time.time() - t0)
    _pg_exec(pg_conn_func, """
        UPDATE fraude.batch_runs SET estado='COMPLETADO', total_input=%s, total_evaluate=%s,
          total_skip=%s, alertas_alta=%s, alertas_media=%s, alertas_baja=%s,
          duracion_seg=%s, finished_at=NOW()
        WHERE id_batch=%s
    """, (total_input, total_eval, skipped, alta, media, baja, duracion, batch_id))
    hoy = date.today()
    _pg_exec(pg_conn_func, """
        INSERT INTO fraude.stats_diarias (fecha, total_afiliaciones, total_evaluados,
          total_skipped, alertas_alta, alertas_media, alertas_baja, duracion_seg)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON CONFLICT (fecha) DO UPDATE SET
          total_evaluados=EXCLUDED.total_evaluados, alertas_alta=EXCLUDED.alertas_alta,
          alertas_media=EXCLUDED.alertas_media, alertas_baja=EXCLUDED.alertas_baja,
          duracion_seg=EXCLUDED.duracion_seg
    """, (hoy, total_input, total_eval, skipped, alta, media, baja, duracion))


def _enviar_alertas(pg_conn_func, batch_id, resultados):
    alertas = [r for r in resultados
               if (r.get("nivel_alerta") or "").upper() in ("ALTA", "MEDIA")]
    if not alertas:
        return
    _log(pg_conn_func, batch_id, "EMAIL", f"Enviando {len(alertas)} alertas")
    tabla = "<table border='1' cellpadding='4'><tr><th>Comercio</th><th>Match</th><th>Score</th><th>Alerta</th></tr>"
    for a in sorted(alertas, key=lambda x: x.get("score_final") or x.get("score") or 0, reverse=True):
        score = a.get("score_final") or a.get("score") or 0
        nivel = a.get("nivel_alerta") or ""
        c = "#ff4444" if nivel.upper() == "ALTA" else "#ff8800"
        tabla += f"<tr><td>{a.get('nom_comercio','')}</td><td>{a.get('nombre_referencia_match','')}</td>"
        tabla += f"<td>{score:.2f}</td><td style='color:{c}'>{nivel}</td></tr>"
    tabla += "</table>"
    for email in ALERT_EMAILS:
        try:
            requests.post(ALERT_EMAIL_URL, json={
                "title": f"Fraude NomCom — {len(alertas)} alertas ({date.today().isoformat()})",
                "message": f"Batch: {batch_id}<br>{tabla}",
                "color": "red", "email": email
            }, timeout=10)
        except Exception as e:
            log.warning(f"Alert email error {email}: {e}")


def _log(pg_conn_func, batch_id, paso, mensaje, nivel="INFO"):
    try:
        _pg_exec(pg_conn_func, """
            INSERT INTO fraude.batch_log (id_batch, paso, nivel, mensaje)
            VALUES (%s,%s,%s,%s)
        """, (batch_id, paso, nivel, mensaje))
    except:
        pass


def _pg_exec(pg_conn_func, sql, params=None):
    with pg_conn_func() as conn:
        cur = conn.cursor()
        cur.execute(sql, params)
