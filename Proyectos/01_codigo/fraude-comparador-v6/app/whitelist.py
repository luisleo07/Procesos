"""
whitelist.py - Valida si el comercio es agente autorizado de una marca.
Si el comercio tiene rubro compatible con la marca + nombre contiene patrones
típicos de distribuidor (EQUIPOS, AGENTE, DIST, etc), reduce el score.
"""
import os, logging, re
import psycopg2

log = logging.getLogger(__name__)

DISTRIBUIDOR_PATTERNS = re.compile(
    r'\b(EQUIPOS?|AGENTE|DIST(RIBUIDOR)?|SERVICIO|TIENDA|CORPORAC|CENTRO|OFICIAL|AUTORIZADO|REPRESENT)\b',
    re.IGNORECASE
)

RUBRO_MARCA_MAP = {
    "MOVISTAR": {"telecomunicaciones", "celulares", "telefonia", "tienda_celulares"},
    "CLARO": {"telecomunicaciones", "celulares", "telefonia", "tienda_celulares"},
    "ENTEL": {"telecomunicaciones", "celulares", "telefonia"},
    "LA POSITIVA": {"seguros", "aseguradora", "finanzas"},
    "PACIFICO": {"seguros", "aseguradora", "finanzas"},
    "RIMAC": {"seguros", "aseguradora", "finanzas"},
    "INTERBANK": {"banca", "finanzas", "cambio_divisas"},
    "BCP": {"banca", "finanzas", "cambio_divisas"},
    "SCOTIABANK": {"banca", "finanzas"},
    "BBVA": {"banca", "finanzas"},
    "YAPE": {"banca", "fintech", "pagos"},
    "PLIN": {"banca", "fintech", "pagos"},
    "PLAZA VEA": {"supermercado", "retail"},
    "TOTTUS": {"supermercado", "retail"},
    "WONG": {"supermercado", "retail"},
    "METRO": {"supermercado", "retail"},
    "FARMACIAS INKAFARMA": {"farmacia", "salud", "botica"},
    "MIFARMA": {"farmacia", "salud", "botica"},
    "BOTICAS PERUANAS": {"farmacia", "salud", "botica"},
}


def check_authorized_agent(cod_comercio, nom_comercio, marca_suplantada, rubro=None, pg_dsn=None):
    """
    Returns dict con:
    - is_authorized_agent: bool
    - confidence: 0.0-1.0
    - reason: str
    - score_adjustment: float (a restar del score_final)
    """
    result = {
        "is_authorized_agent": False,
        "confidence": 0.0,
        "reason": "",
        "score_adjustment": 0.0
    }

    if pg_dsn:
        try:
            conn = psycopg2.connect(pg_dsn)
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT marca, tipo_autorizacion, vigente
                    FROM fraude.agentes_autorizados_izipay
                    WHERE cod_comercio = %s AND vigente = TRUE
                    LIMIT 1
                """, (cod_comercio,))
                row = cur.fetchone()
            conn.close()
            if row:
                result.update({
                    "is_authorized_agent": True,
                    "confidence": 1.0,
                    "reason": f"En whitelist oficial: {row[0]} ({row[1]})",
                    "score_adjustment": 0.5
                })
                return result
        except Exception as e:
            log.warning(f"whitelist DB check failed: {e}")

    marca_up = (marca_suplantada or "").upper().strip()
    nom_up = (nom_comercio or "").upper().strip()
    has_dist_pattern = bool(DISTRIBUIDOR_PATTERNS.search(nom_up))
    rubros_esperados = RUBRO_MARCA_MAP.get(marca_up, set())
    rubro_match = rubro and any(r in (rubro or "").lower() for r in rubros_esperados)

    if has_dist_pattern and rubro_match:
        result.update({
            "is_authorized_agent": True,
            "confidence": 0.7,
            "reason": f"Nombre incluye patrón distribuidor + rubro compatible ({rubro})",
            "score_adjustment": 0.3
        })
    elif has_dist_pattern:
        result.update({
            "is_authorized_agent": False,
            "confidence": 0.4,
            "reason": f"Nombre incluye patrón distribuidor pero rubro no coincide",
            "score_adjustment": 0.1
        })
    elif rubro_match:
        result.update({
            "is_authorized_agent": False,
            "confidence": 0.3,
            "reason": f"Rubro compatible pero sin patrón de distribuidor en nombre",
            "score_adjustment": 0.05
        })

    return result
