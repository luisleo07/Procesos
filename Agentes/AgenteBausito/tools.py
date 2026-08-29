"""
Tools del Agente Central de Reportería de IZIPAY - BAUSITO.

FASE ACTUAL: REAL. Estas funciones consultan BigQuery productivo de verdad,
usando las credenciales ADC de quien corre `adk web`. Mismas firmas que la
versión mock anterior, más una tool nueva (`ejecutar_select_muestra`) para
traer filas reales de muestra.

Controles de seguridad aplicados aquí, ADEMÁS del guardrail global en
callbacks.py (antes de que la tool se llame):
- `proyecto`, `dataset` y `tabla` se validan con una lista blanca de
  caracteres (letras, números, guion y guion bajo) antes de insertarse en el
  SQL, porque son identificadores y no se pueden parametrizar como valores
  en BigQuery — esto evita inyección SQL vía esos argumentos.
- `patron` y `palabras_clave` sí son valores (van en un WHERE ... LIKE), así
  que se pasan como query parameters reales, nunca concatenados directo.
- Todo job de BigQuery se lanza con `maximum_bytes_billed` para evitar un
  costo descontrolado si alguien pide sin querer un SELECT * sobre una
  tabla enorme.
- `ejecutar_select_muestra` solo acepta sentencias que empiecen con SELECT
  o WITH, y le agrega un LIMIT si el modelo no lo puso.
"""

import base64
import os
import re
from datetime import date, datetime, time
from decimal import Decimal
from typing import Any

from dotenv import load_dotenv
from google.cloud import bigquery

load_dotenv()

# Proyecto que paga por los jobs de BigQuery (billing project). No tiene que
# coincidir con el proyecto que se está consultando — BigQuery permite leer
# metadata/datos de otro proyecto si tienes permisos, y el job se factura al
# proyecto del cliente.
_BILLING_PROJECT = os.environ.get("GOOGLE_CLOUD_PROJECT", "prd-izipay-data-operation")

# Tabla de conocimiento previo curado (ver sql/crear_tabla_conocimiento_previo.sql)
_TABLA_CONOCIMIENTO_PREVIO = os.environ.get(
    "BQ_TABLA_CONOCIMIENTO_PREVIO",
    "prd-izipay-data-storage-pv.agente_conocimiento.conocimiento_previo_reporteria",
)

# Tabla de logs de uso (ver sql/crear_tabla_logs_uso_agente.sql). A diferencia
# de conocimiento_previo, esta SÍ se escribe automáticamente en cada turno —
# ver registrar_log_uso() al final del archivo.
_TABLA_LOGS_USO = os.environ.get(
    "BQ_TABLA_LOGS_USO",
    "prd-izipay-data-storage-pv.agente_conocimiento.logs_uso_agente",
)

# Tope de bytes facturables por query, para evitar un costo descontrolado.
# 500 MB es conservador; súbelo si tus tablas de reportería son grandes.
_MAX_BYTES_BILLED = int(os.environ.get("BQ_MAX_BYTES_BILLED", 500 * 1024 * 1024))

_IDENTIFICADOR_VALIDO = re.compile(r"^[A-Za-z0-9_-]+$")

# Datasets personales/de desarrollo de analistas — NUNCA deben considerarse en
# consultas del agente. Configurable por .env para no requerir un redeploy
# cada vez que cambie la lista.
_PREFIJOS_DATASET_EXCLUIDOS = tuple(
    p.strip().lower()
    for p in os.environ.get("BQ_PREFIJOS_DATASET_EXCLUIDOS", "mc,tr,pr").split(",")
    if p.strip()
)
_DATASETS_EXCLUIDOS_EXPLICITOS = {
    d.strip().lower()
    for d in os.environ.get(
        "BQ_DATASETS_EXCLUIDOS",
        "emedina_inside,gmaravi_inside,gnunurat_inside,jalvarez_inside,ldiaz",
    ).split(",")
    if d.strip()
}


