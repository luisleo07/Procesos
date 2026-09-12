ALTER TABLE `dev-izipay-data-storage.raw_riesgo_operativo.resultado_analisis_fraude_nomcom`
ADD COLUMN IF NOT EXISTS fecha_batch DATE,
ADD COLUMN IF NOT EXISTS razon_social STRING,
ADD COLUMN IF NOT EXISTS representante_legal STRING,
ADD COLUMN IF NOT EXISTS id_referencia INT64,
ADD COLUMN IF NOT EXISTS score_fonetico FLOAT64,
ADD COLUMN IF NOT EXISTS tecnica_suplantacion STRING,
ADD COLUMN IF NOT EXISTS marca_identificada STRING,
ADD COLUMN IF NOT EXISTS es_fraude_ia BOOL,
ADD COLUMN IF NOT EXISTS fase_skip STRING,
ADD COLUMN IF NOT EXISTS procesado_por STRING,
ADD COLUMN IF NOT EXISTS duracion_ms INT64,
ADD COLUMN IF NOT EXISTS revision_royc STRING,
ADD COLUMN IF NOT EXISTS fecha_revision TIMESTAMP,
ADD COLUMN IF NOT EXISTS comentario_revision STRING,
ADD COLUMN IF NOT EXISTS revisado_por STRING;

CREATE OR REPLACE VIEW `dev-izipay-data-storage.raw_riesgo_operativo.v_alertas_pendientes` AS
SELECT fecha_batch, cod_comercio, nom_comercio, tipo_documento, fecha_apertura_comercio,
       nombre_referencia_match, marca_identificada, tecnica_suplantacion,
       ROUND(score_final, 3) AS score_final, nivel_alerta,
       SUBSTR(detalle_ia, 1, 300) AS detalle_ia, origen, fecha_analisis
FROM `dev-izipay-data-storage.raw_riesgo_operativo.resultado_analisis_fraude_nomcom`
WHERE nivel_alerta IN ('ALTA', 'MEDIA') AND revision_royc IS NULL
ORDER BY fecha_batch DESC, score_final DESC;

CREATE OR REPLACE VIEW `dev-izipay-data-storage.raw_riesgo_operativo.v_resumen_batches` AS
SELECT fecha_batch, id_batch, origen,
       COUNT(*) AS total,
       COUNTIF(nivel_alerta = 'ALTA') AS alta,
       COUNTIF(nivel_alerta = 'MEDIA') AS media,
       COUNTIF(nivel_alerta = 'BAJA') AS baja,
       COUNTIF(fase_skip IS NOT NULL) AS skipped,
       COUNTIF(revision_royc IS NOT NULL) AS revisados,
       MIN(fecha_analisis) AS inicio, MAX(fecha_analisis) AS fin
FROM `dev-izipay-data-storage.raw_riesgo_operativo.resultado_analisis_fraude_nomcom`
GROUP BY fecha_batch, id_batch, origen;

CREATE OR REPLACE VIEW `dev-izipay-data-storage.raw_riesgo_operativo.v_traza_comercio` AS
SELECT r.fecha_batch, r.id_batch, r.cod_comercio, r.nom_comercio, r.nom_comercio_norm,
       a.razon_social, a.representante_legal, a.tipo_documento, a.fecha_apertura_comercio,
       a.fecha_carga AS fecha_ingreso, r.nombre_referencia_match, r.origen_referencia,
       r.score_sintactico, r.score_semantico, r.score_ia, r.score_final,
       r.nivel_alerta, r.metodo_deteccion, r.tecnica_suplantacion, r.marca_identificada,
       r.detalle_ia, r.fase_skip, r.origen, r.procesado_por, r.fecha_analisis,
       r.revision_royc, r.fecha_revision, r.comentario_revision, r.revisado_por
FROM `dev-izipay-data-storage.raw_riesgo_operativo.resultado_analisis_fraude_nomcom` r
LEFT JOIN `dev-izipay-data-storage.raw_riesgo_operativo.lista_afiliaciones_analizar` a
  ON r.cod_comercio = a.cod_comercio;
