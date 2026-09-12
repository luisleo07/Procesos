"""
engine_v6.py - Motor Junta Médica v6.0
Mejoras vs v5.3:
1. GPT-5.1 Responses API en vez de GPT-4.1 Chat Completions
2. pgvector rerank semántico (e5-base 768d) en vez de solo fuzzy
3. Whitelist validator de agentes autorizados (reduce FP)
4. Few-shot context con top-5 casos históricos validados
5. Prompt estructurado con CoT y criterios explícitos
"""
import os, json, logging, time, uuid, threading
from datetime import datetime
import psycopg2, psycopg2.extras
from rapidfuzz import fuzz, process as rfprocess
from rapidfuzz.distance import JaroWinkler

from gpt51_client import GPT51Client
from embeddings import save_marca_embeddings, semantic_rerank, embed_text
from whitelist import check_authorized_agent

log = logging.getLogger(__name__)

PG_DSN = os.getenv("PG_DSN", "")
VERSION = "6.0.0"
VECTOR_TOPK = int(os.getenv("VECTOR_TOPK", "10"))
FUZZY_TOPK = int(os.getenv("FUZZY_TOPK", "10"))


SYSTEM_PROMPT_V6 = """Eres un analista SENIOR de fraude de Izipay (procesadora de pagos de Perú). 
Tu tarea es evaluar si un nombre comercial SUPLANTA intencionalmente una marca registrada.

CRITERIOS EN ORDEN DE PRIORIDAD:
1. Si el nombre es EXACTAMENTE una marca registrada famosa (Apple, Disney, Movistar) sin relación legítima con la empresa → FRAUDE ALTO
2. Si el nombre contiene la marca + agregados geográficos o descriptivos y NO parece agente autorizado → FRAUDE ALTO  
3. Si el nombre es similar fonéticamente pero es un término genérico (CASA BLANCA, BOTICA) → FALSO POSITIVO
4. Si hay patrón de distribuidor autorizado (EQUIPOS, DISTRIBUIDOR, AGENTE) + rubro compatible → AGENTE AUTORIZADO PROBABLE
5. Si la marca referenciada NO está en el parque Izipay ni es marca famosa conocida → NO ES SUPLANTACIÓN

Responde SIEMPRE en JSON estricto con estos campos:
{
  "nivel": "ALTA" | "MEDIA" | "BAJA" | "DESCARTAR",
  "score_ia": 0-100 (entero),
  "tecnica": "nombre_exacto" | "fonetica" | "insercion" | "visual" | "ninguna",
  "marca_identificada": "nombre normalizado de la marca suplantada o null",
  "es_fraude": true | false,
  "es_agente_autorizado_probable": true | false,
  "razonamiento": "2-3 líneas explicando decisión"
}

NIVELES:
- ALTA: score_ia >= 80, técnica clara, marca famosa verificable
- MEDIA: score_ia 60-79, similitud alta pero dudas
- BAJA: score_ia 30-59, caso débil
- DESCARTAR: score_ia < 30 o es término genérico"""