def _es_dataset_excluido(nombre_dataset: str) -> bool:
    """True si el dataset es personal/de desarrollo de un analista (prefijos
    mc/tr/pr, o un dataset "_inside" explícito) y por lo tanto no debe
    considerarse en ninguna consulta del agente — ni para listarlo, ni para
    explorarlo, ni para referenciarlo en un SELECT.
    """
    nombre = nombre_dataset.lower()
    if nombre in _DATASETS_EXCLUIDOS_EXPLICITOS:
        return True
    return any(nombre.startswith(p) for p in _PREFIJOS_DATASET_EXCLUIDOS)


def _validar_dataset_permitido(nombre_dataset: str) -> None:
    """Lanza ValueError si el dataset es personal/de desarrollo — mismo
    patrón que _validar_identificador, para bloquear el acceso ANTES de que
    la tool llegue a tocar BigQuery.
    """
    if _es_dataset_excluido(nombre_dataset):
        raise ValueError(
            f"'{nombre_dataset}' es un dataset personal/de desarrollo de un analista "
            f"(prefijo mc/tr/pr o dataset '_inside' explícito) — no se considera en "
            f"consultas del agente. Usa un dataset de producción real (ej. master_party, "
            f"master_product, raw_*, bi_*)."
        )


_client: bigquery.Client | None = None


def _get_client() -> bigquery.Client:
    global _client
    if _client is None:
        _client = bigquery.Client(project=_BILLING_PROJECT)
    return _client


def _validar_identificador(valor: str, nombre_campo: str) -> None:
    """Lanza ValueError si `valor` no es un identificador seguro (proyecto,
    dataset o tabla). Previene inyección SQL vía estos argumentos, que no se
    pueden pasar como query parameters porque son identificadores, no valores.
    """
    if not _IDENTIFICADOR_VALIDO.match(valor):
        raise ValueError(
            f"'{valor}' no es un {nombre_campo} válido (solo letras, números, "
            f"guion y guion bajo)."
        )


def _valor_serializable(valor: Any) -> Any:
    """Convierte tipos de BigQuery que no son JSON-serializables (DATE,
    DATETIME, TIME, BYTES, DECIMAL) a algo que sí lo es, antes de devolver
    la fila al agente. Sin esto, cualquier tabla con columnas de fecha o
    campos encriptados (BYTES) rompe la respuesta con un TypeError.
    """
    if isinstance(valor, (date, datetime, time)):
        return valor.isoformat()
    if isinstance(valor, Decimal):
        return float(valor)
    if isinstance(valor, bytes):
        # Campos encriptados (p. ej. AEAD) u otros BYTES: se codifican en
        # base64 para que el JSON no truene; no es lo mismo que el valor
        # desencriptado en texto plano.
        return base64.b64encode(valor).decode("ascii")
    return valor


def _ejecutar_query(sql: str, params: list | None = None) -> dict[str, Any]:
    """Ejecuta una query de BigQuery con tope de bytes facturables y devuelve
    las filas como lista de dicts (con tipos ya JSON-serializables), o un
    error legible si algo falla (permiso, tabla inexistente, cuota, etc.) —
    nunca deja que la excepción cruda llegue al agente.
    """
    client = _get_client()
    job_config = bigquery.QueryJobConfig(
        maximum_bytes_billed=_MAX_BYTES_BILLED,
        query_parameters=params or [],
    )
    try:
        job = client.query(sql, job_config=job_config)
        filas = [
            {k: _valor_serializable(v) for k, v in dict(row).items()}
            for row in job.result()
        ]
        return {
            "status": "success",
            "mock": False,
            "filas": filas,
            "bytes_facturados": job.total_bytes_processed,
        }
    except Exception as e:  # noqa: BLE001 — capturamos cualquier error de BQ y lo reportamos legible
        return {"status": "error", "mock": False, "error": str(e)}


