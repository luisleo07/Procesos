"""
Callbacks de seguridad del Agente BAU Reporteador.

La sección 11 del prompt ("nunca borrar en producción") es una regla
innegociable. No basta con confiar en que el LLM la respete siempre por
texto: este callback la refuerza a nivel de código, bloqueando la
ejecución de cualquier tool cuyo argumento contenga una sentencia SQL
destructiva, ANTES de que llegue a correr.

Hoy (fase mock) ninguna tool ejecuta SQL real contra BigQuery, así que este
callback no debería activarse — pero queda conectado desde ya, para que el
día que se agregue una tool tipo `ejecutar_sql(query: str)` la protección
ya esté puesta y no dependa de acordarse de agregarla después.
"""

import re
from typing import Any

# Patrones prohibidos según la sección 11 del prompt: DROP, TRUNCATE,
# DELETE FROM, y MERGE ... WHEN MATCHED THEN DELETE.
_PATRONES_PROHIBIDOS = [
    re.compile(r"\bdrop\s+(table|schema|dataset)\b", re.IGNORECASE),
    re.compile(r"\btruncate\s+table\b", re.IGNORECASE),
    re.compile(r"\bdelete\s+from\b", re.IGNORECASE),
    re.compile(r"\bwhen\s+matched\s+then\s+delete\b", re.IGNORECASE),
    re.compile(r"\balter\s+table\b.*\bdrop\b", re.IGNORECASE | re.DOTALL),
]


def bloquear_sql_destructivo(tool, args: dict[str, Any], tool_context):
    """before_tool_callback: bloquea tools cuyos argumentos de texto
    contengan una sentencia SQL destructiva sobre producción.

    Si detecta un patrón prohibido, devuelve una respuesta de error en vez
    de dejar que el ADK ejecute la tool (equivalente a "cortocircuitar" la
    llamada). Si todo está limpio, devuelve None y el flujo normal continúa.
    """
    for valor in args.values():
        if not isinstance(valor, str):
            continue
        for patron in _PATRONES_PROHIBIDOS:
            if patron.search(valor):
                return {
                    "status": "error",
                    "error": (
                        "Bloqueado por regla de seguridad (sección 11 del prompt): "
                        "el agente no puede ejecutar sentencias que borren, trunquen "
                        "o eliminen datos/objetos en producción. Si el requerimiento "
                        "realmente necesita eliminar datos, debe hacerlo manualmente "
                        "una persona autorizada, fuera del agente."
                    ),
                }
    return None


# ---------------------------------------------------------------------------
# Logging de uso — Fase 1. Se llena SOLO, sin validación humana (a diferencia
# del conocimiento previo): es telemetría operativa (quién, cuándo, qué
# tools, cuánto costó), no una afirmación de negocio.
#
# Patrón: acumular_telemetria_tool va guardando datos en tool_context.state
# en cada llamada a tool durante el turno; registrar_uso_turno lee ese
# acumulado al final del turno y escribe UNA sola fila en BigQuery.
# ---------------------------------------------------------------------------

import time

# Nombre del modelo activo — hoy es fijo porque solo hay un modelo. Cuando
# se implemente el diseño multi-modelo (Fase 2), esto debe resolverse por
# sub-agente en vez de ser una constante única.
_MODELO_ACTUAL = "gemini-3.1-flash-lite"


def marcar_inicio_turno(callback_context):
    """before_agent_callback: guarda el timestamp de inicio del turno, para
    poder calcular tiempo_respuesta_ms al cerrar el log.

    ADK invoca este callback pasando el argumento por nombre exacto
    "callback_context" (no posicional) — el nombre del parámetro debe
    coincidir, si no lanza TypeError.
    """
    callback_context.state["_log_inicio_ts"] = time.time()
    return None


def acumular_telemetria_tool(tool, args: dict[str, Any], tool_context, tool_response):
    """after_tool_callback: acumula, en el estado de la sesión, qué tools se
    llamaron y cuántos bytes se facturaron durante el turno actual — sin
    modificar la respuesta real que ve el modelo.
    """
    tools_previas = tool_context.state.get("_log_tools_invocadas", [])
    tools_previas.append(tool.name)
    tool_context.state["_log_tools_invocadas"] = tools_previas

    if isinstance(tool_response, dict):
        bytes_nuevos = tool_response.get("bytes_facturados") or 0
        bytes_previos = tool_context.state.get("_log_bytes_facturados", 0)
        tool_context.state["_log_bytes_facturados"] = bytes_previos + bytes_nuevos

        if tool_response.get("status") == "error":
            tool_context.state["_log_status"] = "error"
            tool_context.state["_log_mensaje_error"] = str(tool_response.get("error"))[:2000]

        if tool_response.get("cache_hit"):
            tool_context.state["_log_cache_hit"] = True

    return None  # nunca modifica la respuesta original de la tool


def registrar_uso_turno(callback_context):
    """after_agent_callback: al cerrar el turno, arma y guarda UNA fila de
    telemetría en logs_uso_agente — automático, sin validación humana.

    ADK invoca este callback pasando el argumento por nombre exacto
    "callback_context" (no posicional) — igual que marcar_inicio_turno.

    Import perezoso de tools (en vez de al tope del archivo) para evitar un
    ciclo de imports, ya que agent.py importa este módulo antes que tools.
    """
    from . import tools as _tools

    inicio = callback_context.state.get("_log_inicio_ts")
    tiempo_ms = int((time.time() - inicio) * 1000) if inicio else None

    tools_invocadas = callback_context.state.get("_log_tools_invocadas", [])

    pregunta = ""
    try:
        if callback_context.user_content and callback_context.user_content.parts:
            pregunta = " ".join(
                p.text for p in callback_context.user_content.parts if getattr(p, "text", None)
            )
    except Exception:  # noqa: BLE001
        pregunta = ""

    _tools.registrar_log_uso(
        session_id=getattr(callback_context.session, "id", None) or callback_context.invocation_id,
        usuario_final=callback_context.user_id or "desconocido",
        pregunta_usuario=pregunta,
        dominio=None,
        tools_invocadas=", ".join(tools_invocadas) if tools_invocadas else None,
        modelo_usado=_MODELO_ACTUAL,
        bytes_facturados=callback_context.state.get("_log_bytes_facturados") or None,
        cache_hit=callback_context.state.get("_log_cache_hit"),
        tiempo_respuesta_ms=tiempo_ms,
        status=callback_context.state.get("_log_status", "success"),
        mensaje_error=callback_context.state.get("_log_mensaje_error"),
    )

    # Reinicia los acumuladores para que el próximo turno empiece de cero.
    # State (de ADK) no soporta .pop() ni del — solo lectura/escritura por
    # clave — así que "limpiar" significa sobrescribir con un valor neutro,
    # no borrar la clave.
    callback_context.state["_log_inicio_ts"] = None
    callback_context.state["_log_tools_invocadas"] = []
    callback_context.state["_log_bytes_facturados"] = 0
    callback_context.state["_log_status"] = "success"
    callback_context.state["_log_mensaje_error"] = None
    callback_context.state["_log_cache_hit"] = False

    return None  # nunca cambia la respuesta final que recibe el usuario
