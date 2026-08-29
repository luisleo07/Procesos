-- Crea el dataset y la tabla de conocimiento previo curado del equipo
-- (sección 9 del prompt del agente). Ejecutar UNA VEZ, manualmente, antes
-- de que el agente empiece a usar buscar_conocimiento_previo().
--
-- Proyecto: prd-izipay-data-storage-pv (a pedido del usuario).
-- Incluye los 4 campos de auditoría estándar de IZIPAY (mismos usados en
-- las cargas nativas del equipo, ver Notebook_GCP de referencia):
--   process_date, record_source, load_date, creation_user.

create schema if not exists `prd-izipay-data-storage-pv.agente_conocimiento`
options (
  location = 'US',
  description = 'Dataset de conocimiento curado generado/consultado por agentes IA de reportería.'
);

create table if not exists `prd-izipay-data-storage-pv.agente_conocimiento.conocimiento_previo_reporteria` (
  dominio               string    not null options(description = 'Área de negocio (ej. reportería CX, reportería riesgo, reportería comercios)'),
  pregunta_usuario      string    not null options(description = 'Enunciado tipo del requerimiento que originó la query'),
  sql_generado          string    not null options(description = 'Query final validada (formateada según sección 4 del prompt)'),
  tablas_involucradas   string            options(description = 'Tablas/datasets que toca, para indexar la búsqueda'),
  funciono              bool      not null options(description = 'true si la query fue aprobada/usada en producción'),

  -- Campos de auditoría estándar de IZIPAY
  process_date          date      not null options(description = 'Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
  record_source          string           options(description = 'Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
  load_date              datetime  not null options(description = 'Fecha y hora de inserción del registro en el modelo'),
  creation_user           string   not null options(description = 'Usuario que crea el registro en la BD')
)
options (
  description = 'Conocimiento previo curado de reportería, usado por el Agente Central de Reportería de IZIPAY - BAUSITO (buscar_conocimiento_previo). Carga manual, validada por un experto del área — el agente solo propone el INSERT, nunca lo ejecuta.'
);

-- Ejemplo de formato de INSERT (referencia — el agente genera algo así vía
-- la tool proponer_insert_conocimiento_previo, para que el analista lo
-- revise y lo corra manualmente):
--
-- insert into `prd-izipay-data-storage-pv.agente_conocimiento.conocimiento_previo_reporteria`
--   (dominio, pregunta_usuario, sql_generado, tablas_involucradas, funciono,
--    process_date, record_source, load_date, creation_user)
-- select
--   'reportería comercios',
--   'Comercios activos por segmento del mes',
--   'select ... from prd-izipay-data-storage-pv.master_party.m_comercio ...',
--   'master_party.m_comercio',
--   true,
--   current_date('America/Lima'),
--   'Agente Central de Reportería de IZIPAY - BAUSITO',
--   current_datetime('America/Lima'),
--   session_user();
