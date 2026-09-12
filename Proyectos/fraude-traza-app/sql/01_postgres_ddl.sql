CREATE SCHEMA IF NOT EXISTS fraude;

CREATE TABLE IF NOT EXISTS fraude.batch_runs (
  id              SERIAL PRIMARY KEY,
  id_batch        TEXT NOT NULL UNIQUE,
  fecha_batch     DATE NOT NULL DEFAULT CURRENT_DATE,
  origen          TEXT NOT NULL DEFAULT 'PIPELINE_DIARIO',
  estado          TEXT NOT NULL DEFAULT 'INICIADO',
  total_input     INT DEFAULT 0,
  total_evaluate  INT DEFAULT 0,
  total_skip      INT DEFAULT 0,
  alertas_alta    INT DEFAULT 0,
  alertas_media   INT DEFAULT 0,
  alertas_baja    INT DEFAULT 0,
  duracion_seg    INT,
  error_message   TEXT,
  iniciado_por    TEXT DEFAULT 'SCHEDULER',
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  finished_at     TIMESTAMPTZ,
  CONSTRAINT chk_estado CHECK (estado IN ('INICIADO','EN_PROCESO','COMPLETADO','ERROR','CANCELADO'))
);
CREATE INDEX IF NOT EXISTS idx_batch_runs_fecha ON fraude.batch_runs(fecha_batch DESC);

CREATE TABLE IF NOT EXISTS fraude.batch_log (
  id              SERIAL PRIMARY KEY,
  id_batch        TEXT NOT NULL REFERENCES fraude.batch_runs(id_batch),
  paso            TEXT NOT NULL,
  nivel           TEXT NOT NULL DEFAULT 'INFO',
  mensaje         TEXT NOT NULL,
  detalle         JSONB,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_nivel CHECK (nivel IN ('DEBUG','INFO','WARN','ERROR','FATAL'))
);
CREATE INDEX IF NOT EXISTS idx_batch_log_batch ON fraude.batch_log(id_batch, created_at);

CREATE TABLE IF NOT EXISTS fraude.incidencias (
  id              SERIAL PRIMARY KEY,
  id_batch        TEXT REFERENCES fraude.batch_runs(id_batch),
  tipo            TEXT NOT NULL,
  severidad       TEXT NOT NULL DEFAULT 'MEDIA',
  titulo          TEXT NOT NULL,
  detalle         TEXT,
  stack_trace     TEXT,
  cod_comercio    TEXT,
  estado          TEXT NOT NULL DEFAULT 'ABIERTA',
  resuelta_por    TEXT,
  fecha_resolucion TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_severidad CHECK (severidad IN ('BAJA','MEDIA','ALTA','CRITICA')),
  CONSTRAINT chk_estado_inc CHECK (estado IN ('ABIERTA','EN_REVISION','RESUELTA','IGNORADA'))
);
CREATE INDEX IF NOT EXISTS idx_incidencias_estado ON fraude.incidencias(estado, created_at DESC);

CREATE TABLE IF NOT EXISTS fraude.revision_royc (
  id              SERIAL PRIMARY KEY,
  id_resultado_bq TEXT NOT NULL,
  id_batch        TEXT NOT NULL,
  cod_comercio    TEXT NOT NULL,
  nom_comercio    TEXT NOT NULL,
  nivel_alerta    TEXT NOT NULL,
  score_final     FLOAT,
  decision        TEXT NOT NULL,
  motivo          TEXT,
  accion_tomada   TEXT,
  revisado_por    TEXT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT chk_decision CHECK (decision IN ('CONFIRMADO_FRAUDE','FALSO_POSITIVO','REQUIERE_MAS_INFO','ESCALADO'))
);
CREATE INDEX IF NOT EXISTS idx_revision_cod ON fraude.revision_royc(cod_comercio);
CREATE INDEX IF NOT EXISTS idx_revision_batch ON fraude.revision_royc(id_batch);