def listar_datasets(proyecto: str) -> dict[str, Any]:
    """Lista los datasets (schemas) disponibles en un proyecto de BigQuery
    productivo, consultando INFORMATION_SCHEMA.SCHEMATA en vivo.

    Usa esta tool para descubrir qué datasets existen en un proyecto antes
    de buscar una tabla específica, cuando no sepas en qué dataset vive.

    NO la uses contra prd-izipay-data-sensitive: la identidad de este
    agente no tiene permisos ahí a propósito (403 esperado, no un bug). Para
    desencriptar PII, usa directo el patrón canónico de la sección 9.4a.

    Los datasets personales/de desarrollo de analistas (prefijos mc/tr/pr, o
    datasets "_inside") se filtran automáticamente de la respuesta — nunca
    los vas a ver en esta lista, y no debes asumir que existen ni inventar
    uno con esos prefijos como ejemplo.

    Args:
        proyecto: nombre del proyecto GCP, p. ej. "prd-izipay-data-storage-pv".

    Returns:
        dict con status y la lista de datasets encontrados (ya filtrada).
    """
    _validar_identificador(proyecto, "proyecto")
    sql = f"select schema_name from `{proyecto}`.`region-us`.INFORMATION_SCHEMA.SCHEMATA"
    resultado = _ejecutar_query(sql)
    if resultado["status"] == "error":
        return resultado
    datasets = [f["schema_name"] for f in resultado["filas"] if not _es_dataset_excluido(f["schema_name"])]
    return {
        "status": "success",
        "mock": False,
        "bytes_facturados": resultado.get("bytes_facturados"),
        "proyecto": proyecto,
        "datasets": datasets,
    }


def buscar_tabla_por_nombre(proyecto: str, patron: str) -> dict[str, Any]:
    """Busca en QUÉ dataset(s) existe una tabla dentro de todo un proyecto,
    en una sola consulta — sin tener que adivinar el dataset ni iterarlos
    uno por uno.

    Úsala SIEMPRE que sepas el nombre (o parte del nombre) de una tabla
    pero no sepas en qué dataset vive, en vez de suponer un dataset
    "lógico" (p. ej. no asumas que una tabla de comercios vive en un
    dataset llamado "master_data" solo porque el nombre suena razonable —
    búscala con esta tool primero).

    Los datasets personales/de desarrollo de analistas (prefijos mc/tr/pr, o
    datasets "_inside") se filtran automáticamente — nunca van a aparecer
    entre las coincidencias, aunque el nombre de tabla ahí coincida.

    Args:
        proyecto: nombre del proyecto GCP.
        patron: fragmento del nombre de tabla a buscar (se usa como
            LIKE '%patron%', no distingue mayúsculas/minúsculas).

    Returns:
        dict con status y la lista de coincidencias (ya filtrada), cada una
        con table_schema (el dataset) y table_name.
    """
    _validar_identificador(proyecto, "proyecto")
    sql = f"""
        select table_schema, table_name, table_type
        from `{proyecto}`.`region-us`.INFORMATION_SCHEMA.TABLES
        where lower(table_name) like lower(@patron)
        limit 100
    """
    params = [bigquery.ScalarQueryParameter("patron", "STRING", f"%{patron}%")]
    resultado = _ejecutar_query(sql, params)
    if resultado["status"] == "error":
        return resultado
    resultado["filas"] = [
        f for f in resultado["filas"] if not _es_dataset_excluido(f["table_schema"])
    ][:30]
    return {
        "status": "success",
        "mock": False,
        "bytes_facturados": resultado.get("bytes_facturados"),
        "proyecto": proyecto,
        "patron": patron,
        "coincidencias": resultado["filas"],
    }


def listar_tablas(proyecto: str, dataset: str) -> dict[str, Any]:
    """Lista las tablas y su tipo dentro de un dataset de BigQuery
    productivo, consultando INFORMATION_SCHEMA.TABLES en vivo.

    Args:
        proyecto: nombre del proyecto GCP.
        dataset: nombre del dataset dentro del proyecto.

    Returns:
        dict con status y la lista de tablas encontradas.
    """
    _validar_identificador(proyecto, "proyecto")
    _validar_identificador(dataset, "dataset")
    _validar_dataset_permitido(dataset)
    sql = f"select table_name, table_type from `{proyecto}.{dataset}`.INFORMATION_SCHEMA.TABLES"
    resultado = _ejecutar_query(sql)
    if resultado["status"] == "error":
        return resultado
    return {
        "status": "success",
        "mock": False,
        "bytes_facturados": resultado.get("bytes_facturados"),
        "proyecto": proyecto,
        "dataset": dataset,
        "tablas": resultado["filas"],
    }