class EngineV6:
    def __init__(self, pg_dsn=None):
        self.pg_dsn = pg_dsn or PG_DSN
        self.gpt = GPT51Client()
        log.info(f"EngineV6 v{VERSION} initialized")

    def _conn(self):
        return psycopg2.connect(self.pg_dsn)

    def create_job(self, use_ia=True, threshold=0.4, ia_threshold=0.3):
        job_id = f"cmpv6_{datetime.now().strftime('%Y%m%d_%H%M%S')}_{uuid.uuid4().hex[:6]}"
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO fraude.jobs (job_id, status, phase, use_ia, threshold, ia_threshold, engine_version)
                    VALUES (%s, 'queued', 'Inicializado', %s, %s, %s, %s)
                """, (job_id, use_ia, threshold, ia_threshold, VERSION))
                conn.commit()
        return job_id

    def save_referencia(self, job_id, records):
        rows = []
        for r in records:
            nombre = r.get("nombre", "") or r.get("nom_comercio", "") or ""
            if not nombre.strip():
                continue
            rows.append((job_id, nombre.strip(), nombre.strip().lower(),
                         r.get("ruc", ""), r.get("razon_social", ""), r.get("cod_comercio", "")))
        with self._conn() as conn:
            with conn.cursor() as cur:
                psycopg2.extras.execute_values(cur,
                    "INSERT INTO fraude.upload_referencia (job_id,nombre,nombre_norm,ruc,razon_social,cod_comercio) VALUES %s",
                    rows, template="(%s,%s,%s,%s,%s,%s)", page_size=5000)
                cur.execute("UPDATE fraude.jobs SET total_referencia=%s WHERE job_id=%s", (len(rows), job_id))
                conn.commit()
        save_marca_embeddings(job_id, records, self.pg_dsn)
        return len(rows)

    def save_afiliaciones(self, job_id, records):
        rows = []
        for r in records:
            nom = r.get("nom_comercio", "") or r.get("nombre", "") or ""
            if not nom.strip():
                continue
            rows.append((job_id, nom.strip(), nom.strip().lower(),
                         r.get("cod_comercio", ""), r.get("ruc", ""), r.get("razon_social", "")))
        with self._conn() as conn:
            with conn.cursor() as cur:
                psycopg2.extras.execute_values(cur,
                    "INSERT INTO fraude.upload_afiliaciones (job_id,nom_comercio,nom_comercio_norm,cod_comercio,ruc,razon_social) VALUES %s",
                    rows, template="(%s,%s,%s,%s,%s,%s)", page_size=5000)
                cur.execute("UPDATE fraude.jobs SET total_afiliaciones=%s WHERE job_id=%s", (len(rows), job_id))
                conn.commit()
        return len(rows)

    def _update_job(self, job_id, **kwargs):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cols = [f"{k}=%s" for k in kwargs]
                cur.execute(f"UPDATE fraude.jobs SET {','.join(cols)} WHERE job_id=%s",
                            list(kwargs.values()) + [job_id])
                conn.commit()

    def _fewshot_examples(self):
        try:
            with self._conn() as conn:
                with conn.cursor() as cur:
                    cur.execute("""
                        SELECT nom_comercio, marca_ref, veredicto_humano, razonamiento
                        FROM fraude.ground_truth
                        WHERE vigente = TRUE
                        ORDER BY RANDOM()
                        LIMIT 5
                    """)
                    rows = cur.fetchall()
            if not rows:
                return ""
            lines = ["EJEMPLOS HISTÓRICOS VALIDADOS POR ANALISTAS HUMANOS:"]
            for nom, marca, vered, razon in rows:
                lines.append(f"- '{nom}' vs marca '{marca}' → {vered}. {razon[:100]}")
            return "\n".join(lines) + "\n"
        except Exception as e:
            log.warning(f"fewshot load failed: {e}")
            return ""

    def _ia_evaluate(self, afil_nom, candidates_fuzzy, candidates_vec, fewshot):
        all_candidates = {}
        for c in candidates_fuzzy:
            all_candidates[c["nombre"]] = {**c, "source": "fuzzy"}
        for c in candidates_vec:
            if c["nombre"] in all_candidates:
                all_candidates[c["nombre"]]["source"] = "fuzzy+vector"
                all_candidates[c["nombre"]]["similarity"] = c["similarity"]
            else:
                all_candidates[c["nombre"]] = {**c, "source": "vector"}

        top_candidates = sorted(all_candidates.values(),
                                key=lambda x: x.get("score_fuzzy", 0) + x.get("similarity", 0) * 100,
                                reverse=True)[:5]

        user_input = f"""{fewshot}
COMERCIO A EVALUAR: "{afil_nom}"

CANDIDATOS DE MARCAS REFERENCIADAS (top-5 por similitud):
{json.dumps([{"marca": c["nombre"], "fuzzy": c.get("score_fuzzy", 0), "vector": c.get("similarity", 0), "source": c.get("source", "")} for c in top_candidates], ensure_ascii=False, indent=2)}

