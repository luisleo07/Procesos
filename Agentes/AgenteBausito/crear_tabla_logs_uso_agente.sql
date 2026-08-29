-- Tabla de logs de uso del Agente Central de Reportería de IZIPAY - BAUSITO.
-- A diferencia de conocimiento_previo_reporteria, esta tabla SÍ se llena
-- automáticamente en cada turno — es telemetría operativa (quién, cuándo,
-- qué costó, si vino de caché), no conocimiento de negocio que requiera
-- validación humana.
--
-- Ejecutar UNA VEZ, antes de activar el logging en el agente.

create table if not exists `prd-izipay-data-storage-pv.agente_conocimiento.logs_uso_agente` (
  session_id           string    not null options(description = 'ID de la sesión/conversación en ADK — agrupa todos los turnos de un mismo chat'),
  usuario_final         string   not null options(description = 'user_id real de la persona que conversó con el agente (correo corporativo, vía VertexAiSessionService) — distinto de creation_user, que siempre es la identidad de servicio del agente'),
  pregunta_usuario      string    not null options(description = 'Texto de la pregunta/solicitud de ese turno'),
  dominio               string            options(description = 'Área de negocio si aplica (reportería comercios, riesgo, etc.)'),
  tools_invocadas        string           options(description = 'Lista de tools llamadas en ese turno, separadas por coma, en orden'),
  modelo_usado           string   not null options(description = 'Modelo que generó la respuesta (ej. gemini-3.1-flash-lite) — clave cuando haya más de un modelo en el agente'),
  bytes_facturados        integer         options(description = 'Bytes reales facturados por BigQuery en ese turno (suma de todos los query jobs). NULL si no se ejecutó ningún query facturable'),
  cache_hit               bool            options(description = 'true si la respuesta de metadata vino de la caché diaria en vez de consultar INFORMATION_SCHEMA en vivo'),
  tiempo_respuesta_ms      integer        options(description = 'Latencia total del turno, en milisegundos'),
  status                  string   not null options(description = 'success | error'),
  mensaje_error            string          options(description = 'Detalle del error si status = error'),

  -- Campos de auditoría estándar de IZIPAY (mismo patrón que conocimiento_previo_reporteria)
  process_date            date     not null options(description = 'Fecha de proceso (America/Lima)'),
  record_source            string          options(description = 'Aplicativo origen — "Agente Central de Reportería de IZIPAY - BAUSITO"'),
  load_date                datetime not null options(description = 'Fecha y hora de inserción del registro'),
  creation_user             string  not null options(description = 'Identidad que crea el registro — session_user(), siempre el service account del agente, no la persona')
)
partition by process_date
options (
  description = 'Log de uso operativo del agente BAUSITO: quién, cuándo, qué tools, costo y estado de cada turno. Se llena automáticamente, sin validación humana — es telemetría, no conocimiento de negocio.'
);