def obtener_columnas(proyecto: str, dataset: str, tabla: str) -> dict[str, Any]:
    """Obtiene nombre, tipo de dato y descripción de las columnas de una
    tabla productiva, consultando INFORMATION_SCHEMA.COLUMNS +
    COLUMN_FIELD_PATHS en vivo.

    Úsala SIEMPRE antes de referenciar una columna en un SELECT/CTE, para
    confirmar su nombre exacto y tipo de dato — nunca asumas nombres.

    Args:
        proyecto: nombre del proyecto GCP.
        dataset: nombre del dataset.
        tabla: nombre de la tabla a inspeccionar.

    Returns:
        dict con status y la lista de columnas.
    """
    _validar_identificador(proyecto, "proyecto")
    _validar_identificador(dataset, "dataset")
    _validar_identificador(tabla, "tabla")
    _validar_dataset_permitido(dataset)
    sql = f"""
        select c.column_name, c.data_type, cfp.description
        from `{proyecto}.{dataset}`.INFORMATION_SCHEMA.COLUMNS c
        left join `{proyecto}.{dataset}`.INFORMATION_SCHEMA.COLUMN_FIELD_PATHS cfp
          on c.table_name = cfp.table_name and c.column_name = cfp.column_name
        where c.table_name = @tabla
    """
    params = [bigquery.ScalarQueryParameter("tabla", "STRING", tabla)]
    resultado = _ejecutar_query(sql, params)
    if resultado["status"] == "error":
        return resultado
    return {
        "status": "success",
        "mock": False,
        "bytes_facturados": resultado.get("bytes_facturados"),
        "proyecto": proyecto,
        "dataset": dataset,
        "tabla": tabla,
        "columnas": resultado["filas"],
    }


def buscar_procedimientos(proyecto: str, dataset: str, patron: str) -> dict[str, Any]:
    """Busca procedimientos ya existentes en INFORMATION_SCHEMA.ROUTINES,
    en vivo sobre el proyecto productivo.

    Úsala antes de escribir un procedimiento nuevo, para reutilizar lógica
    existente en vez de duplicarla.

    Args:
        proyecto: proyecto GCP donde viven los procedimientos
            (normalmente "prd-izipay-data-operation").
        dataset: dataset dentro del proyecto.
        patron: fragmento del nombre a buscar (se usa como LIKE '%patron%').

    Returns:
        dict con status y los procedimientos encontrados.
    """
    _validar_identificador(proyecto, "proyecto")
    _validar_identificador(dataset, "dataset")
    _validar_dataset_permitido(dataset)
    sql = f"""
        select routine_name, routine_type, routine_definition
        from `{proyecto}.{dataset}`.INFORMATION_SCHEMA.ROUTINES
        where routine_name like @patron
    """
    params = [bigquery.ScalarQueryParameter("patron", "STRING", f"%{patron}%")]
    resultado = _ejecutar_query(sql, params)
    if resultado["status"] == "error":
        return resultado
    return {
        "status": "success",
        "mock": False,
        "bytes_facturados": resultado.get("bytes_facturados"),
        "proyecto": proyecto,
        "dataset": dataset,
        "patron": patron,
        "procedimientos": resultado["filas"],
    }


def buscar_conocimiento_previo(dominio: str, palabras_clave: str) -> dict[str, Any]:
    """Busca querys de reportería ya validadas en el conocimiento previo del
    equipo, en la tabla conocimiento_previo_reporteria.

    Úsala ANTES de generar una query de reportería desde cero: si hay una
    entrada con alta similitud, adáptala en vez de reescribirla.

    Args:
        dominio: área de negocio, p. ej. "reportería CX", "reportería riesgo",
            "reportería comercios".
        palabras_clave: términos clave del requerimiento del usuario.

    Returns:
        dict con status y las entradas encontradas (solo funciono = true).
    """
    sql = f"""
        select pregunta_usuario, sql_generado, tablas_involucradas,
               creation_user, record_source, process_date, load_date
        from `{_TABLA_CONOCIMIENTO_PREVIO}`
        where funciono = true
          and dominio = @dominio
          and (pregunta_usuario like @palabras_clave or tablas_involucradas like @palabras_clave)
        order by load_date desc
        limit 5
    """
    params = [
        bigquery.ScalarQueryParameter("dominio", "STRING", dominio),
        bigquery.ScalarQueryParameter("palabras_clave", "STRING", f"%{palabras_clave}%"),
    ]
    resultado = _ejecutar_query(sql, params)
    if resultado["status"] == "error":
        return resultado
    return {
        "status": "success",
        "mock": False,
        "bytes_facturados": resultado.get("bytes_facturados"),
        "dominio": dominio,
        "palabras_clave": palabras_clave,
        "resultados": resultado["filas"],
    }