Evalúa si el COMERCIO está suplantando alguna de estas marcas. Responde en JSON estricto."""

        try:
            result, usage = self.gpt.ask_json(SYSTEM_PROMPT_V6, user_input, max_tokens=800, temperature=0.1)
            return result, top_candidates[0] if top_candidates else None, usage
        except Exception as e:
            log.error(f"IA eval failed for '{afil_nom}': {e}")
            return None, None, None

    def run_comparison(self, job_id):
        self._update_job(job_id, status="processing", phase="Cargando datos...")
        t0 = time.time()

        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT use_ia,threshold,ia_threshold FROM fraude.jobs WHERE job_id=%s", (job_id,))
                use_ia, threshold, ia_threshold = cur.fetchone()
                cur.execute("SELECT nombre,nombre_norm,ruc FROM fraude.upload_referencia WHERE job_id=%s", (job_id,))
                ref_rows = cur.fetchall()
                cur.execute("SELECT id,nom_comercio,nom_comercio_norm,cod_comercio,ruc,razon_social FROM fraude.upload_afiliaciones WHERE job_id=%s", (job_id,))
                afil_rows = cur.fetchall()

        seen = set()
        afil_dedup = []
        for a in afil_rows:
            key = (a[1] or "").strip().upper()
            if key not in seen:
                seen.add(key)
                afil_dedup.append(a)

        total = len(afil_dedup)
        ref_names = [r[0] for r in ref_rows]
        self._update_job(job_id, phase=f"Fase 1/4 — Fuzzy filter ({total} afil x {len(ref_rows)} ref)...", total=total)

        fewshot = self._fewshot_examples()
        results = []
        counter = {"done": 0, "alertas": {"ALTA": 0, "MEDIA": 0, "BAJA": 0}}

        for idx, afil in enumerate(afil_dedup):
            afil_id, nom_comercio, nom_norm, cod_com, ruc, razon = afil

            fuzzy_matches = rfprocess.extract(
                nom_norm, ref_names,
                scorer=fuzz.WRatio, limit=FUZZY_TOPK, score_cutoff=threshold * 100
            )
            fuzzy_cands = [{"nombre": m[0], "score_fuzzy": m[1] / 100.0} for m in fuzzy_matches]

            try:
                vec_cands = semantic_rerank(job_id, nom_comercio, top_k=VECTOR_TOPK, pg_dsn=self.pg_dsn)
                vec_cands = [c for c in vec_cands if c["similarity"] >= 0.70]
            except Exception as e:
                log.warning(f"vector rerank fallo para {nom_comercio}: {e}")
                vec_cands = []

            if not fuzzy_cands and not vec_cands:
                counter["done"] += 1
                continue

            if use_ia:
                ia_result, best_cand, usage = self._ia_evaluate(nom_comercio, fuzzy_cands, vec_cands, fewshot)
                if ia_result is None:
                    counter["done"] += 1
                    continue

                marca_suplantada = ia_result.get("marca_identificada") or (best_cand["nombre"] if best_cand else "")

                wl = check_authorized_agent(cod_com, nom_comercio, marca_suplantada, rubro=None, pg_dsn=self.pg_dsn)
                score_ia = ia_result.get("score_ia", 0) / 100.0
                score_fuzzy = best_cand.get("score_fuzzy", 0) if best_cand else 0
                score_vector = best_cand.get("similarity", 0) if best_cand else 0
                score_final = max(0.0, (score_ia * 0.5 + score_fuzzy * 0.3 + score_vector * 0.2) - wl["score_adjustment"])

                nivel = ia_result.get("nivel", "DESCARTAR")
                if wl["is_authorized_agent"] and nivel in ("ALTA", "MEDIA"):
                    nivel = "BAJA"
                if nivel == "DESCARTAR":
                    counter["done"] += 1
                    continue

                result_row = {
                    "job_id": job_id,
                    "afil_id": afil_id,
                    "cod_comercio": cod_com,
                    "nom_comercio": nom_comercio,
                    "nom_comercio_norm": nom_norm,
                    "nombre_referencia_match": marca_suplantada,
                    "score_sintactico": score_fuzzy,
                    "score_semantico": score_vector,
                    "score_ia": score_ia,
                    "score_final": score_final,
                    "nivel_alerta": nivel,
                    "tecnica_suplantacion": ia_result.get("tecnica"),
                    "marca_identificada": ia_result.get("marca_identificada"),
                    "es_fraude_ia": ia_result.get("es_fraude", False),
                    "es_agente_autorizado": wl["is_authorized_agent"],
                    "whitelist_reason": wl["reason"],
                    "detalle_ia": f"[v6/GPT-5.1 score={ia_result.get('score_ia',0)} T:{ia_result.get('tecnica','')}] {ia_result.get('razonamiento','')[:400]}",
                    "metodo_deteccion": "JUNTA_MEDICA_V6",
                    "procesado_por": "fraude-comparador-v6.0"
                }
                results.append(result_row)
                if nivel in counter["alertas"]:
                    counter["alertas"][nivel] += 1

            counter["done"] += 1
            if counter["done"] % 50 == 0:
                self._update_job(job_id,
                                 phase=f"Fase 3/4 — IA GPT-5.1: {counter['done']}/{total}",
                                 processed=counter["done"],
                                 alertas_alta=counter["alertas"]["ALTA"],
                                 alertas_media=counter["alertas"]["MEDIA"],
                                 alertas_baja=counter["alertas"]["BAJA"])

        self._update_job(job_id, phase="Fase 4/4 — Guardando...", processed=total)
        self._save_results(job_id, results)
        elapsed = int((time.time() - t0) * 1000)
        self._update_job(job_id, status="done", phase="Completado",
                         matches_total=len(results),
                         matches_alta=counter["alertas"]["ALTA"],
                         matches_media=counter["alertas"]["MEDIA"],
                         matches_baja=counter["alertas"]["BAJA"],
                         elapsed_ms=elapsed)
        log.info(f"Job {job_id} done: {len(results)} matches en {elapsed}ms")

    def _save_results(self, job_id, results):
        if not results:
            return
        rows = [(r["job_id"], r["cod_comercio"], r["nom_comercio"], r["nombre_referencia_match"],
                 r["score_sintactico"], r["score_semantico"], r["score_ia"], r["score_final"],
                 r["nivel_alerta"], r["tecnica_suplantacion"], r["marca_identificada"],
                 r["es_fraude_ia"], r["es_agente_autorizado"], r["whitelist_reason"],
                 r["detalle_ia"], r["metodo_deteccion"], r["procesado_por"]) for r in results]
        with self._conn() as conn:
            with conn.cursor() as cur:
                psycopg2.extras.execute_values(cur, """
                    INSERT INTO fraude.resultados (job_id, cod_comercio, nom_comercio,
                      nombre_referencia_match, score_sintactico, score_semantico, score_ia,
                      score_final, nivel_alerta, tecnica_suplantacion, marca_identificada,
                      es_fraude_ia, es_agente_autorizado, whitelist_reason, detalle_ia,
                      metodo_deteccion, procesado_por) VALUES %s
                """, rows, page_size=500)
                conn.commit()
