-- ══════════════════════════════════════════════════════════
-- Tabla de auditoría de DESCARTADOS (P1 — visibilidad)
-- Recibe los casos que NO generan alerta:
--   * metodo_deteccion = 'JUNTA_MEDICA' -> descartado por la IA (con detalle_ia)
--   * metodo_deteccion = 'PRE_FILTRO'   -> descartado por regla previa (sin IA)
-- Particionada por fecha_batch para controlar costo/volumen.
-- Recomendado: setear expiración de partición (p.ej. 90 días).
-- ══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS `dev-izipay-data-storage.raw_riesgo_operativo.auditoria_descartados_fraude_nomcom` (
  id                      STRING,
  id_batch                STRING,
  fecha_batch             DATE,
  cod_comercio            STRING,
  nom_comercio            STRING,
  nom_comercio_norm       STRING,
  tipo_documento          STRING,
  fecha_apertura_comercio DATE,
  nombre_referencia_match STRING,
  origen_referencia       STRING,
  score_sintactico        FLOAT64,
  score_semantico         FLOAT64,
  score_ia                FLOAT64,
  score_final             FLOAT64,
  nivel_alerta            STRING,   -- siempre 'DESCARTADO'
  metodo_deteccion        STRING,   -- 'JUNTA_MEDICA' | 'PRE_FILTRO'
  detalle_ia              STRING,
  razon_social            STRING,
  representante_legal     STRING,
  origen                  STRING,
  procesado_por           STRING,
  fecha_analisis          TIMESTAMP
)
PARTITION BY fecha_batch
CLUSTER BY metodo_deteccion, cod_comercio;

-- Opcional: expiración de partición a 90 días
-- ALTER TABLE `dev-izipay-data-storage.raw_riesgo_operativo.auditoria_descartados_fraude_nomcom`
--   SET OPTIONS (partition_expiration_days = 90);