def proponer_insert_conocimiento_previo(
    dominio: str,
    pregunta_usuario: str,
    sql_generado: str,
    tablas_involucradas: str,
) -> dict[str, Any]:
    """Redacta (NO ejecuta) el INSERT para dar de alta una query ya validada
    en la tabla de conocimiento previo del equipo.

    Úsala solo cuando el usuario haya confirmado EXPLÍCITAMENTE que el
    script quedó validado por un experto del área (ej. "sí, ya lo validó
    Fulano" o "confirmado, dalo de alta") — nunca la uses solo porque una
    query corrió sin error, eso no es lo mismo que estar validada para el
    negocio. Esta tool solo devuelve el texto del INSERT: el analista debe
    revisarlo y ejecutarlo él mismo en BigQuery. Esta tool NUNCA escribe en
    la tabla ni ejecuta nada contra BigQuery.

    Los campos de auditoría (process_date, record_source, load_date,
    creation_user) se completan automáticamente en el INSERT usando
    funciones nativas de BigQuery (current_date, current_datetime,
    session_user), siguiendo el mismo patrón que usan las cargas nativas
    de IZIPAY — session_user() capturará el usuario real de quien ejecute
    el INSERT, no de este agente.

    Args:
        dominio: área de negocio, p. ej. "reportería comercios".
        pregunta_usuario: enunciado tipo del requerimiento que originó la query.
        sql_generado: la query final ya validada (tal como quedó aprobada).
        tablas_involucradas: tablas/datasets que toca la query, para indexar
            la búsqueda futura.

    Returns:
        dict con status y el texto del INSERT propuesto (para mostrarlo al
        usuario, nunca para ejecutarlo desde aquí).
    """

    def _escapar(texto: str) -> str:
        # Comillas triples """...""" porque sql_generado casi siempre trae
        # saltos de línea reales, y un literal '...' de comilla simple NO
        # puede contener saltos de línea en BigQuery (rompe con "Unclosed
        # string literal"). Se escapan backslash y comillas dobles, en ese
        # orden, para que ninguna secuencia """ quede sin escapar dentro
        # del texto.
        return texto.replace("\\", "\\\\").replace('"', '\\"')

    insert_sql = f"""insert into `{_TABLA_CONOCIMIENTO_PREVIO}`
  (dominio, pregunta_usuario, sql_generado, tablas_involucradas, funciono,
   process_date, record_source, load_date, creation_user)
select
  \"\"\"{_escapar(dominio)}\"\"\",
  \"\"\"{_escapar(pregunta_usuario)}\"\"\",
  \"\"\"{_escapar(sql_generado)}\"\"\",
  \"\"\"{_escapar(tablas_involucradas)}\"\"\",
  true,
  current_date('America/Lima'),
  'Agente Central de Reportería de IZIPAY - BAUSITO',
  current_datetime('America/Lima'),
  session_user();"""

    return {
        "status": "success",
        "mock": False,
        "ejecutado": False,
        "nota": (
            "Este INSERT NO fue ejecutado. Revísalo y ejecútalo tú mismo en "
            "BigQuery cuando confirmes que la query quedó validada."
        ),
        "insert_propuesto": insert_sql,
    }


