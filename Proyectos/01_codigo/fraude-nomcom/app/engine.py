"""
Motor de Matching v2.0 — PostgreSQL pg_trgm + IA doble pasada
Búsqueda fuzzy en base de datos, no en memoria.
"""
import re, unicodedata, logging, time, os, json
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass
from contextlib import contextmanager

import psycopg2, psycopg2.extras
from rapidfuzz.distance import JaroWinkler, Levenshtein

logger = logging.getLogger("engine")

# ─── CONFIG ────────────────────────────────────────────────────
TH_ALTA  = 0.85
TH_MEDIA = 0.65
TH_BAJA  = 0.45

TOP_CANDIDATES_PER_TOKEN = 15
MAX_FINAL_CANDIDATES = 30

# ─── LEETSPEAK ─────────────────────────────────────────────────
LEET_MAP = {
    "0": "O", "1": "I", "3": "E", "4": "A", "5": "S",
    "6": "G", "7": "T", "8": "B", "9": "G",
    "@": "A", "$": "S", "!": "I", "|": "I",
    "+": "T", "ph": "F", "PH": "F", "vv": "W", "VV": "W",
}

PHONETIC_MAP = {
    "Z": "S", "K": "C", "W": "U", "X": "S",
    "QU": "K", "CK": "K", "PH": "F",
    "CE": "SE", "CI": "SI",
}

LEGAL_SUFFIXES = {
    "SAC", "S A C", "S.A.C", "S.A.C.", "SA", "S.A", "S.A.",
    "EIRL", "E.I.R.L", "E.I.R.L.", "SRL", "S.R.L", "S.R.L.",
    "SAA", "S.A.A", "S.A.A.", "SCRL", "S.C.R.L", "LTDA",
}

STOPWORDS = {
    "SOCIEDAD", "COMERCIAL", "DISTRIBUIDORA", "EMPRESA", "CORPORACION",
    "COMPANIA", "GRUPO", "SERVICIOS", "INVERSIONES", "NEGOCIACIONES",
    "REPRESENTACIONES", "IMPORTACIONES", "EXPORTACIONES", "CONSULTORA",
    "ASOCIACION", "FUNDACION", "COOPERATIVA", "INDUSTRIAL",
    "SUCURSAL", "AGENCIA", "OFICINA", "SEDE", "LOCAL", "TIENDA",
    "PUNTO", "VENTA", "PRINCIPAL", "ANEXO", "CENTRAL",
    "IZI", "DEL", "LOS", "LAS", "PER", "PERU", "CORP",
    "DE", "EL", "LA", "EN", "SAN", "SANTA",
}

_sorted_suffixes = sorted([re.escape(s) for s in LEGAL_SUFFIXES], key=len, reverse=True)
_LEGAL_PATTERN = re.compile(r"\b(?:" + "|".join(_sorted_suffixes) + r")\s*$", re.IGNORECASE)


# ─── NORMALIZACIÓN ─────────────────────────────────────────────

def apply_leetspeak(s: str) -> str:
    for old in sorted(LEET_MAP.keys(), key=len, reverse=True):
        s = s.replace(old, LEET_MAP[old])
    return s

def apply_phonetic(s: str) -> str:
    for old in sorted(PHONETIC_MAP.keys(), key=len, reverse=True):
        s = s.replace(old, PHONETIC_MAP[old])
    return s

def strip_accents(s: str) -> str:
    return "".join(ch for ch in unicodedata.normalize("NFD", s) if unicodedata.category(ch) != "Mn")

