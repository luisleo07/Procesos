-- ══════════════════════════════════════════════════════════
-- DDL BigQuery — Fraude NomCom v3
-- Dataset: dev-izipay-data-storage.master_party
-- ══════════════════════════════════════════════════════════

-- TABLA 1: Afiliaciones a analizar (Hugo alimenta)
CREATE TABLE IF NOT EXISTS `dev-izipay-data-storage.master_party.lista_afiliaciones_analizar` (
  cod_comercio            STRING NOT NULL,
  nom_comercio            STRING NOT NULL,
  tipo_documento          STRING,
  fecha_apertura_comercio DATE,
  fecha_carga             TIMESTAMP
);

-- TABLA 2: Lista de referencia (Hugo alimenta)
CREATE TABLE IF NOT EXISTS `dev-izipay-data-storage.master_party.lista_referencia_nomcom` (
  id                  INT64     NOT NULL,
  nombre_comercial    STRING    NOT NULL,
  razon_social        STRING,
  origen              STRING    NOT NULL,
  activo              BOOL      NOT NULL,
  fecha_actualizacion TIMESTAMP NOT NULL
);

-- TABLA 3: Resultados del análisis (la API escribe)
CREATE TABLE IF NOT EXISTS `dev-izipay-data-storage.master_party.resultado_analisis_nomcom` (
  id                      STRING    NOT NULL,
  id_batch                STRING    NOT NULL,
  cod_comercio            STRING,
  nom_comercio            STRING    NOT NULL,
  nom_comercio_norm       STRING,
  nombre_referencia_match STRING,
  origen_referencia       STRING,
  score_sintactico        FLOAT64,
  score_semantico         FLOAT64,
  score_ia                FLOAT64,
  score_final             FLOAT64,
  nivel_alerta            STRING,
  metodo_deteccion        STRING,
  detalle_ia              STRING,
  origen                  STRING,
  fecha_analisis          TIMESTAMP NOT NULL
);

-- TABLA 4: Log de consultas (la API escribe)
CREATE TABLE IF NOT EXISTS `dev-izipay-data-storage.master_party.log_consultas_nomcom` (
  id                  STRING    NOT NULL,
  origen              STRING,
  usuario             STRING,
  nombre_consultado   STRING,
  nombre_normalizado  STRING,
  cantidad_matches    INT64,
  max_score           FLOAT64,
  nivel_alerta_max    STRING,
  ip_origen           STRING,
  tiempo_respuesta_ms INT64,
  fecha_consulta      TIMESTAMP NOT NULL
);