def previsualizar_tabla(proyecto: str, dataset: str, tabla: str, columnas: list[str] | None = None, limite: int = 20) -> dict[str, Any]:
    """Previsualiza filas de una tabla SIN COSTO — usa la API de preview de
    BigQuery (tabledata.list), la misma que la pestaña "Preview" de la
    consola. NO ejecuta un query job ni escanea bytes facturables, a
    diferencia de ejecutar_select_muestra.

    Úsala PRIMERO cuando el usuario solo quiera "ver filas de muestra" o
    "algunas columnas" de una tabla, sin filtros, joins, cálculos ni
    lógica (por ejemplo: "muéstrame 5 filas de m_comercio",
    "dame cod_comercio y nom_comercio de muestra"). Es más barata y más
    rápida que ejecutar_select_muestra para ese caso.

    Limitación real: no soporta WHERE, joins, funciones ni desencriptación
    — es una lectura cruda de la tabla tal como está almacenada. Si el
    usuario pide algo con filtros, cálculos o desencriptación de PII, usa
    ejecutar_select_muestra en su lugar, no esta tool.

    Args:
        proyecto: nombre del proyecto GCP.
        dataset: nombre del dataset.
        tabla: nombre de la tabla.
        columnas: lista opcional de nombres de columna a traer (si se omite,
            trae todas las columnas de la tabla).
        limite: máximo de filas a devolver (default 20, tope duro 200).

    Returns:
        dict con status y las filas de muestra, sin costo de bytes facturados.
    """
    _validar_identificador(proyecto, "proyecto")
    _validar_identificador(dataset, "dataset")
    _validar_identificador(tabla, "tabla")
    _validar_dataset_permitido(dataset)
    limite = max(1, min(limite, 200))
    try:
        client = _get_client()
        tabla_ref = client.get_table(f"{proyecto}.{dataset}.{tabla}")
        rows = client.list_rows(tabla_ref, selected_fields=None, max_results=limite)
        filas = [
            {k: _valor_serializable(v) for k, v in dict(row).items() if columnas is None or k in columnas}
            for row in rows
        ]
        return {"status": "success", "mock": False, "costo": "sin cargo (preview API)", "filas": filas}
    except Exception as e:  # noqa: BLE001
        return {"status": "error", "mock": False, "error": str(e)}


def _detectar_dataset_excluido_en_sql(sql: str) -> str | None:
    """Escanea un SQL libre buscando referencias a datasets personales/de
    desarrollo dentro de rutas `proyecto.dataset.tabla` (siempre entre
    backticks, por convención de este agente) y devuelve el primer dataset
    excluido que encuentra, o None si no hay ninguno. No reemplaza los
    otros controles (_validar_dataset_permitido solo aplica a parámetros
    estructurados) — este cubre el caso de SQL escrito libremente, como en
    ejecutar_select_muestra.

    Importante: el dataset es siempre el SEGUNDO segmento de la ruta
    (proyecto.dataset.tabla) — nunca el primero, para no confundir el
    proyecto (ej. "prd-izipay-...", que también empieza con "pr") con el
    dataset real.
    """
    for m in re.finditer(r"`([A-Za-z0-9_.-]+)`", sql):
        partes = m.group(1).split(".")
        if len(partes) >= 2:
            candidato_dataset = partes[1]
            if _es_dataset_excluido(candidato_dataset):
                return candidato_dataset
    return None