def normalize_text(s: str) -> str:
    if not s: return ""
    s = str(s).strip()
    s = strip_accents(s).upper()
    s = apply_leetspeak(s)
    s = _LEGAL_PATTERN.sub("", s).strip()
    s = re.sub(r"^\s*IZI\s*\*?\s*", "", s).strip()
    s = re.sub(r"[^A-Z0-9\s]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s

def extract_core_tokens(s: str) -> List[str]:
    norm = normalize_text(s)
    tokens = norm.split()
    # Quitar stopwords y tokens de 1-2 chars
    core = [t for t in tokens if t not in STOPWORDS and len(t) > 2]
    # Si quedó vacío, intentar con tokens de 2+ chars
    if not core:
        core = [t for t in tokens if t not in STOPWORDS and len(t) > 1]
    return core

def normalize_phonetic(s: str) -> str:
    return apply_phonetic(normalize_text(s))

def jaro_winkler_sim(a: str, b: str) -> float:
    if not a and not b: return 1.0
    if not a or not b: return 0.0
    return float(JaroWinkler.similarity(a, b))

def levenshtein_sim(a: str, b: str) -> float:
    if not a and not b: return 1.0
    if not a or not b: return 0.0
    return 1.0 - (Levenshtein.distance(a, b) / max(len(a), len(b)))


# ─── RESULTADO ─────────────────────────────────────────────────

@dataclass
class MatchResult:
    nombre_referencia: str
    nombre_referencia_original: str
    origen: str
    score_sintactico: float = 0.0
    score_semantico: float = 0.0
    score_ia: float = 0.0
    score_final: float = 0.0
    nivel_alerta: str = "DESCARTADO"
    metodo_deteccion: str = ""
    detalle_ia: str = ""

    def to_dict(self) -> dict:
        return {
            "nombre_referencia_match": self.nombre_referencia_original,
            "nombre_referencia_norm": self.nombre_referencia,
            "origen_referencia": self.origen,
            "score_sintactico": round(self.score_sintactico, 4),
            "score_semantico": round(self.score_semantico, 4),
            "score_ia": round(self.score_ia, 4),
            "score_final": round(self.score_final, 4),
            "nivel_alerta": self.nivel_alerta,
            "metodo_deteccion": self.metodo_deteccion,
            "detalle_ia": self.detalle_ia,
        }


# ─── MOTOR v2: PostgreSQL pg_trgm ─────────────────────────────

class MatchingEngine:
    def __init__(self):
        self.is_loaded = False
        self.last_update = None
        self.reference_count = 0
        self._oai_client = None
        self._db_config = None

    def set_db_config(self, config: dict):
        self._db_config = config

    @contextmanager
    def _pg(self):
        conn = psycopg2.connect(**self._db_config)
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def get_oai_client(self):
        if not self._oai_client:
            try:
                from openai import AzureOpenAI
                ep = os.environ.get("AZURE_OPENAI_ENDPOINT", "")
                key = os.environ.get("AZURE_OPENAI_API_KEY", "")
                ver = os.environ.get("AZURE_OPENAI_API_VERSION", "2025-01-01-preview")
                if ep and key:
                    self._oai_client = AzureOpenAI(azure_endpoint=ep, api_key=key, api_version=ver)
            except Exception as e:
                logger.warning(f"Azure OpenAI no disponible: {e}")
        return self._oai_client

    # ── Setup: crear tabla pg_trgm ──────────────────────────────
    def setup_pg_table(self):
        if not self._db_config:
            return
        try:
            with self._pg() as conn:
                with conn.cursor() as cur:
                    cur.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")
                    cur.execute("""
                        CREATE TABLE IF NOT EXISTS ref_nombres_comerciales (
                            id SERIAL PRIMARY KEY,
                            nombre_original TEXT NOT NULL,
                            nombre_norm TEXT NOT NULL,
                            nombre_phonetic TEXT NOT NULL,
                            nombre_nospace TEXT NOT NULL,
                            origen TEXT NOT NULL,
                            tokens TEXT[]
                        )
                    """)
                    cur.execute("""
                        CREATE INDEX IF NOT EXISTS idx_ref_trgm_norm
                        ON ref_nombres_comerciales USING GIN (nombre_norm gin_trgm_ops)
                    """)
                    cur.execute("""
                        CREATE INDEX IF NOT EXISTS idx_ref_trgm_phonetic
                        ON ref_nombres_comerciales USING GIN (nombre_phonetic gin_trgm_ops)
                    """)
                    cur.execute("""
                        CREATE INDEX IF NOT EXISTS idx_ref_trgm_nospace
                        ON ref_nombres_comerciales USING GIN (nombre_nospace gin_trgm_ops)
                    """)
            logger.info("Tabla pg_trgm creada/verificada")
        except Exception as e:
            logger.error(f"Error creando tabla pg_trgm: {e}")

    # ── Cargar referencia: BQ → PostgreSQL ──────────────────────
    def load_reference(self, names: List[str], origins: List[str]):
        if not self._db_config:
            logger.warning("No hay config de BD, no se puede cargar referencia")
            return

        t0 = time.time()
        self.setup_pg_table()

        # Si PG ya tiene datos, usarlos sin re-cargar de BQ
        try:
            with self._pg() as conn:
                with conn.cursor() as cur:
                    cur.execute('SELECT COUNT(*) FROM ref_nombres_comerciales')
                    existing = cur.fetchone()[0]
                    if existing > 1000:
                        self.reference_count = existing
                        self.is_loaded = True
                        self.last_update = time.time()
                        logger.info(f'PG ya tiene {existing} registros, listo')
                        return
        except Exception:
            pass

        # Si PG ya tiene datos, usarlos directamente sin re-cargar
        try:
            with self._pg() as conn:
                with conn.cursor() as cur:
                    cur.execute("SELECT COUNT(*) FROM ref_nombres_comerciales")
                    existing = cur.fetchone()[0]
                    if existing > 1000 and not names:
                        self.reference_count = existing
                        self.is_loaded = True
                        logger.info(f"PostgreSQL ya tiene {existing} registros, usando datos existentes")
                        return
        except Exception:
            pass

        try:
            with self._pg() as conn:
                with conn.cursor() as cur:
                    cur.execute("TRUNCATE ref_nombres_comerciales")

                    batch = []
                    for i, (name, origin) in enumerate(zip(names, origins)):
                        if not name or not str(name).strip():
                            continue
                        norm = normalize_text(name)
                        if not norm:
                            continue
                        phonetic = normalize_phonetic(name)
                        nospace = norm.replace(" ", "")
                        tokens = extract_core_tokens(name)

                        batch.append((name, norm, phonetic, nospace, origin, tokens))

                        if len(batch) >= 5000:
                            psycopg2.extras.execute_values(
                                cur,
                                """INSERT INTO ref_nombres_comerciales
                                   (nombre_original, nombre_norm, nombre_phonetic, nombre_nospace, origen, tokens)
                                   VALUES %s""",
                                batch,
                                template="(%s, %s, %s, %s, %s, %s)"
                            )
                            batch = []

                    if batch:
                        psycopg2.extras.execute_values(
                            cur,
                            """INSERT INTO ref_nombres_comerciales
                               (nombre_original, nombre_norm, nombre_phonetic, nombre_nospace, origen, tokens)
                               VALUES %s""",
                            batch,
                            template="(%s, %s, %s, %s, %s, %s)"
                        )

                    cur.execute("SELECT COUNT(*) FROM ref_nombres_comerciales")
                    self.reference_count = cur.fetchone()[0]

            self.is_loaded = True
            self.last_update = time.time()
            elapsed = time.time() - t0
            logger.info(f"Referencia cargada en PostgreSQL: {self.reference_count} nombres en {elapsed:.1f}s")

        except Exception as e:
            logger.error(f"Error cargando referencia en PG: {e}")

    # ── Búsqueda: token por token con pg_trgm ──────────────────
    def _search_candidates(self, name: str) -> List[dict]:
        tokens = extract_core_tokens(name)
        name_norm = normalize_text(name)
        name_phonetic = normalize_phonetic(name)
        name_nospace = name_norm.replace(" ", "")

        if not tokens and not name_norm:
            return []

        candidates = {}  # id → {data}

        try:
            with self._pg() as conn:
                with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:

                    # Búsqueda 1: nombre completo por similitud de trigramas
                    cur.execute("""
                        SELECT id, nombre_original, nombre_norm, origen,
                               similarity(nombre_norm, %s) as sim_norm,
                               similarity(nombre_phonetic, %s) as sim_phonetic,
                               similarity(nombre_nospace, %s) as sim_nospace
                        FROM ref_nombres_comerciales
                        WHERE similarity(nombre_norm, %s) > 0.15
                           OR similarity(nombre_phonetic, %s) > 0.15
                           OR similarity(nombre_nospace, %s) > 0.15
                        ORDER BY GREATEST(
                            similarity(nombre_norm, %s),
                            similarity(nombre_phonetic, %s),
                            similarity(nombre_nospace, %s)
                        ) DESC
                        LIMIT %s
                    """, (name_norm, name_phonetic, name_nospace,
                          name_norm, name_phonetic, name_nospace,
                          name_norm, name_phonetic, name_nospace,
                          TOP_CANDIDATES_PER_TOKEN))

                    for row in cur.fetchall():
                        rid = row["id"]
                        if rid not in candidates:
                            candidates[rid] = dict(row)
                            candidates[rid]["match_source"] = "FULL"

                    # Búsqueda 2: token por token (LA CLAVE)
                    for token in tokens:
                        if len(token) < 3:
                            continue
                        token_ph = apply_phonetic(token)

                        cur.execute("""
                            SELECT id, nombre_original, nombre_norm, origen,
                                   similarity(nombre_norm, %s) as sim_norm,
                                   similarity(nombre_phonetic, %s) as sim_phonetic,
                                   similarity(nombre_nospace, %s) as sim_nospace
                            FROM ref_nombres_comerciales
                            WHERE nombre_norm %% %s
                               OR nombre_phonetic %% %s
                               OR nombre_nospace %% %s
                            ORDER BY GREATEST(
                                similarity(nombre_norm, %s),
                                similarity(nombre_phonetic, %s)
                            ) DESC
                            LIMIT %s
                        """, (token, token_ph, token,
                              token, token_ph, token,
                              token, token_ph,
                              TOP_CANDIDATES_PER_TOKEN))

                        for row in cur.fetchall():
                            rid = row["id"]
                            if rid not in candidates:
                                candidates[rid] = dict(row)
                                candidates[rid]["match_source"] = f"TOKEN:{token}"
                            else:
                                # Ya existe, actualizar scores si son mejores
                                existing = candidates[rid]
                                existing["sim_norm"] = max(existing.get("sim_norm", 0), row["sim_norm"])
                                existing["sim_phonetic"] = max(existing.get("sim_phonetic", 0), row["sim_phonetic"])

                    # Búsqueda 3: cada token individual contra tokens almacenados
                    for token in tokens:
                        if len(token) < 3:
                            continue
                        token_ph = apply_phonetic(token)

                        cur.execute("""
                            SELECT id, nombre_original, nombre_norm, origen,
                                   similarity(nombre_norm, %s) as sim_norm,
                                   similarity(nombre_phonetic, %s) as sim_phonetic,
                                   0.0 as sim_nospace
                            FROM ref_nombres_comerciales
                            WHERE %s = ANY(tokens)
                               OR EXISTS (
                                   SELECT 1 FROM unnest(tokens) t
                                   WHERE similarity(t, %s) > 0.4
                               )
                            ORDER BY similarity(nombre_norm, %s) DESC
                            LIMIT %s
                        """, (token, token_ph,
                              token,
                              token,
                              token,
                              TOP_CANDIDATES_PER_TOKEN))

                        for row in cur.fetchall():
                            rid = row["id"]
                            if rid not in candidates:
                                candidates[rid] = dict(row)
                                candidates[rid]["match_source"] = f"TOKEN_ARRAY:{token}"

        except Exception as e:
            logger.error(f"Error buscando candidatos en PG: {e}")

        # Ordenar por mejor score y limitar
        result = sorted(candidates.values(),
                       key=lambda x: max(x.get("sim_norm", 0), x.get("sim_phonetic", 0), x.get("sim_nospace", 0)),
                       reverse=True)
        return result[:MAX_FINAL_CANDIDATES]

    # ── Scoring fino ───────────────────────────────────────────
    def _compute_scores(self, name: str, candidate: dict) -> MatchResult:
        name_norm = normalize_text(name)
        name_phonetic = normalize_phonetic(name)
        name_nospace = name_norm.replace(" ", "")
        cand_norm = candidate["nombre_norm"]

        # Score sintáctico: mejor de Jaro-Winkler en varias formas
        s_jw_norm = jaro_winkler_sim(name_norm, cand_norm)
        s_jw_nospace = jaro_winkler_sim(name_nospace, cand_norm.replace(" ", ""))
        s_jw_phonetic = jaro_winkler_sim(name_phonetic, apply_phonetic(cand_norm))
        s_lev = levenshtein_sim(name_norm, cand_norm)
        s_lev_nospace = levenshtein_sim(name_nospace, cand_norm.replace(" ", ""))

        s_syntactic = max(s_jw_norm, s_jw_nospace, s_jw_phonetic) * 0.6 + max(s_lev, s_lev_nospace) * 0.4

        # Score semántico: token overlap sobre tokens core
        input_tokens = set(extract_core_tokens(name))
        input_tokens_ph = set(apply_phonetic(t) for t in input_tokens)
        ref_tokens = set(extract_core_tokens(candidate["nombre_original"]))
        ref_tokens_ph = set(apply_phonetic(t) for t in ref_tokens)

        # Fuzzy token matching: cada token input contra cada token ref
        token_matches = 0
        token_total = max(len(input_tokens), 1)
        for it in input_tokens:
            best_sim = 0
            it_ph = apply_phonetic(it)
            for rt in ref_tokens:
                rt_ph = apply_phonetic(rt)
                sim = max(
                    jaro_winkler_sim(it, rt),
                    jaro_winkler_sim(it_ph, rt_ph),
                    levenshtein_sim(it, rt),
                    # Partial: si uno contiene al otro
                    1.0 if (it in rt or rt in it) and min(len(it), len(rt)) >= 3 else 0.0,
                    1.0 if (it_ph in rt_ph or rt_ph in it_ph) and min(len(it_ph), len(rt_ph)) >= 3 else 0.0,
                )
                best_sim = max(best_sim, sim)
            if best_sim >= 0.7:
                token_matches += best_sim

        s_semantic = token_matches / token_total if token_total > 0 else 0

        # pg_trgm score como boost
        pg_sim = max(
            candidate.get("sim_norm", 0),
            candidate.get("sim_phonetic", 0),
            candidate.get("sim_nospace", 0)
        )

        # Score final combinado
        score_final = s_syntactic * 0.35 + s_semantic * 0.40 + pg_sim * 0.25

        mr = MatchResult(
            nombre_referencia=cand_norm,
            nombre_referencia_original=candidate["nombre_original"],
            origen=candidate["origen"],
            score_sintactico=s_syntactic,
            score_semantico=s_semantic,
            score_final=score_final,
        )

        if score_final >= TH_ALTA:
            mr.nivel_alerta = "ALTA"
            mr.metodo_deteccion = "SINTACTICO+SEMANTICO+TRGM"
        elif score_final >= TH_MEDIA:
            mr.nivel_alerta = "MEDIA"
            mr.metodo_deteccion = "SINTACTICO+SEMANTICO+TRGM"
        elif score_final >= TH_BAJA:
            mr.nivel_alerta = "BAJA"
            mr.metodo_deteccion = "SINTACTICO+SEMANTICO+TRGM"

        return mr

    # ── Match individual ───────────────────────────────────────
    def match_single(self, name: str, use_ia: bool = True, top_n: int = 5) -> List[MatchResult]:
        if not self.is_loaded:
            return []

        candidates = self._search_candidates(name)
        if not candidates:
            return []

        results = []
        for cand in candidates:
            mr = self._compute_scores(name, cand)
            if mr.score_final >= TH_BAJA:
                results.append(mr)

        results.sort(key=lambda r: r.score_final, reverse=True)
        results = results[:top_n]

        # IA doble pasada para zona gris
        if use_ia and results:
            ia_candidates = [r for r in results if TH_BAJA <= r.score_final < TH_ALTA]
            if ia_candidates:
                self._apply_ia_layer(name, normalize_text(name), ia_candidates)

            # Recalcular si IA intervino
            for r in results:
                if r.score_ia > 0:
                    r.score_final = (
                        r.score_sintactico * 0.15 +
                        r.score_semantico * 0.15 +
                        r.score_ia * 0.70
                    )
                    if r.score_final >= TH_ALTA:
                        r.nivel_alerta = "ALTA"
                        r.metodo_deteccion = "IA"
                    elif r.score_final >= TH_MEDIA:
                        r.nivel_alerta = "MEDIA"
                        r.metodo_deteccion = "IA"

        results.sort(key=lambda r: r.score_final, reverse=True)
        return [r for r in results if r.nivel_alerta != "DESCARTADO"]

    # ── IA doble pasada ────────────────────────────────────────
    def _apply_ia_layer(self, original: str, normalized: str, candidates: List[MatchResult]):
        client = self.get_oai_client()
        if not client:
            return

        model = os.environ.get("AZURE_OPENAI_MODEL", "gpt-4.1")

        for mr in candidates:
            try:
                prompt_eval = (
                    f"Eres analista senior de fraude en Izipay, procesadora de pagos en Perú.\n\n"
                    f"NOMBRE NUEVO: '{original}'\n"
                    f"NORMALIZADO: '{normalized}'\n"
                    f"REFERENCIA: '{mr.nombre_referencia_original}' (norm: '{mr.nombre_referencia}')\n\n"
                    f"INSTRUCCIONES:\n"
                    f"1. Descompón ambos nombres en tokens core (ignora: IZI, SUCURSAL, LOCAL, TIENDA, CORP, SAC, EIRL, SRL, SA, DE)\n"
                    f"2. Compara token por token considerando leetspeak (3→E, 1→I, 0→O, 4→A, 5→S, Z→S)\n"
                    f"3. Considera que suplantadores ABREVIAN: COSME=COSMETICOS, BOUT=BOUTIQUE, SJM=SAN JUAN MIRAFLORES\n"
                    f"4. Si los tokens core coinciden (incluso parcialmente), score ALTO\n"
                    f"5. Si no comparten tokens core reales, score BAJO (<0.2)\n\n"
                    f"JSON: {{\"score\": 0.0-1.0, \"tokens_core_nuevo\": [...], \"tokens_core_ref\": [...], \"razon\": \"...\"}}"
                )
                resp = client.chat.completions.create(
                    model=model,
                    messages=[{"role": "user", "content": prompt_eval}],
                    max_tokens=300, temperature=0.1,
                )
                text = resp.choices[0].message.content.strip().replace("```json","").replace("```","").strip()
                data = json.loads(text)
                score_eval = float(data.get("score", 0))
                razon = data.get("razon", "")

                # Auditor si score >= 0.4
                if score_eval >= 0.4:
                    prompt_audit = (
                        f"AUDITOR FINAL. Nombre nuevo: '{original}' vs Referencia: '{mr.nombre_referencia_original}'.\n"
                        f"Evaluación previa: score={score_eval}, razón: {razon}\n\n"
                        f"¿Un cliente REALMENTE confundiría estos comercios? Sé ESTRICTO.\n"
                        f"Si comparten palabras core (aunque abreviadas/modificadas) → confirmar.\n"
                        f"Si solo comparten palabras genéricas → rechazar.\n\n"
                        f"JSON: {{\"score_final\": 0.0-1.0, \"es_suplantacion\": true/false, \"razon\": \"...\"}}"
                    )
                    resp2 = client.chat.completions.create(
                        model=model,
                        messages=[{"role": "user", "content": prompt_audit}],
                        max_tokens=200, temperature=0.1,
                    )
                    text2 = resp2.choices[0].message.content.strip().replace("```json","").replace("```","").strip()
                    data2 = json.loads(text2)
                    score_audit = float(data2.get("score_final", score_eval))
                    es_sup = data2.get("es_suplantacion", True)
                    razon2 = data2.get("razon", "")

                    if not es_sup:
                        mr.score_ia = min(score_audit, 0.2)
                        mr.detalle_ia = f"[DESCARTADO] {razon2}"
                    else:
                        mr.score_ia = score_audit
                        mr.detalle_ia = f"[CONFIRMADO] {razon2}"
                else:
                    mr.score_ia = score_eval
                    mr.detalle_ia = razon

            except Exception as e:
                logger.warning(f"Error IA: {e}")
                mr.score_ia = 0.0
                mr.detalle_ia = f"Error: {str(e)[:100]}"

    # ── Batch ──────────────────────────────────────────────────
    def match_batch(self, names: List[Dict], use_ia: bool = True, top_n: int = 3) -> List[Dict]:
        all_results = []
        for i, item in enumerate(names):
            nom = item.get("nom_comercio", "")
            cod = item.get("cod_comercio", "")
            matches = self.match_single(nom, use_ia=use_ia, top_n=top_n)
            for m in matches:
                result = m.to_dict()
                result["cod_comercio"] = cod
                result["nom_comercio"] = nom
                result["nom_comercio_norm"] = normalize_text(nom)
                all_results.append(result)
            if (i + 1) % 100 == 0:
                logger.info(f"  Batch: {i+1}/{len(names)}")
        return all_results



    # ── Batch SQL: cruce directo en PostgreSQL ─────────────
    def batch_sql(self, names_with_codes: list, top_n: int = 1) -> list:
        """
        Cruza N afiliaciones contra 467K de golpe en PostgreSQL.
        1 query en vez de N llamadas HTTP.
        """
        if not self.is_loaded or not self._db_config:
            return []

        import time as _time
        t0 = _time.time()
        results = []

        try:
            with self._pg() as conn:
                with conn.cursor() as cur:
                    # Crear tabla temporal con las afiliaciones
                    cur.execute("DROP TABLE IF EXISTS tmp_batch_afiliaciones")
                    cur.execute("""
                        CREATE TEMPORARY TABLE tmp_batch_afiliaciones (
                            cod_comercio TEXT,
                            nom_comercio TEXT,
                            nombre_norm TEXT,
                            nombre_phonetic TEXT,
                            nombre_nospace TEXT
                        )
                    """)

                    # Insertar afiliaciones normalizadas
                    from engine import normalize_text, normalize_phonetic
                    batch_rows = []
                    for item in names_with_codes:
                        cod = item.get("cod_comercio", "")
                        nom = item.get("nom_comercio", "")
                        norm = normalize_text(nom)
                        if not norm:
                            continue
                        ph = normalize_phonetic(nom)
                        ns = norm.replace(" ", "")
                        batch_rows.append((cod, nom, norm, ph, ns))

                    import psycopg2.extras
                    psycopg2.extras.execute_values(
                        cur,
                        """INSERT INTO tmp_batch_afiliaciones
                           (cod_comercio, nom_comercio, nombre_norm, nombre_phonetic, nombre_nospace)
                           VALUES %s""",
                        batch_rows,
                        template="(%s, %s, %s, %s, %s)"
                    )
                    logger.info(f"Batch: {len(batch_rows)} afiliaciones insertadas en temp")

                    # Usar operador % con GIN index (rápido)
                    cur.execute("SET pg_trgm.similarity_threshold = 0.1")
                    
                    query = """
                        SELECT
                            a.cod_comercio,
                            a.nom_comercio,
                            a.nombre_norm as nom_norm,
                            r.nombre_original as ref_match,
                            r.nombre_norm as ref_norm,
                            r.origen,
                            GREATEST(
                                similarity(a.nombre_norm, r.nombre_norm),
                                similarity(a.nombre_phonetic, r.nombre_phonetic),
                                similarity(a.nombre_nospace, r.nombre_nospace)
                            ) as pg_score
                        FROM tmp_batch_afiliaciones a
                        CROSS JOIN LATERAL (
                            SELECT nombre_original, nombre_norm, nombre_phonetic, nombre_nospace, origen
                            FROM ref_nombres_comerciales
                            WHERE nombre_norm %% a.nombre_norm
                               OR nombre_phonetic %% a.nombre_phonetic
                               OR nombre_nospace %% a.nombre_nospace
                            ORDER BY GREATEST(
                                similarity(nombre_norm, a.nombre_norm),
                                similarity(nombre_phonetic, a.nombre_phonetic),
                                similarity(nombre_nospace, a.nombre_nospace)
                            ) DESC
                            LIMIT %s
                        ) r
                    """
                    cur.execute(query, (top_n,))

                    rows = cur.fetchall()
                    cols = [desc[0] for desc in cur.description]

                    for row in rows:
                        d = dict(zip(cols, row))

                        # Scoring fino
                        from engine import jaro_winkler_sim, levenshtein_sim, extract_core_tokens, apply_phonetic
                        nom_n = d["nom_norm"]
                        ref_n = d["ref_norm"]

                        s_jw = max(
                            jaro_winkler_sim(nom_n, ref_n),
                            jaro_winkler_sim(nom_n.replace(" ",""), ref_n.replace(" ","")),
                        )
                        s_lev = max(
                            levenshtein_sim(nom_n, ref_n),
                            levenshtein_sim(nom_n.replace(" ",""), ref_n.replace(" ","")),
                        )
                        s_syntactic = s_jw * 0.6 + s_lev * 0.4

                        # Token overlap
                        input_tokens = set(extract_core_tokens(d["nom_comercio"]))
                        ref_tokens = set(extract_core_tokens(d["ref_match"]))
                        token_matches = 0
                        for it in input_tokens:
                            best = 0
                            it_ph = apply_phonetic(it)
                            for rt in ref_tokens:
                                rt_ph = apply_phonetic(rt)
                                sim = max(
                                    jaro_winkler_sim(it, rt),
                                    jaro_winkler_sim(it_ph, rt_ph),
                                    1.0 if (it in rt or rt in it) and min(len(it),len(rt))>=3 else 0.0,
                                )
                                best = max(best, sim)
                            if best >= 0.7:
                                token_matches += best
                        s_semantic = token_matches / max(len(input_tokens), 1)

                        pg_sim = float(d["pg_score"])
                        score_final = s_syntactic * 0.35 + s_semantic * 0.40 + pg_sim * 0.25

                        nivel = "DESCARTADO"
                        if score_final >= 0.85: nivel = "ALTA"
                        elif score_final >= 0.65: nivel = "MEDIA"
                        elif score_final >= 0.45: nivel = "BAJA"

                        if nivel != "DESCARTADO":
                            results.append({
                                "cod_comercio": d["cod_comercio"],
                                "nom_comercio": d["nom_comercio"],
                                "nom_comercio_norm": d["nom_norm"],
                                "nombre_referencia_match": d["ref_match"],
                                "origen_referencia": d["origen"],
                                "score_sintactico": round(s_syntactic, 4),
                                "score_semantico": round(s_semantic, 4),
                                "score_ia": 0.0,
                                "score_final": round(score_final, 4),
                                "nivel_alerta": nivel,
                                "metodo_deteccion": "BATCH_SQL+TRGM",
                                "detalle_ia": "",
                            })

                    cur.execute("DROP TABLE IF EXISTS tmp_batch_afiliaciones")

        except Exception as e:
            logger.error(f"Error batch_sql: {e}")

        elapsed = _time.time() - t0
        logger.info(f"Batch SQL: {len(names_with_codes)} evaluados → {len(results)} matches en {elapsed:.1f}s")
        return results

    def stats(self) -> dict:
        return {
            "loaded": self.is_loaded,
            "reference_count": self.reference_count,
            "last_update": self.last_update,
            "engine_type": "pg_trgm_v2",
        }
