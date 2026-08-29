"""
Agente Central de Reportería de IZIPAY - BAUSITO

Fase actual: PRODUCCIÓN. Las tools (ver tools.py) consultan y ejecutan
contra BigQuery productivo real.

`adk web` busca en este archivo una variable llamada exactamente
`root_agent` — no cambies ese nombre.
"""

from google.adk.agents import Agent

from . import tools
from .callbacks import (
    acumular_telemetria_tool,
    bloquear_sql_destructivo,
    marcar_inicio_turno,
    registrar_uso_turno,
)
from .prompts import SYSTEM_PROMPT

root_agent = Agent(
    name="agente_bau_reporteador",
    model="gemini-3.1-flash-lite",  # rápido y económico, ideal para iterar el flujo en pruebas
    description=(
        "Agente Central de Reportería de IZIPAY - BAUSITO: genera y valida SQL de BigQuery "
        "para reportería (queries, fichas de reporte, procedimientos), "
        "consultando INFORMATION_SCHEMA en vivo y el conocimiento previo "
        "curado del equipo. Apoya también migraciones puntuales desde Azure "
        "como capacidad secundaria."
    ),
    instruction=SYSTEM_PROMPT,
    tools=[
        tools.listar_datasets,
        tools.buscar_tabla_por_nombre,
        tools.listar_tablas,
        tools.obtener_columnas,
        tools.buscar_procedimientos,
        tools.buscar_conocimiento_previo,
        tools.proponer_insert_conocimiento_previo,
        tools.previsualizar_tabla,
        tools.ejecutar_select_muestra,
    ],
    before_tool_callback=bloquear_sql_destructivo,
    before_agent_callback=marcar_inicio_turno,
    after_tool_callback=acumular_telemetria_tool,
    after_agent_callback=registrar_uso_turno,
)