def ejecutar_select_muestra(sql: str, limite: int = 20) -> dict[str, Any]:
    """Ejecuta una sentencia SELECT (de solo lectura) contra BigQuery
    productivo y devuelve una muestra de filas reales. A diferencia de
    previsualizar_tabla, esto SÍ ejecuta un query job y factura bytes
    escaneados (con tope en maximum_bytes_billed).

    Úsala cuando la solicitud necesita filtros (WHERE), joins, funciones,
    desencriptación de PII, o cualquier lógica que un preview crudo de
    tabla no puede resolver. Si el usuario solo quiere ver filas de
    muestra sin lógica, usa previsualizar_tabla en su lugar — es gratis y
    más rápida.

    NUNCA para sentencias que modifiquen o borren datos (esas se bloquean
    antes de llegar aquí, ver callbacks.py y la sección 11 del prompt).

    Args:
        sql: sentencia SQL completa, debe empezar con SELECT o WITH.
        limite: máximo de filas a devolver (default 20, tope duro 200).

    Returns:
        dict con status y las filas de muestra, o un error si la sentencia
        no es de solo lectura o si BigQuery rechaza la query.
    """
    sql_limpio = sql.strip()
    if not re.match(r"^(select|with)\b", sql_limpio, re.IGNORECASE):
        return {
            "status": "error",
            "mock": False,
            "error": "Solo se permiten sentencias SELECT o WITH de solo lectura en esta tool.",
        }
    dataset_excluido = _detectar_dataset_excluido_en_sql(sql_limpio)
    if dataset_excluido:
        return {
            "status": "error",
            "mock": False,
            "error": (
                f"'{dataset_excluido}' es un dataset personal/de desarrollo de un "
                f"analista — no se considera en consultas del agente. Usa un dataset "
                f"de producción real."
            ),
        }
    limite = max(1, min(limite, 200))
    if not re.search(r"\blimit\s+\d+\s*$", sql_limpio, re.IGNORECASE):
        sql_limpio = f"{sql_limpio.rstrip(';')}\nlimit {limite}"
    return _ejecutar_query(sql_limpio)


def _identidad_actual() -> str:
    """Intenta resolver la identidad de servicio que corre el código, para
    el campo de auditoría creation_user. En Cloud Run devuelve el correo
    del service account; en local (ADC de usuario) puede no estar
    disponible, y se usa un valor de reserva legible en vez de fallar.
    """
    try:
        import google.auth

        credenciales, _ = google.auth.default()
        email = getattr(credenciales, "service_account_email", None)
        if email:
            return email
    except Exception:  # noqa: BLE001
        pass
    return os.environ.get("K_SERVICE", "identidad-local-no-resuelta")


def registrar_log_uso(
    session_id: str,
    usuario_final: str,
    pregunta_usuario: str,
    dominio: str | None,
    tools_invocadas: str | None,
    modelo_usado: str,
    bytes_facturados: int | None,
    cache_hit: bool | None,
    tiempo_respuesta_ms: int | None,
    status: str,
    mensaje_error: str | None,
) -> None:
    """Inserta una fila de telemetría de uso en logs_uso_agente.

    A diferencia de proponer_insert_conocimiento_previo, esta función SÍ
    escribe directo en BigQuery — no es conocimiento de negocio que
    requiera validación humana, es telemetría operativa (quién, cuándo,
    qué tools, cuánto costó). Por eso tampoco se expone como tool del
    agente: la llama únicamente el callback after_agent_callback (ver
    callbacks.py), nunca el modelo por su cuenta.

    Falla en silencio (solo deja un print) si la escritura no funciona —
    un problema de logging nunca debe tumbar la respuesta real al usuario.
    """
    from datetime import datetime

    try:
        from zoneinfo import ZoneInfo

        ahora = datetime.now(ZoneInfo("America/Lima"))
    except Exception:  # noqa: BLE001
        ahora = datetime.utcnow()

    fila = {
        "session_id": session_id,
        "usuario_final": usuario_final,
        "pregunta_usuario": (pregunta_usuario or "")[:8000],
        "dominio": dominio,
        "tools_invocadas": tools_invocadas,
        "modelo_usado": modelo_usado,
        "bytes_facturados": bytes_facturados,
        "cache_hit": cache_hit,
        "tiempo_respuesta_ms": tiempo_respuesta_ms,
        "status": status,
        "mensaje_error": (mensaje_error or None) and mensaje_error[:2000],
        "process_date": ahora.date().isoformat(),
        "record_source": "Agente Central de Reportería de IZIPAY - BAUSITO",
        "load_date": ahora.strftime("%Y-%m-%dT%H:%M:%S"),
        "creation_user": _identidad_actual(),
    }
    try:
        client = _get_client()
        errores = client.insert_rows_json(_TABLA_LOGS_USO, [fila])
        if errores:
            print(f"[logs_uso_agente] BigQuery rechazó el insert: {errores}")
    except Exception as e:  # noqa: BLE001 — nunca dejar que un fallo de logging tumbe la respuesta
        print(f"[logs_uso_agente] excepción al insertar log: {e}")
