"""
embeddings.py - NO-OP version (v6.2)
Embeddings desactivados. Funciones retornan valores neutros para que 
engine_v6.py siga funcionando sin capa semantica.
El motor opera con 3 capas: fuzzy + whitelist + GPT-5.1 junta medica.
"""
import logging
log = logging.getLogger(__name__)


def embed_text(text, prefix="query: "):
    return None


def embed_batch(texts, prefix="passage: ", batch_size=16):
    return [None] * len(texts)


def save_marca_embeddings(job_id, ref_records, pg_dsn=None):
    log.info(f"embeddings disabled: skip save for job {job_id}")
    return 0


def semantic_rerank(job_id, afil_nombre, top_k=10, pg_dsn=None):
    return []