CREATE TABLE IF NOT EXISTS fraude.audit_trail (
  id              SERIAL PRIMARY KEY,
  tabla           TEXT NOT NULL,
  accion          TEXT NOT NULL,
  registro_id     TEXT NOT NULL,
  campo_modificado TEXT,
  valor_anterior  TEXT,
  valor_nuevo     TEXT,
  usuario         TEXT NOT NULL,
  ip_origen       TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_registro ON fraude.audit_trail(tabla, registro_id);

CREATE TABLE IF NOT EXISTS fraude.resultados_cache (
  id                      TEXT PRIMARY KEY,
  id_batch                TEXT NOT NULL,
  fecha_batch             DATE NOT NULL,
  cod_comercio            TEXT NOT NULL,
  nom_comercio            TEXT NOT NULL,
  nom_comercio_norm       TEXT,
  tipo_documento          TEXT,
  fecha_apertura_comercio DATE,
  nombre_referencia_match TEXT,
  origen_referencia       TEXT,
  score_sintactico        FLOAT,
  score_semantico         FLOAT,
  score_ia                FLOAT,
  score_final             FLOAT,
  nivel_alerta            TEXT,
  metodo_deteccion        TEXT,
  tecnica_suplantacion    TEXT,
  marca_identificada      TEXT,
  detalle_ia              TEXT,
  fase_skip               TEXT,
  origen                  TEXT,
  fecha_analisis          TIMESTAMPTZ,
  synced_at               TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cache_fecha ON fraude.resultados_cache(fecha_batch DESC);
CREATE INDEX IF NOT EXISTS idx_cache_alerta ON fraude.resultados_cache(nivel_alerta) WHERE nivel_alerta IN ('ALTA','MEDIA');
CREATE INDEX IF NOT EXISTS idx_cache_comercio ON fraude.resultados_cache(cod_comercio);

CREATE TABLE IF NOT EXISTS fraude.stats_diarias (
  id              SERIAL PRIMARY KEY,
  fecha           DATE NOT NULL UNIQUE,
  total_afiliaciones INT,
  total_referencia   INT,
  total_evaluados    INT,
  total_skipped      INT,
  alertas_alta       INT,
  alertas_media      INT,
  alertas_baja       INT,
  revisados          INT DEFAULT 0,
  confirmados_fraude INT DEFAULT 0,
  falsos_positivos   INT DEFAULT 0,
  precision_pct      FLOAT,
  duracion_seg       INT,
  created_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE VIEW fraude.v_alertas_pendientes AS
SELECT
  rc.id, rc.id_batch, rc.fecha_batch, rc.cod_comercio, rc.nom_comercio,
  rc.tipo_documento, rc.nombre_referencia_match, rc.marca_identificada,
  rc.tecnica_suplantacion, rc.score_final, rc.nivel_alerta, rc.detalle_ia, rc.origen
FROM fraude.resultados_cache rc
LEFT JOIN fraude.revision_royc rv ON rc.id = rv.id_resultado_bq
WHERE rc.nivel_alerta IN ('ALTA', 'MEDIA') AND rv.id IS NULL
ORDER BY rc.fecha_batch DESC, rc.score_final DESC;

CREATE OR REPLACE VIEW fraude.v_dashboard AS
SELECT
  br.fecha_batch, br.id_batch, br.estado, br.total_input,
  br.alertas_alta, br.alertas_media, br.alertas_baja, br.total_skip,
  br.duracion_seg, br.iniciado_por,
  COALESCE(rev.revisados, 0) AS revisados,
  COALESCE(rev.confirmados, 0) AS confirmados_fraude,
  COALESCE(rev.falsos_pos, 0) AS falsos_positivos,
  COALESCE(inc.total, 0) AS incidencias_abiertas
FROM fraude.batch_runs br
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS revisados,
         COUNT(*) FILTER (WHERE decision = 'CONFIRMADO_FRAUDE') AS confirmados,
         COUNT(*) FILTER (WHERE decision = 'FALSO_POSITIVO') AS falsos_pos
  FROM fraude.revision_royc WHERE id_batch = br.id_batch
) rev ON TRUE
LEFT JOIN LATERAL (
  SELECT COUNT(*) AS total FROM fraude.incidencias WHERE id_batch = br.id_batch AND estado = 'ABIERTA'
) inc ON TRUE
ORDER BY br.fecha_batch DESC;

CREATE OR REPLACE VIEW fraude.v_traza_comercio AS
SELECT
  rc.cod_comercio, rc.nom_comercio, rc.fecha_batch, rc.score_final,
  rc.nivel_alerta, rc.nombre_referencia_match, rc.tecnica_suplantacion,
  rc.marca_identificada, rc.fase_skip, rc.origen,
  rv.decision, rv.motivo, rv.revisado_por, rv.created_at AS fecha_revision
FROM fraude.resultados_cache rc
LEFT JOIN fraude.revision_royc rv ON rc.id = rv.id_resultado_bq
ORDER BY rc.fecha_batch DESC;
